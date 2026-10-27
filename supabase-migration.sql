-- ============================================
-- Multi-Tenant School Management System
-- Complete Migration for Supabase
-- Run this in your Supabase SQL Editor:
-- https://olzldkzxsemkjgjsrfgj.supabase.co/sql/new
-- ============================================

-- ============================================
-- 1. CORE TENANT TABLE: SCHOOLS
-- ============================================

CREATE TABLE IF NOT EXISTS schools (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  code TEXT UNIQUE NOT NULL,
  category TEXT DEFAULT 'private',
  owner_name TEXT,
  owner_email TEXT,
  owner_phone TEXT,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'suspended')),
  plan TEXT DEFAULT 'free',
  is_free_grant BOOLEAN DEFAULT false,
  settings JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Default school for existing data
INSERT INTO schools (id, name, code, category, owner_name, owner_email, status, plan)
VALUES ('00000000-0000-0000-0000-000000000001', 'Default School', 'SCH-DEFAULT', 'private', 'Super Owner', 'michaelnhyira77@gmail.com', 'active', 'free')
ON CONFLICT (code) DO NOTHING;

-- ============================================
-- 2. USERS & ROLES TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS users (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  full_name TEXT NOT NULL,
  phone TEXT,
  role TEXT NOT NULL DEFAULT 'teacher' CHECK (role IN ('owner', 'administrator', 'teacher', 'accountant', 'librarian', 'student', 'parent')),
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'suspended', 'pending')),
  avatar_url TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(school_id, email)
);

-- ============================================
-- 3. STAFF INVITATIONS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS staff_invitations (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  invited_email TEXT NOT NULL,
  invited_role TEXT NOT NULL CHECK (invited_role IN ('owner', 'administrator', 'teacher', 'accountant', 'librarian')),
  invited_by UUID REFERENCES users(id),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'expired', 'revoked')),
  token TEXT UNIQUE NOT NULL DEFAULT (encode(gen_random_bytes(32), 'hex')),
  expires_at TIMESTAMPTZ DEFAULT (now() + interval '7 days'),
  created_at TIMESTAMPTZ DEFAULT now(),
  accepted_at TIMESTAMPTZ,
  UNIQUE(school_id, invited_email, status)
);

-- ============================================
-- 4. EXISTING BUSINESS TABLES (with school_id)
-- ============================================

-- Students
ALTER TABLE students ADD COLUMN IF NOT EXISTS school_id UUID;

-- Teachers
ALTER TABLE teachers ADD COLUMN IF NOT EXISTS school_id UUID;

-- Classes
ALTER TABLE classes ADD COLUMN IF NOT EXISTS school_id UUID;

-- Subjects
ALTER TABLE subjects ADD COLUMN IF NOT EXISTS school_id UUID;

-- Payments
ALTER TABLE payments ADD COLUMN IF NOT EXISTS school_id UUID;

-- ============================================
-- 5. NEW BUSINESS TABLES
-- ============================================

-- Attendance
CREATE TABLE IF NOT EXISTS attendance (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  student_id TEXT NOT NULL,
  class_id TEXT,
  date DATE NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('present', 'absent', 'late', 'excused')),
  noted_by UUID,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(school_id, student_id, date)
);

-- Results / Grades
CREATE TABLE IF NOT EXISTS results (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  student_id TEXT NOT NULL,
  subject_id TEXT NOT NULL,
  class_id TEXT,
  term TEXT NOT NULL,
  academic_year TEXT NOT NULL,
  assessment_type TEXT CHECK (assessment_type IN ('ca', 'exam', 'total')),
  score DECIMAL(5,2),
  max_score DECIMAL(5,2) DEFAULT 100,
  grade TEXT,
  remarks TEXT,
  entered_by UUID,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Fees
CREATE TABLE IF NOT EXISTS fees (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  code TEXT NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  category TEXT DEFAULT 'tuition' CHECK (category IN ('tuition', 'exam', 'transport', 'hostel', 'other')),
  applicable_classes TEXT[],
  due_date DATE,
  is_recurring BOOLEAN DEFAULT false,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(school_id, code)
);

-- Guardians
CREATE TABLE IF NOT EXISTS guardians (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  student_id TEXT NOT NULL,
  full_name TEXT NOT NULL,
  relationship TEXT CHECK (relationship IN ('father', 'mother', 'guardian', 'other')),
  phone TEXT,
  email TEXT,
  address TEXT,
  is_primary BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Timetables
CREATE TABLE IF NOT EXISTS timetables (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  class_id TEXT NOT NULL,
  subject_id TEXT NOT NULL,
  teacher_id TEXT,
  day_of_week INTEGER NOT NULL CHECK (day_of_week BETWEEN 1 AND 7),
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  room TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Announcements
CREATE TABLE IF NOT EXISTS announcements (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  target_audience TEXT DEFAULT 'all' CHECK (target_audience IN ('all', 'students', 'teachers', 'parents', 'staff')),
  target_classes TEXT[],
  priority TEXT DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
  published_by UUID,
  published_at TIMESTAMPTZ DEFAULT now(),
  expires_at TIMESTAMPTZ,
  status TEXT DEFAULT 'published' CHECK (status IN ('draft', 'published', 'archived')),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Inventory
CREATE TABLE IF NOT EXISTS inventory (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  category TEXT,
  quantity INTEGER DEFAULT 0,
  unit TEXT,
  location TEXT,
  purchase_date DATE,
  purchase_price DECIMAL(10,2),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Payroll
CREATE TABLE IF NOT EXISTS payroll (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  staff_id TEXT NOT NULL,
  month INTEGER NOT NULL CHECK (month BETWEEN 1 AND 12),
  year INTEGER NOT NULL,
  base_salary DECIMAL(10,2) NOT NULL,
  allowances DECIMAL(10,2) DEFAULT 0,
  deductions DECIMAL(10,2) DEFAULT 0,
  bonus DECIMAL(10,2) DEFAULT 0,
  net_pay DECIMAL(10,2) GENERATED ALWAYS AS (base_salary + allowances - deductions + bonus) STORED,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'paid', 'cancelled')),
  paid_at TIMESTAMPTZ,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(school_id, staff_id, month, year)
);

-- School Settings
CREATE TABLE IF NOT EXISTS school_settings (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  setting_key TEXT NOT NULL,
  setting_value JSONB NOT NULL,
  description TEXT,
  updated_by UUID,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(school_id, setting_key)
);

-- ============================================
-- 6. ASSIGN EXISTING DATA TO DEFAULT SCHOOL
-- ============================================

UPDATE students SET school_id = '00000000-0000-0000-0000-000000000001' WHERE school_id IS NULL;
UPDATE teachers SET school_id = '00000000-0000-0000-0000-000000000001' WHERE school_id IS NULL;
UPDATE classes SET school_id = '00000000-0000-0000-0000-000000000001' WHERE school_id IS NULL;
UPDATE subjects SET school_id = '00000000-0000-0000-0000-000000000001' WHERE school_id IS NULL;
UPDATE payments SET school_id = '00000000-0000-0000-0000-000000000001' WHERE school_id IS NULL;

-- ============================================
-- 7. INDEXES FOR PERFORMANCE
-- ============================================

-- School ID indexes on all tables
CREATE INDEX IF NOT EXISTS idx_users_school_id ON users(school_id);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_staff_invitations_school_id ON staff_invitations(school_id);
CREATE INDEX IF NOT EXISTS idx_staff_invitations_token ON staff_invitations(token);
CREATE INDEX IF NOT EXISTS idx_staff_invitations_email ON staff_invitations(invited_email);
CREATE INDEX IF NOT EXISTS idx_students_school_id ON students(school_id);
CREATE INDEX IF NOT EXISTS idx_teachers_school_id ON teachers(school_id);
CREATE INDEX IF NOT EXISTS idx_classes_school_id ON classes(school_id);
CREATE INDEX IF NOT EXISTS idx_subjects_school_id ON subjects(school_id);
CREATE INDEX IF NOT EXISTS idx_payments_school_id ON payments(school_id);
CREATE INDEX IF NOT EXISTS idx_attendance_school_id ON attendance(school_id);
CREATE INDEX IF NOT EXISTS idx_attendance_student_date ON attendance(school_id, student_id, date);
CREATE INDEX IF NOT EXISTS idx_results_school_id ON results(school_id);
CREATE INDEX IF NOT EXISTS idx_results_student ON results(school_id, student_id);
CREATE INDEX IF NOT EXISTS idx_fees_school_id ON fees(school_id);
CREATE INDEX IF NOT EXISTS idx_guardians_school_id ON guardians(school_id);
CREATE INDEX IF NOT EXISTS idx_guardians_student ON guardians(school_id, student_id);
CREATE INDEX IF NOT EXISTS idx_timetables_school_id ON timetables(school_id);
CREATE INDEX IF NOT EXISTS idx_timetables_class ON timetables(school_id, class_id);
CREATE INDEX IF NOT EXISTS idx_announcements_school_id ON announcements(school_id);
CREATE INDEX IF NOT EXISTS idx_inventory_school_id ON inventory(school_id);
CREATE INDEX IF NOT EXISTS idx_payroll_school_id ON payroll(school_id);
CREATE INDEX IF NOT EXISTS idx_payroll_staff ON payroll(school_id, staff_id);
CREATE INDEX IF NOT EXISTS idx_school_settings_school_id ON school_settings(school_id);
CREATE INDEX IF NOT EXISTS idx_school_settings_key ON school_settings(school_id, setting_key);

-- ============================================
-- 8. ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================

-- Helper function to get current user's school_id
CREATE OR REPLACE FUNCTION get_user_school_id()
RETURNS UUID AS $$
  SELECT school_id FROM users 
  WHERE email = auth.jwt() ->> 'email' 
  LIMIT 1;
$$ LANGUAGE SQL STABLE;

-- Helper function to get current user's role
CREATE OR REPLACE FUNCTION get_user_role()
RETURNS TEXT AS $$
  SELECT role FROM users 
  WHERE email = auth.jwt() ->> 'email' 
  LIMIT 1;
$$ LANGUAGE SQL STABLE;

-- Helper function to check if user is super owner
CREATE OR REPLACE FUNCTION is_super_owner()
RETURNS BOOLEAN AS $$
  SELECT auth.jwt() ->> 'email' = 'michaelnhyira77@gmail.com';
$$ LANGUAGE SQL STABLE;

-- ---- SCHOOLS TABLE ----
ALTER TABLE schools ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can read schools" ON schools;
CREATE POLICY "Anyone can read schools"
  ON schools FOR SELECT USING (true);

DROP POLICY IF EXISTS "Super owner can manage schools" ON schools;
CREATE POLICY "Super owner can manage schools"
  ON schools FOR ALL USING (is_super_owner()) WITH CHECK (is_super_owner());

-- ---- USERS TABLE ----
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read own school users" ON users;
CREATE POLICY "Users can read own school users"
  ON users FOR SELECT USING (school_id = get_user_school_id());

DROP POLICY IF EXISTS "Super owner can read all users" ON users;
CREATE POLICY "Super owner can read all users"
  ON users FOR SELECT USING (is_super_owner());

DROP POLICY IF EXISTS "Admins can manage users" ON users;
CREATE POLICY "Admins can manage users"
  ON users FOR ALL USING (
    school_id = get_user_school_id() AND 
    get_user_role() IN ('owner', 'administrator')
  ) WITH CHECK (
    school_id = get_user_school_id() AND 
    get_user_role() IN ('owner', 'administrator')
  );

-- ---- STAFF INVITATIONS TABLE ----
ALTER TABLE staff_invitations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can manage invitations" ON staff_invitations;
CREATE POLICY "Admins can manage invitations"
  ON staff_invitations FOR ALL USING (
    school_id = get_user_school_id() AND 
    get_user_role() IN ('owner', 'administrator')
  ) WITH CHECK (
    school_id = get_user_school_id() AND 
    get_user_role() IN ('owner', 'administrator')
  );

-- ---- STUDENTS TABLE ----
ALTER TABLE students ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read own school students" ON students;
CREATE POLICY "Users can read own school students"
  ON students FOR SELECT USING (school_id = get_user_school_id());

DROP POLICY IF EXISTS "Staff can manage own school students" ON students;
CREATE POLICY "Staff can manage own school students"
  ON students FOR ALL USING (
    school_id = get_user_school_id() AND 
    get_user_role() IN ('owner', 'administrator', 'teacher')
  ) WITH CHECK (school_id = get_user_school_id());

-- ---- TEACHERS TABLE ----
ALTER TABLE teachers ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read own school teachers" ON teachers;
CREATE POLICY "Users can read own school teachers"
  ON teachers FOR SELECT USING (school_id = get_user_school_id());

DROP POLICY IF EXISTS "Admins can manage teachers" ON teachers;
CREATE POLICY "Admins can manage teachers"
  ON teachers FOR ALL USING (
    school_id = get_user_school_id() AND 
    get_user_role() IN ('owner', 'administrator')
  ) WITH CHECK (school_id = get_user_school_id());

-- ---- CLASSES TABLE ----
ALTER TABLE classes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read own school classes" ON classes;
CREATE POLICY "Users can read own school classes"
  ON classes FOR SELECT USING (school_id = get_user_school_id());

DROP POLICY IF EXISTS "Admins can manage classes" ON classes;
CREATE POLICY "Admins can manage classes"
  ON classes FOR ALL USING (
    school_id = get_user_school_id() AND 
    get_user_role() IN ('owner', 'administrator')
  ) WITH CHECK (school_id = get_user_school_id());

-- ---- SUBJECTS TABLE ----
ALTER TABLE subjects ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read own school subjects" ON subjects;
CREATE POLICY "Users can read own school subjects"
  ON subjects FOR SELECT USING (school_id = get_user_school_id());

DROP POLICY IF EXISTS "Admins can manage subjects" ON subjects;
CREATE POLICY "Admins can manage subjects"
  ON subjects FOR ALL USING (
    school_id = get_user_school_id() AND 
    get_user_role() IN ('owner', 'administrator')
  ) WITH CHECK (school_id = get_user_school_id());

-- ---- PAYMENTS TABLE ----
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read own school payments" ON payments;
CREATE POLICY "Users can read own school payments"
  ON payments FOR SELECT USING (school_id = get_user_school_id());

DROP POLICY IF EXISTS "Staff can manage own school payments" ON payments;
CREATE POLICY "Staff can manage own school payments"
  ON payments FOR ALL USING (
    school_id = get_user_school_id() AND 
    get_user_role() IN ('owner', 'administrator', 'accountant')
  ) WITH CHECK (school_id = get_user_school_id());

-- ---- ATTENDANCE TABLE ----
ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read own school attendance" ON attendance;
CREATE POLICY "Users can read own school attendance"
  ON attendance FOR SELECT USING (school_id = get_user_school_id());

DROP POLICY IF EXISTS "Teachers can manage attendance" ON attendance;
CREATE POLICY "Teachers can manage attendance"
  ON attendance FOR ALL USING (
    school_id = get_user_school_id() AND 
    get_user_role() IN ('owner', 'administrator', 'teacher')
  ) WITH CHECK (school_id = get_user_school_id());

-- ---- RESULTS TABLE ----
ALTER TABLE results ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read own school results" ON results;
CREATE POLICY "Users can read own school results"
  ON results FOR SELECT USING (school_id = get_user_school_id());

DROP POLICY IF EXISTS "Teachers can manage results" ON results;
CREATE POLICY "Teachers can manage results"
  ON results FOR ALL USING (
    school_id = get_user_school_id() AND 
    get_user_role() IN ('owner', 'administrator', 'teacher')
  ) WITH CHECK (school_id = get_user_school_id());

-- ---- FEES TABLE ----
ALTER TABLE fees ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read own school fees" ON fees;
CREATE POLICY "Users can read own school fees"
  ON fees FOR SELECT USING (school_id = get_user_school_id());

DROP POLICY IF EXISTS "Admins can manage fees" ON fees;
CREATE POLICY "Admins can manage fees"
  ON fees FOR ALL USING (
    school_id = get_user_school_id() AND 
    get_user_role() IN ('owner', 'administrator', 'accountant')
  ) WITH CHECK (school_id = get_user_school_id());

-- ---- GUARDIANS TABLE ----
ALTER TABLE guardians ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read own school guardians" ON guardians;
CREATE POLICY "Users can read own school guardians"
  ON guardians FOR SELECT USING (school_id = get_user_school_id());

DROP POLICY IF EXISTS "Staff can manage guardians" ON guardians;
CREATE POLICY "Staff can manage guardians"
  ON guardians FOR ALL USING (
    school_id = get_user_school_id() AND 
    get_user_role() IN ('owner', 'administrator', 'teacher')
  ) WITH CHECK (school_id = get_user_school_id());

-- ---- TIMETABLES TABLE ----
ALTER TABLE timetables ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read own school timetables" ON timetables;
CREATE POLICY "Users can read own school timetables"
  ON timetables FOR SELECT USING (school_id = get_user_school_id());

DROP POLICY IF EXISTS "Admins can manage timetables" ON timetables;
CREATE POLICY "Admins can manage timetables"
  ON timetables FOR ALL USING (
    school_id = get_user_school_id() AND 
    get_user_role() IN ('owner', 'administrator')
  ) WITH CHECK (school_id = get_user_school_id());

-- ---- ANNOUNCEMENTS TABLE ----
ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read own school announcements" ON announcements;
CREATE POLICY "Users can read own school announcements"
  ON announcements FOR SELECT USING (school_id = get_user_school_id());

DROP POLICY IF EXISTS "Staff can manage announcements" ON announcements;
CREATE POLICY "Staff can manage announcements"
  ON announcements FOR ALL USING (
    school_id = get_user_school_id() AND 
    get_user_role() IN ('owner', 'administrator')
  ) WITH CHECK (school_id = get_user_school_id());

-- ---- INVENTORY TABLE ----
ALTER TABLE inventory ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read own school inventory" ON inventory;
CREATE POLICY "Users can read own school inventory"
  ON inventory FOR SELECT USING (school_id = get_user_school_id());

DROP POLICY IF EXISTS "Staff can manage inventory" ON inventory;
CREATE POLICY "Staff can manage inventory"
  ON inventory FOR ALL USING (
    school_id = get_user_school_id() AND 
    get_user_role() IN ('owner', 'administrator', 'accountant')
  ) WITH CHECK (school_id = get_user_school_id());

-- ---- PAYROLL TABLE ----
ALTER TABLE payroll ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Owner can read payroll" ON payroll;
CREATE POLICY "Owner can read payroll"
  ON payroll FOR SELECT USING (
    school_id = get_user_school_id() AND 
    get_user_role() IN ('owner', 'administrator', 'accountant')
  );

DROP POLICY IF EXISTS "Owner can manage payroll" ON payroll;
CREATE POLICY "Owner can manage payroll"
  ON payroll FOR ALL USING (
    school_id = get_user_school_id() AND 
    get_user_role() = 'owner'
  ) WITH CHECK (school_id = get_user_school_id());

-- ---- SCHOOL SETTINGS TABLE ----
ALTER TABLE school_settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read own school settings" ON school_settings;
CREATE POLICY "Users can read own school settings"
  ON school_settings FOR SELECT USING (school_id = get_user_school_id());

DROP POLICY IF EXISTS "Admins can manage settings" ON school_settings;
CREATE POLICY "Admins can manage settings"
  ON school_settings FOR ALL USING (
    school_id = get_user_school_id() AND 
    get_user_role() IN ('owner', 'administrator')
  ) WITH CHECK (school_id = get_user_school_id());

-- ============================================
-- 9. TRIGGERS FOR UPDATED_AT
-- ============================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_schools_updated_at ON schools;
CREATE TRIGGER trigger_update_schools_updated_at
  BEFORE UPDATE ON schools
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trigger_update_users_updated_at ON users;
CREATE TRIGGER trigger_update_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trigger_update_school_settings_updated_at ON school_settings;
CREATE TRIGGER trigger_update_school_settings_updated_at
  BEFORE UPDATE ON school_settings
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 10. FUNCTION TO INITIALIZE NEW SCHOOL
-- ============================================

CREATE OR REPLACE FUNCTION initialize_school_data(p_school_id UUID, p_owner_email TEXT, p_owner_name TEXT)
RETURNS VOID AS $$
BEGIN
  -- Create the owner user
  INSERT INTO users (school_id, email, full_name, role, status)
  VALUES (p_school_id, p_owner_email, p_owner_name, 'owner', 'active')
  ON CONFLICT (school_id, email) DO NOTHING;

  -- Create default settings
  INSERT INTO school_settings (school_id, setting_key, setting_value)
  VALUES 
    (p_school_id, 'academic_year', '{"current": "2024-2025", "terms": [{"name": "Term 1", "start": "2024-09-01", "end": "2024-12-15"}, {"name": "Term 2", "start": "2025-01-15", "end": "2025-04-15"}, {"name": "Term 3", "start": "2025-05-01", "end": "2025-07-31"}]}')
    ON CONFLICT (school_id, setting_key) DO NOTHING;

  INSERT INTO school_settings (school_id, setting_key, setting_value)
  VALUES 
    (p_school_id, 'grading_scale', '{"A": {"min": 80, "max": 100}, "B": {"min": 70, "max": 79}, "C": {"min": 60, "max": 69}, "D": {"min": 50, "max": 59}, "F": {"min": 0, "max": 49}}')
    ON CONFLICT (school_id, setting_key) DO NOTHING;

  INSERT INTO school_settings (school_id, setting_key, setting_value)
  VALUES 
    (p_school_id, 'school_info', '{"name": "", "logo": "", "motto": "", "address": "", "phone": "", "email": "", "website": ""}')
    ON CONFLICT (school_id, setting_key) DO NOTHING;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 11. FUNCTION TO ACCEPT STAFF INVITATION
-- ============================================

CREATE OR REPLACE FUNCTION accept_staff_invitation(p_token TEXT, p_full_name TEXT, p_email TEXT)
RETURNS UUID AS $$
DECLARE
  v_invitation staff_invitations%ROWTYPE;
  v_user_id UUID;
BEGIN
  -- Find the invitation
  SELECT * INTO v_invitation FROM staff_invitations WHERE token = p_token;
  
  -- Check if invitation is valid
  IF v_invitation.id IS NULL THEN
    RAISE EXCEPTION 'Invalid invitation token';
  END IF;
  
  IF v_invitation.status != 'pending' THEN
    RAISE EXCEPTION 'Invitation is no longer valid';
  END IF;
  
  IF v_invitation.expires_at < now() THEN
    UPDATE staff_invitations SET status = 'expired' WHERE id = v_invitation.id;
    RAISE EXCEPTION 'Invitation has expired';
  END IF;
  
  -- Create the user
  INSERT INTO users (school_id, email, full_name, role, status)
  VALUES (v_invitation.school_id, p_email, p_full_name, v_invitation.invited_role, 'active')
  RETURNING id INTO v_user_id;
  
  -- Mark invitation as accepted
  UPDATE staff_invitations 
  SET status = 'accepted', accepted_at = now()
  WHERE id = v_invitation.id;
  
  RETURN v_user_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- DONE
-- ============================================
