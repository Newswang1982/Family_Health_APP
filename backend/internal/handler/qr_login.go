package handler

import (
	"crypto/rand"
	"database/sql"
	"fmt"
	"net/http"
	"sync"
	"time"

	"family-health-backend/internal/db"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
)

// 内存中存放待扫码的登录会话
var qrLoginSessions = struct {
	sync.RWMutex
	sessions map[string]*qrSession
}{sessions: make(map[string]*qrSession)}

type qrSession struct {
	Token     string    // 二维码唯一标识
	Status    string    // pending / scanned / confirmed / expired
	UserID    string    // 扫码确认后记录 user_id
	ExpiresAt time.Time // 过期时间
	CreatedAt time.Time
}

// QRLoginHandler handles QR code scan-to-login
type QRLoginHandler struct {
	JWTSecret string
}

func NewQRLoginHandler(jwtSecret string) *QRLoginHandler {
	return &QRLoginHandler{JWTSecret: jwtSecret}
}

// GenerateQRToken 生成二维码登录令牌
// GET /api/v1/auth/qr/generate
func (h *QRLoginHandler) GenerateQRToken(c *gin.Context) {
	// 生成随机 token
	b := make([]byte, 32)
	rand.Read(b)
	token := fmt.Sprintf("%x", b)

	session := &qrSession{
		Token:     token,
		Status:    "pending",
		CreatedAt: time.Now(),
		ExpiresAt: time.Now().Add(5 * time.Minute), // 5 分钟有效
	}

	qrLoginSessions.Lock()
	qrLoginSessions.sessions[token] = session
	qrLoginSessions.Unlock()

	// 定时清理过期会话
	go func() {
		time.Sleep(6 * time.Minute)
		qrLoginSessions.Lock()
		if s, ok := qrLoginSessions.sessions[token]; ok && s.Status == "pending" {
			s.Status = "expired"
		}
		qrLoginSessions.Unlock()
	}()

	c.JSON(http.StatusOK, gin.H{
		"qr_token":  token,
		"expire_in": 300,
	})
}

// CheckQRStatus 轮询检查二维码状态
// GET /api/v1/auth/qr/status/:token
func (h *QRLoginHandler) CheckQRStatus(c *gin.Context) {
	token := c.Param("token")

	qrLoginSessions.RLock()
	session, exists := qrLoginSessions.sessions[token]
	qrLoginSessions.RUnlock()

	if !exists {
		c.JSON(http.StatusNotFound, gin.H{"error": "二维码已过期"})
		return
	}

	if session.Status == "expired" || time.Now().After(session.ExpiresAt) {
		c.JSON(http.StatusOK, gin.H{"status": "expired"})
		return
	}

	if session.Status == "confirmed" && session.UserID != "" {
		// 扫码成功，生成 JWT token 返回
		claims := jwt.MapClaims{
			"user_id": session.UserID,
			"exp":     time.Now().Add(168 * time.Hour).Unix(),
			"iat":     time.Now().Unix(),
		}
		jwtToken := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
		tokenStr, _ := jwtToken.SignedString([]byte(h.JWTSecret))

		// 获取用户信息
		var name, phone string
		db.DB.QueryRow("SELECT name, phone FROM users WHERE id = ?", session.UserID).Scan(&name, &phone)

		c.JSON(http.StatusOK, gin.H{
			"status": "confirmed",
			"token":  tokenStr,
			"user": gin.H{
				"id":    session.UserID,
				"name":  name,
				"phone": phone,
			},
		})

		// 清理已使用的 session
		qrLoginSessions.Lock()
		delete(qrLoginSessions.sessions, token)
		qrLoginSessions.Unlock()
		return
	}

	if session.Status == "scanned" {
		c.JSON(http.StatusOK, gin.H{"status": "scanned"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": "pending"})
}

// ScanQR 手机端扫码确认
// POST /api/v1/auth/qr/scan
// 需要登录认证（手机用户已登录）
func (h *QRLoginHandler) ScanQR(c *gin.Context) {
	userID, _ := c.Get("user_id")

	var req struct {
		QRToken string `json:"qr_token" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "缺少二维码令牌"})
		return
	}

	qrLoginSessions.Lock()
	defer qrLoginSessions.Unlock()

	session, exists := qrLoginSessions.sessions[req.QRToken]
	if !exists {
		c.JSON(http.StatusNotFound, gin.H{"error": "二维码已过期"})
		return
	}

	if session.Status != "pending" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "二维码已被使用"})
		return
	}

	if time.Now().After(session.ExpiresAt) {
		session.Status = "expired"
		c.JSON(http.StatusBadRequest, gin.H{"error": "二维码已过期"})
		return
	}

	// 标记为已扫码，记录用户ID
	session.Status = "confirmed"
	session.UserID = userID.(string)

	c.JSON(http.StatusOK, gin.H{
		"status":  "confirmed",
		"message": "登录确认成功",
	})
}

// GetUserPhone 获取当前登录用户的手机号（用于二维码页面显示）
// GET /api/v1/auth/qr/user-info
func (h *QRLoginHandler) GetUserInfo(c *gin.Context) {
	userID, _ := c.Get("user_id")

	var name, avatar string
	err := db.DB.QueryRow(
		"SELECT name, avatar_url FROM users WHERE id = ?", userID,
	).Scan(&name, &avatar)
	if err == sql.ErrNoRows {
		c.JSON(http.StatusNotFound, gin.H{"error": "用户不存在"})
		return
	}
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "查询失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"name":   name,
		"avatar": avatar,
	})
}
