-- ============================================================
-- Waylo (AuraTour) — Master Idempotent Database Schema & Seed
-- Compatible with Supabase Cloud PostgreSQL
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- 1. PROFILES & USERS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    display_name TEXT,
    avatar_url TEXT,
    is_pro BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public profiles are viewable by authenticated users" ON public.profiles;
CREATE POLICY "Public profiles are viewable by authenticated users"
    ON public.profiles FOR SELECT
    TO authenticated
    USING (true);

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile"
    ON public.profiles FOR UPDATE
    TO authenticated
    USING (auth.uid() = id);

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, display_name, avatar_url, is_pro)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
        NEW.raw_user_meta_data->>'avatar_url',
        FALSE
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- 2. MODULAR CITY PACKAGES, POIS & AUDIO CAPSULES
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
    category TEXT NOT NULL,
    rating DOUBLE PRECISION DEFAULT 4.5,
    image_url TEXT,
    audio_url TEXT,
    weight INT DEFAULT 1,
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

ALTER TABLE public.city_packages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pois ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audio_capsules ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public read access to city packages" ON public.city_packages;
CREATE POLICY "Allow public read access to city packages"
    ON public.city_packages FOR SELECT TO authenticated, anon USING (true);

DROP POLICY IF EXISTS "Allow public read access to pois" ON public.pois;
CREATE POLICY "Allow public read access to pois"
    ON public.pois FOR SELECT TO authenticated, anon USING (true);

DROP POLICY IF EXISTS "Allow public read access to audio capsules" ON public.audio_capsules;
CREATE POLICY "Allow public read access to audio capsules"
    ON public.audio_capsules FOR SELECT TO authenticated, anon USING (true);

-- ============================================================
-- 3. PLANNING, SAVED SEARCHES & AFFILIATE CLICKS
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
    provider TEXT NOT NULL,
    category TEXT NOT NULL,
    destination TEXT NOT NULL,
    generated_url TEXT NOT NULL,
    clicked_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_saved_searches_user ON public.saved_searches(user_id);
CREATE INDEX IF NOT EXISTS idx_affiliate_clicks_user ON public.affiliate_clicks(user_id);

ALTER TABLE public.saved_searches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.affiliate_clicks ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage their own saved searches" ON public.saved_searches;
CREATE POLICY "Users can manage their own saved searches"
    ON public.saved_searches FOR ALL
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert affiliate click logs" ON public.affiliate_clicks;
CREATE POLICY "Users can insert affiliate click logs"
    ON public.affiliate_clicks FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- ============================================================
-- 4. TRAVEL GROUPS & REALTIME ITINERARY
-- ============================================================
CREATE TABLE IF NOT EXISTS public.travel_groups (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    invite_code VARCHAR(8) UNIQUE NOT NULL,
    owner_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    destination_city TEXT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    max_members INT DEFAULT 5,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.group_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    group_id UUID NOT NULL REFERENCES public.travel_groups(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    role TEXT NOT NULL DEFAULT 'member',
    location_sharing BOOLEAN DEFAULT FALSE,
    last_lat DOUBLE PRECISION,
    last_lng DOUBLE PRECISION,
    last_location_at TIMESTAMPTZ,
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (group_id, user_id)
);

CREATE TABLE IF NOT EXISTS public.itinerary_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    group_id UUID NOT NULL REFERENCES public.travel_groups(id) ON DELETE CASCADE,
    poi_id TEXT REFERENCES public.pois(id) ON DELETE SET NULL,
    custom_title TEXT,
    added_by UUID NOT NULL REFERENCES public.profiles(id),
    scheduled_date DATE NOT NULL,
    scheduled_time TEXT,
    duration_minutes INT DEFAULT 60,
    status TEXT NOT NULL DEFAULT 'planned',
    notes TEXT,
    sort_order INT DEFAULT 0,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_group_members_group ON public.group_members(group_id);
CREATE INDEX IF NOT EXISTS idx_group_members_user ON public.group_members(user_id);
CREATE INDEX IF NOT EXISTS idx_itinerary_group ON public.itinerary_items(group_id);
CREATE INDEX IF NOT EXISTS idx_itinerary_date ON public.itinerary_items(group_id, scheduled_date);

ALTER TABLE public.travel_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.itinerary_items ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.is_group_member(check_group_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.group_members
        WHERE group_id = check_group_id AND user_id = auth.uid()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP POLICY IF EXISTS "Members can view their groups" ON public.travel_groups;
CREATE POLICY "Members can view their groups"
    ON public.travel_groups FOR SELECT
    TO authenticated
    USING (public.is_group_member(id) OR owner_id = auth.uid());

DROP POLICY IF EXISTS "Authenticated users can create groups" ON public.travel_groups;
CREATE POLICY "Authenticated users can create groups"
    ON public.travel_groups FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = owner_id);

DROP POLICY IF EXISTS "Owners and admins can update groups" ON public.travel_groups;
CREATE POLICY "Owners and admins can update groups"
    ON public.travel_groups FOR UPDATE
    TO authenticated
    USING (owner_id = auth.uid());

DROP POLICY IF EXISTS "Members can view peers in same group" ON public.group_members;
CREATE POLICY "Members can view peers in same group"
    ON public.group_members FOR SELECT
    TO authenticated
    USING (public.is_group_member(group_id));

DROP POLICY IF EXISTS "Users can join group" ON public.group_members;
CREATE POLICY "Users can join group"
    ON public.group_members FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own member state" ON public.group_members;
CREATE POLICY "Users can update their own member state"
    ON public.group_members FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Members can leave or owner can remove" ON public.group_members;
CREATE POLICY "Members can leave or owner can remove"
    ON public.group_members FOR DELETE
    TO authenticated
    USING (auth.uid() = user_id OR EXISTS (
        SELECT 1 FROM public.travel_groups WHERE id = group_id AND owner_id = auth.uid()
    ));

DROP POLICY IF EXISTS "Group members can view itinerary" ON public.itinerary_items;
CREATE POLICY "Group members can view itinerary"
    ON public.itinerary_items FOR SELECT
    TO authenticated
    USING (public.is_group_member(group_id));

DROP POLICY IF EXISTS "Group members can insert/edit itinerary" ON public.itinerary_items;
CREATE POLICY "Group members can insert/edit itinerary"
    ON public.itinerary_items FOR ALL
    TO authenticated
    USING (public.is_group_member(group_id))
    WITH CHECK (public.is_group_member(group_id));

-- Realtime publication
DO $$
BEGIN
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.itinerary_items;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.group_members;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
END $$;

-- ============================================================
-- 5. MEMORIES VAULT & STORAGE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.memory_photos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    group_id UUID NOT NULL REFERENCES public.travel_groups(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    poi_id TEXT REFERENCES public.pois(id) ON DELETE SET NULL,
    storage_url TEXT NOT NULL,
    thumbnail_url TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    captured_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    uploaded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    caption TEXT,
    exif_data JSONB DEFAULT '{}'::jsonb
);

CREATE INDEX IF NOT EXISTS idx_memories_group ON public.memory_photos(group_id);
CREATE INDEX IF NOT EXISTS idx_memories_poi ON public.memory_photos(poi_id);
CREATE INDEX IF NOT EXISTS idx_memories_timeline ON public.memory_photos(group_id, captured_at DESC);
CREATE INDEX IF NOT EXISTS idx_memories_coords ON public.memory_photos(latitude, longitude);

ALTER TABLE public.memory_photos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Group members can view memories" ON public.memory_photos;
CREATE POLICY "Group members can view memories"
    ON public.memory_photos FOR SELECT
    TO authenticated
    USING (public.is_group_member(group_id));

DROP POLICY IF EXISTS "Group members can upload photos" ON public.memory_photos;
CREATE POLICY "Group members can upload photos"
    ON public.memory_photos FOR INSERT
    TO authenticated
    WITH CHECK (public.is_group_member(group_id) AND auth.uid() = user_id);

DROP POLICY IF EXISTS "Uploader can edit caption or delete" ON public.memory_photos;
CREATE POLICY "Uploader can edit caption or delete"
    ON public.memory_photos FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Uploader or group owner can delete photo" ON public.memory_photos;
CREATE POLICY "Uploader or group owner can delete photo"
    ON public.memory_photos FOR DELETE
    TO authenticated
    USING (auth.uid() = user_id OR EXISTS (
        SELECT 1 FROM public.travel_groups WHERE id = group_id AND owner_id = auth.uid()
    ));

DO $$
BEGIN
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.memory_photos;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
END $$;

-- Storage setup (Bucket: waylo-memories)
INSERT INTO storage.buckets (id, name, public)
VALUES ('waylo-memories', 'waylo-memories', true)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "Group members can upload to waylo-memories" ON storage.objects;
CREATE POLICY "Group members can upload to waylo-memories"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (bucket_id = 'waylo-memories');

DROP POLICY IF EXISTS "Anyone with link can read photos" ON storage.objects;
CREATE POLICY "Anyone with link can read photos"
    ON storage.objects FOR SELECT
    TO authenticated
    USING (bucket_id = 'waylo-memories');

-- ============================================================
-- 6. SEED DATA (GUADALAJARA, LIVERPOOL, BARCELONA)
-- ============================================================
INSERT INTO public.city_packages (id, city_name, country_code, map_style_url, bounds_ne_lat, bounds_ne_lng, bounds_sw_lat, bounds_sw_lng, version, size_mb, package_url, checksum_sha256)
VALUES 
(
    'guadalajara_mx',
    'Guadalajara',
    'MEX',
    'mapbox://styles/mapbox/outdoors-v12',
    20.7500, -103.2500,
    20.6000, -103.4500,
    1,
    58,
    'https://assets.waylo.app/packs/guadalajara_v1.zip',
    'f3c988b488bc8a98b4c77c68b8e0c8b9194bb89e81b6c59b66a5b28d6c7b9194'
),
(
    'liverpool_uk',
    'Liverpool',
    'GBR',
    'mapbox://styles/mapbox/outdoors-v12',
    53.4350, -2.9300,
    53.3800, -3.0150,
    1,
    42,
    'https://assets.waylo.app/packs/liverpool_v1.zip',
    'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'
),
(
    'barcelona_es',
    'Barcelona',
    'ESP',
    'mapbox://styles/mapbox/outdoors-v12',
    41.4400, 2.2300,
    41.3500, 2.1100,
    1,
    65,
    'https://assets.waylo.app/packs/barcelona_v1.zip',
    'ca978112ca1bbdcafac231b39a23dc4da786eff8147c4e72b9807785afee48bb'
)
ON CONFLICT (id) DO NOTHING;

-- POIs
INSERT INTO public.pois (id, city_id, name, description, latitude, longitude, category, rating, image_url, audio_url, weight, is_indoor, tags)
VALUES
(
    'poi_gdl_catedral',
    'guadalajara_mx',
    'Catedral Basílica de Guadalajara',
    'Emblemática catedral con sus icónicas torres neo-góticas de color amarillo, criptas coloniales y el corazón histórico de la Perla Tapatía.',
    20.6770, -103.3469,
    'church',
    4.9,
    'https://images.unsplash.com/photo-1512813195386-6cf811ad3542?auto=format&fit=crop&w=800&q=80',
    'https://assets.waylo.app/audio/gdl_catedral_es.mp3',
    5,
    true,
    ARRAY['historic', 'architecture', 'iconic', 'indoor']
),
(
    'poi_gdl_cabanas',
    'guadalajara_mx',
    'Hospicio Cabañas (Museo Cabañas)',
    'Patrimonio de la Humanidad por la UNESCO con los monumentales murales de José Clemente Orozco, destacando "El Hombre de Fuego".',
    20.6773, -103.3376,
    'museum',
    5.0,
    'https://images.unsplash.com/photo-1584646098378-0874589d76b1?auto=format&fit=crop&w=800&q=80',
    'https://assets.waylo.app/audio/gdl_cabanas_es.mp3',
    5,
    true,
    ARRAY['unesco', 'art', 'orozco', 'museum', 'indoor']
),
(
    'poi_gdl_degollado',
    'guadalajara_mx',
    'Teatro Degollado',
    'Joya neoclásica sede de la Orquesta Filarmónica de Jalisco, famosa por el fresco de la Divina Comedia y el águila en el arco.',
    20.6769, -103.3444,
    'monument',
    4.8,
    'https://images.unsplash.com/photo-1568605117036-5fe5e7bab0b7?auto=format&fit=crop&w=800&q=80',
    'https://assets.waylo.app/audio/gdl_degollado_es.mp3',
    4,
    true,
    ARRAY['theatre', 'architecture', 'music', 'historic', 'indoor']
),
(
    'poi_gdl_expiatorio',
    'guadalajara_mx',
    'Templo Expiatorio del Santísimo Sacramento',
    'Máxima obra del estilo neogótico en México, construido en cantera tallada con vitrales franceses y reloj carillón.',
    20.6728, -103.3592,
    'church',
    4.9,
    'https://images.unsplash.com/photo-1548625361-195fe57871b6?auto=format&fit=crop&w=800&q=80',
    'https://assets.waylo.app/audio/gdl_expiatorio_es.mp3',
    4,
    true,
    ARRAY['gothic', 'architecture', 'plaza', 'indoor']
),
(
    'poi_gdl_minerva',
    'guadalajara_mx',
    'Glorieta La Minerva',
    'Monumento emblemático de la diosa romana protectora de la ciudad en Av. Vallarta.',
    20.6744, -103.3874,
    'monument',
    4.7,
    'https://images.unsplash.com/photo-1509316975850-ff9c5deb0cd9?auto=format&fit=crop&w=800&q=80',
    'https://assets.waylo.app/audio/gdl_minerva_es.mp3',
    4,
    false,
    ARRAY['landmark', 'monument', 'outdoor']
),
(
    'poi_gdl_san_juan',
    'guadalajara_mx',
    'Mercado San Juan de Dios (Mercado Libertad)',
    'El mercado techado más grande de América Latina, epicentro de tortas ahogadas, birria y artesanías.',
    20.6750, -103.3400,
    'market',
    4.7,
    'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=800&q=80',
    'https://assets.waylo.app/audio/gdl_san_juan_es.mp3',
    4,
    true,
    ARRAY['food', 'market', 'tradition', 'indoor']
),
(
    'poi_gdl_tlaquepaque',
    'guadalajara_mx',
    'Pueblo Mágico de Tlaquepaque (El Parián)',
    'Corazón del mariachi y artesanías en barro y vidrio soplado, serenatas en El Parián.',
    20.6400, -103.3150,
    'monument',
    4.9,
    'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?auto=format&fit=crop&w=800&q=80',
    'https://assets.waylo.app/audio/gdl_tlaquepaque_es.mp3',
    4,
    false,
    ARRAY['mariachi', 'artisan', 'tradition', 'tequila', 'outdoor']
),
(
    'poi_liv_albert_dock',
    'liverpool_uk',
    'Royal Albert Dock',
    'Histórico complejo de muelles y almacenes inaugurado en 1846 frente al río Mersey.',
    53.3992, -2.9917,
    'monument',
    4.8,
    'https://images.unsplash.com/photo-1579273166657-6e696348325a?auto=format&fit=crop&w=800&q=80',
    'https://assets.waylo.app/audio/liv_albert_dock_es.mp3',
    5,
    false,
    ARRAY['history', 'unesco', 'waterfront', 'dining']
),
(
    'poi_liv_beatles_story',
    'liverpool_uk',
    'The Beatles Story',
    'La exposición permanente más grande del mundo dedicada exclusivamente a The Beatles.',
    53.3990, -2.9919,
    'museum',
    4.9,
    'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?auto=format&fit=crop&w=800&q=80',
    'https://assets.waylo.app/audio/liv_beatles_story_es.mp3',
    5,
    true,
    ARRAY['music', 'beatles', 'indoor', 'culture']
),
(
    'poi_liv_cavern_club',
    'liverpool_uk',
    'The Cavern Club',
    'El legendario club subterráneo en Mathew Street donde The Beatles tocaron casi 300 veces.',
    53.4063, -2.9878,
    'monument',
    4.7,
    'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?auto=format&fit=crop&w=800&q=80',
    'https://assets.waylo.app/audio/liv_cavern_club_es.mp3',
    4,
    true,
    ARRAY['music', 'nightlife', 'historic', 'indoor']
)
ON CONFLICT (id) DO NOTHING;

-- Audio Capsules
INSERT INTO public.audio_capsules (id, poi_id, language, title, duration_seconds, file_path, file_size_kb, bitrate_kbps)
VALUES
(
    'aud_gdl_cabanas_01',
    'poi_gdl_cabanas',
    'es',
    'El Hombre de Fuego y los Murales de Orozco',
    115,
    'audio/guadalajara/cabanas_es.mp3',
    920,
    64
),
(
    'aud_gdl_catedral_01',
    'poi_gdl_catedral',
    'es',
    'Las Torres Doradas y los Secretos del Centro',
    90,
    'audio/guadalajara/catedral_es.mp3',
    720,
    64
),
(
    'aud_liv_dock_01',
    'poi_liv_albert_dock',
    'es',
    'El Corazón del Imperio Marítimo de Liverpool',
    95,
    'audio/liverpool/albert_dock_es.mp3',
    760,
    64
),
(
    'aud_liv_beatles_01',
    'poi_liv_beatles_story',
    'es',
    'De The Quarrymen a la Beatlemanía Mundial',
    110,
    'audio/liverpool/beatles_story_es.mp3',
    880,
    64
)
ON CONFLICT (id) DO NOTHING;
