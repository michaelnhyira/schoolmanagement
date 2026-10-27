-- ============================================
-- Supabase Migration for School Management App
-- Run this in your Supabase SQL Editor:
-- https://olzldkzxsemkjgjsrfgj.supabase.co/sql/new
-- ============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- STEP 1: DROP ALL EXISTING POLICIES FIRST
-- ============================================
DROP POLICY IF EXISTS "Allow all access" ON user_roles;
DROP POLICY IF EXISTS "Allow all access" ON users;
DROP POLICY IF EXISTS "Allow all access" ON students;
DROP POLICY IF EXISTS "Allow all access" ON teachers;
DROP POLICY IF EXISTS "Allow all access" ON classes;
DROP POLICY IF EXISTS "Allow all access" ON class_subdivisions;
DROP POLICY IF EXISTS "Allow all access" ON subjects;
DROP POLICY IF EXISTS "Allow all access" ON fees;
DROP POLICY IF EXISTS "Allow all access" ON academic_periods;
DROP POLICY IF EXISTS "Allow all access" ON academic_period_student_payments;
DROP POLICY IF EXISTS "Allow all access" ON academic_period_payments;
DROP POLICY IF EXISTS "Allow all access" ON grades_academic_period;
DROP POLICY IF EXISTS "Allow all access" ON grades_academic_period_grades;
DROP POLICY IF EXISTS "Allow all access" ON attendance;
DROP POLICY IF EXISTS "Allow all access" ON attendance_students;
DROP POLICY IF EXISTS "Allow all access" ON promotions;
DROP POLICY IF EXISTS "Allow all access" ON completed_batches;
DROP POLICY IF EXISTS "Allow all access" ON completed_batch_students;
DROP POLICY IF EXISTS "Allow all access" ON system;
DROP POLICY IF EXISTS "Allow all access" ON schools;
DROP POLICY IF EXISTS "Allow all access" ON school_settings;
DROP POLICY IF EXISTS "Allow all access" ON user_payment_lock_dismissed;

-- ============================================
-- STEP 2: DROP ALL TABLES (reverse dependency order)
-- ============================================
DROP TABLE IF EXISTS user_payment_lock_dismissed CASCADE;
DROP TABLE IF EXISTS school_settings CASCADE;
DROP TABLE IF EXISTS schools CASCADE;
DROP TABLE IF EXISTS system CASCADE;
DROP TABLE IF EXISTS completed_batch_students CASCADE;
DROP TABLE IF EXISTS completed_batches CASCADE;
DROP TABLE IF EXISTS promotions CASCADE;
DROP TABLE IF EXISTS attendance_students CASCADE;
DROP TABLE IF EXISTS attendance CASCADE;
DROP TABLE IF EXISTS grades_academic_period_grades CASCADE;
DROP TABLE IF EXISTS grades_academic_period CASCADE;
DROP TABLE IF EXISTS academic_period_payments CASCADE;
DROP TABLE IF EXISTS academic_period_student_payments CASCADE;
DROP TABLE IF EXISTS academic_periods CASCADE;
DROP TABLE IF EXISTS fees CASCADE;
DROP TABLE IF EXISTS subjects CASCADE;
DROP TABLE IF EXISTS class_subdivisions CASCADE;
DROP TABLE IF EXISTS classes CASCADE;
DROP TABLE IF EXISTS teachers CASCADE;
DROP TABLE IF EXISTS students CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS user_roles CASCADE;

-- ============================================
-- STEP 3: CREATE ALL TABLES FROM SCRATCH
-- (No IF NOT EXISTS - tables were just dropped above)
-- ============================================

-- 0. SCHOOLS TABLE (must be created first - referenced by all other tables)
CREATE TABLE schools (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR NOT NULL,
  code VARCHAR UNIQUE NOT NULL,
  category VARCHAR DEFAULT 'private',
  owner_name VARCHAR,
  owner_email VARCHAR,
  owner_phone VARCHAR,
  status VARCHAR DEFAULT 'active',
  plan VARCHAR DEFAULT 'free',
  is_free_grant BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 1. USER ROLES TABLE
CREATE TABLE user_roles (
  email VARCHAR PRIMARY KEY,
  school_id UUID REFERENCES schools(id) ON DELETE CASCADE,
  display_name VARCHAR NOT NULL,
  role VARCHAR NOT NULL CHECK (role IN ('admin', 'teacher', 'accountant')),
  created_by VARCHAR,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  updated_by VARCHAR
);

-- 2. USERS TABLE (for auth state tracking)
CREATE TABLE users (
  uid VARCHAR PRIMARY KEY,
  school_id UUID REFERENCES schools(id) ON DELETE CASCADE,
  email VARCHAR,
  display_name VARCHAR,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  last_login_at TIMESTAMPTZ,
  selected_academic_period VARCHAR
);

-- ============================================
-- 3. STUDENTS TABLE
-- ============================================
CREATE TABLE students (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id UUID REFERENCES schools(id) ON DELETE CASCADE,
  name VARCHAR,
  full_name VARCHAR,
  grade VARCHAR,
  class VARCHAR,
  assigned_class VARCHAR,
  parent_name VARCHAR,
  phone VARCHAR,
  photo_url TEXT,
  status VARCHAR DEFAULT 'active',
  promotion_status VARCHAR,
  previous_class VARCHAR,
  promoted_from_class VARCHAR,
  promoted_at TIMESTAMPTZ,
  promoted_by VARCHAR,
  is_repeating BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 4. TEACHERS TABLE
-- ============================================
CREATE TABLE teachers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id UUID REFERENCES schools(id) ON DELETE CASCADE,
  name VARCHAR,
  full_name VARCHAR,
  subject VARCHAR,
  phone VARCHAR,
  email VARCHAR,
  photo_url TEXT,
  status VARCHAR DEFAULT 'active',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 5. CLASSES TABLE
-- ============================================
CREATE TABLE classes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id UUID REFERENCES schools(id) ON DELETE CASCADE,
  name VARCHAR NOT NULL,
  grade VARCHAR,
  subdivision VARCHAR,
  education_level VARCHAR,
  capacity INTEGER DEFAULT 25,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 6. CLASS SUBDIVISIONS TABLE
-- ============================================
CREATE TABLE class_subdivisions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id UUID REFERENCES schools(id) ON DELETE CASCADE,
  class_id UUID REFERENCES classes(id) ON DELETE CASCADE,
  subdivision VARCHAR,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 7. SUBJECTS TABLE
-- ============================================
CREATE TABLE subjects (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id UUID REFERENCES schools(id) ON DELETE CASCADE,
  name VARCHAR NOT NULL,
  teacher VARCHAR,
  teacher_id UUID REFERENCES teachers(id) ON DELETE CASCADE,
  credits INTEGER DEFAULT 3,
  duration VARCHAR DEFAULT 'Full Year',
  education_level VARCHAR,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 8. FEES TABLE
-- ============================================
CREATE TABLE fees (
  id VARCHAR PRIMARY KEY,
  school_id UUID REFERENCES schools(id) ON DELETE CASCADE,
  academic_year VARCHAR,
  term VARCHAR,
  class_fees JSONB,
  is_active BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 9. ACADEMIC PERIODS TABLE
-- ============================================
CREATE TABLE academic_periods (
  id VARCHAR PRIMARY KEY,
  school_id UUID REFERENCES schools(id) ON DELETE CASCADE,
  academic_year VARCHAR,
  term VARCHAR,
  is_active BOOLEAN DEFAULT false,
  description TEXT,
  total_payments INTEGER DEFAULT 0,
  total_amount NUMERIC DEFAULT 0,
  payment_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 10. ACADEMIC PERIOD STUDENT PAYMENTS TABLE
-- ============================================
CREATE TABLE academic_period_student_payments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id UUID REFERENCES schools(id) ON DELETE CASCADE,
  academic_period_id VARCHAR REFERENCES academic_periods(id) ON DELETE CASCADE,
  student_id VARCHAR,
  student_name VARCHAR,
  class_name VARCHAR,
  academic_year VARCHAR,
  term VARCHAR,
  period_id VARCHAR,
  payments JSONB DEFAULT '[]'::jsonb,
  total_paid NUMERIC DEFAULT 0,
  payment_count INTEGER DEFAULT 0,
  last_payment_date TIMESTAMPTZ,
  last_payment_method VARCHAR,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 11. ACADEMIC PERIOD PAYMENTS TABLE
-- ============================================
CREATE TABLE academic_period_payments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id UUID REFERENCES schools(id) ON DELETE CASCADE,
  academic_period_id VARCHAR REFERENCES academic_periods(id) ON DELETE CASCADE,
  student_id VARCHAR,
  student_name VARCHAR,
  amount NUMERIC,
  payment_method VARCHAR,
  class_name VARCHAR,
  academic_year VARCHAR,
  term VARCHAR,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 12. GRADES ACADEMIC PERIOD TABLE
-- ============================================
CREATE TABLE grades_academic_period (
  id VARCHAR PRIMARY KEY,
  school_id UUID REFERENCES schools(id) ON DELETE CASCADE,
  academic_year VARCHAR,
  term VARCHAR,
  is_active BOOLEAN DEFAULT false,
  total_grades INTEGER DEFAULT 0,
  total_students INTEGER DEFAULT 0,
  average_score NUMERIC DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 13. GRADES ACADEMIC PERIOD GRADES TABLE
-- ============================================
CREATE TABLE grades_academic_period_grades (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id UUID REFERENCES schools(id) ON DELETE CASCADE,
  grades_academic_period_id VARCHAR REFERENCES grades_academic_period(id) ON DELETE CASCADE,
  student_id VARCHAR,
  student_name VARCHAR,
  grades JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 14. ATTENDANCE TABLE
-- ============================================
CREATE TABLE attendance (
  id VARCHAR PRIMARY KEY,
  school_id UUID REFERENCES schools(id) ON DELETE CASCADE,
  academic_year VARCHAR,
  term VARCHAR,
  description TEXT,
  is_active BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 15. ATTENDANCE STUDENTS TABLE
-- ============================================
CREATE TABLE attendance_students (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id UUID REFERENCES schools(id) ON DELETE CASCADE,
  attendance_id VARCHAR REFERENCES attendance(id) ON DELETE CASCADE,
  student_id VARCHAR,
  academic_year VARCHAR,
  term VARCHAR,
  class_name VARCHAR,
  attendance JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 16. PROMOTIONS TABLE
-- ============================================
CREATE TABLE promotions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id UUID REFERENCES schools(id) ON DELETE CASCADE,
  from_class VARCHAR,
  to_class VARCHAR,
  promoted_by VARCHAR,
  students UUID[],
  status VARCHAR DEFAULT 'pending',
  academic_year VARCHAR,
  term VARCHAR,
  promoted_at TIMESTAMPTZ,
  confirmed_by VARCHAR,
  confirmed_at TIMESTAMPTZ,
  reversed_by VARCHAR,
  reversed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 17. COMPLETED BATCHES TABLE
-- ============================================
CREATE TABLE completed_batches (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id UUID REFERENCES schools(id) ON DELETE CASCADE,
  batch_name VARCHAR,
  completion_year VARCHAR,
  students UUID[],
  created_by VARCHAR,
  batch_year VARCHAR,
  student_ids UUID[],
  student_count INTEGER,
  status VARCHAR DEFAULT 'completed',
  completed_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 18. COMPLETED BATCH STUDENTS TABLE
-- ============================================
CREATE TABLE completed_batch_students (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id UUID REFERENCES schools(id) ON DELETE CASCADE,
  completed_batch_id UUID REFERENCES completed_batches(id) ON DELETE CASCADE,
  student_id VARCHAR,
  name VARCHAR,
  full_name VARCHAR,
  grade VARCHAR,
  class VARCHAR,
  parent_name VARCHAR,
  phone VARCHAR,
  photo_url TEXT,
  completed_batch VARCHAR,
  completed_at TIMESTAMPTZ,
  original_student_id VARCHAR,
  status VARCHAR DEFAULT 'graduated'
);

-- ============================================
-- 19. SYSTEM TABLE
-- ============================================
CREATE TABLE system (
  id VARCHAR PRIMARY KEY,
  school_id UUID REFERENCES schools(id) ON DELETE CASCADE,
  academic_year VARCHAR,
  term VARCHAR,
  period_id VARCHAR,
  is_active BOOLEAN,
  is_lock_active BOOLEAN DEFAULT false,
  is_notice_active BOOLEAN DEFAULT false,
  lock_activated_at TIMESTAMPTZ,
  notice_activated_at TIMESTAMPTZ,
  activated_by VARCHAR,
  message TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 20. SCHOOL SETTINGS TABLE
-- ============================================
CREATE TABLE school_settings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id UUID REFERENCES schools(id) ON DELETE CASCADE,
  setting_key VARCHAR NOT NULL,
  setting_value TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(school_id, setting_key)
);

-- ============================================
-- 22. USERS PAYMENT LOCK DISMISSED TABLE
-- ============================================
CREATE TABLE user_payment_lock_dismissed (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id VARCHAR,
  dismissed_at TIMESTAMPTZ DEFAULT NOW(),
  lock_activated_at TIMESTAMPTZ
);

-- ============================================
-- INDEXES for performance
-- ============================================
CREATE INDEX idx_students_class ON students(assigned_class);
CREATE INDEX idx_students_status ON students(status);
CREATE INDEX idx_teachers_subject ON teachers(subject);
CREATE INDEX idx_classes_grade ON classes(grade);
CREATE INDEX idx_fees_year_term ON fees(academic_year, term);
CREATE INDEX idx_academic_periods_active ON academic_periods(is_active);
CREATE INDEX idx_student_payments_period ON academic_period_student_payments(academic_period_id);
CREATE INDEX idx_student_payments_student ON academic_period_student_payments(student_id);
CREATE INDEX idx_grades_period ON grades_academic_period_grades(grades_academic_period_id);
CREATE INDEX idx_grades_student ON grades_academic_period_grades(student_id);
CREATE INDEX idx_attendance_period ON attendance_students(attendance_id);
CREATE INDEX idx_attendance_student ON attendance_students(student_id);
CREATE INDEX idx_schools_code ON schools(code);
CREATE INDEX idx_schools_owner ON schools(owner_email);
CREATE INDEX idx_school_settings_school ON school_settings(school_id);
CREATE INDEX idx_user_roles_school ON user_roles(school_id);
CREATE INDEX idx_users_school ON users(school_id);
CREATE INDEX idx_students_school ON students(school_id);
CREATE INDEX idx_teachers_school ON teachers(school_id);
CREATE INDEX idx_classes_school ON classes(school_id);
CREATE INDEX idx_class_subdivisions_school ON class_subdivisions(school_id);
CREATE INDEX idx_subjects_school ON subjects(school_id);
CREATE INDEX idx_fees_school ON fees(school_id);
CREATE INDEX idx_academic_periods_school ON academic_periods(school_id);
CREATE INDEX idx_academic_period_student_payments_school ON academic_period_student_payments(school_id);
CREATE INDEX idx_academic_period_payments_school ON academic_period_payments(school_id);
CREATE INDEX idx_grades_academic_period_school ON grades_academic_period(school_id);
CREATE INDEX idx_grades_academic_period_grades_school ON grades_academic_period_grades(school_id);
CREATE INDEX idx_attendance_school ON attendance(school_id);
CREATE INDEX idx_attendance_students_school ON attendance_students(school_id);
CREATE INDEX idx_promotions_school ON promotions(school_id);
CREATE INDEX idx_completed_batches_school ON completed_batches(school_id);
CREATE INDEX idx_completed_batch_students_school ON completed_batch_students(school_id);
CREATE INDEX idx_system_school ON system(school_id);

-- ============================================
-- INSERT DEFAULT SCHOOL (must come before admin user)
-- ============================================
INSERT INTO schools (id, name, code, category, owner_name, owner_email, status, plan)
VALUES ('00000000-0000-0000-0000-000000000001', 'Default School', 'SCH-DEFAULT', 'private', 'Super Owner', 'michaelnhyira77@gmail.com', 'active', 'free')
ON CONFLICT (code) DO NOTHING;

-- ============================================
-- INSERT DEFAULT ADMIN USER (linked to default school)
-- ============================================
INSERT INTO user_roles (email, school_id, display_name, role, created_by, is_active)
VALUES ('michaelnhyira77@gmail.com', '00000000-0000-0000-0000-000000000001', 'Michael Nhyira (Admin)', 'admin', 'system', true)
ON CONFLICT (email) DO NOTHING;

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================
-- Enable RLS on all tables
ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE students ENABLE ROW LEVEL SECURITY;
ALTER TABLE teachers ENABLE ROW LEVEL SECURITY;
ALTER TABLE classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE class_subdivisions ENABLE ROW LEVEL SECURITY;
ALTER TABLE subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE fees ENABLE ROW LEVEL SECURITY;
ALTER TABLE academic_periods ENABLE ROW LEVEL SECURITY;
ALTER TABLE academic_period_student_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE academic_period_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE grades_academic_period ENABLE ROW LEVEL SECURITY;
ALTER TABLE grades_academic_period_grades ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance_students ENABLE ROW LEVEL SECURITY;
ALTER TABLE promotions ENABLE ROW LEVEL SECURITY;
ALTER TABLE completed_batches ENABLE ROW LEVEL SECURITY;
ALTER TABLE completed_batch_students ENABLE ROW LEVEL SECURITY;
ALTER TABLE system ENABLE ROW LEVEL SECURITY;
ALTER TABLE schools ENABLE ROW LEVEL SECURITY;
ALTER TABLE school_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_payment_lock_dismissed ENABLE ROW LEVEL SECURITY;

-- Allow all operations for now (using anon key)
-- In production, restrict these policies based on auth.uid()
DO $$
DECLARE
  tbl TEXT;
BEGIN
  FOR tbl IN SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND tablename IN (
    'user_roles', 'users', 'students', 'teachers', 'classes', 'class_subdivisions',
    'subjects', 'fees', 'academic_periods', 'academic_period_student_payments',
    'academic_period_payments', 'grades_academic_period', 'grades_academic_period_grades',
    'attendance', 'attendance_students', 'promotions', 'completed_batches',
    'completed_batch_students', 'system', 'schools', 'school_settings',
    'user_payment_lock_dismissed'
  ) LOOP
    EXECUTE format('DROP POLICY IF EXISTS "Allow all access" ON %I', tbl);
    EXECUTE format('CREATE POLICY "Allow all access" ON %I FOR ALL USING (true) WITH CHECK (true)', tbl);
  END LOOP;
END $$;
