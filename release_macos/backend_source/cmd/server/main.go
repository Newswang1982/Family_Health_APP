package main

import (
	"fmt"
	"log"

	"family-health-backend/internal/config"
	"family-health-backend/internal/db"
	"family-health-backend/internal/handler"
	"family-health-backend/internal/middleware"

	"github.com/gin-gonic/gin"
)

func main() {
	cfg := config.Load()
	db.Connect(cfg)
	defer db.DB.Close()

	// Initialize handlers
	authHandler := handler.NewAuthHandler(cfg)
	wechatHandler := handler.NewWeChatHandler(cfg)
	qqHandler := handler.NewQQHandler(cfg)

	familyHandler := handler.NewFamilyHandler()

	// Create a membership checker function
	checkMember := func(userID, familyID string) bool {
		var exists bool
		err := db.DB.QueryRow(
			`SELECT EXISTS(SELECT 1 FROM family_members WHERE family_id = ? AND user_id = ?)`,
			familyID, userID,
		).Scan(&exists)
		return err == nil && exists
	}

	profileHandler := handler.NewProfileHandler(checkMember)
	recordHandler := handler.NewRecordHandler(checkMember)
	deviceHandler := handler.NewDeviceHandler(checkMember)
	statsHandler := handler.NewStatisticsHandler(checkMember)
	reportHandler := handler.NewReportHandler(checkMember)
	notificationHandler := handler.NewNotificationHandler()

	// Setup router
	gin.SetMode(cfg.ServerMode)
	r := gin.Default()

	// Public routes (no auth required)
	auth := r.Group("/api/v1/auth")
	{
		auth.POST("/register", authHandler.Register)
		auth.POST("/login", authHandler.Login)
		auth.GET("/wechat/auth-url", wechatHandler.GetWeChatAuthURL)
		auth.POST("/wechat/callback", wechatHandler.WeChatCallback)

		// QQ OAuth public routes
		auth.GET("/qq/auth-url", qqHandler.GetQQAuthURL)
		auth.POST("/qq/callback", qqHandler.QQCallback)
	}

	// Authenticated routes
	api := r.Group("/api/v1")
	api.Use(middleware.AuthMiddleware(cfg.JWTSecret))
	{
		// User profile
		api.GET("/auth/profile", authHandler.GetProfile)
		api.PUT("/auth/profile", authHandler.UpdateProfile)
		api.POST("/auth/wechat/bind", wechatHandler.BindWeChat)
		api.POST("/auth/wechat/unbind", wechatHandler.UnbindWeChat)
		api.GET("/auth/wechat/check", wechatHandler.CheckWeChatBind)

		// QQ OAuth authenticated routes
		api.POST("/auth/qq/bind", qqHandler.BindQQ)
		api.POST("/auth/qq/unbind", qqHandler.UnbindQQ)
		api.GET("/auth/qq/check", qqHandler.CheckQQBind)

		// Families
		api.POST("/families", familyHandler.CreateFamily)
		api.GET("/families", familyHandler.ListFamilies)
		api.POST("/families/join", familyHandler.JoinFamily)
		api.GET("/families/:id", familyHandler.GetFamily)
		api.POST("/families/:id/invite", familyHandler.RegenerateInviteCode)
		api.DELETE("/families/:id/members/:user_id", familyHandler.RemoveMember)

		// Member Profiles
		api.POST("/families/:id/profiles", profileHandler.CreateProfile)
		api.GET("/families/:id/profiles", profileHandler.ListProfiles)
		api.GET("/families/:id/profiles/:pid", profileHandler.GetProfile)
		api.PUT("/families/:id/profiles/:pid", profileHandler.UpdateProfile)
		api.DELETE("/families/:id/profiles/:pid", profileHandler.DeleteProfile)
		api.PUT("/families/:id/profiles/:pid/reference", profileHandler.SetReferenceRange)

		// Health Records (all types)
		api.POST("/records/health", recordHandler.CreateHealthRecord)
		api.POST("/records/sleep", recordHandler.CreateSleepRecord)
		api.POST("/records/work-posture", recordHandler.CreateWorkPostureRecord)
		api.POST("/records/smoking", recordHandler.CreateSmokingRecord)
		api.POST("/records/drinking", recordHandler.CreateDrinkingRecord)
		api.POST("/records/diet", recordHandler.CreateDietRecord)
		api.POST("/records/sugar", recordHandler.CreateSugarRecord)
		api.POST("/records/food-detail", recordHandler.CreateFoodDetailRecord)
		api.POST("/records/environment", recordHandler.CreateEnvironmentHazardRecord)
		api.GET("/records", recordHandler.QueryRecords)
		api.PUT("/records/:id", recordHandler.UpdateRecord)
		api.DELETE("/records/:id", recordHandler.DeleteRecord)

		// Statistics & K-Line
		api.GET("/statistics/:pid/:indicator_type", statsHandler.GetStatistics)
		api.GET("/statistics/:pid/:indicator_type/kline", statsHandler.GetKLine)
		api.GET("/statistics/:pid/correlation", statsHandler.GetCorrelation)
		api.GET("/statistics/:pid/trends", statsHandler.GetTrends)

		// Reports
		api.POST("/reports/generate/:pid", reportHandler.GenerateReport)
		api.GET("/reports/list/:pid", reportHandler.GetReports)
		api.POST("/reports/share/:rid", reportHandler.ShareReport)
		api.POST("/reports/push-sms/:rid", reportHandler.PushSMS)

		// Devices (BLE)
		api.POST("/families/:id/devices", deviceHandler.BindDevice)
		api.GET("/families/:id/devices", deviceHandler.ListDevices)
		api.DELETE("/families/:id/devices/:did", deviceHandler.UnbindDevice)
		api.PUT("/families/:id/devices/:did/sync", deviceHandler.UpdateDeviceSyncTime)

		// Notifications
		api.GET("/notifications", notificationHandler.ListNotifications)
		api.GET("/notifications/unread-count", notificationHandler.GetUnreadCount)
		api.PUT("/notifications/:id/read", notificationHandler.MarkAsRead)
	}

	addr := fmt.Sprintf(":%s", cfg.ServerPort)
	log.Printf("Server starting on %s", addr)
	if err := r.Run(addr); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
