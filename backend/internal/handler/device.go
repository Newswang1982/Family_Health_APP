package handler

import (
	"net/http"

	"family-health-backend/internal/db"
	"family-health-backend/internal/model"

	"github.com/gin-gonic/gin"
)

type DeviceHandler struct {
	checkMember func(userID, familyID string) bool
}

func NewDeviceHandler(checkMember func(userID, familyID string) bool) *DeviceHandler {
	return &DeviceHandler{checkMember: checkMember}
}

// BindDevice binds a BLE device to a family
func (h *DeviceHandler) BindDevice(c *gin.Context) {
	userID, _ := c.Get("user_id")
	familyID := c.Param("id")

	if !h.checkMember(userID.(string), familyID) {
		c.JSON(http.StatusForbidden, gin.H{"error": "not a family member"})
		return
	}

	var req model.BindDeviceRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// INSERT ... ON CONFLICT ... DO UPDATE + LastInsertId + SELECT instead of RETURNING
	res, err := db.DB.Exec(
		`INSERT INTO device_bindings (family_id, user_id, device_id, member_profile_id, device_name, device_type)
		 VALUES (?, ?, ?, ?, ?, ?)
		 ON CONFLICT (family_id, device_id) DO UPDATE
		 SET member_profile_id = excluded.member_profile_id, device_name = excluded.device_name, device_type = excluded.device_type, user_id = excluded.user_id`,
		familyID, userID, req.DeviceID, req.MemberProfileID, req.DeviceName, req.DeviceType,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to bind device"})
		return
	}

	newID, _ := res.LastInsertId()
	var binding model.DeviceBinding
	err = db.DB.QueryRow(
		`SELECT id, family_id, user_id, device_id, member_profile_id, device_name, device_type, last_synced_at, created_at
		 FROM device_bindings WHERE rowid = ?`, newID,
	).Scan(&binding.ID, &binding.FamilyID, &binding.UserID, &binding.DeviceID, &binding.MemberProfileID,
		&binding.DeviceName, &binding.DeviceType, &binding.LastSyncedAt, &binding.CreatedAt)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to bind device"})
		return
	}

	c.JSON(http.StatusCreated, binding)
}

// ListDevices returns all devices for a family
func (h *DeviceHandler) ListDevices(c *gin.Context) {
	userID, _ := c.Get("user_id")
	familyID := c.Param("id")

	if !h.checkMember(userID.(string), familyID) {
		c.JSON(http.StatusForbidden, gin.H{"error": "not a family member"})
		return
	}

	rows, err := db.DB.Query(
		`SELECT id, family_id, user_id, device_id, member_profile_id, device_name, device_type, last_synced_at, created_at
		 FROM device_bindings WHERE family_id = ?
		 ORDER BY created_at DESC`,
		familyID,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "database error"})
		return
	}
	defer rows.Close()

	var devices []model.DeviceBinding
	for rows.Next() {
		var d model.DeviceBinding
		if err := rows.Scan(&d.ID, &d.FamilyID, &d.UserID, &d.DeviceID, &d.MemberProfileID,
			&d.DeviceName, &d.DeviceType, &d.LastSyncedAt, &d.CreatedAt); err != nil {
			continue
		}
		devices = append(devices, d)
	}
	if devices == nil {
		devices = []model.DeviceBinding{}
	}

	c.JSON(http.StatusOK, devices)
}

// UnbindDevice removes a device binding
func (h *DeviceHandler) UnbindDevice(c *gin.Context) {
	userID, _ := c.Get("user_id")
	familyID := c.Param("id")
	deviceID := c.Param("did")

	if !h.checkMember(userID.(string), familyID) {
		c.JSON(http.StatusForbidden, gin.H{"error": "not a family member"})
		return
	}

	result, err := db.DB.Exec(
		`DELETE FROM device_bindings WHERE family_id = ? AND device_id = ?`,
		familyID, deviceID,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "unbind failed"})
		return
	}
	affected, _ := result.RowsAffected()
	if affected == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "device not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "device unbound"})
}

// UpdateDeviceSyncTime updates the last sync time for a device
func (h *DeviceHandler) UpdateDeviceSyncTime(c *gin.Context) {
	userID, _ := c.Get("user_id")
	familyID := c.Param("id")
	deviceID := c.Param("did")

	if !h.checkMember(userID.(string), familyID) {
		c.JSON(http.StatusForbidden, gin.H{"error": "not a family member"})
		return
	}

	_, err := db.DB.Exec(
		`UPDATE device_bindings SET last_synced_at = datetime('now') WHERE family_id = ? AND device_id = ?`,
		familyID, deviceID,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "update failed"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "sync time updated"})
}
