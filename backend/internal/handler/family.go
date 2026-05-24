package handler

import (
	"database/sql"
	"math/rand"
	"net/http"

	"family-health-backend/internal/db"
	"family-health-backend/internal/model"

	"github.com/gin-gonic/gin"

)

type FamilyHandler struct{}

func NewFamilyHandler() *FamilyHandler {
	return &FamilyHandler{}
}

func generateInviteCode() string {
	const charset = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
	code := make([]byte, 8)
	for i := range code {
		code[i] = charset[rand.Intn(len(charset))]
	}
	return string(code)
}

// CreateFamily creates a new family group
func (h *FamilyHandler) CreateFamily(c *gin.Context) {
	userID, _ := c.Get("user_id")

	var req model.CreateFamilyRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	inviteCode := generateInviteCode()

	// INSERT + LastInsertId + SELECT instead of RETURNING
	res, err := db.DB.Exec(
		`INSERT INTO families (name, invite_code, created_by) 
		 VALUES (?, ?, ?)`,
		req.Name, inviteCode, userID,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create family"})
		return
	}

	newID, _ := res.LastInsertId()
	var family model.Family
	err = db.DB.QueryRow(
		`SELECT id, name, invite_code, qr_code_url, created_by, created_at, updated_at
		 FROM families WHERE rowid = ?`, newID,
	).Scan(&family.ID, &family.Name, &family.InviteCode, &family.QRCodeURL, &family.CreatedBy, &family.CreatedAt, &family.UpdatedAt)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to retrieve created family"})
		return
	}

	// Add creator as admin
	_, err = db.DB.Exec(
		`INSERT INTO family_members (family_id, user_id, role) VALUES (?, ?, 'admin')`,
		family.ID, userID,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to add creator as admin"})
		return
	}

	c.JSON(http.StatusCreated, family)
}

// ListFamilies returns all families the current user belongs to
func (h *FamilyHandler) ListFamilies(c *gin.Context) {
	userID, _ := c.Get("user_id")

	rows, err := db.DB.Query(
		`SELECT f.id, f.name, f.invite_code, f.qr_code_url, f.created_by, f.created_at, f.updated_at,
		        fm.role
		 FROM families f
		 JOIN family_members fm ON fm.family_id = f.id
		 WHERE fm.user_id = ?
		 ORDER BY f.created_at DESC`,
		userID,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "database error"})
		return
	}
	defer rows.Close()

	type FamilyWithRole struct {
		model.Family
		Role string `json:"role"`
	}

	var families []FamilyWithRole
	for rows.Next() {
		var f FamilyWithRole
		if err := rows.Scan(&f.ID, &f.Name, &f.InviteCode, &f.QRCodeURL, &f.CreatedBy, &f.CreatedAt, &f.UpdatedAt, &f.Role); err != nil {
			continue
		}
		families = append(families, f)
	}

	if families == nil {
		families = []FamilyWithRole{}
	}

	c.JSON(http.StatusOK, families)
}

// GetFamily returns family details
func (h *FamilyHandler) GetFamily(c *gin.Context) {
	userID, _ := c.Get("user_id")
	familyID := c.Param("id")

	// Check membership
	if !h.isMember(userID.(string), familyID) {
		c.JSON(http.StatusForbidden, gin.H{"error": "not a family member"})
		return
	}

	var family model.Family
	err := db.DB.QueryRow(
		`SELECT id, name, invite_code, qr_code_url, created_by, created_at, updated_at
		 FROM families WHERE id = ?`, familyID,
	).Scan(&family.ID, &family.Name, &family.InviteCode, &family.QRCodeURL, &family.CreatedBy, &family.CreatedAt, &family.UpdatedAt)

	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "family not found"})
		return
	}

	// Get member count
	var memberCount int
	db.DB.QueryRow(`SELECT COUNT(*) FROM family_members WHERE family_id = ?`, familyID).Scan(&memberCount)

	// Get members
	rows, err := db.DB.Query(
		`SELECT fm.id, fm.family_id, fm.user_id, fm.role, fm.joined_at,
		        u.phone, u.name, u.avatar_url
		 FROM family_members fm
		 JOIN users u ON u.id = fm.user_id
		 WHERE fm.family_id = ?`,
		familyID,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "database error"})
		return
	}
	defer rows.Close()

	type MemberInfo struct {
		model.FamilyMember
		Phone      string `json:"phone"`
		UserName   string `json:"user_name"`
		AvatarURL  string `json:"avatar_url"`
	}

	var members []MemberInfo
	for rows.Next() {
		var m MemberInfo
		if err := rows.Scan(&m.ID, &m.FamilyID, &m.UserID, &m.Role, &m.JoinedAt, &m.Phone, &m.UserName, &m.AvatarURL); err != nil {
			continue
		}
		members = append(members, m)
	}
	if members == nil {
		members = []MemberInfo{}
	}

	// Get profile count
	var profileCount int
	db.DB.QueryRow(`SELECT COUNT(*) FROM member_profiles WHERE family_id = ?`, familyID).Scan(&profileCount)

	c.JSON(http.StatusOK, gin.H{
		"family":        family,
		"member_count":  memberCount,
		"members":       members,
		"profile_count": profileCount,
	})
}

// JoinFamily adds user to a family via invite code
func (h *FamilyHandler) JoinFamily(c *gin.Context) {
	userID, _ := c.Get("user_id")

	var req model.JoinFamilyRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Find family by invite code
	var familyID string
	err := db.DB.QueryRow(`SELECT id FROM families WHERE invite_code = ?`, req.InviteCode).Scan(&familyID)
	if err == sql.ErrNoRows {
		c.JSON(http.StatusNotFound, gin.H{"error": "invalid invite code"})
		return
	}
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "database error"})
		return
	}

	// Check if already a member
	var exists bool
	db.DB.QueryRow(`SELECT EXISTS(SELECT 1 FROM family_members WHERE family_id = ? AND user_id = ?)`, familyID, userID).Scan(&exists)
	if exists {
		c.JSON(http.StatusConflict, gin.H{"error": "already a member of this family"})
		return
	}

	_, err = db.DB.Exec(
		`INSERT INTO family_members (family_id, user_id, role) VALUES (?, ?, 'member')`,
		familyID, userID,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to join family"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "joined family successfully", "family_id": familyID})
}

// RegenerateInviteCode generates a new invite code for the family
func (h *FamilyHandler) RegenerateInviteCode(c *gin.Context) {
	userID, _ := c.Get("user_id")
	familyID := c.Param("id")

	if !h.isAdmin(userID.(string), familyID) {
		c.JSON(http.StatusForbidden, gin.H{"error": "only admins can regenerate invite code"})
		return
	}

	newCode := generateInviteCode()
	_, err := db.DB.Exec(`UPDATE families SET invite_code = ?, updated_at = datetime('now') WHERE id = ?`, newCode, familyID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to regenerate code"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"invite_code": newCode})
}

// RemoveMember removes a user from a family
func (h *FamilyHandler) RemoveMember(c *gin.Context) {
	userID, _ := c.Get("user_id")
	familyID := c.Param("id")
	targetUserID := c.Param("user_id")

	if !h.isAdmin(userID.(string), familyID) {
		c.JSON(http.StatusForbidden, gin.H{"error": "only admins can remove members"})
		return
	}

	// Cannot remove yourself if you're the last admin
	var adminCount int
	db.DB.QueryRow(`SELECT COUNT(*) FROM family_members WHERE family_id = ? AND role = 'admin'`, familyID).Scan(&adminCount)
	if userID == targetUserID && adminCount <= 1 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "cannot remove the last admin"})
		return
	}

	_, err := db.DB.Exec(
		`DELETE FROM family_members WHERE family_id = ? AND user_id = ?`,
		familyID, targetUserID,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to remove member"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "member removed"})
}

func (h *FamilyHandler) isMember(userID, familyID string) bool {
	var exists bool
	db.DB.QueryRow(
		`SELECT EXISTS(SELECT 1 FROM family_members WHERE family_id = ? AND user_id = ?)`,
		familyID, userID,
	).Scan(&exists)
	return exists
}

func (h *FamilyHandler) isAdmin(userID, familyID string) bool {
	var role string
	err := db.DB.QueryRow(
		`SELECT role FROM family_members WHERE family_id = ? AND user_id = ?`,
		familyID, userID,
	).Scan(&role)
	return err == nil && role == "admin"
}
