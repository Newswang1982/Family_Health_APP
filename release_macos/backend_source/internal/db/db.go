package db

import (
	"database/sql"
	"fmt"
	"log"
	"os"
	"path/filepath"

	_ "github.com/mattn/go-sqlite3"

	"family-health-backend/internal/config"
)

var DB *sql.DB

func Connect(cfg *config.Config) {
	home, _ := os.UserHomeDir()
	dbDir := filepath.Join(home, ".family-health")
	os.MkdirAll(dbDir, 0755)
	dbPath := filepath.Join(dbDir, "data.db")

	var err error
	DB, err = sql.Open("sqlite3", dbPath+"?_journal_mode=WAL&_foreign_keys=on")
	if err != nil {
		log.Fatalf("Failed to open database: %v", err)
	}
	DB.SetMaxOpenConns(1) // SQLite doesn't support concurrent writes

	if err = DB.Ping(); err != nil {
		log.Fatalf("Failed to ping database: %v", err)
	}
	fmt.Println("Database connected at", dbPath)
	RunMigrations()
}
