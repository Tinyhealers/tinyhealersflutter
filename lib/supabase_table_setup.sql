-- SQL script to create required tables in Supabase
-- Run this in your Supabase SQL editor

-- 1. Create salary_payments table
CREATE TABLE IF NOT EXISTS public.salary_payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  doctor_id UUID NOT NULL REFERENCES public.doctors(id),
  total_consultations INTEGER NOT NULL,
  amount NUMERIC(10,2) NOT NULL,
  payment_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Create appointments table
CREATE TABLE IF NOT EXISTS public.appointments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  doctor_id UUID NOT NULL REFERENCES public.doctors(id),
  patient_id UUID NOT NULL REFERENCES public.patients(id),
  appointment_time TIMESTAMPTZ NOT NULL,
  is_follow_up BOOLEAN NOT NULL DEFAULT false,
  status TEXT NOT NULL DEFAULT 'scheduled',
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. Create doctor_status_logs table
CREATE TABLE IF NOT EXISTS public.doctor_status_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  doctor_id UUID NOT NULL REFERENCES public.doctors(id),
  is_online BOOLEAN NOT NULL,
  timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable Row Level Security (optional)
ALTER TABLE public.salary_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.doctor_status_logs ENABLE ROW LEVEL SECURITY;

-- 4. Ensure override columns exist on doctors table for admin adjustments
ALTER TABLE public.doctors
  ADD COLUMN IF NOT EXISTS appointment_count INTEGER,
  ADD COLUMN IF NOT EXISTS follow_up_count INTEGER;
