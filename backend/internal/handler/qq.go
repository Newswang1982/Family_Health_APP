package handler

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"time"

	"family-health-backend/internal/config"
	"family-health-backend/internal/db"
	"family-health-backend/internal/middleware"
	"family-health-backend/internal/model"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
)

type QQHandler struct {
	Cfg *config.Config
}

func NewQQHandler(cfg *config.Config) *QQHandler {
	return &QQHandler{Cfg: cfg}
}

// qqTokenResponse is the JSON returned by QQ OAuth API
type qqTokenResponse struct {
	AccessToken  string `json:"access_token"`
	ExpiresIn    int    `json:"expires_in"`
	RefreshToken string `json:"refresh_token"`
	ErrCode      int    `json:"errcode"`      // may not be present on error
	ErrMsg       string `json:"errmsg"`       // error description
	Error        string `json:"error"`        // QQ uses "error" field on failure
	ErrorDesc    string `json:"error_description"`
}

type qqOpenIDResponse struct {
	ClientID string `json:"client_id"`
	OpenID   string `json:"openid"`
	ErrCode  int    `json:"errcode"`
	ErrMsg   string `json:"errmsg"`
}

type qqUserInfo struct {
	Ret            int    `json:"ret"`
	Msg            string `json:"msg"`
	Nickname       string `json:"nickname"`
	FigureURL      string `json:"figureurl"`         // 30x30
	FigureURL1     string `json:"figureurl_1"`       // 50x50
	FigureURL2     string `json:"figureurl_2"`       // 100x100
	FigureURLQQ    string `json:"figureurl_qq_1"`    // 40x40
	FigureURLQQ2   string `json:"figureurl_qq_2"`    // 100x100
	Gender         string `json:"gender"`
	IsYellowVip    string `json:"is_yellow_vip"`
	Vip            string `json:"vip"`
	YellowVipLevel string `json:"yellow_vip_level"`
	Level          string `json:"level"`
	IsYellowYearVip string `json:"is_yellow_year_vip"`
}

// GetQQAuthURL returns the QQ OAuth authorization URL for the app to open
func (h *QQHandler) GetQQAuthURL(c *gin.Context) {
	if h.Cfg.QQAppID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "QQ登录未配置"})
		return
	}

	state := fmt.Sprintf("state_%d", time.Now().UnixNano())

	// QQ OAuth 2.0 authorize URL
	redirectURI := fmt.Sprintf("https://%s/api/v1/auth/qq/callback", c.Request.Host)
	authURL := fmt.Sprintf(
		"https://graph.qq.com/oauth2.0/authorize?response_type=code&client_id=%s&redirect_uri=%s&state=%s&scope=get_user_info",
		h.Cfg.QQAppID,
		url.QueryEscape(redirectURI),
		state,
	)

	c.JSON(http.StatusOK, gin.H{
		"auth_url": authURL,
		"state":    state,
	})
}

// QQCallback handles the OAuth callback from QQ
// POST /api/v1/auth/qq/callback with {"code": "xxx"}
func (h *QQHandler) QQCallback(c *gin.Context) {
	var req struct {
		Code string `json:"code" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "缺少授权码"})
		return
	}

	// 1. Exchange code for access_token
	tokenResp, err := h.exchangeQQCode(req.Code)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": fmt.Sprintf("获取QQ token失败: %v", err)})
		return
	}
	if tokenResp.Error != "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": fmt.Sprintf("QQ授权失败: %s",	tokenResp.ErrorDesc)})
		return
	}

	// 2. Get openid
	openIDResp, err := h.getQQOpenID(tokenResp.AccessToken)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": fmt.Sprintf("获取QQ OpenID失败: %v", err)})
		return
	}
	if openIDResp.OpenID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "获取QQ OpenID失败"})
		return
	}

	// 3. Get user info from QQ
	userInfo, err := h.getQQUserInfo(tokenResp.AccessToken, openIDResp.OpenID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": fmt.Sprintf("获取QQ用户信息失败: %v", err)})
		return
	}

	// 4. Check if we already have this user by qq_openid
	var user model.User
	err = db.DB.QueryRow(
		`SELECT id, phone, email, name, avatar_url, 
		        COALESCE(qq_nickname, '') as qq_nickname, COALESCE(qq_avatar, '') as qq_avatar,
		        created_at, updated_at
		 FROM users WHERE qq_openid = ?`,
		openIDResp.OpenID,
	).Scan(&user.ID, &user.Phone, &user.Email, &user.Name, &user.AvatarURL,
		&user.QQNickName, &user.QQAvatar, &user.CreatedAt, &user.UpdatedAt)

	if err == sql.ErrNoRows {
		// New user — create account with QQ info
		avatarURL := userInfo.FigureURLQQ2
		if avatarURL == "" {
			avatarURL = userInfo.FigureURL
		}
		user, err = h.createQQUser(openIDResp.OpenID, userInfo, avatarURL)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "创建用户失败"})
			return
		}
	} else if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "查询用户失败"})
		return
	}

	// 5. Generate JWT token
	token, err := h.generateQQToken(user.ID, user.Phone)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "生成token失败"})
		return
	}

	c.JSON(http.StatusOK, model.AuthResponse{
		Token: token,
		User:  user,
	})
}

// BindQQ binds an existing account to QQ
// POST /api/v1/auth/qq/bind with {"code": "xxx"}
func (h *QQHandler) BindQQ(c *gin.Context) {
	userID, _ := c.Get("user_id")

	var req struct {
		Code string `json:"code" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "缺少授权码"})
		return
	}

	tokenResp, err := h.exchangeQQCode(req.Code)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "获取QQ token失败"})
		return
	}
	if tokenResp.Error != "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": fmt.Sprintf("QQ授权失败: %s",	tokenResp.ErrorDesc)})
		return
	}

	openIDResp, err := h.getQQOpenID(tokenResp.AccessToken)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "获取QQ OpenID失败"})
		return
	}
	if openIDResp.OpenID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "获取QQ OpenID失败"})
		return
	}

	userInfo, err := h.getQQUserInfo(tokenResp.AccessToken, openIDResp.OpenID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "获取QQ用户信息失败"})
		return
	}

	// Check if this openid already bound to another account
	var exists bool
	db.DB.QueryRow(`SELECT EXISTS(SELECT 1 FROM users WHERE qq_openid = ? AND id != ?)`,
		openIDResp.OpenID, userID).Scan(&exists)
	if exists {
		c.JSON(http.StatusConflict, gin.H{"error": "该QQ已绑定其他账号"})
		return
	}

	avatarURL := userInfo.FigureURLQQ2
	if avatarURL == "" {
		avatarURL = userInfo.FigureURL
	}

	_, err = db.DB.Exec(
		`UPDATE users SET qq_openid = ?, qq_nickname = ?, qq_avatar = ?, updated_at = datetime('now') WHERE id = ?`,
		openIDResp.OpenID, userInfo.Nickname, avatarURL, userID,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "绑定失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "QQ绑定成功"})
}

// UnbindQQ unbinds QQ from the account
func (h *QQHandler) UnbindQQ(c *gin.Context) {
	userID, _ := c.Get("user_id")

	// Cannot unbind if no phone and no email — user won't be able to login
	var phone, email string
	db.DB.QueryRow(`SELECT COALESCE(phone,''), COALESCE(email,'') FROM users WHERE id = ?`, userID).Scan(&phone, &email)
	if phone == "" && email == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "请先绑定手机号或邮箱后再解绑QQ"})
		return
	}

	_, err := db.DB.Exec(
		`UPDATE users SET qq_openid = '', qq_nickname = '', qq_avatar = '', updated_at = datetime('now') WHERE id = ?`,
		userID,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "解绑失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "QQ解绑成功"})
}

// CheckQQBind returns whether the current user has QQ bound
func (h *QQHandler) CheckQQBind(c *gin.Context) {
	userID, _ := c.Get("user_id")

	var qqOpenid string
	err := db.DB.QueryRow(`SELECT COALESCE(qq_openid, '') FROM users WHERE id = ?`, userID).Scan(&qqOpenid)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "查询失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"bound": qqOpenid != "",
	})
}

// ============================================================
// Internal helpers
// ============================================================

func (h *QQHandler) exchangeQQCode(code string) (*qqTokenResponse, error) {
	redirectURI := fmt.Sprintf("https://%s/api/v1/auth/qq/callback", "localhost") // fallback
	urlStr := fmt.Sprintf(
		"https://graph.qq.com/oauth2.0/token?grant_type=authorization_code&client_id=%s&client_secret=%s&code=%s&redirect_uri=%s&fmt=json",
		h.Cfg.QQAppID, h.Cfg.QQAppKey, code, url.QueryEscape(redirectURI),
	)

	resp, err := http.Get(urlStr)
	if err != nil {
		return nil, fmt.Errorf("request failed: %w", err)
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(resp.Body)
	var result qqTokenResponse
	if err := json.Unmarshal(body, &result); err != nil {
		return nil, fmt.Errorf("parse failed: %w", err)
	}
	return &result, nil
}

func (h *QQHandler) getQQOpenID(accessToken string) (*qqOpenIDResponse, error) {
	urlStr := fmt.Sprintf(
		"https://graph.qq.com/oauth2.0/me?access_token=%s&fmt=json",
		accessToken,
	)

	resp, err := http.Get(urlStr)
	if err != nil {
		return nil, fmt.Errorf("request failed: %w", err)
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(resp.Body)
	var result qqOpenIDResponse
	if err := json.Unmarshal(body, &result); err != nil {
		return nil, fmt.Errorf("parse failed: %w", err)
	}
	return &result, nil
}

func (h *QQHandler) getQQUserInfo(accessToken, openID string) (*qqUserInfo, error) {
	urlStr := fmt.Sprintf(
		"https://graph.qq.com/user/get_user_info?access_token=%s&oauth_consumer_key=%s&openid=%s",
		accessToken, h.Cfg.QQAppID, openID,
	)

	resp, err := http.Get(urlStr)
	if err != nil {
		return nil, fmt.Errorf("request failed: %w", err)
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(resp.Body)
	var user qqUserInfo
	if err := json.Unmarshal(body, &user); err != nil {
		return nil, fmt.Errorf("parse failed: %w", err)
	}
	return &user, nil
}

func (h *QQHandler) createQQUser(openID string, userInfo *qqUserInfo, avatarURL string) (model.User, error) {
	// INSERT + LastInsertId + SELECT instead of RETURNING
	res, err := db.DB.Exec(
		`INSERT INTO users (phone, email, name, avatar_url, qq_openid, qq_nickname, qq_avatar)
		 VALUES (?, ?, ?, ?, ?, ?, ?)`,
		"", "", userInfo.Nickname, avatarURL, openID, userInfo.Nickname, avatarURL,
	)
	if err != nil {
		return model.User{}, err
	}
	newID, _ := res.LastInsertId()
	var user model.User
	err = db.DB.QueryRow(
		`SELECT id, phone, email, name, avatar_url, 
		           COALESCE(qq_nickname, '') as qq_nickname, COALESCE(qq_avatar, '') as qq_avatar,
		           created_at, updated_at
		 FROM users WHERE rowid = ?`, newID,
	).Scan(&user.ID, &user.Phone, &user.Email, &user.Name, &user.AvatarURL,
		&user.QQNickName, &user.QQAvatar, &user.CreatedAt, &user.UpdatedAt)
	return user, err
}

func (h *QQHandler) generateQQToken(userID, phone string) (string, error) {
	claims := &middleware.Claims{
		UserID: userID,
		Phone:  phone,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(168 * time.Hour)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
		},
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(h.Cfg.JWTSecret))
}
