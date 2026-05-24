package handler

import (
	"encoding/json"
	"net/http"

	"family-health-backend/internal/db"
	"family-health-backend/internal/model"

	"github.com/gin-gonic/gin"
)

type RecordHandler struct {
	checkMember func(userID, familyID string) bool
}

func NewRecordHandler(checkMember func(userID, familyID string) bool) *RecordHandler {
	return &RecordHandler{checkMember: checkMember}
}

func setDefaultSource(source string) string {
	if source == "" {
		return "manual"
	}
	return source
}

func (h *RecordHandler) CreateSleepRecord(c *gin.Context) {
	userID, _ := c.Get("user_id")
	var req model.CreateSleepRecordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	res, err := db.DB.Exec(
		`INSERT INTO sleep_records (member_profile_id, record_date, sleep_time, wake_time, nap_hours, quality, note, source, created_by)
		 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
		req.MemberProfileID, req.RecordDate, req.SleepTime, req.WakeTime, req.NapHours, req.Quality, req.Note, setDefaultSource(req.Source), userID,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create sleep record", "detail": err.Error()})
		return
	}
	newID, _ := res.LastInsertId()
	var record model.SleepRecord
	err = db.DB.QueryRow(
		`SELECT id, member_profile_id, record_date, sleep_time, wake_time, nap_hours, quality, note, source, created_by, created_at, updated_at
		 FROM sleep_records WHERE rowid = ?`, newID,
	).Scan(&record.ID, &record.MemberProfileID, &record.RecordDate, &record.SleepTime, &record.WakeTime,
		&record.NapHours, &record.Quality, &record.Note, &record.Source, &record.CreatedBy, &record.CreatedAt, &record.UpdatedAt)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create sleep record", "detail": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, record)
}

func (h *RecordHandler) CreateWorkPostureRecord(c *gin.Context) {
	userID, _ := c.Get("user_id")
	var req model.CreateWorkPostureRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	totalPct := req.SittingPct + req.StandingPct + req.WalkingPct + req.HeavyPct
	if totalPct < 99.5 || totalPct > 100.5 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "posture percentages must sum to 100"})
		return
	}
	res, err := db.DB.Exec(
		`INSERT INTO work_posture_records (member_profile_id, record_date, total_hours, sitting_pct, standing_pct, walking_pct, heavy_pct, note, source, created_by)
		 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
		req.MemberProfileID, req.RecordDate, req.TotalHours, req.SittingPct, req.StandingPct, req.WalkingPct, req.HeavyPct, req.Note, setDefaultSource(req.Source), userID,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create work posture record", "detail": err.Error()})
		return
	}
	newID, _ := res.LastInsertId()
	var record model.WorkPostureRecord
	err = db.DB.QueryRow(
		`SELECT id, member_profile_id, record_date, total_hours, sitting_pct, standing_pct, walking_pct, heavy_pct, note, source, created_by, created_at, updated_at
		 FROM work_posture_records WHERE rowid = ?`, newID,
	).Scan(&record.ID, &record.MemberProfileID, &record.RecordDate, &record.TotalHours, &record.SittingPct,
		&record.StandingPct, &record.WalkingPct, &record.HeavyPct, &record.Note, &record.Source,
		&record.CreatedBy, &record.CreatedAt, &record.UpdatedAt)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create work posture record", "detail": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, record)
}

func (h *RecordHandler) CreateSmokingRecord(c *gin.Context) {
	userID, _ := c.Get("user_id")
	var req model.CreateSmokingRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	res, err := db.DB.Exec(
		`INSERT INTO smoking_records (member_profile_id, record_date, count, note, source, created_by)
		 VALUES (?, ?, ?, ?, ?, ?)`,
		req.MemberProfileID, req.RecordDate, req.Count, req.Note, setDefaultSource(req.Source), userID,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create smoking record", "detail": err.Error()})
		return
	}
	newID, _ := res.LastInsertId()
	var record model.SmokingRecord
	err = db.DB.QueryRow(
		`SELECT id, member_profile_id, record_date, count, note, source, created_by, created_at, updated_at
		 FROM smoking_records WHERE rowid = ?`, newID,
	).Scan(&record.ID, &record.MemberProfileID, &record.RecordDate, &record.Count,
		&record.Note, &record.Source, &record.CreatedBy, &record.CreatedAt, &record.UpdatedAt)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create smoking record", "detail": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, record)
}

func (h *RecordHandler) CreateDrinkingRecord(c *gin.Context) {
	userID, _ := c.Get("user_id")
	var req model.CreateDrinkingRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	res, err := db.DB.Exec(
		`INSERT INTO drinking_records (member_profile_id, record_date, liquor_type, amount, unit, note, source, created_by)
		 VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
		req.MemberProfileID, req.RecordDate, req.LiquorType, req.Amount, req.Unit, req.Note, setDefaultSource(req.Source), userID,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create drinking record", "detail": err.Error()})
		return
	}
	newID, _ := res.LastInsertId()
	var record model.DrinkingRecord
	err = db.DB.QueryRow(
		`SELECT id, member_profile_id, record_date, liquor_type, amount, unit, note, source, created_by, created_at, updated_at
		 FROM drinking_records WHERE rowid = ?`, newID,
	).Scan(&record.ID, &record.MemberProfileID, &record.RecordDate, &record.LiquorType, &record.Amount,
		&record.Unit, &record.Note, &record.Source, &record.CreatedBy, &record.CreatedAt, &record.UpdatedAt)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create drinking record", "detail": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, record)
}

func (h *RecordHandler) CreateDietRecord(c *gin.Context) {
	userID, _ := c.Get("user_id")
	var req model.CreateDietRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	res, err := db.DB.Exec(
		`INSERT INTO diet_records (member_profile_id, record_date, water_ml, breakfast_ok, lunch_ok, dinner_ok, binge, note, source, created_by)
		 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
		req.MemberProfileID, req.RecordDate, req.WaterMl, req.BreakfastOk, req.LunchOk, req.DinnerOk, req.Binge, req.Note, setDefaultSource(req.Source), userID,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create diet record", "detail": err.Error()})
		return
	}
	newID, _ := res.LastInsertId()
	var record model.DietRecord
	err = db.DB.QueryRow(
		`SELECT id, member_profile_id, record_date, water_ml, breakfast_ok, lunch_ok, dinner_ok, binge, note, source, created_by, created_at, updated_at
		 FROM diet_records WHERE rowid = ?`, newID,
	).Scan(&record.ID, &record.MemberProfileID, &record.RecordDate, &record.WaterMl, &record.BreakfastOk,
		&record.LunchOk, &record.DinnerOk, &record.Binge, &record.Note, &record.Source,
		&record.CreatedBy, &record.CreatedAt, &record.UpdatedAt)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create diet record", "detail": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, record)
}

func (h *RecordHandler) CreateSugarRecord(c *gin.Context) {
	userID, _ := c.Get("user_id")
	var req model.CreateSugarRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	res, err := db.DB.Exec(
		`INSERT INTO sugar_records (member_profile_id, record_date, soda, juice, milk_tea, cake, candy, note, source, created_by)
		 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
		req.MemberProfileID, req.RecordDate, req.Soda, req.Juice, req.MilkTea, req.Cake, req.Candy, req.Note, setDefaultSource(req.Source), userID,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create sugar record", "detail": err.Error()})
		return
	}
	newID, _ := res.LastInsertId()
	var record model.SugarRecord
	err = db.DB.QueryRow(
		`SELECT id, member_profile_id, record_date, soda, juice, milk_tea, cake, candy, note, source, created_by, created_at, updated_at
		 FROM sugar_records WHERE rowid = ?`, newID,
	).Scan(&record.ID, &record.MemberProfileID, &record.RecordDate, &record.Soda, &record.Juice,
		&record.MilkTea, &record.Cake, &record.Candy, &record.Note, &record.Source,
		&record.CreatedBy, &record.CreatedAt, &record.UpdatedAt)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create sugar record", "detail": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, record)
}

func (h *RecordHandler) CreateFoodDetailRecord(c *gin.Context) {
	userID, _ := c.Get("user_id")
	var req model.CreateFoodDetailRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	res, err := db.DB.Exec(
		`INSERT INTO food_detail_records (member_profile_id, record_date, lean_meat, fatty_meat, freshwater_fish, seafood, high_cholesterol, note, source, created_by)
		 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
		req.MemberProfileID, req.RecordDate, req.LeanMeat, req.FattyMeat, req.FreshwaterFish, req.Seafood, req.HighCholesterol, req.Note, setDefaultSource(req.Source), userID,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create food detail record", "detail": err.Error()})
		return
	}
	newID, _ := res.LastInsertId()
	var record model.FoodDetailRecord
	err = db.DB.QueryRow(
		`SELECT id, member_profile_id, record_date, lean_meat, fatty_meat, freshwater_fish, seafood, high_cholesterol, note, source, created_by, created_at, updated_at
		 FROM food_detail_records WHERE rowid = ?`, newID,
	).Scan(&record.ID, &record.MemberProfileID, &record.RecordDate, &record.LeanMeat, &record.FattyMeat,
		&record.FreshwaterFish, &record.Seafood, &record.HighCholesterol, &record.Note, &record.Source,
		&record.CreatedBy, &record.CreatedAt, &record.UpdatedAt)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create food detail record", "detail": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, record)
}

func (h *RecordHandler) CreateEnvironmentHazardRecord(c *gin.Context) {
	userID, _ := c.Get("user_id")
	var req model.CreateEnvironmentHazardRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	res, err := db.DB.Exec(
		`INSERT INTO environment_hazard_records (member_profile_id, record_date, dust, noise, chemical_fumes, high_temp, damp, radiation, note, source, created_by)
		 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
		req.MemberProfileID, req.RecordDate, req.Dust, req.Noise, req.ChemicalFumes, req.HighTemp, req.Damp, req.Radiation, req.Note, setDefaultSource(req.Source), userID,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create environment hazard record", "detail": err.Error()})
		return
	}
	newID, _ := res.LastInsertId()
	var record model.EnvironmentHazardRecord
	err = db.DB.QueryRow(
		`SELECT id, member_profile_id, record_date, dust, noise, chemical_fumes, high_temp, damp, radiation, note, source, created_by, created_at, updated_at
		 FROM environment_hazard_records WHERE rowid = ?`, newID,
	).Scan(&record.ID, &record.MemberProfileID, &record.RecordDate, &record.Dust, &record.Noise,
		&record.ChemicalFumes, &record.HighTemp, &record.Damp, &record.Radiation, &record.Note, &record.Source,
		&record.CreatedBy, &record.CreatedAt, &record.UpdatedAt)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create environment hazard record", "detail": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, record)
}

func (h *RecordHandler) CreateHealthRecord(c *gin.Context) {
	userID, _ := c.Get("user_id")
	var req model.CreateHealthRecordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	valueJSON, _ := json.Marshal(req.ValueJSON)
	res, err := db.DB.Exec(
		`INSERT INTO health_records (member_profile_id, record_date, record_type, value_json, note, source, created_by)
		 VALUES (?, ?, ?, ?, ?, ?, ?)`,
		req.MemberProfileID, req.RecordDate, req.RecordType, valueJSON, req.Note, setDefaultSource(req.Source), userID,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create health record", "detail": err.Error()})
		return
	}
	newID, _ := res.LastInsertId()
	var record model.HealthRecord
	err = db.DB.QueryRow(
		`SELECT id, member_profile_id, record_date, record_type, note, source, created_by, created_at, updated_at
		 FROM health_records WHERE rowid = ?`, newID,
	).Scan(&record.ID, &record.MemberProfileID, &record.RecordDate, &record.RecordType,
		&record.Note, &record.Source, &record.CreatedBy, &record.CreatedAt, &record.UpdatedAt)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create health record", "detail": err.Error()})
		return
	}
	var rawJSON []byte
	db.DB.QueryRow(`SELECT value_json FROM health_records WHERE id = ?`, record.ID).Scan(&rawJSON)
	json.Unmarshal(rawJSON, &record.ValueJSON)
	c.JSON(http.StatusCreated, record)
}

func (h *RecordHandler) QueryRecords(c *gin.Context) {
	var q model.RecordQuery
	if err := c.ShouldBindQuery(&q); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// SQLite version: use json_object() instead of row_to_json(), no ::text or ::date casts
	baseSQL := `
		SELECT * FROM (
		SELECT 'health' as type, id, member_profile_id, record_date, record_type,
		       json_object('id', id, 'member_profile_id', member_profile_id, 'record_date', record_date, 'record_type', record_type, 'note', note, 'source', source, 'created_by', created_by, 'created_at', created_at, 'updated_at', updated_at) as data
		FROM health_records hr
		WHERE (? = '' OR member_profile_id = ?)
		  AND (? = '' OR record_date >= ?)
		  AND (? = '' OR record_date <= ?)
		UNION ALL
		SELECT 'sleep' as type, id, member_profile_id, record_date, 'sleep' as record_type,
		       json_object('id', id, 'member_profile_id', member_profile_id, 'record_date', record_date, 'sleep_time', sleep_time, 'wake_time', wake_time, 'quality', quality, 'note', note, 'source', source, 'created_by', created_by, 'created_at', created_at, 'updated_at', updated_at) as data
		FROM sleep_records sr
		WHERE (? = '' OR member_profile_id = ?)
		  AND (? = '' OR record_date >= ?)
		  AND (? = '' OR record_date <= ?)
		UNION ALL
		SELECT 'work_posture' as type, id, member_profile_id, record_date, 'work_posture' as record_type,
		       json_object('id', id, 'member_profile_id', member_profile_id, 'record_date', record_date, 'total_hours', total_hours, 'sitting_pct', sitting_pct, 'standing_pct', standing_pct, 'walking_pct', walking_pct, 'heavy_pct', heavy_pct, 'note', note, 'source', source, 'created_by', created_by, 'created_at', created_at, 'updated_at', updated_at) as data
		FROM work_posture_records wp
		WHERE (? = '' OR member_profile_id = ?)
		  AND (? = '' OR record_date >= ?)
		  AND (? = '' OR record_date <= ?)
		UNION ALL
		SELECT 'smoking' as type, id, member_profile_id, record_date, 'smoking' as record_type,
		       json_object('id', id, 'member_profile_id', member_profile_id, 'record_date', record_date, 'count', count, 'note', note, 'source', source, 'created_by', created_by, 'created_at', created_at, 'updated_at', updated_at) as data
		FROM smoking_records sr
		WHERE (? = '' OR member_profile_id = ?)
		  AND (? = '' OR record_date >= ?)
		  AND (? = '' OR record_date <= ?)
		UNION ALL
		SELECT 'drinking' as type, id, member_profile_id, record_date, 'drinking' as record_type,
		       json_object('id', id, 'member_profile_id', member_profile_id, 'record_date', record_date, 'liquor_type', liquor_type, 'amount', amount, 'unit', unit, 'note', note, 'source', source, 'created_by', created_by, 'created_at', created_at, 'updated_at', updated_at) as data
		FROM drinking_records dr
		WHERE (? = '' OR member_profile_id = ?)
		  AND (? = '' OR record_date >= ?)
		  AND (? = '' OR record_date <= ?)
		) AS q
		ORDER BY q.record_date DESC, 1 DESC
		LIMIT ? OFFSET ?
	`

	rows, err := db.DB.Query(baseSQL,
		q.MemberProfileID, q.MemberProfileID,
		q.DateFrom, q.DateFrom,
		q.DateTo, q.DateTo,
		q.MemberProfileID, q.MemberProfileID,
		q.DateFrom, q.DateFrom,
		q.DateTo, q.DateTo,
		q.MemberProfileID, q.MemberProfileID,
		q.DateFrom, q.DateFrom,
		q.DateTo, q.DateTo,
		q.MemberProfileID, q.MemberProfileID,
		q.DateFrom, q.DateFrom,
		q.DateTo, q.DateTo,
		q.MemberProfileID, q.MemberProfileID,
		q.DateFrom, q.DateFrom,
		q.DateTo, q.DateTo,
		q.Limit, q.Offset,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "query failed", "detail": err.Error()})
		return
	}
	defer rows.Close()

	var results []map[string]interface{}
	for rows.Next() {
		var recType, id, mpID, recDate, recTypeName string
		var data []byte
		if err := rows.Scan(&recType, &id, &mpID, &recDate, &recTypeName, &data); err != nil {
			continue
		}
		var rowData map[string]interface{}
		json.Unmarshal(data, &rowData)
		rowData["_type"] = recType
		results = append(results, rowData)
	}
	if results == nil {
		results = []map[string]interface{}{}
	}
	c.JSON(http.StatusOK, results)
}

func (h *RecordHandler) UpdateRecord(c *gin.Context) {
	c.JSON(http.StatusNotImplemented, gin.H{"error": "update not yet implemented"})
}

func (h *RecordHandler) DeleteRecord(c *gin.Context) {
	recordID := c.Param("id")
	table := c.Query("table")
	allowedTables := map[string]string{
		"health": "health_records", "sleep": "sleep_records", "work_posture": "work_posture_records",
		"smoking": "smoking_records", "drinking": "drinking_records", "diet": "diet_records",
		"sugar": "sugar_records", "food_detail": "food_detail_records", "environment": "environment_hazard_records",
	}
	realTable, ok := allowedTables[table]
	if !ok {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid table name"})
		return
	}
	result, err := db.DB.Exec("DELETE FROM "+realTable+" WHERE id = ?", recordID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "delete failed"})
		return
	}
	affected, _ := result.RowsAffected()
	if affected == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "record not found"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "record deleted"})
}
