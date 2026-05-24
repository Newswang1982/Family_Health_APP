package db

import (
	"fmt"
	"log"
)

func RunMigrations() {
	migrations := []string{
		// Users table
		`CREATE TABLE IF NOT EXISTS users (
			id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
			phone TEXT NOT NULL DEFAULT '',
			email TEXT NOT NULL DEFAULT '',
			password_hash TEXT NOT NULL DEFAULT '',
			name TEXT NOT NULL DEFAULT '',
			avatar_url TEXT NOT NULL DEFAULT '',
			wechat_openid TEXT NOT NULL DEFAULT '',
			wechat_nickname TEXT NOT NULL DEFAULT '',
			wechat_avatar TEXT NOT NULL DEFAULT '',
			wechat_unionid TEXT NOT NULL DEFAULT '',
			qq_openid TEXT NOT NULL DEFAULT '',
			qq_nickname TEXT NOT NULL DEFAULT '',
			qq_avatar TEXT NOT NULL DEFAULT '',
			created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
			updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
		)`,

		`CREATE UNIQUE INDEX IF NOT EXISTS idx_users_phone ON users(phone) WHERE phone != ''`,
		`CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email ON users(email) WHERE email != ''`,
		`CREATE UNIQUE INDEX IF NOT EXISTS idx_users_wechat_openid ON users(wechat_openid) WHERE wechat_openid != ''`,
		`CREATE UNIQUE INDEX IF NOT EXISTS idx_users_qq_openid ON users(qq_openid) WHERE qq_openid != ''`,

		// Families table
		`CREATE TABLE IF NOT EXISTS families (
			id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
			name TEXT NOT NULL,
			invite_code TEXT NOT NULL,
			qr_code_url TEXT NOT NULL DEFAULT '',
			created_by TEXT NOT NULL REFERENCES users(id),
			created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
			updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
		)`,

		`CREATE UNIQUE INDEX IF NOT EXISTS idx_families_invite_code ON families(invite_code)`,

		// Family members table
		`CREATE TABLE IF NOT EXISTS family_members (
			id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
			family_id TEXT NOT NULL REFERENCES families(id),
			user_id TEXT NOT NULL REFERENCES users(id),
			role TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('admin', 'member')),
			joined_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
			UNIQUE(family_id, user_id)
		)`,

		// Member profiles table
		`CREATE TABLE IF NOT EXISTS member_profiles (
			id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
			family_id TEXT NOT NULL REFERENCES families(id),
			name TEXT NOT NULL,
			gender TEXT NOT NULL DEFAULT 'unknown' CHECK (gender IN ('male', 'female', 'unknown')),
			birth_date TEXT,
			height_cm REAL,
			weight_kg REAL,
			health_conditions TEXT NOT NULL DEFAULT '',
			allergies TEXT NOT NULL DEFAULT '',
			created_by TEXT NOT NULL REFERENCES users(id),
			created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
			updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
		)`,

		// Health reference ranges table
		`CREATE TABLE IF NOT EXISTS health_reference_ranges (
			id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
			member_profile_id TEXT NOT NULL REFERENCES member_profiles(id),
			indicator_type TEXT NOT NULL,
			min_value REAL,
			max_value REAL,
			unit TEXT NOT NULL DEFAULT '',
			UNIQUE(member_profile_id, indicator_type)
		)`,

		// Health records table
		`CREATE TABLE IF NOT EXISTS health_records (
			id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
			member_profile_id TEXT NOT NULL REFERENCES member_profiles(id),
			record_date TEXT NOT NULL,
			record_type TEXT NOT NULL,
			value_json TEXT NOT NULL DEFAULT '{}',
			note TEXT NOT NULL DEFAULT '',
			source TEXT NOT NULL DEFAULT 'manual' CHECK (source IN ('manual', 'voice', 'ocr', 'ble')),
			created_by TEXT NOT NULL REFERENCES users(id),
			created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
			updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
		)`,

		// Sleep records table
		`CREATE TABLE IF NOT EXISTS sleep_records (
			id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
			member_profile_id TEXT NOT NULL REFERENCES member_profiles(id),
			record_date TEXT NOT NULL,
			sleep_time TEXT NOT NULL,
			wake_time TEXT NOT NULL,
			nap_hours REAL,
			quality INTEGER NOT NULL CHECK (quality >= 1 AND quality <= 4),
			note TEXT NOT NULL DEFAULT '',
			source TEXT NOT NULL DEFAULT 'manual' CHECK (source IN ('manual', 'voice', 'ocr', 'ble')),
			created_by TEXT NOT NULL REFERENCES users(id),
			created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
			updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
		)`,

		// Work posture records table
		`CREATE TABLE IF NOT EXISTS work_posture_records (
			id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
			member_profile_id TEXT NOT NULL REFERENCES member_profiles(id),
			record_date TEXT NOT NULL,
			total_hours REAL NOT NULL,
			sitting_pct REAL NOT NULL CHECK (sitting_pct >= 0 AND sitting_pct <= 100),
			standing_pct REAL NOT NULL CHECK (standing_pct >= 0 AND standing_pct <= 100),
			walking_pct REAL NOT NULL CHECK (walking_pct >= 0 AND walking_pct <= 100),
			heavy_pct REAL NOT NULL CHECK (heavy_pct >= 0 AND heavy_pct <= 100),
			note TEXT NOT NULL DEFAULT '',
			source TEXT NOT NULL DEFAULT 'manual' CHECK (source IN ('manual', 'voice', 'ocr', 'ble')),
			created_by TEXT NOT NULL REFERENCES users(id),
			created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
			updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
		)`,

		`CREATE INDEX IF NOT EXISTS idx_posture_pct_sum ON work_posture_records(member_profile_id)`,
		`CREATE INDEX IF NOT EXISTS idx_work_posture_profile_date ON work_posture_records(member_profile_id, record_date)`,

		// Smoking records table
		`CREATE TABLE IF NOT EXISTS smoking_records (
			id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
			member_profile_id TEXT NOT NULL REFERENCES member_profiles(id),
			record_date TEXT NOT NULL,
			count INTEGER NOT NULL DEFAULT 0 CHECK (count >= 0),
			note TEXT NOT NULL DEFAULT '',
			source TEXT NOT NULL DEFAULT 'manual' CHECK (source IN ('manual', 'voice', 'ocr', 'ble')),
			created_by TEXT NOT NULL REFERENCES users(id),
			created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
			updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
		)`,

		// Drinking records table
		`CREATE TABLE IF NOT EXISTS drinking_records (
			id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
			member_profile_id TEXT NOT NULL REFERENCES member_profiles(id),
			record_date TEXT NOT NULL,
			liquor_type TEXT NOT NULL,
			amount REAL NOT NULL CHECK (amount >= 0),
			unit TEXT NOT NULL DEFAULT 'ml',
			note TEXT NOT NULL DEFAULT '',
			source TEXT NOT NULL DEFAULT 'manual' CHECK (source IN ('manual', 'voice', 'ocr', 'ble')),
			created_by TEXT NOT NULL REFERENCES users(id),
			created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
			updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
		)`,

		// Diet records table
		`CREATE TABLE IF NOT EXISTS diet_records (
			id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
			member_profile_id TEXT NOT NULL REFERENCES member_profiles(id),
			record_date TEXT NOT NULL,
			water_ml INTEGER NOT NULL DEFAULT 0,
			breakfast_ok INTEGER NOT NULL DEFAULT 0 CHECK (breakfast_ok IN (0, 1)),
			lunch_ok INTEGER NOT NULL DEFAULT 0 CHECK (lunch_ok IN (0, 1)),
			dinner_ok INTEGER NOT NULL DEFAULT 0 CHECK (dinner_ok IN (0, 1)),
			binge INTEGER NOT NULL DEFAULT 0 CHECK (binge IN (0, 1)),
			note TEXT NOT NULL DEFAULT '',
			source TEXT NOT NULL DEFAULT 'manual' CHECK (source IN ('manual', 'voice', 'ocr', 'ble')),
			created_by TEXT NOT NULL REFERENCES users(id),
			created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
			updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
		)`,

		// Sugar records table
		`CREATE TABLE IF NOT EXISTS sugar_records (
			id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
			member_profile_id TEXT NOT NULL REFERENCES member_profiles(id),
			record_date TEXT NOT NULL,
			soda INTEGER NOT NULL DEFAULT 0 CHECK (soda IN (0, 1)),
			juice INTEGER NOT NULL DEFAULT 0 CHECK (juice IN (0, 1)),
			milk_tea INTEGER NOT NULL DEFAULT 0 CHECK (milk_tea IN (0, 1)),
			cake INTEGER NOT NULL DEFAULT 0 CHECK (cake IN (0, 1)),
			candy INTEGER NOT NULL DEFAULT 0 CHECK (candy IN (0, 1)),
			note TEXT NOT NULL DEFAULT '',
			source TEXT NOT NULL DEFAULT 'manual' CHECK (source IN ('manual', 'voice', 'ocr', 'ble')),
			created_by TEXT NOT NULL REFERENCES users(id),
			created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
			updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
		)`,

		// Food detail records table
		`CREATE TABLE IF NOT EXISTS food_detail_records (
			id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
			member_profile_id TEXT NOT NULL REFERENCES member_profiles(id),
			record_date TEXT NOT NULL,
			lean_meat INTEGER NOT NULL DEFAULT 0 CHECK (lean_meat >= 0 AND lean_meat <= 3),
			fatty_meat INTEGER NOT NULL DEFAULT 0 CHECK (fatty_meat >= 0 AND fatty_meat <= 3),
			freshwater_fish INTEGER NOT NULL DEFAULT 0 CHECK (freshwater_fish >= 0 AND freshwater_fish <= 3),
			seafood INTEGER NOT NULL DEFAULT 0 CHECK (seafood >= 0 AND seafood <= 3),
			high_cholesterol INTEGER NOT NULL DEFAULT 0 CHECK (high_cholesterol >= 0 AND high_cholesterol <= 3),
			note TEXT NOT NULL DEFAULT '',
			source TEXT NOT NULL DEFAULT 'manual' CHECK (source IN ('manual', 'voice', 'ocr', 'ble')),
			created_by TEXT NOT NULL REFERENCES users(id),
			created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
			updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
		)`,

		// Environment hazard records table
		`CREATE TABLE IF NOT EXISTS environment_hazard_records (
			id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
			member_profile_id TEXT NOT NULL REFERENCES member_profiles(id),
			record_date TEXT NOT NULL,
			dust INTEGER NOT NULL DEFAULT 0 CHECK (dust IN (0, 1)),
			noise INTEGER NOT NULL DEFAULT 0 CHECK (noise IN (0, 1)),
			chemical_fumes INTEGER NOT NULL DEFAULT 0 CHECK (chemical_fumes IN (0, 1)),
			high_temp INTEGER NOT NULL DEFAULT 0 CHECK (high_temp IN (0, 1)),
			damp INTEGER NOT NULL DEFAULT 0 CHECK (damp IN (0, 1)),
			radiation INTEGER NOT NULL DEFAULT 0 CHECK (radiation IN (0, 1)),
			note TEXT NOT NULL DEFAULT '',
			source TEXT NOT NULL DEFAULT 'manual' CHECK (source IN ('manual', 'voice', 'ocr', 'ble')),
			created_by TEXT NOT NULL REFERENCES users(id),
			created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
			updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
		)`,

		// Device bindings table
		`CREATE TABLE IF NOT EXISTS device_bindings (
			id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
			family_id TEXT NOT NULL REFERENCES families(id),
			user_id TEXT NOT NULL REFERENCES users(id),
			device_id TEXT NOT NULL,
			member_profile_id TEXT REFERENCES member_profiles(id),
			device_name TEXT NOT NULL DEFAULT '',
			device_type TEXT NOT NULL DEFAULT '',
			last_synced_at TEXT,
			created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
			UNIQUE(family_id, device_id)
		)`,

		// Health reports table
		`CREATE TABLE IF NOT EXISTS health_reports (
			id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
			member_profile_id TEXT NOT NULL REFERENCES member_profiles(id),
			family_id TEXT NOT NULL REFERENCES families(id),
			period_type TEXT NOT NULL,
			period_start TEXT NOT NULL,
			period_end TEXT NOT NULL,
			report_data TEXT NOT NULL DEFAULT '{}',
			created_by TEXT NOT NULL REFERENCES users(id),
			created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
		)`,

		// Notifications table
		`CREATE TABLE IF NOT EXISTS notifications (
			id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
			family_id TEXT NOT NULL REFERENCES families(id),
			user_id TEXT NOT NULL REFERENCES users(id),
			member_profile_id TEXT REFERENCES member_profiles(id),
			alert_type TEXT NOT NULL,
			severity TEXT NOT NULL DEFAULT 'info' CHECK (severity IN ('info', 'warning', 'critical')),
			indicator_type TEXT NOT NULL DEFAULT '',
			indicator_value REAL,
			threshold_min REAL,
			threshold_max REAL,
			message TEXT NOT NULL,
			is_read INTEGER NOT NULL DEFAULT 0,
			pushed_sms INTEGER NOT NULL DEFAULT 0,
			created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
		)`,
	}

	for i, m := range migrations {
		if _, err := DB.Exec(m); err != nil {
			log.Fatalf("Migration %d failed: %v\nSQL: %s", i+1, err, m)
		}
	}
	fmt.Println("Migrations completed successfully")
}
