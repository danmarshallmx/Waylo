-- ============================================================
-- 002_city_packages.sql: Modular City Packages, POIs & Audio
-- ============================================================

CREATE TABLE IF NOT EXISTS public.city_packages (
    id TEXT PRIMARY KEY,
    city_name TEXT NOT NULL,
    country_code VARCHAR(3) NOT NULL,
    map_style_url TEXT,
    bounds_ne_lat DOUBLE PRECISION NOT NULL,
    bounds_ne_lng DOUBLE PRECISION NOT NULL,
    bounds_sw_lat DOUBLE PRECISION NOT NULL,
    bounds_sw_lng DOUBLE PRECISION NOT NULL,
    version INT DEFAULT 1,
    size_mb INT DEFAULT 0,
    package_url TEXT,
    checksum_sha256 TEXT,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.pois (
    id TEXT PRIMARY KEY,
    city_id TEXT NOT NULL REFERENCES public.city_packages(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    category TEXT NOT NULL, -- museum, park, restaurant, monument, church, viewpoint, indoor
    rating DOUBLE PRECISION DEFAULT 4.5,
    image_url TEXT,
    audio_url TEXT,
    weight INT DEFAULT 1, -- For weighted centroid calculation (popularity * avg visit)
    localized_names JSONB DEFAULT '{}'::jsonb,
    tags TEXT[] DEFAULT ARRAY[]::TEXT[],
    is_indoor BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_pois_city_id ON public.pois(city_id);
CREATE INDEX IF NOT EXISTS idx_pois_coords ON public.pois(latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_pois_category ON public.pois(category);

CREATE TABLE IF NOT EXISTS public.audio_capsules (
    id TEXT PRIMARY KEY,
    poi_id TEXT NOT NULL REFERENCES public.pois(id) ON DELETE CASCADE,
    language VARCHAR(10) DEFAULT 'es',
    title TEXT NOT NULL,
    duration_seconds INT NOT NULL,
    file_path TEXT NOT NULL,
    file_size_kb INT NOT NULL,
    bitrate_kbps INT DEFAULT 64,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_audio_capsules_poi ON public.audio_capsules(poi_id);

-- RLS
ALTER TABLE public.city_packages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pois ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audio_capsules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read access to city packages"
    ON public.city_packages FOR SELECT TO authenticated, anon USING (true);

CREATE POLICY "Allow public read access to pois"
    ON public.pois FOR SELECT TO authenticated, anon USING (true);

CREATE POLICY "Allow public read access to audio capsules"
    ON public.audio_capsules FOR SELECT TO authenticated, anon USING (true);
