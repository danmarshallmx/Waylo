-- ============================================================
-- 003_planning.sql: Planning, Saved Searches & Affiliate Tracking
-- ============================================================

CREATE TABLE IF NOT EXISTS public.saved_searches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    destination TEXT NOT NULL,
    departure_city TEXT,
    start_date DATE,
    end_date DATE,
    travelers INT DEFAULT 1,
    recommended_zone_lat DOUBLE PRECISION,
    recommended_zone_lng DOUBLE PRECISION,
    recommended_radius_km DOUBLE PRECISION,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.affiliate_clicks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    provider TEXT NOT NULL, -- skyscanner, booking, kayak, hostelworld
    category TEXT NOT NULL, -- flight, hotel, package
    destination TEXT NOT NULL,
    generated_url TEXT NOT NULL,
    clicked_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_saved_searches_user ON public.saved_searches(user_id);
CREATE INDEX IF NOT EXISTS idx_affiliate_clicks_user ON public.affiliate_clicks(user_id);

ALTER TABLE public.saved_searches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.affiliate_clicks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own saved searches"
    ON public.saved_searches FOR ALL
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can insert affiliate click logs"
    ON public.affiliate_clicks FOR INSERT
    TO authenticated
    WITH CHECK (true);
