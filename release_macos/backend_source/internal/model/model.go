package model

import (
	"database/sql"
	"time"
)

// User represents an app user
type User struct {
	ID           string    `json:"id"`
	Phone        string    `json:"phone"`
	PasswordHash string    `json:"-"`
	Name         string    `json:"name"`
	AvatarURL    string    `json:"avatar_url"`
	Email        string    `json:"email"`
	QQOpenID     string    `json:"-"` // not exposed via JSON
	QQNickName   string    `json:"qq_nickname,omitempty"`
	QQAvatar     string    `json:"qq_avatar,omitempty"`
	CreatedAt    string `json:"created_at"`
	UpdatedAt    string `json:"updated_at"`
}

// Family represents a family group
type Family struct {
	ID         string    `json:"id"`
	Name       string    `json:"name"`
	InviteCode string    `json:"invite_code"`
	QRCodeURL  string    `json:"qr_code_url"`
	CreatedBy  string    `json:"created_by"`
	CreatedAt    string `json:"created_at"`
	UpdatedAt    string `json:"updated_at"`
}

// FamilyMember links a user to a family
type FamilyMember struct {
	ID       string    `json:"id"`
	FamilyID string    `json:"family_id"`
	UserID   string    `json:"user_id"`
	Role     string    `json:"role"` // admin / member
	JoinedAt time.Time `json:"joined_at"`
}

// MemberProfile represents a health profile (could be elderly/child without account)
type MemberProfile struct {
	ID                string    `json:"id"`
	FamilyID          string    `json:"family_id"`
	Name              string    `json:"name"`
	Gender            string    `json:"gender"`
	BirthDate         *string   `json:"birth_date,omitempty"`
	HeightCm          *float64  `json:"height_cm,omitempty"`
	WeightKg          *float64  `json:"weight_kg,omitempty"`
	HealthConditions  string    `json:"health_conditions"`
	Allergies         string    `json:"allergies"`
	CreatedBy         string    `json:"created_by"`
	CreatedAt    string `json:"created_at"`
	UpdatedAt    string `json:"updated_at"`
}

// HealthReferenceRange defines personal thresholds
type HealthReferenceRange struct {
	ID               string  `json:"id"`
	MemberProfileID  string  `json:"member_profile_id"`
	IndicatorType    string  `json:"indicator_type"`
	MinValue         *float64 `json:"min_value,omitempty"`
	MaxValue         *float64 `json:"max_value,omitempty"`
	Unit             string  `json:"unit"`
}

// HealthRecord general health vitals
type HealthRecord struct {
	ID              string                 `json:"id"`
	MemberProfileID string                 `json:"member_profile_id"`
	RecordDate      string                 `json:"record_date"`
	RecordType      string                 `json:"record_type"`
	ValueJSON       map[string]interface{} `json:"value_json"`
	Note            string                 `json:"note"`
	Source          string                 `json:"source"` // manual/voice/ocr/ble
	CreatedBy       string                 `json:"created_by"`
	CreatedAt    string              `json:"created_at"`
	UpdatedAt    string              `json:"updated_at"`
}

// SleepRecord
type SleepRecord struct {
	ID              string    `json:"id"`
	MemberProfileID string    `json:"member_profile_id"`
	RecordDate      string    `json:"record_date"`
	SleepTime       string    `json:"sleep_time"`
	WakeTime        string    `json:"wake_time"`
	NapHours        *float64  `json:"nap_hours,omitempty"`
	Quality         int       `json:"quality"`
	Note            string    `json:"note"`
	Source          string    `json:"source"`
	CreatedBy       string    `json:"created_by"`
	CreatedAt    string `json:"created_at"`
	UpdatedAt    string `json:"updated_at"`
}

// WorkPostureRecord
type WorkPostureRecord struct {
	ID              string    `json:"id"`
	MemberProfileID string    `json:"member_profile_id"`
	RecordDate      string    `json:"record_date"`
	TotalHours      float64   `json:"total_hours"`
	SittingPct      float64   `json:"sitting_pct"`
	StandingPct     float64   `json:"standing_pct"`
	WalkingPct      float64   `json:"walking_pct"`
	HeavyPct        float64   `json:"heavy_pct"`
	Note            string    `json:"note"`
	Source          string    `json:"source"`
	CreatedBy       string    `json:"created_by"`
	CreatedAt    string `json:"created_at"`
	UpdatedAt    string `json:"updated_at"`
}

// SmokingRecord
type SmokingRecord struct {
	ID              string    `json:"id"`
	MemberProfileID string    `json:"member_profile_id"`
	RecordDate      string    `json:"record_date"`
	Count           int       `json:"count"`
	Note            string    `json:"note"`
	Source          string    `json:"source"`
	CreatedBy       string    `json:"created_by"`
	CreatedAt    string `json:"created_at"`
	UpdatedAt    string `json:"updated_at"`
}

// DrinkingRecord
type DrinkingRecord struct {
	ID              string    `json:"id"`
	MemberProfileID string    `json:"member_profile_id"`
	RecordDate      string    `json:"record_date"`
	LiquorType      string    `json:"liquor_type"`
	Amount          float64   `json:"amount"`
	Unit            string    `json:"unit"`
	Note            string    `json:"note"`
	Source          string    `json:"source"`
	CreatedBy       string    `json:"created_by"`
	CreatedAt    string `json:"created_at"`
	UpdatedAt    string `json:"updated_at"`
}

// DietRecord
type DietRecord struct {
	ID              string    `json:"id"`
	MemberProfileID string    `json:"member_profile_id"`
	RecordDate      string    `json:"record_date"`
	WaterMl         int       `json:"water_ml"`
	BreakfastOk     int       `json:"breakfast_ok"`
	LunchOk         int       `json:"lunch_ok"`
	DinnerOk        int       `json:"dinner_ok"`
	Binge           int       `json:"binge"`
	Note            string    `json:"note"`
	Source          string    `json:"source"`
	CreatedBy       string    `json:"created_by"`
	CreatedAt    string `json:"created_at"`
	UpdatedAt    string `json:"updated_at"`
}

// SugarRecord
type SugarRecord struct {
	ID              string    `json:"id"`
	MemberProfileID string    `json:"member_profile_id"`
	RecordDate      string    `json:"record_date"`
	Soda            int       `json:"soda"`
	Juice           int       `json:"juice"`
	MilkTea         int       `json:"milk_tea"`
	Cake            int       `json:"cake"`
	Candy           int       `json:"candy"`
	Note            string    `json:"note"`
	Source          string    `json:"source"`
	CreatedBy       string    `json:"created_by"`
	CreatedAt    string `json:"created_at"`
	UpdatedAt    string `json:"updated_at"`
}

// FoodDetailRecord
type FoodDetailRecord struct {
	ID              string    `json:"id"`
	MemberProfileID string    `json:"member_profile_id"`
	RecordDate      string    `json:"record_date"`
	LeanMeat        int       `json:"lean_meat"`
	FattyMeat       int       `json:"fatty_meat"`
	FreshwaterFish  int       `json:"freshwater_fish"`
	Seafood         int       `json:"seafood"`
	HighCholesterol int       `json:"high_cholesterol"`
	Note            string    `json:"note"`
	Source          string    `json:"source"`
	CreatedBy       string    `json:"created_by"`
	CreatedAt    string `json:"created_at"`
	UpdatedAt    string `json:"updated_at"`
}

// EnvironmentHazardRecord
type EnvironmentHazardRecord struct {
	ID              string    `json:"id"`
	MemberProfileID string    `json:"member_profile_id"`
	RecordDate      string    `json:"record_date"`
	Dust            int       `json:"dust"`
	Noise           int       `json:"noise"`
	ChemicalFumes   int       `json:"chemical_fumes"`
	HighTemp        int       `json:"high_temp"`
	Damp            int       `json:"damp"`
	Radiation       int       `json:"radiation"`
	Note            string    `json:"note"`
	Source          string    `json:"source"`
	CreatedBy       string    `json:"created_by"`
	CreatedAt    string `json:"created_at"`
	UpdatedAt    string `json:"updated_at"`
}

// DeviceBinding
type DeviceBinding struct {
	ID              string         `json:"id"`
	FamilyID        string         `json:"family_id"`
	UserID          string         `json:"user_id"`
	DeviceID        string         `json:"device_id"`
	MemberProfileID *string        `json:"member_profile_id,omitempty"`
	DeviceName      string         `json:"device_name"`
	DeviceType      string         `json:"device_type"`
	LastSyncedAt    *time.Time     `json:"last_synced_at,omitempty"`
	CreatedAt    string      `json:"created_at"`
}

// HealthReport
type HealthReport struct {
	ID              string                 `json:"id"`
	MemberProfileID string                 `json:"member_profile_id"`
	FamilyID        string                 `json:"family_id"`
	PeriodType      string                 `json:"period_type"`
	PeriodStart     string                 `json:"period_start"`
	PeriodEnd       string                 `json:"period_end"`
	ReportData      map[string]interface{} `json:"report_data"`
	CreatedBy       string                 `json:"created_by"`
	CreatedAt    string              `json:"created_at"`
}

// Notification
type Notification struct {
	ID              string     `json:"id"`
	FamilyID        string     `json:"family_id"`
	UserID          string     `json:"user_id"`
	MemberProfileID *string    `json:"member_profile_id,omitempty"`
	AlertType       string     `json:"alert_type"`
	Severity        string     `json:"severity"`
	IndicatorType   string     `json:"indicator_type"`
	IndicatorValue  *float64   `json:"indicator_value,omitempty"`
	ThresholdMin    *float64   `json:"threshold_min,omitempty"`
	ThresholdMax    *float64   `json:"threshold_max,omitempty"`
	Message         string     `json:"message"`
	IsRead          bool       `json:"is_read"`
	PushedSMS       bool       `json:"pushed_sms"`
	CreatedAt    string  `json:"created_at"`
}

// ============================================================
// Request / Response DTOs
// ============================================================

type RegisterRequest struct {
	Phone    string `json:"phone" binding:"required"`
	Password string `json:"password" binding:"required,min=6"`
	Name     string `json:"name"`
	Email    string `json:"email"`
}

type LoginRequest struct {
	Phone    string `json:"phone"`     // can be phone or email
	Email    string `json:"email"`     // alternative login identifier
	Password string `json:"password" binding:"required"`
}

type AuthResponse struct {
	Token string `json:"token"`
	User  User   `json:"user"`
}

type CreateFamilyRequest struct {
	Name string `json:"name" binding:"required"`
}

type JoinFamilyRequest struct {
	InviteCode string `json:"invite_code" binding:"required"`
}

type CreateProfileRequest struct {
	Name     string  `json:"name" binding:"required"`
	Gender   string  `json:"gender"`
	BirthDate *string `json:"birth_date"`
	HeightCm *float64 `json:"height_cm"`
	WeightKg *float64 `json:"weight_kg"`
}

type CreateHealthRecordRequest struct {
	MemberProfileID string                 `json:"member_profile_id" binding:"required"`
	RecordDate      string                 `json:"record_date" binding:"required"`
	RecordType      string                 `json:"record_type" binding:"required"`
	ValueJSON       map[string]interface{} `json:"value_json" binding:"required"`
	Note            string                 `json:"note"`
	Source          string                 `json:"source"`
}

type CreateSleepRecordRequest struct {
	MemberProfileID string  `json:"member_profile_id" binding:"required"`
	RecordDate      string  `json:"record_date" binding:"required"`
	SleepTime       string  `json:"sleep_time" binding:"required"`
	WakeTime        string  `json:"wake_time" binding:"required"`
	NapHours        *float64 `json:"nap_hours"`
	Quality         int     `json:"quality" binding:"required,min=1,max=4"`
	Note            string  `json:"note"`
	Source          string  `json:"source"`
}

type CreateWorkPostureRequest struct {
	MemberProfileID string  `json:"member_profile_id" binding:"required"`
	RecordDate      string  `json:"record_date" binding:"required"`
	TotalHours      float64 `json:"total_hours" binding:"required"`
	SittingPct      float64 `json:"sitting_pct" binding:"required"`
	StandingPct     float64 `json:"standing_pct" binding:"required"`
	WalkingPct      float64 `json:"walking_pct" binding:"required"`
	HeavyPct        float64 `json:"heavy_pct" binding:"required"`
	Note            string  `json:"note"`
	Source          string  `json:"source"`
}

type CreateSmokingRequest struct {
	MemberProfileID string `json:"member_profile_id" binding:"required"`
	RecordDate      string `json:"record_date" binding:"required"`
	Count           int    `json:"count" binding:"min=0"`
	Note            string `json:"note"`
	Source          string `json:"source"`
}

type CreateDrinkingRequest struct {
	MemberProfileID string  `json:"member_profile_id" binding:"required"`
	RecordDate      string  `json:"record_date" binding:"required"`
	LiquorType      string  `json:"liquor_type" binding:"required"`
	Amount          float64 `json:"amount" binding:"required"`
	Unit            string  `json:"unit" binding:"required"`
	Note            string  `json:"note"`
	Source          string  `json:"source"`
}

type CreateDietRequest struct {
	MemberProfileID string `json:"member_profile_id" binding:"required"`
	RecordDate      string `json:"record_date" binding:"required"`
	WaterMl         int    `json:"water_ml" binding:"required"`
	BreakfastOk     int    `json:"breakfast_ok" binding:"gte=0,lte=1"`
	LunchOk         int    `json:"lunch_ok" binding:"gte=0,lte=1"`
	DinnerOk        int    `json:"dinner_ok" binding:"gte=0,lte=1"`
	Binge           int    `json:"binge" binding:"gte=0,lte=1"`
	Note            string `json:"note"`
	Source          string `json:"source"`
}

type CreateSugarRequest struct {
	MemberProfileID string `json:"member_profile_id" binding:"required"`
	RecordDate      string `json:"record_date" binding:"required"`
	Soda            int    `json:"soda" binding:"gte=0,lte=1"`
	Juice           int    `json:"juice" binding:"gte=0,lte=1"`
	MilkTea         int    `json:"milk_tea" binding:"gte=0,lte=1"`
	Cake            int    `json:"cake" binding:"gte=0,lte=1"`
	Candy           int    `json:"candy" binding:"gte=0,lte=1"`
	Note            string `json:"note"`
	Source          string `json:"source"`
}

type CreateFoodDetailRequest struct {
	MemberProfileID string `json:"member_profile_id" binding:"required"`
	RecordDate      string `json:"record_date" binding:"required"`
	LeanMeat        int    `json:"lean_meat" binding:"gte=0,lte=3"`
	FattyMeat       int    `json:"fatty_meat" binding:"gte=0,lte=3"`
	FreshwaterFish  int    `json:"freshwater_fish" binding:"gte=0,lte=3"`
	Seafood         int    `json:"seafood" binding:"gte=0,lte=3"`
	HighCholesterol int    `json:"high_cholesterol" binding:"gte=0,lte=3"`
	Note            string `json:"note"`
	Source          string `json:"source"`
}

type CreateEnvironmentHazardRequest struct {
	MemberProfileID string `json:"member_profile_id" binding:"required"`
	RecordDate      string `json:"record_date" binding:"required"`
	Dust            int    `json:"dust" binding:"gte=0,lte=1"`
	Noise           int    `json:"noise" binding:"gte=0,lte=1"`
	ChemicalFumes   int    `json:"chemical_fumes" binding:"gte=0,lte=1"`
	HighTemp        int    `json:"high_temp" binding:"gte=0,lte=1"`
	Damp            int    `json:"damp" binding:"gte=0,lte=1"`
	Radiation       int    `json:"radiation" binding:"gte=0,lte=1"`
	Note            string `json:"note"`
	Source          string `json:"source"`
}

type RecordQuery struct {
	MemberProfileID string `form:"member_profile_id"`
	DateFrom        string `form:"date_from"`
	DateTo          string `form:"date_to"`
	RecordType      string `form:"type"`
	Limit           int    `form:"limit,default=50"`
	Offset          int    `form:"offset,default=0"`
}

type BindDeviceRequest struct {
	DeviceID        string  `json:"device_id" binding:"required"`
	DeviceName      string  `json:"device_name"`
	DeviceType      string  `json:"device_type"`
	MemberProfileID *string `json:"member_profile_id"`
}

type SetReferenceRangeRequest struct {
	IndicatorType string `json:"indicator_type" binding:"required"`
	MinValue      *float64 `json:"min_value"`
	MaxValue      *float64 `json:"max_value"`
	Unit          string `json:"unit"`
}

type GenerateReportRequest struct {
	PeriodType string `json:"period_type" binding:"required,oneof=day week month quarter year"`
	PeriodFrom string `json:"period_from" binding:"required"`
	PeriodTo   string `json:"period_to" binding:"required"`
}

// For nullable fields from DB scans
type NullableFloat sql.NullFloat64
type NullableString sql.NullString
type NullableInt sql.NullInt64
type NullableTime sql.NullTime
