# Multi-Tenant School Management System — Setup Guide

## Overview

This system supports **thousands of schools** on a single Supabase project with strict data isolation. Each school gets its own isolated data, users, roles, and settings — all scoped by `school_id`.

## Architecture

### Tables (15+ tenant-scoped tables)

| Table | Description |
|-------|-------------|
| `schools` | Core tenant table — one row per school |
| `users` | User accounts with roles, linked to school_id |
| `staff_invitations` | Email-based staff invitation system |
| `students` | Student records |
| `teachers` | Teacher records |
| `classes` | Class/grade levels |
| `subjects` | Academic subjects |
| `payments` | Payment records |
| `attendance` | Daily attendance tracking |
| `results` | Grades and exam results |
| `fees` | Fee structures |
| `guardians` | Parent/guardian contacts |
| `timetables` | Class schedules |
| `announcements` | School-wide announcements |
| `inventory` | School inventory tracking |
| `payroll` | Staff payroll |
| `school_settings` | Per-school configuration |

### Roles

- **Owner** — Full control over their school
- **Administrator** — Manage users, classes, subjects, settings
- **Teacher** — Manage students, attendance, results
- **Accountant** — Manage fees, payments, inventory
- **Librarian** — Library management
- **Student** — View own data
- **Parent** — View children's data

### Row Level Security (RLS)

Every table has RLS policies that ensure:
- Users can only see data from their own school
- Roles control what actions are permitted
- Super owner (`michaelnhyira77@gmail.com`) can manage all schools
- No school can access another school's data

## Step 1: Run the SQL Migration

1. Go to **https://olzldkzxsemkjgjsrfgj.supabase.co/sql/new**
2. Open the file `supabase-migration.sql` in your project
3. **Copy all the SQL code** from that file
4. **Paste it** into the Supabase SQL Editor
5. Click **Run** (or press `Ctrl + Enter`)

This will:
- Create all 15+ tables with proper schema
- Add `school_id` column to existing tables
- Create a "Default School" and assign existing data to it
- Set up RLS policies for all tables
- Create helper functions for school initialization and staff invitations
- Create indexes for performance

## Step 2: Verify the Setup

After running the migration:

1. Go to **https://olzldkzxsemkjgjsrfgj.supabase.co/table-editor** 
2. You should see all the new tables listed
3. Open the `schools` table — you should see "Default School" with code `SCH-DEFAULT`
4. Open the `users` table — it should be empty (users are created when schools are created)

## Step 3: Using the System

### For Super Owner

1. Sign in as `michaelnhyira77@gmail.com`
2. Navigate to **Settings** → **Schools** tab
3. You can:
   - **Create new schools** — each gets a fresh database structure
   - **Manage users** — invite staff, change roles, suspend accounts
   - **Switch between schools** — to view or manage any school
   - **Suspend/activate schools** — control access
   - **Delete schools** — removes all associated data

### For School Owners

1. When a super owner creates a school, the owner's account is automatically created
2. The owner signs in and is routed directly to their school's workspace
3. They can invite staff members via the Schools management interface
4. Invited staff receive an email and can accept the invitation

### For Staff Members

1. Receive invitation email from school owner
2. Accept the invitation
3. Automatically associated with the inviting school
4. Can only see and access their own school's data

## Files

| File | Purpose |
|------|---------|
| `supabase-migration.sql` | Complete database schema, RLS policies, functions |
| `assets/supabase-client.js` | Supabase client initialization |
| `assets/supabase-schools.js` | Service layer for all school operations |
| `assets/schools-management-ui.js` | UI for managing schools (super owner only) |

## Key Functions

### Database Functions

- `initialize_school_data(school_id, owner_email, owner_name)` — Creates owner user and default settings for a new school
- `accept_staff_invitation(token, full_name, email)` — Validates invitation and creates user account
- `get_user_school_id()` — Returns current user's school_id (used by RLS)
- `get_user_role()` — Returns current user's role (used by RLS)
- `is_super_owner()` — Checks if current user is super owner

### JavaScript API (window.SchoolsService)

```javascript
// Schools
SchoolsService.createSchool({ name, code, owner_name, owner_email, ... })
SchoolsService.getAllSchools()
SchoolsService.deleteSchool(id)
SchoolsService.toggleSchoolStatus(id, 'active'|'suspended')

// Users
SchoolsService.getCurrentUserProfile()
SchoolsService.getCurrentUserSchoolId()
SchoolsService.getCurrentUserRole()
SchoolsService.getSchoolUsers(schoolId)
SchoolsService.updateUserRole(userId, newRole)

// Invitations
SchoolsService.inviteStaff(schoolId, email, role)
SchoolsService.getPendingInvitations(schoolId)
SchoolsService.revokeInvitation(invitationId)

// Routing
SchoolsService.getPostAuthRedirect(email)  // Returns #schools or #app
SchoolsService.setActiveSchool(school)
SchoolsService.getActiveSchool()
```

## Security

- **RLS policies** prevent any cross-tenant data access
- **school_id** is on every business table
- **Indexes** on school_id ensure fast queries even with thousands of schools
- **Staff invitations** use secure tokens with 7-day expiration
- **Role-based access** controls what each user can do within their school

## Performance

- All queries are filtered by `school_id` — never queries all schools' data
- Indexes on `school_id`, foreign keys, and commonly searched fields
- RLS policies use helper functions that cache user context
- Designed to scale to thousands of schools on a single Supabase project
