-- Migration: Create profiles table with Row Level Security (RLS)
--
-- This migration creates the profiles table for storing user profile information.
-- The table is secured with RLS policies to ensure users can only access their own data.
--
-- IMPORTANT: This migration should be applied to a development or test Supabase project.
-- Never apply migrations to a production project without explicit approval.

-- Create the profiles table
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT NOT NULL,
  email TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create an index on the id column for faster lookups
CREATE INDEX idx_profiles_id ON profiles(id);

-- Create an index on the username column for faster lookups
CREATE INDEX idx_profiles_username ON profiles(username);

-- Enable Row Level Security (RLS) on the profiles table
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only select their own profile
CREATE POLICY profiles_select_own ON profiles
  FOR SELECT USING (auth.uid() = id);

-- Policy: Users can only insert their own profile (during signup)
CREATE POLICY profiles_insert_own ON profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Policy: Users can only update their own profile
CREATE POLICY profiles_update_own ON profiles
  FOR UPDATE USING (auth.uid() = id);

-- Policy: Users can only delete their own profile
CREATE POLICY profiles_delete_own ON profiles
  FOR DELETE USING (auth.uid() = id);

-- Create a trigger to automatically update the updated_at column
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Add a comment to the table
COMMENT ON TABLE profiles IS 'User profiles for Synvero app';
COMMENT ON COLUMN profiles.id IS 'References auth.users(id)';COMMENT ON COLUMN profiles.username IS 'User-chosen username';
COMMENT ON COLUMN profiles.email IS 'User email (mirrored from auth.users)';
COMMENT ON COLUMN profiles.created_at IS 'When the profile was created';
COMMENT ON COLUMN profiles.updated_at IS 'When the profile was last updated';