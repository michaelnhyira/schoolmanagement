// Supabase client configuration
const SUPABASE_URL = 'https://olzldkzxsemkjgjsrfgj.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9semxka3p4c2Vta2pnanNyZmdqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTExMjE0MDksImV4cCI6MjEwNjY5NzQwOX0.iSKt_BcTDBruT3l9DyorDcIwjmYJvsEZ7oQW31CLDEY';
const SUPER_OWNER_EMAIL = 'michaelnhyra77@gmail.com';

// Minimal Supabase client for schools management
window.SupabaseClient = {
  url: SUPABASE_URL,
  key: SUPABASE_ANON_KEY,
  superOwnerEmail: SUPER_OWNER_EMAIL
};

console.log('[Supabase Client] Initialized');
