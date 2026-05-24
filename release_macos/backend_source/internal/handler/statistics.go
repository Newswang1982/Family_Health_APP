package handler

import (
	"database/sql"
	"encoding/json"
	"math"
	"net/http"
	"sort"
	"strconv"
	"time"

	"family-health-backend/internal/db"

	"github.com/gin-gonic/gin"
)

type StatisticsHandler struct {
	checkMember func(userID, familyID string) bool
}

func NewStatisticsHandler(checkMember func(userID, familyID string) bool) *StatisticsHandler {
	return &StatisticsHandler{checkMember: checkMember}
}

type KLinePoint struct {
	Date  string  `json:"date"`
	Open  float64 `json:"open"`
	Close float64 `json:"close"`
	High  float64 `json:"high"`
	Low   float64 `json:"low"`
	Mean  float64 `json:"mean"`
	Count int     `json:"count"`
}

type sleepEntry struct {
	date     string
	duration float64
}

var indicatorMapping = map[string]struct {
	table      string
	recordType string
	valueField string
}{
	"heart_rate":     {table: "health_records", recordType: "vitals", valueField: "heart_rate"},
	"blood_pressure": {table: "health_records", recordType: "vitals", valueField: "bp_systolic"},
	"blood_oxygen":   {table: "health_records", recordType: "vitals", valueField: "blood_oxygen"},
	"temperature":    {table: "health_records", recordType: "vitals", valueField: "temperature"},
	"weight":         {table: "health_records", recordType: "vitals", valueField: "weight"},
	"blood_sugar":    {table: "health_records", recordType: "vitals", valueField: "blood_sugar"},
	"smoking":        {table: "smoking_records", recordType: "", valueField: "count"},
	"drinking":       {table: "drinking_records", recordType: "", valueField: "amount"},
}

func (h *StatisticsHandler) GetStatistics(c *gin.Context) {
	profileID := c.Param("pid")
	indicatorType := c.Param("indicator_type")
	period := c.DefaultQuery("period", "month")

	userID, _ := c.Get("user_id")
	familyID := c.Query("family_id")
	if familyID != "" && !h.checkMember(userID.(string), familyID) {
		c.JSON(http.StatusForbidden, gin.H{"error": "not a family member"})
		return
	}

	dateFrom, dateTo := getPeriodRange(period)

	var refMin, refMax *float64
	row := db.DB.QueryRow(
		`SELECT min_value, max_value FROM health_reference_ranges 
		 WHERE member_profile_id = ? AND indicator_type = ?`,
		profileID, indicatorType,
	)
	var rm, rx float64
	if err := row.Scan(&rm, &rx); err == nil {
		refMin = &rm
		refMax = &rx
	}

	values, err := queryIndicatorValues(profileID, indicatorType, dateFrom, dateTo)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "query failed", "detail": err.Error()})
		return
	}

	if len(values) == 0 {
		c.JSON(http.StatusOK, gin.H{
			"indicator": indicatorType, "period": period,
			"mean": nil, "median": nil, "min": nil, "max": nil,
			"reference_min": refMin, "reference_max": refMax,
			"status": "no_data", "data_points": 0, "values": []float64{},
		})
		return
	}

	sort.Float64s(values)
	mean := calculateMean(values)
	median := calculateMedian(values)
	minVal := values[0]
	maxVal := values[len(values)-1]

	status := "normal"
	if refMin != nil && mean < *refMin {
		status = "below_range"
	}
	if refMax != nil && mean > *refMax {
		status = "above_range"
	}

	c.JSON(http.StatusOK, gin.H{
		"indicator": indicatorType, "period": period,
		"mean": roundTo(mean, 2), "median": roundTo(median, 2),
		"min": roundTo(minVal, 2), "max": roundTo(maxVal, 2),
		"reference_min": refMin, "reference_max": refMax,
		"status": status, "data_points": len(values), "values": values,
	})
}

func (h *StatisticsHandler) GetKLine(c *gin.Context) {
	profileID := c.Param("pid")
	indicatorType := c.Param("indicator_type")
	period := c.DefaultQuery("period", "day")

	userID, _ := c.Get("user_id")
	familyID := c.Query("family_id")
	if familyID != "" && !h.checkMember(userID.(string), familyID) {
		c.JSON(http.StatusForbidden, gin.H{"error": "not a family member"})
		return
	}

	dateFrom, _ := getPeriodRange(period)

	var points []KLinePoint
	switch indicatorType {
	case "sleep":
		points = querySleepKLine(profileID, dateFrom)
	case "smoking":
		points = querySimpleKLine(profileID, dateFrom, "smoking_records", "count")
	case "drinking":
		points = querySimpleKLine(profileID, dateFrom, "drinking_records", "amount")
	default:
		points = queryHealthRecordKLine(profileID, dateFrom, indicatorType)
	}
	if points == nil {
		points = []KLinePoint{}
	}

	c.JSON(http.StatusOK, gin.H{
		"indicator": indicatorType, "period": period, "points": points,
	})
}

func (h *StatisticsHandler) GetCorrelation(c *gin.Context) {
	profileID := c.Param("pid")
	period := c.DefaultQuery("period", "month")

	userID, _ := c.Get("user_id")
	familyID := c.Query("family_id")
	if familyID != "" && !h.checkMember(userID.(string), familyID) {
		c.JSON(http.StatusForbidden, gin.H{"error": "not a family member"})
		return
	}

	dateFrom, _ := getPeriodRange(period)
	data := gin.H{"period": period, "date_from": dateFrom, "indicators": []string{
		"smoking", "drinking", "sleep", "heart_rate", "blood_pressure", "weight",
	}}

	r, _ := db.DB.Query(
		`SELECT record_date, count FROM smoking_records 
		 WHERE member_profile_id = ? AND record_date >= ? ORDER BY record_date ASC`,
		profileID, dateFrom,
	)
	if r != nil {
		defer r.Close()
		var sd []gin.H
		for r.Next() {
			var d string
			var c int
			r.Scan(&d, &c)
			sd = append(sd, gin.H{"date": d, "value": c})
		}
		data["smoking"] = sd
	}

	r2, _ := db.DB.Query(
		`SELECT record_date, amount FROM drinking_records 
		 WHERE member_profile_id = ? AND record_date >= ? ORDER BY record_date ASC`,
		profileID, dateFrom,
	)
	if r2 != nil {
		defer r2.Close()
		var dd []gin.H
		for r2.Next() {
			var d string
			var a float64
			r2.Scan(&d, &a)
			dd = append(dd, gin.H{"date": d, "value": a})
		}
		data["drinking"] = dd
	}

	r3, _ := db.DB.Query(
		`SELECT record_date, sleep_time, wake_time FROM sleep_records 
		 WHERE member_profile_id = ? AND record_date >= ? ORDER BY record_date ASC`,
		profileID, dateFrom,
	)
	if r3 != nil {
		defer r3.Close()
		var sd []gin.H
		for r3.Next() {
			var d, st, wt string
			r3.Scan(&d, &st, &wt)
			sleepParsed, _ := time.Parse("15:04:05", st)
			wakeParsed, _ := time.Parse("15:04:05", wt)
			duration := wakeParsed.Sub(sleepParsed).Hours()
			if duration < 0 {
				duration += 24
			}
			sd = append(sd, gin.H{"date": d, "value": roundTo(duration, 1)})
		}
		data["sleep"] = sd
	}

	c.JSON(http.StatusOK, data)
}

func (h *StatisticsHandler) GetTrends(c *gin.Context) {
	profileID := c.Param("pid")
	period := c.DefaultQuery("period", "month")

	userID, _ := c.Get("user_id")
	familyID := c.Query("family_id")
	if familyID != "" && !h.checkMember(userID.(string), familyID) {
		c.JSON(http.StatusForbidden, gin.H{"error": "not a family member"})
		return
	}

	dateFrom, dateTo := getPeriodRange(period)
	result := make(map[string]interface{})

	for indicatorType := range indicatorMapping {
		values, err := queryIndicatorValues(profileID, indicatorType, dateFrom, dateTo)
		if err == nil && len(values) > 0 {
			sort.Float64s(values)
			result[indicatorType] = gin.H{
				"mean":   roundTo(calculateMean(values), 2),
				"median": roundTo(calculateMedian(values), 2),
				"min":    roundTo(values[0], 2),
				"max":    roundTo(values[len(values)-1], 2),
				"count":  len(values),
			}
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"period": period, "date_from": dateFrom, "date_to": dateTo, "indicators": result,
	})
}

func queryHealthRecordKLine(profileID, dateFrom, indicatorType string) []KLinePoint {
	mapping, ok := indicatorMapping[indicatorType]
	if !ok || mapping.table != "health_records" {
		return nil
	}
	rows, err := db.DB.Query(
		`SELECT record_date, value_json FROM health_records 
		 WHERE member_profile_id = ? AND record_type = ? AND record_date >= ?
		 ORDER BY record_date ASC`,
		profileID, mapping.recordType, dateFrom,
	)
	if err != nil {
		return nil
	}
	defer rows.Close()
	return aggregateDailyKLineFromJSON(rows, mapping.valueField)
}

func querySimpleKLine(profileID, dateFrom, table, field string) []KLinePoint {
	query := "SELECT record_date, " + field + " FROM " + table +
		" WHERE member_profile_id = ? AND record_date >= ? ORDER BY record_date ASC"
	rows, err := db.DB.Query(query, profileID, dateFrom)
	if err != nil {
		return nil
	}
	defer rows.Close()
	return aggregateDailySimpleKLine(rows)
}

func querySleepKLine(profileID, dateFrom string) []KLinePoint {
	rows, err := db.DB.Query(
		`SELECT record_date, sleep_time, wake_time FROM sleep_records 
		 WHERE member_profile_id = ? AND record_date >= ? ORDER BY record_date ASC`,
		profileID, dateFrom,
	)
	if err != nil {
		return nil
	}
	defer rows.Close()

	var durations []sleepEntry
	for rows.Next() {
		var date, st, wt string
		if err := rows.Scan(&date, &st, &wt); err != nil {
			continue
		}
		var sleepParsed, wakeParsed time.Time
		sleepParsed, _ = time.Parse("15:04:05", st)
		wakeParsed, _ = time.Parse("15:04:05", wt)
		base := time.Date(2000, 1, 1, 0, 0, 0, 0, time.UTC)
		s := base.Add(time.Duration(sleepParsed.Hour())*time.Hour + time.Duration(sleepParsed.Minute())*time.Minute)
		w := base.Add(time.Duration(wakeParsed.Hour())*time.Hour + time.Duration(wakeParsed.Minute())*time.Minute)
		duration := w.Sub(s).Hours()
		if duration < 0 {
			duration += 24
		}
		durations = append(durations, sleepEntry{date: date, duration: duration})
	}
	return aggregateDailySleep(durations)
}

func aggregateDailyKLineFromJSON(rows *sql.Rows, valueField string) []KLinePoint {
	var points []KLinePoint
	var dailyValues []float64
	var currentDate string

	for rows.Next() {
		var date string
		var rawJSON []byte
		if err := rows.Scan(&date, &rawJSON); err != nil {
			continue
		}
		var vals map[string]interface{}
		if err := json.Unmarshal(rawJSON, &vals); err != nil {
			continue
		}
		v, ok := vals[valueField]
		if !ok {
			continue
		}
		var val float64
		switch tv := v.(type) {
		case float64:
			val = tv
		case string:
			val, _ = strconv.ParseFloat(tv, 64)
		default:
			continue
		}
		if currentDate == "" {
			currentDate = date
		}
		if date != currentDate && len(dailyValues) > 0 {
			points = append(points, makeKLine(currentDate, dailyValues))
			dailyValues = nil
			currentDate = date
		}
		dailyValues = append(dailyValues, val)
	}
	if len(dailyValues) > 0 {
		points = append(points, makeKLine(currentDate, dailyValues))
	}
	return points
}

func aggregateDailySimpleKLine(rows *sql.Rows) []KLinePoint {
	var points []KLinePoint
	var dailyValues []float64
	var currentDate string

	for rows.Next() {
		var date string
		var val float64
		if err := rows.Scan(&date, &val); err != nil {
			continue
		}
		if currentDate == "" {
			currentDate = date
		}
		if date != currentDate && len(dailyValues) > 0 {
			points = append(points, makeKLine(currentDate, dailyValues))
			dailyValues = nil
			currentDate = date
		}
		dailyValues = append(dailyValues, val)
	}
	if len(dailyValues) > 0 {
		points = append(points, makeKLine(currentDate, dailyValues))
	}
	return points
}

func aggregateDailySleep(entries []sleepEntry) []KLinePoint {
	var points []KLinePoint
	var dailyValues []float64
	var currentDate string

	for _, e := range entries {
		if currentDate == "" {
			currentDate = e.date
		}
		if e.date != currentDate && len(dailyValues) > 0 {
			points = append(points, makeKLine(currentDate, dailyValues))
			dailyValues = nil
			currentDate = e.date
		}
		dailyValues = append(dailyValues, e.duration)
	}
	if len(dailyValues) > 0 {
		points = append(points, makeKLine(currentDate, dailyValues))
	}
	return points
}

func makeKLine(date string, values []float64) KLinePoint {
	sorted := make([]float64, len(values))
	copy(sorted, values)
	sort.Float64s(sorted)
	return KLinePoint{
		Date: date, Open: values[0], Close: values[len(values)-1],
		High: sorted[len(sorted)-1], Low: sorted[0],
		Mean: calculateMean(values), Count: len(values),
	}
}

func getPeriodRange(period string) (string, string) {
	now := time.Now()
	var from time.Time
	switch period {
	case "day":
		from = now.AddDate(0, 0, -1)
	case "week":
		from = now.AddDate(0, 0, -7)
	case "month":
		from = now.AddDate(0, -1, 0)
	case "quarter":
		from = now.AddDate(0, -3, 0)
	case "year":
		from = now.AddDate(-1, 0, 0)
	default:
		from = now.AddDate(0, -1, 0)
	}
	return from.Format("2006-01-02"), now.Format("2006-01-02")
}

func queryIndicatorValues(profileID, indicatorType, dateFrom, dateTo string) ([]float64, error) {
	mapping, ok := indicatorMapping[indicatorType]
	if !ok {
		return nil, nil
	}

	if mapping.table == "health_records" {
		rows, err := db.DB.Query(
			`SELECT value_json FROM health_records 
			 WHERE member_profile_id = ? AND record_type = ?
			 AND record_date >= ? AND record_date <= ?`,
			profileID, mapping.recordType, dateFrom, dateTo,
		)
		if err != nil {
			return nil, err
		}
		defer rows.Close()
		var values []float64
		for rows.Next() {
			var rawJSON []byte
			if err := rows.Scan(&rawJSON); err != nil {
				continue
			}
			var vals map[string]interface{}
			if err := json.Unmarshal(rawJSON, &vals); err != nil {
				continue
			}
			v, ok := vals[mapping.valueField]
			if !ok {
				continue
			}
			switch tv := v.(type) {
			case float64:
				values = append(values, tv)
			case string:
				f, _ := strconv.ParseFloat(tv, 64)
				values = append(values, f)
			}
		}
		return values, nil
	}

	if mapping.table == "smoking_records" {
		rows, err := db.DB.Query(
			`SELECT count FROM smoking_records 
			 WHERE member_profile_id = ? AND record_date >= ? AND record_date <= ?`,
			profileID, dateFrom, dateTo,
		)
		if err != nil {
			return nil, err
		}
		defer rows.Close()
		var values []float64
		for rows.Next() {
			var count int
			rows.Scan(&count)
			values = append(values, float64(count))
		}
		return values, nil
	}

	if mapping.table == "drinking_records" {
		rows, err := db.DB.Query(
			`SELECT amount FROM drinking_records 
			 WHERE member_profile_id = ? AND record_date >= ? AND record_date <= ?`,
			profileID, dateFrom, dateTo,
		)
		if err != nil {
			return nil, err
		}
		defer rows.Close()
		var values []float64
		for rows.Next() {
			var amount float64
			rows.Scan(&amount)
			values = append(values, amount)
		}
		return values, nil
	}

	return nil, nil
}

func calculateMean(values []float64) float64 {
	if len(values) == 0 {
		return 0
	}
	sum := 0.0
	for _, v := range values {
		sum += v
	}
	return sum / float64(len(values))
}

func calculateMedian(values []float64) float64 {
	n := len(values)
	if n == 0 {
		return 0
	}
	if n%2 == 1 {
		return values[n/2]
	}
	return (values[n/2-1] + values[n/2]) / 2.0
}

func roundTo(val float64, decimals int) float64 {
	pow := math.Pow(10, float64(decimals))
	return math.Round(val*pow) / pow
}
