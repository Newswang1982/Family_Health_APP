package config

import (
	"log"
	"os"

	"github.com/joho/godotenv"
)

type Config struct {
	ServerPort     string
	ServerMode     string
	JWTSecret      string
	JWTExpiryHours string

	// WeChat Mini Program / Official Account OAuth
	WeChatAppID     string
	WeChatAppSecret string
	WeChatRedirectURI string

	// QQ OAuth
	QQAppID  string
	QQAppKey string
}

func Load() *Config {
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found, using environment variables")
	}

	return &Config{
		ServerPort:    getEnv("SERVER_PORT", "8080"),
		ServerMode:    getEnv("SERVER_MODE", "debug"),
		JWTSecret:     getEnv("JWT_SECRET", "dev-secret-change-me"),
		JWTExpiryHours: getEnv("JWT_EXPIRY_HOURS", "168"),

		WeChatAppID:      getEnv("WECHAT_APP_ID", ""),
		WeChatAppSecret:  getEnv("WECHAT_APP_SECRET", ""),
		WeChatRedirectURI: getEnv("WECHAT_REDIRECT_URI", ""),

		QQAppID:  getEnv("QQ_APP_ID", ""),
		QQAppKey: getEnv("QQ_APP_KEY", ""),
	}
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
