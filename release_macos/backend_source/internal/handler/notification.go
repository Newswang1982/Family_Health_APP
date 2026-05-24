package handler

import (
	"net/http"

	"family-health-backend/internal/db"

	"github.com/gin-gonic/gin"
)

type NotificationHandler struct{}

func NewNotificationHandler() *NotificationHandler {
	return &NotificationHandler{}
}

// ListNotifications returns notifications for current user
func (h *NotificationHandler) ListNotifications(c *gin.Context) {
	userID, _ := c.Get("user_id")
	unreadOnly := c.DefaultQuery("unread", "false")

	var query string
	var args []interface{}

	if unreadOnly == "true" {
		query = `SELECT id, family_id, user_id, member_profile_id, alert_type, severity, 
		                indicator_type, indicator_value, threshold_min, threshold_max, 
		                message, is_read, pushed_sms, created_at
		         FROM notifications WHERE user_id = ? AND is_read = FALSE
		         ORDER BY created_at DESC LIMIT 50`
		args = append(args, userID)
	} else {
		query = `SELECT id, family_id, user_id, member_profile_id, alert_type, severity, 
		                indicator_type, indicator_value, threshold_min, threshold_max, 
		                message, is_read, pushed_sms, created_at
		         FROM notifications WHERE user_id = ?
		         ORDER BY created_at DESC LIMIT 50`
		args = append(args, userID)
	}

	rows, err := db.DB.Query(query, args...)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "query failed"})
		return
	}
	defer rows.Close()

	var notifications []gin.H
	for rows.Next() {
		var id, famID, userID2, alertType, severity, indicatorType, message string
		var mpID, indicatorVal, threshMin, threshMax *float64
		var isRead, pushedSMS bool
		var createdAt string
		if err := rows.Scan(&id, &famID, &userID2, &mpID, &alertType, &severity,
			&indicatorType, &indicatorVal, &threshMin, &threshMax,
			&message, &isRead, &pushedSMS, &createdAt); err != nil {
			continue
		}
		notifications = append(notifications, gin.H{
			"id": id, "family_id": famID, "alert_type": alertType, "severity": severity,
			"indicator_type": indicatorType, "indicator_value": indicatorVal,
			"threshold_min": threshMin, "threshold_max": threshMax,
			"message": message, "is_read": isRead, "pushed_sms": pushedSMS,
			"created_at": createdAt,
		})
	}
	if notifications == nil {
		notifications = []gin.H{}
	}

	c.JSON(http.StatusOK, notifications)
}

// MarkAsRead marks a notification as read
func (h *NotificationHandler) MarkAsRead(c *gin.Context) {
	userID, _ := c.Get("user_id")
	notificationID := c.Param("id")

	_, err := db.DB.Exec(
		`UPDATE notifications SET is_read = TRUE WHERE id = ? AND user_id = ?`,
		notificationID, userID,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "update failed"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "marked as read"})
}

// GetUnreadCount returns count of unread notifications
func (h *NotificationHandler) GetUnreadCount(c *gin.Context) {
	userID, _ := c.Get("user_id")

	var count int
	err := db.DB.QueryRow(
		`SELECT COUNT(*) FROM notifications WHERE user_id = ? AND is_read = FALSE`,
		userID,
	).Scan(&count)
	if err != nil {
		count = 0
	}

	c.JSON(http.StatusOK, gin.H{"unread_count": count})
}
