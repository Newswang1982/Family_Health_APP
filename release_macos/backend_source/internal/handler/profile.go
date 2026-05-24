package handler

import (
	"net/http"

	"family-health-backend/internal/db"
	"family-health-backend/internal/model"

	"github.com/gin-gonic/gin"
)

type ProfileHandler struct {
	checkMember func(userID, familyID string) bool
}

func NewProfileHandler(checkMember func(userID, familyID string) bool) *ProfileHandler {
	return &ProfileHandler{checkMember: checkMember}
}

// CreateProfile creates a health profile for a family member (elderly/child)
func (h *ProfileHandler) CreateProfile(c *gin.Context) {
	userID, _ := c.Get("user_id")
	familyID := c.Param("id")

	if !h.checkMember(userID.(string), familyID) {
		c.JSON(http.StatusForbidden, gin.H{"error": "not a family member"})
		return
	}

	var req model.CreateProfileRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// INSERT + LastInsertId + SELECT instead of RETURNING
	res, err := db.DB.Exec(
		`INSERT INTO member_profiles (family_id, name, gender, birth_date, height_cm, weight_kg, created_by)
		 VALUES (?, ?, ?, ?, ?, ?, ?)`,
		familyID, req.Name, req.Gender, req.BirthDate, req.HeightCm, req.WeightKg, userID,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create profile"})
		return
	}

	newID, _ := res.LastInsertId()
	var profile model.MemberProfile
	err = db.DB.QueryRow(
		`SELECT id, family_id, name, gender, birth_date, height_cm, weight_kg, 
		           health_conditions, allergies, created_by, created_at, updated_at
		 FROM member_profiles WHERE rowid = ?`, newID,
	).Scan(&profile.ID, &profile.FamilyID, &profile.Name, &profile.Gender, &profile.BirthDate,
		&profile.HeightCm, &profile.WeightKg, &profile.HealthConditions, &profile.Allergies,
		&profile.CreatedBy, &profile.CreatedAt, &profile.UpdatedAt)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create profile"})
		return
	}

	c.JSON(http.StatusCreated, profile)
}

// ListProfiles returns all profiles for a family
func (h *ProfileHandler) ListProfiles(c *gin.Context) {
	userID, _ := c.Get("user_id")
	familyID := c.Param("id")

	if !h.checkMember(userID.(string), familyID) {
		c.JSON(http.StatusForbidden, gin.H{"error": "not a family member"})
		return
	}

	rows, err := db.DB.Query(
		`SELECT id, family_id, name, gender, birth_date, height_cm, weight_kg,
		        health_conditions, allergies, created_by, created_at, updated_at
		 FROM member_profiles WHERE family_id = ?
		 ORDER BY created_at ASC`,
		familyID,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "database error"})
		return
	}
	defer rows.Close()

	var profiles []model.MemberProfile
	for rows.Next() {
		var p model.MemberProfile
		if err := rows.Scan(&p.ID, &p.FamilyID, &p.Name, &p.Gender, &p.BirthDate,
			&p.HeightCm, &p.WeightKg, &p.HealthConditions, &p.Allergies,
			&p.CreatedBy, &p.CreatedAt, &p.UpdatedAt); err != nil {
			continue
		}
		profiles = append(profiles, p)
	}
	if profiles == nil {
		profiles = []model.MemberProfile{}
	}

	c.JSON(http.StatusOK, profiles)
}

// GetProfile returns a single profile
func (h *ProfileHandler) GetProfile(c *gin.Context) {
	userID, _ := c.Get("user_id")
	familyID := c.Param("id")
	profileID := c.Param("pid")

	if !h.checkMember(userID.(string), familyID) {
		c.JSON(http.StatusForbidden, gin.H{"error": "not a family member"})
		return
	}

	var p model.MemberProfile
	err := db.DB.QueryRow(
		`SELECT id, family_id, name, gender, birth_date, height_cm, weight_kg,
		        health_conditions, allergies, created_by, created_at, updated_at
		 FROM member_profiles WHERE id = ? AND family_id = ?`,
		profileID, familyID,
	).Scan(&p.ID, &p.FamilyID, &p.Name, &p.Gender, &p.BirthDate,
		&p.HeightCm, &p.WeightKg, &p.HealthConditions, &p.Allergies,
		&p.CreatedBy, &p.CreatedAt, &p.UpdatedAt)

	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "profile not found"})
		return
	}

	// Also get reference ranges
	refRows, err := db.DB.Query(
		`SELECT id, member_profile_id, indicator_type, min_value, max_value, unit
		 FROM health_reference_ranges WHERE member_profile_id = ?`,
		profileID,
	)
	if err == nil {
		defer refRows.Close()
		var ranges []model.HealthReferenceRange
		for refRows.Next() {
			var r model.HealthReferenceRange
			if err := refRows.Scan(&r.ID, &r.MemberProfileID, &r.IndicatorType, &r.MinValue, &r.MaxValue, &r.Unit); err == nil {
				ranges = append(ranges, r)
			}
		}
		c.JSON(http.StatusOK, gin.H{
			"profile":          p,
			"reference_ranges": ranges,
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"profile":          p,
		"reference_ranges": []model.HealthReferenceRange{},
	})
}

// UpdateProfile updates a member profile
func (h *ProfileHandler) UpdateProfile(c *gin.Context) {
	userID, _ := c.Get("user_id")
	familyID := c.Param("id")
	profileID := c.Param("pid")

	if !h.checkMember(userID.(string), familyID) {
		c.JSON(http.StatusForbidden, gin.H{"error": "not a family member"})
		return
	}

	var req model.CreateProfileRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	_, err := db.DB.Exec(
		`UPDATE member_profiles 
		 SET name = COALESCE(NULLIF(?, ''), name),
		     gender = COALESCE(NULLIF(?, ''), gender),
		     birth_date = COALESCE(?, birth_date),
		     height_cm = COALESCE(?, height_cm),
		     weight_kg = COALESCE(?, weight_kg),
		     updated_at = datetime('now')
		 WHERE id = ? AND family_id = ?`,
		req.Name, req.Gender, req.BirthDate, req.HeightCm, req.WeightKg, profileID, familyID,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "update failed"})
		return
	}

	h.GetProfile(c)
}

// SetReferenceRange sets or updates personal health reference ranges
func (h *ProfileHandler) SetReferenceRange(c *gin.Context) {
	userID, _ := c.Get("user_id")
	familyID := c.Param("id")
	profileID := c.Param("pid")

	if !h.checkMember(userID.(string), familyID) {
		c.JSON(http.StatusForbidden, gin.H{"error": "not a family member"})
		return
	}

	var req model.SetReferenceRangeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	_, err := db.DB.Exec(
		`INSERT INTO health_reference_ranges (member_profile_id, indicator_type, min_value, max_value, unit)
		 VALUES (?, ?, ?, ?, ?)
		 ON CONFLICT (member_profile_id, indicator_type)
		 DO UPDATE SET min_value = excluded.min_value, max_value = excluded.max_value, unit = excluded.unit`,
		profileID, req.IndicatorType, req.MinValue, req.MaxValue, req.Unit,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to set reference range"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "reference range updated"})
}

// DeleteProfile deletes a member profile
func (h *ProfileHandler) DeleteProfile(c *gin.Context) {
	userID, _ := c.Get("user_id")
	familyID := c.Param("id")
	profileID := c.Param("pid")

	if !h.checkMember(userID.(string), familyID) {
		c.JSON(http.StatusForbidden, gin.H{"error": "not a family member"})
		return
	}

	_, err := db.DB.Exec(`DELETE FROM member_profiles WHERE id = ? AND family_id = ?`, profileID, familyID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "delete failed"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "profile deleted"})
}
