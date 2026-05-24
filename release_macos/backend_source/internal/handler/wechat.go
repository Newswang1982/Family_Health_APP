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

type WeChatHandler struct {
	Cfg *config.Config
}

func NewWeChatHandler(cfg *config.Config) *WeChatHandler {
	return &WeChatHandler{Cfg: cfg}
}

// weChatTokenResponse is the JSON returned by wechat api
type weChatTokenResponse struct {
	AccessToken  string `json:"access_token"`
	ExpiresIn    int    `json:"expires_in"`
	RefreshToken string `json:"refresh_token"`
	OpenID       string `json:"openid"`
	Scope        string `json:"scope"`
	UnionID      string `json:"unionid"`
	ErrCode      int    `json:"errcode"`
	ErrMsg       string `json:"errmsg"`
}

type weChatUserInfo struct {
	OpenID     string `json:"openid"`
	Nickname   string `json:"nickname"`
	Sex        int    `json:"sex"`
	Province   string `json:"province"`
	City       string `json:"city"`
	Country    string `json:"country"`
	HeadImgURL string `json:"headimgurl"`
	UnionID    string `json:"unionid"`
	ErrCode    int    `json:"errcode"`
	ErrMsg     string `json:"errmsg"`
}

// GetWeChatAuthURL returns the WeChat OAuth authorization URL for the app to open
func (h *WeChatHandler) GetWeChatAuthURL(c *gin.Context) {
	if h.Cfg.WeChatAppID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "微信登录未配置"})
		return
	}

	state := fmt.Sprintf("state_%d", time.Now().UnixNano())

	authURL := fmt.Sprintf(
		"https://open.weixin.qq.com/connect/oauth2/authorize?appid=%s&redirect_uri=%s&response_type=code&scope=snsapi_userinfo&state=%s#wechat_redirect",
		h.Cfg.WeChatAppID,
		url.QueryEscape(h.Cfg.WeChatRedirectURI),
		state,
	)

	c.JSON(http.StatusOK, gin.H{
		"auth_url": authURL,
		"state":    state,
	})
}

// WeChatCallback handles the OAuth callback from WeChat
// POST /api/v1/auth/wechat/callback with {"code": "xxx"}
func (h *WeChatHandler) WeChatCallback(c *gin.Context) {
	var req struct {
		Code string `json:"code" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "缺少授权码"})
		return
	}

	// 1. Exchange code for access_token + openid
	tokenResp, err := h.exchangeCode(req.Code)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": fmt.Sprintf("获取微信token失败: %v", err)})
		return
	}
	if tokenResp.ErrCode != 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": fmt.Sprintf("微信授权失败: %s", tokenResp.ErrMsg)})
		return
	}

	// 2. Get user info from WeChat
	userInfo, err := h.getUserInfo(tokenResp.AccessToken, tokenResp.OpenID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": fmt.Sprintf("获取微信用户信息失败: %v", err)})
		return
	}

	// 3. Check if we already have this user by wechat_openid
	var user model.User
	err = db.DB.QueryRow(
		`SELECT id, phone, name, avatar_url, created_at, updated_at
		 FROM users WHERE wechat_openid = ?`,
		userInfo.OpenID,
	).Scan(&user.ID, &user.Phone, &user.Name, &user.AvatarURL, &user.CreatedAt, &user.UpdatedAt)

	if err == sql.ErrNoRows {
		// New user — create account with wechat info
		user, err = h.createWeChatUser(userInfo)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "创建用户失败"})
			return
		}
	} else if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "查询用户失败"})
		return
	}

	// 4. Generate JWT token
	token, err := h.generateToken(user.ID, user.Phone)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "生成token失败"})
		return
	}

	c.JSON(http.StatusOK, model.AuthResponse{
		Token: token,
		User:  user,
	})
}

// BindWeChat binds an existing account to WeChat
// POST /api/v1/auth/wechat/bind with {"code": "xxx"}
func (h *WeChatHandler) BindWeChat(c *gin.Context) {
	userID, _ := c.Get("user_id")

	var req struct {
		Code string `json:"code" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "缺少授权码"})
		return
	}

	tokenResp, err := h.exchangeCode(req.Code)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "获取微信token失败"})
		return
	}
	if tokenResp.ErrCode != 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": fmt.Sprintf("微信授权失败: %s", tokenResp.ErrMsg)})
		return
	}

	userInfo, err := h.getUserInfo(tokenResp.AccessToken, tokenResp.OpenID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "获取微信用户信息失败"})
		return
	}

	// Check if this openid already bound to another account
	var exists bool
	db.DB.QueryRow(`SELECT EXISTS(SELECT 1 FROM users WHERE wechat_openid = ? AND id != ?)`,
		userInfo.OpenID, userID).Scan(&exists)
	if exists {
		c.JSON(http.StatusConflict, gin.H{"error": "该微信已绑定其他账号"})
		return
	}

	_, err = db.DB.Exec(
		`UPDATE users SET wechat_openid = ?, wechat_nickname = ?, wechat_avatar = ?, wechat_unionid = ?, updated_at = datetime('now') WHERE id = ?`,
		userInfo.OpenID, userInfo.Nickname, userInfo.HeadImgURL, userInfo.UnionID, userID,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "绑定失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "微信绑定成功"})
}

// UnbindWeChat unbinds WeChat from the account
func (h *WeChatHandler) UnbindWeChat(c *gin.Context) {
	userID, _ := c.Get("user_id")

	// Cannot unbind if no phone — user won't be able to login
	var phone string
	db.DB.QueryRow(`SELECT phone FROM users WHERE id = ?`, userID).Scan(&phone)
	if phone == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "请先绑定手机号后再解绑微信"})
		return
	}

	_, err := db.DB.Exec(
		`UPDATE users SET wechat_openid = '', wechat_nickname = '', wechat_avatar = '', updated_at = datetime('now') WHERE id = ?`,
		userID,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "解绑失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "微信解绑成功"})
}

// CheckWeChatBind returns whether the current user has WeChat bound
func (h *WeChatHandler) CheckWeChatBind(c *gin.Context) {
	userID, _ := c.Get("user_id")

	var wechatOpenid string
	err := db.DB.QueryRow(`SELECT COALESCE(wechat_openid, '') FROM users WHERE id = ?`, userID).Scan(&wechatOpenid)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "查询失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"bound": wechatOpenid != "",
	})
}

// ============================================================
// Internal helpers
// ============================================================

func (h *WeChatHandler) exchangeCode(code string) (*weChatTokenResponse, error) {
	urlStr := fmt.Sprintf(
		"https://api.weixin.qq.com/sns/oauth2/access_token?appid=%s&secret=%s&code=%s&grant_type=authorization_code",
		h.Cfg.WeChatAppID, h.Cfg.WeChatAppSecret, code,
	)

	resp, err := http.Get(urlStr)
	if err != nil {
		return nil, fmt.Errorf("request failed: %w", err)
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(resp.Body)
	var result weChatTokenResponse
	if err := json.Unmarshal(body, &result); err != nil {
		return nil, fmt.Errorf("parse failed: %w", err)
	}
	return &result, nil
}

func (h *WeChatHandler) getUserInfo(accessToken, openID string) (*weChatUserInfo, error) {
	urlStr := fmt.Sprintf(
		"https://api.weixin.qq.com/sns/userinfo?access_token=%s&openid=%s&lang=zh_CN",
		accessToken, openID,
	)

	resp, err := http.Get(urlStr)
	if err != nil {
		return nil, fmt.Errorf("request failed: %w", err)
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(resp.Body)
	var user weChatUserInfo
	if err := json.Unmarshal(body, &user); err != nil {
		return nil, fmt.Errorf("parse failed: %w", err)
	}
	return &user, nil
}

func (h *WeChatHandler) createWeChatUser(userInfo *weChatUserInfo) (model.User, error) {
	// INSERT + LastInsertId + SELECT instead of RETURNING
	res, err := db.DB.Exec(
		`INSERT INTO users (phone, name, avatar_url, wechat_openid, wechat_nickname, wechat_avatar, wechat_unionid)
		 VALUES (?, ?, ?, ?, ?, ?, ?)`,
		"", userInfo.Nickname, userInfo.HeadImgURL, userInfo.OpenID, userInfo.Nickname, userInfo.HeadImgURL, userInfo.UnionID,
	)
	if err != nil {
		return model.User{}, err
	}
	newID, _ := res.LastInsertId()
	var user model.User
	err = db.DB.QueryRow(
		`SELECT id, phone, name, avatar_url, created_at, updated_at
		 FROM users WHERE rowid = ?`, newID,
	).Scan(&user.ID, &user.Phone, &user.Name, &user.AvatarURL, &user.CreatedAt, &user.UpdatedAt)
	return user, err
}

func (h *WeChatHandler) generateToken(userID, phone string) (string, error) {
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
