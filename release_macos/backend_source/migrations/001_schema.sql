-- Family Health App - Database Schema
-- PostgreSQL 16

-- ============================================================
-- 1. Users & Authentication
-- ============================================================

CREATE TABLE users (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone       VARCHAR(20) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    name        VARCHAR(100) NOT NULL DEFAULT '',
    avatar_url  TEXT NOT NULL DEFAULT '',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_users_phone ON users(phone);

-- ============================================================
-- 2. Family Groups
-- ============================================================

CREATE TABLE families (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name        VARCHAR(100) NOT NULL,
    invite_code VARCHAR(20) UNIQUE NOT NULL,
    qr_code_url TEXT NOT NULL DEFAULT '',
    created_by  UUID NOT NULL REFERENCES users(id),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_families_invite_code ON families(invite_code);

-- ============================================================
-- 3. Family Members (user <-> family link)
-- ============================================================

CREATE TABLE family_members (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    family_id   UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role        VARCHAR(20) NOT NULL DEFAULT 'member' CHECK (role IN ('admin', 'member')),
    joined_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(family_id, user_id)
);

CREATE INDEX idx_family_members_family ON family_members(family_id);
CREATE INDEX idx_family_members_user ON family_members(user_id);

-- ============================================================
-- 4. Member Profiles (independent health profiles per family member,
--    e.g. elderly parents / children who may not have their own account)
-- ============================================================

CREATE TABLE member_profiles (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    family_id       UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
    name            VARCHAR(100) NOT NULL,
    gender          VARCHAR(10) NOT NULL DEFAULT '' CHECK (gender IN ('male', 'female', '')),
    birth_date      DATE,
    height_cm       NUMERIC(5,1) DEFAULT 0,
    weight_kg       NUMERIC(5,1) DEFAULT 0,
    health_conditions TEXT NOT NULL DEFAULT '',
    allergies       TEXT NOT NULL DEFAULT '',
    created_by      UUID NOT NULL REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_member_profiles_family ON member_profiles(family_id);

-- ============================================================
-- 5. Personal Health Reference Ranges (thresholds for alerts)
-- ============================================================

CREATE TABLE health_reference_ranges (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    member_profile_id UUID NOT NULL REFERENCES member_profiles(id) ON DELETE CASCADE,
    indicator_type  VARCHAR(50) NOT NULL,
    min_value       NUMERIC(10,2),
    max_value       NUMERIC(10,2),
    unit            VARCHAR(20) NOT NULL DEFAULT '',
    UNIQUE(member_profile_id, indicator_type)
);

CREATE INDEX idx_ref_ranges_profile ON health_reference_ranges(member_profile_id);

-- ============================================================
-- 6. Health Records (general: vitals)
-- ============================================================

CREATE TABLE health_records (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    member_profile_id UUID NOT NULL REFERENCES member_profiles(id) ON DELETE CASCADE,
    record_date     DATE NOT NULL,
    record_type     VARCHAR(50) NOT NULL,
    value_json      JSONB NOT NULL DEFAULT '{}',
    note            TEXT NOT NULL DEFAULT '',
    source          VARCHAR(20) NOT NULL DEFAULT 'manual' CHECK (source IN ('manual', 'voice', 'ocr', 'ble')),
    created_by      UUID NOT NULL REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_health_records_profile_date ON health_records(member_profile_id, record_date);
CREATE INDEX idx_health_records_type ON health_records(record_type);
CREATE INDEX idx_health_records_date ON health_records(record_date);

-- ============================================================
-- 7. Sleep Records
-- ============================================================

CREATE TABLE sleep_records (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    member_profile_id UUID NOT NULL REFERENCES member_profiles(id) ON DELETE CASCADE,
    record_date     DATE NOT NULL,
    sleep_time      TIME NOT NULL,
    wake_time       TIME NOT NULL,
    nap_hours       NUMERIC(3,1) DEFAULT 0,
    quality         INT NOT NULL DEFAULT 0 CHECK (quality >= 1 AND quality <= 4),
    note            TEXT NOT NULL DEFAULT '',
    source          VARCHAR(20) NOT NULL DEFAULT 'manual' CHECK (source IN ('manual', 'voice', 'ocr', 'ble')),
    created_by      UUID NOT NULL REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(member_profile_id, record_date)
);

CREATE INDEX idx_sleep_records_profile_date ON sleep_records(member_profile_id, record_date);

-- ============================================================
-- 8. Work Posture Records
-- ============================================================

CREATE TABLE work_posture_records (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    member_profile_id UUID NOT NULL REFERENCES member_profiles(id) ON DELETE CASCADE,
    record_date     DATE NOT NULL,
    total_hours     NUMERIC(4,1) NOT NULL DEFAULT 0,
    sitting_pct     NUMERIC(5,1) NOT NULL DEFAULT 0,
    standing_pct    NUMERIC(5,1) NOT NULL DEFAULT 0,
    walking_pct     NUMERIC(5,1) NOT NULL DEFAULT 0,
    heavy_pct       NUMERIC(5,1) NOT NULL DEFAULT 0,
    note            TEXT NOT NULL DEFAULT '',
    source          VARCHAR(20) NOT NULL DEFAULT 'manual' CHECK (source IN ('manual', 'voice', 'ocr', 'ble')),
    created_by      UUID NOT NULL REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(member_profile_id, record_date)
);

CREATE INDEX idx_work_posture_profile_date ON work_posture_records(member_profile_id, record_date);

-- ============================================================
-- 9. Smoking Records (daily log)
-- ============================================================

CREATE TABLE smoking_records (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    member_profile_id UUID NOT NULL REFERENCES member_profiles(id) ON DELETE CASCADE,
    record_date     DATE NOT NULL,
    count           INT NOT NULL DEFAULT 0,
    note            TEXT NOT NULL DEFAULT '',
    source          VARCHAR(20) NOT NULL DEFAULT 'manual' CHECK (source IN ('manual', 'voice', 'ocr', 'ble')),
    created_by      UUID NOT NULL REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(member_profile_id, record_date)
);

CREATE INDEX idx_smoking_profile_date ON smoking_records(member_profile_id, record_date);

-- ============================================================
-- 10. Drinking Records (daily log)
-- ============================================================

CREATE TABLE drinking_records (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    member_profile_id UUID NOT NULL REFERENCES member_profiles(id) ON DELETE CASCADE,
    record_date     DATE NOT NULL,
    liquor_type     VARCHAR(20) NOT NULL DEFAULT '' CHECK (liquor_type IN ('baijiu', 'red_wine', 'yellow_wine', 'beer', 'other', '')),
    amount          NUMERIC(6,1) NOT NULL DEFAULT 0,
    unit            VARCHAR(10) NOT NULL DEFAULT 'liang' CHECK (unit IN ('liang', 'can', 'bottle')),
    note            TEXT NOT NULL DEFAULT '',
    source          VARCHAR(20) NOT NULL DEFAULT 'manual' CHECK (source IN ('manual', 'voice', 'ocr', 'ble')),
    created_by      UUID NOT NULL REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(member_profile_id, record_date)
);

CREATE INDEX idx_drinking_profile_date ON drinking_records(member_profile_id, record_date);

-- ============================================================
-- 11. Diet Records
-- ============================================================

CREATE TABLE diet_records (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    member_profile_id UUID NOT NULL REFERENCES member_profiles(id) ON DELETE CASCADE,
    record_date     DATE NOT NULL,
    water_ml        INT NOT NULL DEFAULT 0,
    breakfast_ok    SMALLINT NOT NULL DEFAULT 0 CHECK (breakfast_ok IN (0, 1)),
    lunch_ok        SMALLINT NOT NULL DEFAULT 0 CHECK (lunch_ok IN (0, 1)),
    dinner_ok       SMALLINT NOT NULL DEFAULT 0 CHECK (dinner_ok IN (0, 1)),
    binge           SMALLINT NOT NULL DEFAULT 0 CHECK (binge IN (0, 1)),
    note            TEXT NOT NULL DEFAULT '',
    source          VARCHAR(20) NOT NULL DEFAULT 'manual' CHECK (source IN ('manual', 'voice', 'ocr', 'ble')),
    created_by      UUID NOT NULL REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(member_profile_id, record_date)
);

CREATE INDEX idx_diet_profile_date ON diet_records(member_profile_id, record_date);

-- ============================================================
-- 12. Sugar Intake Records
-- ============================================================

CREATE TABLE sugar_records (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    member_profile_id UUID NOT NULL REFERENCES member_profiles(id) ON DELETE CASCADE,
    record_date     DATE NOT NULL,
    soda            SMALLINT NOT NULL DEFAULT 0 CHECK (soda IN (0, 1)),
    juice           SMALLINT NOT NULL DEFAULT 0 CHECK (juice IN (0, 1)),
    milk_tea        SMALLINT NOT NULL DEFAULT 0 CHECK (milk_tea IN (0, 1)),
    cake            SMALLINT NOT NULL DEFAULT 0 CHECK (cake IN (0, 1)),
    candy           SMALLINT NOT NULL DEFAULT 0 CHECK (candy IN (0, 1)),
    note            TEXT NOT NULL DEFAULT '',
    source          VARCHAR(20) NOT NULL DEFAULT 'manual' CHECK (source IN ('manual', 'voice', 'ocr', 'ble')),
    created_by      UUID NOT NULL REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(member_profile_id, record_date)
);

CREATE INDEX idx_sugar_profile_date ON sugar_records(member_profile_id, record_date);

-- ============================================================
-- 13. Fine Food Structure Records
-- ============================================================

CREATE TABLE food_detail_records (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    member_profile_id UUID NOT NULL REFERENCES member_profiles(id) ON DELETE CASCADE,
    record_date     DATE NOT NULL,
    lean_meat       SMALLINT NOT NULL DEFAULT 0 CHECK (lean_meat IN (0, 1, 2, 3)),
    fatty_meat      SMALLINT NOT NULL DEFAULT 0 CHECK (fatty_meat IN (0, 1, 2, 3)),
    freshwater_fish SMALLINT NOT NULL DEFAULT 0 CHECK (freshwater_fish IN (0, 1, 2, 3)),
    seafood         SMALLINT NOT NULL DEFAULT 0 CHECK (seafood IN (0, 1, 2, 3)),
    high_cholesterol SMALLINT NOT NULL DEFAULT 0 CHECK (high_cholesterol IN (0, 1, 2, 3)),
    note            TEXT NOT NULL DEFAULT '',
    source          VARCHAR(20) NOT NULL DEFAULT 'manual' CHECK (source IN ('manual', 'voice', 'ocr', 'ble')),
    created_by      UUID NOT NULL REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(member_profile_id, record_date)
);

CREATE INDEX idx_food_detail_profile_date ON food_detail_records(member_profile_id, record_date);

-- ============================================================
-- 14. Environment Hazard Records
-- ============================================================

CREATE TABLE environment_hazard_records (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    member_profile_id UUID NOT NULL REFERENCES member_profiles(id) ON DELETE CASCADE,
    record_date     DATE NOT NULL,
    dust            SMALLINT NOT NULL DEFAULT 0 CHECK (dust IN (0, 1)),
    noise           SMALLINT NOT NULL DEFAULT 0 CHECK (noise IN (0, 1)),
    chemical_fumes  SMALLINT NOT NULL DEFAULT 0 CHECK (chemical_fumes IN (0, 1)),
    high_temp       SMALLINT NOT NULL DEFAULT 0 CHECK (high_temp IN (0, 1)),
    damp            SMALLINT NOT NULL DEFAULT 0 CHECK (damp IN (0, 1)),
    radiation       SMALLINT NOT NULL DEFAULT 0 CHECK (radiation IN (0, 1)),
    note            TEXT NOT NULL DEFAULT '',
    source          VARCHAR(20) NOT NULL DEFAULT 'manual' CHECK (source IN ('manual', 'voice', 'ocr', 'ble')),
    created_by      UUID NOT NULL REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(member_profile_id, record_date)
);

CREATE INDEX idx_env_hazard_profile_date ON environment_hazard_records(member_profile_id, record_date);

-- ============================================================
-- 15. Device Bindings (Bluetooth BLE)
-- ============================================================

CREATE TABLE device_bindings (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    family_id       UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
    user_id         UUID NOT NULL REFERENCES users(id),
    device_id       VARCHAR(100) NOT NULL,
    member_profile_id UUID REFERENCES member_profiles(id) ON DELETE SET NULL,
    device_name     VARCHAR(200) NOT NULL DEFAULT '',
    device_type     VARCHAR(50) NOT NULL DEFAULT '',
    last_synced_at  TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(family_id, device_id)
);

CREATE INDEX idx_device_bindings_family ON device_bindings(family_id);
CREATE INDEX idx_device_bindings_member ON device_bindings(member_profile_id);

-- ============================================================
-- 16. Health Reports
-- ============================================================

CREATE TABLE health_reports (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    member_profile_id UUID NOT NULL REFERENCES member_profiles(id) ON DELETE CASCADE,
    family_id       UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
    period_type     VARCHAR(20) NOT NULL CHECK (period_type IN ('day', 'week', 'month', 'quarter', 'year')),
    period_start    DATE NOT NULL,
    period_end      DATE NOT NULL,
    report_data     JSONB NOT NULL DEFAULT '{}',
    created_by      UUID NOT NULL REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_reports_member ON health_reports(member_profile_id);
CREATE INDEX idx_reports_family ON health_reports(family_id);

-- ============================================================
-- 17. Notifications / Alerts (for abnormal indicators)
-- ============================================================

CREATE TABLE notifications (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    family_id       UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    member_profile_id UUID REFERENCES member_profiles(id) ON DELETE SET NULL,
    alert_type      VARCHAR(50) NOT NULL,
    severity        VARCHAR(20) NOT NULL DEFAULT 'warning' CHECK (severity IN ('info', 'warning', 'critical')),
    indicator_type  VARCHAR(50) NOT NULL DEFAULT '',
    indicator_value NUMERIC(10,2),
    threshold_min   NUMERIC(10,2),
    threshold_max   NUMERIC(10,2),
    message         TEXT NOT NULL DEFAULT '',
    is_read         BOOLEAN NOT NULL DEFAULT FALSE,
    pushed_sms      BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_family ON notifications(family_id);
CREATE INDEX idx_notifications_unread ON notifications(user_id, is_read) WHERE is_read = FALSE;

-- ============================================================
-- Indexes for statistics queries
-- ============================================================

CREATE INDEX idx_health_records_type_value ON health_records(member_profile_id, record_type, record_date);
CREATE INDEX idx_health_records_source ON health_records(source);
