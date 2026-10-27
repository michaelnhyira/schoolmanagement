-- ============================================
-- STEP 1: DROP ALL EXISTING POLICIES AND TABLES
-- Run this FIRST and wait for "Success. No rows returned"
-- ============================================

-- Drop all indexes first
DROP INDEX IF EXISTS idx_students_class;
DROP INDEX IF EXISTS idx_students_status;
DROP INDEX IF EXISTS idx_teachers_subject;
DROP INDEX IF EXISTS idx_classes_grade;
DROP INDEX IF EXISTS idx_fees_year_term;
DROP INDEX IF EXISTS idx_academic_periods_active;
DROP INDEX IF EXISTS idx_student_payments_period;
DROP INDEX IF EXISTS idx_student_payments_student;
DROP INDEX IF EXISTS idx_grades_period;
DROP INDEX IF EXISTS idx_grades_student;
DROP INDEX IF EXISTS idx_attendance_period;
DROP INDEX IF EXISTS idx_attendance_student;
DROP INDEX IF EXISTS idx_schools_code;
DROP INDEX IF EXISTS idx_schools_owner;
DROP INDEX IF EXISTS idx_school_settings_school;
DROP INDEX IF EXISTS idx_user_roles_school;
DROP INDEX IF EXISTS idx_users_school;
DROP INDEX IF EXISTS idx_students_school;
DROP INDEX IF EXISTS idx_teachers_school;
DROP INDEX IF EXISTS idx_classes_school;
DROP INDEX IF EXISTS idx_class_subdivisions_school;
DROP INDEX IF EXISTS idx_subjects_school;
DROP INDEX IF EXISTS idx_fees_school;
DROP INDEX IF EXISTS idx_academic_periods_school;
DROP INDEX IF EXISTS idx_academic_period_student_payments_school;
DROP INDEX IF EXISTS idx_academic_period_payments_school;
DROP INDEX IF EXISTS idx_grades_academic_period_school;
DROP INDEX IF EXISTS idx_grades_academic_period_grades_school;
DROP INDEX IF EXISTS idx_attendance_school;
DROP INDEX IF EXISTS idx_attendance_students_school;
DROP INDEX IF EXISTS idx_promotions_school;
DROP INDEX IF EXISTS idx_completed_batches_school;
DROP INDEX IF EXISTS idx_completed_batch_students_school;
DROP INDEX IF EXISTS idx_system_school;

-- Drop all tables first with CASCADE (this automatically drops policies and indexes too)
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

-- If you see "Success. No rows returned" you are ready for Step 2.
