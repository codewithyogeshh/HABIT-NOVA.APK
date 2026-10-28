-- Migration: Create habits and habit_completions tables with Row Level Security (RLS)
--
-- This migration creates the habits table for tracking user-defined habits
-- and the habit_completions table for daily completion records.
--
-- IMPORTANT: This migration should be applied to a development or test Supabase project.
-- Never apply migrations to a production project without explicit approval.

-- ---------------------------------------------------------------------------
-- habits table
-- ---------------------------------------------------------------------------
CREATE TABLE habits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  color TEXT DEFAULT '#4361EE',
  icon TEXT DEFAULT 'track_changes',
  archived BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for user-scoped lookups
CREATE INDEX idx_habits_user_id ON habits(user_id);
CREATE INDEX idx_habits_archived ON habits(archived);

-- Enable Row Level Security
ALTER TABLE habits ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only select their own habits
CREATE POLICY habits_select_own ON habits
  FOR SELECT USING (auth.uid() = user_id);

-- Policy: Users can only insert their own habits
CREATE POLICY habits_insert_own ON habits
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Policy: Users can only update their own habits
CREATE POLICY habits_update_own ON habits
  FOR UPDATE USING (auth.uid() = user_id);

-- Policy: Users can only delete their own habits
CREATE POLICY habits_delete_own ON habits
  FOR DELETE USING (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- habit_completions table
-- ---------------------------------------------------------------------------
CREATE TABLE habit_completions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  habit_id UUID NOT NULL REFERENCES habits(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  completed_at DATE NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  -- Prevent duplicate completion records for the same habit and date
  CONSTRAINT unique_habit_completion UNIQUE (habit_id, completed_at)
);

-- Index for user-scoped and habit-scoped lookups
CREATE INDEX idx_habit_completions_user_id ON habit_completions(user_id);
CREATE INDEX idx_habit_completions_habit_id ON habit_completions(habit_id);
CREATE INDEX idx_habit_completions_completed_at ON habit_completions(completed_at);

-- Enable Row Level Security
ALTER TABLE habit_completions ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only select their own habit completions
CREATE POLICY habit_completions_select_own ON habit_completions
  FOR SELECT USING (auth.uid() = user_id);

-- Policy: Users can only insert their own habit completions
CREATE POLICY habit_completions_insert_own ON habit_completions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Policy: Users can only delete their own habit completions
CREATE POLICY habit_completions_delete_own ON habit_completions
  FOR DELETE USING (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- Trigger to update updated_at on habits
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_habits_updated_at
  BEFORE UPDATE ON habits
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Add comments for documentation
COMMENT ON TABLE habits IS 'User-defined habits for Synvero app';
COMMENT ON COLUMN habits.id IS 'Unique habit identifier';
COMMENT ON COLUMN habits.user_id IS 'References auth.users(id) — owner of the habit';
COMMENT ON COLUMN habits.name IS 'Habit display name';
COMMENT ON COLUMN habits.description IS 'Optional habit description';
COMMENT ON COLUMN habits.color IS 'Hex color for UI theming';
COMMENT ON COLUMN habits.icon IS 'Material icon name for UI theming';
COMMENT ON COLUMN habits.archived IS 'Soft-delete flag — archived habits are hidden from active view';

COMMENT ON TABLE habit_completions IS 'Daily completion records for habits';
COMMENT ON COLUMN habit_completions.id IS 'Unique completion record identifier';
COMMENT ON COLUMN habit_completions.habit_id IS 'References habits(id)';
COMMENT ON COLUMN habit_completions.user_id IS 'References auth.users(id) — owner of the completion';
COMMENT ON COLUMN habit_completions.completed_at IS 'Local calendar date the habit was completed';