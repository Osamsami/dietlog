-- =============================================================================
-- DietLog — Supabase Database Schema Migration
-- Version: 001 — Initial Schema
-- Stack: Supabase (leverages auth.users for identity management)
-- =============================================================================

-- ─── 1. Profiles Table (extends Supabase auth.users) ────────────────────────
-- Stores additional user metadata beyond what Supabase Auth provides.
-- The `id` column references auth.users(id) directly — no custom auth needed.
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row-Level Security
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- RLS Policies: Users can only access their own profile row
CREATE POLICY "Users can view own profile"
    ON public.profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
    ON public.profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

-- ─── 2. Nutrition Logs Table ─────────────────────────────────────────────────
-- Stores per-meal nutritional data from the vision inference pipeline.
-- All numeric nutrition fields enforce non-negative constraints at the DB level.
CREATE TABLE public.nutrition_logs (
    log_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    food_name VARCHAR(150) NOT NULL,
    calories INT NOT NULL CHECK (calories >= 0),
    protein_g NUMERIC(5,2) NOT NULL CHECK (protein_g >= 0),
    carbs_g NUMERIC(5,2) NOT NULL CHECK (carbs_g >= 0),
    fats_g NUMERIC(5,2) NOT NULL CHECK (fats_g >= 0),
    confidence_score NUMERIC(4,2),
    serving_size_estimate VARCHAR(100),
    image_url TEXT,
    logged_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row-Level Security
ALTER TABLE public.nutrition_logs ENABLE ROW LEVEL SECURITY;

-- RLS Policies: Users can only access their own nutrition logs
CREATE POLICY "Users can view own logs"
    ON public.nutrition_logs FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own logs"
    ON public.nutrition_logs FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own logs"
    ON public.nutrition_logs FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own logs"
    ON public.nutrition_logs FOR DELETE
    USING (auth.uid() = user_id);

-- ─── 3. Composite Index for Dashboard Aggregations ──────────────────────────
-- Optimized for 7-day and 30-day temporal window queries used by the dashboard.
-- DESC ordering on logged_at ensures recent-first access patterns are fast.
CREATE INDEX idx_user_logs_date
    ON public.nutrition_logs (user_id, logged_at DESC);

-- ─── 4. Auto-Update Trigger for profiles.updated_at ─────────────────────────
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_profile_updated
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- ─── 5. Auto-Create Profile on Signup ────────────────────────────────────────
-- Automatically inserts a profile row when a new user signs up via Supabase Auth.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, full_name)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', 'User')
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();
