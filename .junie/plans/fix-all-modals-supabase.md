---
sessionId: session-261012-135409-1vv0
---

# Problem Analysis

### Root Cause
The deployed JavaScript bundles (`index-CyHMor9s.js`, `vendor-misc-CaqRlHQz.js`, `chunk-messaging-ByGszVIo.js`) are **stale** — they were built **before** the `convertFieldNames()` and `school_id` auto-injection code was added to the source.

### Evidence
- **Source code** (`firebase-adapter.ts`, `supabaseUtils.ts`, `roleUtils.ts`) contains all correct code: `convertFieldNames()`, `collectionToTable()`, `getCurrentSchoolId()`, and `school_id` auto-injection in `addDoc`, `setDoc`, and `updateDoc`.
- **Deployed bundles** have **zero** occurrences of `convertFieldNames`, `toSnakeCase`, `snake`, `birth_place`, or `guardian_name` — confirmed by grep search.
- **Data flow chain** is correct: `Students.tsx → studentUtils.createStudent → firestoreUtils.addDocument → addDoc (firebase-adapter.ts) → convertFieldNames + school_id → Supabase insert`.

### What's Missing
The app needs to be **rebuilt from source** and the new bundles deployed. No source code changes are needed — the source is already correct.

# Technical Design

### Current Data Flow
```
Page (Students.tsx) 
→ studentUtils.createStudent(studentData with camelCase keys)
→ firestoreUtils.addDocument('students', studentData)
→ addDoc(collection(db, 'students'), { ...data, createdAt, updatedAt })
→ firebase-adapter.ts addDoc()
  → convertFieldNames(data) // camelCase → snake_case
  → collectionToTable('students') // → 'students'
  → getCurrentSchoolId(email) // auto-inject school_id
  → supabase.from('students').insert(insertData)
```

### What Needs to Happen
1. **Rebuild** the app from source (`school-source-temp/`) with Vite
2. **Deploy** new bundles to `school-management-e6e17.web.app/assets/`
3. **Update** `index.html` with new bundle hashes
4. **Recreate** `supabase-client.js` (deleted during assets replacement)
5. **Clean up** stale bundle files from previous builds

### Files That Will Be Affected
- `assets/index-*.js` (new hash)
- `assets/chunk-messaging-*.js` (new hash)
- `assets/vendor-misc-*.js` (new hash)
- `assets/vendor-icons-*.js` (new hash)
- `assets/vendor-pdf-*.js` (new hash)
- `assets/index-*.css` (new hash)
- `assets/supabase-client.js` (recreated)
- `index.html` (updated bundle references)

### No Source Code Changes Needed
All source files are already correct:
- `firebase-adapter.ts`: `convertFieldNames()` in `addDoc`, `setDoc`, `updateDoc` ✓
- `supabaseUtils.ts`: `convertFieldNames()` in `addDocument`, `updateDocument` ✓
- `roleUtils.ts`: `getCurrentSchoolId()` ✓
- `step2-create-all.sql`: All columns present ✓
- All page components send correct camelCase data ✓

# Testing & Validation

### Validation Approach
After rebuilding and deploying, verify:

### Key Scenarios
1. **Create Student**: Fill only `fullName` (only required field), submit → should succeed with all camelCase fields converted to snake_case in Supabase
2. **Create Teacher**: Fill required fields, submit → should succeed with `contactNumber` → `contact_number`, `appointmentDate` → `appointment_date`, etc.
3. **Create Class**: Fill required fields, submit → should succeed with `academicYear` → `academic_year`, `classTeacherId` → `class_teacher_id`, etc.
4. **Create Subject**: Fill name, submit → should succeed
5. **School Creation** (Settings → Schools tab): Create a new school → should succeed with `is_free_grant` column
6. **school_id injection**: Every created record should have a `school_id` pointing to the current user's school

### Verification Steps
- Grep for `convertFieldNames` in the new deployed bundles (should find matches)
- Grep for `school_id` in the new deployed bundles (should find matches)
- Check Supabase Table Editor after creating records to confirm data is stored correctly

# Delivery Steps

### ✓ Step 1: Rebuild the app from source with Vite
Run `npx vite build` in the source folder to produce fresh bundles containing all the `convertFieldNames`, `school_id` injection, and multi-tenant code that's already in the source but missing from deployed bundles.

### ✓ Step 2: Deploy new bundles and update index.html
Replace old assets with new build output, update index.html with new bundle hashes, recreate supabase-client.js, and remove stale bundle files from previous builds.