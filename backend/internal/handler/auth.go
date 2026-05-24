package handler

import (
	"crypto/rand"
	"database/sql"
	"fmt"
	"net/http"
	"time"

	"family-health-backend/internal/config"
	"family-health-backend/internal/db"
	"family-health-backend/internal/middleware"
	"family-health-backend/internal/model"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"golang.org/x/crypto/bcrypt"
)

type AuthHandler struct {
	Cfg *config.Config
}

func NewAuthHandler(cfg *config.Config) *AuthHandler {
	return &AuthHandler{Cfg: cfg}
}

// Register handles user registration (phone or email)
func (h *AuthHandler) Register(c *gin.Context) {
	var req model.RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Require either phone or email
	if req.Phone == "" && req.Email == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "手机号或邮箱至少需要填一个"})
		return
	}

	// Check if phone already exists
	if req.Phone != "" {
		var exists bool
		err := db.DB.QueryRow("SELECT EXISTS(SELECT 1 FROM users WHERE phone = ?)", req.Phone).Scan(&exists)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "database error"})
			return
		}
		if exists {
			c.JSON(http.StatusConflict, gin.H{"error": "手机号已注册"})
			return
		}
	}

	// Check if email already exists
	if req.Email != "" {
		var exists bool
		err := db.DB.QueryRow("SELECT EXISTS(SELECT 1 FROM users WHERE email = ?)", req.Email).Scan(&exists)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "database error"})
			return
		}
		if exists {
			c.JSON(http.StatusConflict, gin.H{"error": "邮箱已注册"})
			return
		}
	}

	// Hash password
	hashedPwd, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to hash password"})
		return
	}

	// Generate UUID in Go using crypto/rand
	b := make([]byte, 16)
	rand.Read(b)
	b[6] = (b[6] & 0x0f) | 0x40 // version 4
	b[8] = (b[8] & 0x3f) | 0x80 // variant 10
	newID := fmt.Sprintf("%x-%x-%x-%x-%x", b[0:4], b[4:6], b[6:8], b[8:10], b[10:])

	// Insert user with explicit UUID and timestamps
	now := time.Now().UTC().Format("2006-01-02 15:04:05")
	_, err = db.DB.Exec(
		`INSERT INTO users (id, phone, email, password_hash, name, created_at, updated_at) 
		 VALUES (?, ?, ?, ?, ?, ?, ?)`,
		newID, req.Phone, req.Email, string(hashedPwd), req.Name, now, now,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create user"})
		return
	}

	// Retrieve the user we just inserted
	user := model.User{
		ID:        newID,
		Phone:     req.Phone,
		Email:     req.Email,
		Name:      req.Name,
		AvatarURL: "",
		CreatedAt: time.Now().UTC().Format("2006-01-02T15:04:05Z"),
		UpdatedAt: time.Now().UTC().Format("2006-01-02T15:04:05Z"),
	}

	// Generate token
	token, err := h.generateToken(user.ID, user.Phone)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to generate token"})
		return
	}

	c.JSON(http.StatusCreated, model.AuthResponse{
		Token: token,
		User:  user,
	})
}

// Login handles user login (phone, email, or QQ openid)
func (h *AuthHandler) Login(c *gin.Context) {
	var req model.LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Determine the identifier: phone field can be phone or email; also check email field
	identifier := req.Phone
	if identifier == "" && req.Email != "" {
		identifier = req.Email
	}

	if identifier == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "请输入手机号或邮箱"})
		return
	}

	var user model.User
	err := db.DB.QueryRow(
		`SELECT id, phone, email, password_hash, name, avatar_url, created_at, updated_at 
		 FROM users WHERE phone = ? OR email = ?`,
		identifier, identifier,
	).Scan(&user.ID, &user.Phone, &user.Email, &user.PasswordHash, &user.Name, &user.AvatarURL, &user.CreatedAt, &user.UpdatedAt)

	if err == sql.ErrNoRows {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "账号或密码错误"})
		return
	}
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "database error"})
		return
	}

	// Verify password
	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.Password)); err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "账号或密码错误"})
		return
	}

	token, err := h.generateToken(user.ID, user.Phone)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to generate token"})
		return
	}

	c.JSON(http.StatusOK, model.AuthResponse{
		Token: token,
		User:  user,
	})
}

// GetProfile returns current user's profile
func (h *AuthHandler) GetProfile(c *gin.Context) {
	userID, _ := c.Get("user_id")

	var user model.User
	err := db.DB.QueryRow(
		`SELECT id, phone, email, name, avatar_url, 
		        COALESCE(qq_nickname, '') as qq_nickname, COALESCE(qq_avatar, '') as qq_avatar,
		        created_at, updated_at 
		 FROM users WHERE id = ?`, userID,
	).Scan(&user.ID, &user.Phone, &user.Email, &user.Name, &user.AvatarURL,
		&user.QQNickName, &user.QQAvatar, &user.CreatedAt, &user.UpdatedAt)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "user not found"})
		return
	}

	c.JSON(http.StatusOK, user)
}

// UpdateProfile updates current user's profile
func (h *AuthHandler) UpdateProfile(c *gin.Context) {
	userID, _ := c.Get("user_id")

	var req struct {
		Name      string `json:"name"`
		AvatarURL string `json:"avatar_url"`
		Password  string `json:"password"`
		Email     string `json:"email"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if req.Name != "" {
		_, err := db.DB.Exec(`UPDATE users SET name = ?, updated_at = datetime('now') WHERE id = ?`, req.Name, userID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "update failed"})
			return
		}
	}

	if req.AvatarURL != "" {
		_, err := db.DB.Exec(`UPDATE users SET avatar_url = ?, updated_at = datetime('now') WHERE id = ?`, req.AvatarURL, userID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "update failed"})
			return
		}
	}

	if req.Email != "" {
		_, err := db.DB.Exec(`UPDATE users SET email = ?, updated_at = datetime('now') WHERE id = ?`, req.Email, userID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "update failed"})
			return
		}
	}

	if req.Password != "" {
		hashedPwd, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to hash password"})
			return
		}
		_, err = db.DB.Exec(`UPDATE users SET password_hash = ?, updated_at = datetime('now') WHERE id = ?`, string(hashedPwd), userID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "update failed"})
			return
		}
	}

	h.GetProfile(c)
}

func (h *AuthHandler) generateToken(userID, phone string) (string, error) {
	expiryHours := 168 // default 7 days
	if h.Cfg.JWTExpiryHours != "" {
		if h, err := time.ParseDuration(h.Cfg.JWTExpiryHours + "h"); err == nil {
			expiryHours = int(h.Hours())
		}
	}

	claims := &middleware.Claims{
		UserID: userID,
		Phone:  phone,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(time.Duration(expiryHours) * time.Hour)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(h.Cfg.JWTSecret))
}
