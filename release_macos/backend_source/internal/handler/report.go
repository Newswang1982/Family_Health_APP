package handler

import (
	"encoding/json"
	"net/http"
	"time"

	"family-health-backend/internal/db"

	"github.com/gin-gonic/gin"
)

type ReportHandler struct {
	checkMember func(userID, familyID string) bool
}

func NewReportHandler(checkMember func(userID, familyID string) bool) *ReportHandler {
	return &ReportHandler{checkMember: checkMember}
}

// GenerateReport generates a health report for a member
func (h *ReportHandler) GenerateReport(c *gin.Context) {
	userID, _ := c.Get("user_id")
	profileID := c.Param("pid")

	// Collect report data
	reportData := gin.H{
		"generated_at": time.Now().Format(time.RFC3339),
		"profile_id":   profileID,
		"summary":      gin.H{},
		"sections":     []string{},
	}

	reportJSON, _ := json.Marshal(reportData)

	// Compute dates in Go code instead of using SQL INTERVAL
	now := time.Now()
	from := now.AddDate(0, 0, -30).Format("2006-01-02")
	to := now.Format("2006-01-02")

	res, err := db.DB.Exec(
		`INSERT INTO health_reports (member_profile_id, family_id, period_type, period_start, period_end, report_data, created_by)
		 VALUES (?, ?, ?, ?, ?, ?, ?)`,
		profileID,
		c.Param("id"),
		c.DefaultQuery("period", "month"),
		c.DefaultQuery("from", from),
		c.DefaultQuery("to", to),
		reportJSON,
		userID,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to generate report"})
		return
	}

	newID, _ := res.LastInsertId()
	var reportID string
	err = db.DB.QueryRow(`SELECT id FROM health_reports WHERE rowid = ?`, newID).Scan(&reportID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to retrieve report"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"id":     reportID,
		"report": reportData,
	})
}

// GetReports returns reports for a member
func (h *ReportHandler) GetReports(c *gin.Context) {
	profileID := c.Param("pid")

	rows, err := db.DB.Query(
		`SELECT id, member_profile_id, family_id, period_type, period_start, period_end, report_data, created_by, created_at
		 FROM health_reports WHERE member_profile_id = ?
		 ORDER BY created_at DESC
		 LIMIT 20`,
		profileID,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "query failed"})
		return
	}
	defer rows.Close()

	var reports []gin.H
	for rows.Next() {
		var id, mpID, famID, pType, pStart, pEnd, createdBy string
		var rawJSON []byte
		var createdAt string
		if err := rows.Scan(&id, &mpID, &famID, &pType, &pStart, &pEnd, &rawJSON, &createdBy, &createdAt); err != nil {
			continue
		}
		var data map[string]interface{}
		json.Unmarshal(rawJSON, &data)
		reports = append(reports, gin.H{
			"id": id, "period_type": pType, "period_start": pStart, "period_end": pEnd,
			"data": data, "created_at": createdAt,
		})
	}
	if reports == nil {
		reports = []gin.H{}
	}

	c.JSON(http.StatusOK, reports)
}

// ShareReport shares a report (placeholder)
func (h *ReportHandler) ShareReport(c *gin.Context) {
	reportID := c.Param("rid")

	c.JSON(http.StatusOK, gin.H{
		"message":   "report shared",
		"report_id": reportID,
		"share_url": "https://app.family-health.example.com/report/" + reportID,
	})
}

// PushSMS sends report via SMS (placeholder)
func (h *ReportHandler) PushSMS(c *gin.Context) {
	reportID := c.Param("rid")

	c.JSON(http.StatusOK, gin.H{
		"message":   "report pushed via SMS",
		"report_id": reportID,
	})
}
