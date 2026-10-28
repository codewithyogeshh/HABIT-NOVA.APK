// Supabase configuration for Synvero.
//
// This file contains the Supabase project configuration.
//
// IMPORTANT: Replace the placeholder values with your actual Supabase project
// configuration. The publishable/anon key is safe to include in the Flutter app.
// Never include the service-role key in client code.
//
// To get your Supabase configuration:
// 1. Go to https://app.supabase.com
// 2. Select your project
// 3. Go to Settings > API
// 4. Copy the "URL" and "anon/public key"

const String supabaseUrl = 'https://stazogqvkrayckdigfwz.supabase.co';

/// The publishable/anon client key is safe to use in the Flutter app.
/// This key is publicly readable and allows the app to authenticate users.
/// Never use the service-role key in client code.
const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN0YXpvZ3F2a3JheWNrZGlnZnd6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTMxMjY5NjIsImV4cCI6MjEwODcwMjk2Mn0.QDIA65x5IisRrruCNGE4EMruejXmUFOphF7l2SqGlng';

/// The service-role key is a privileged key that should NEVER be included in
/// client code. It should only be used in secure server-side code.
///
/// const String supabaseServiceRoleKey = 'your-service-role-key-here';
