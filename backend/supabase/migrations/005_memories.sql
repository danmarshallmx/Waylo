-- ============================================================
-- 005_memories.sql: Collaborative Memory Vault & Photos
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

CREATE POLICY "Group members can view memories"
    ON public.memory_photos FOR SELECT
    TO authenticated
    USING (public.is_group_member(group_id));

CREATE POLICY "Group members can upload photos"
    ON public.memory_photos FOR INSERT
    TO authenticated
    WITH CHECK (public.is_group_member(group_id) AND auth.uid() = user_id);

CREATE POLICY "Uploader can edit caption or delete"
    ON public.memory_photos FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id);

CREATE POLICY "Uploader or group owner can delete photo"
    ON public.memory_photos FOR DELETE
    TO authenticated
    USING (auth.uid() = user_id OR EXISTS (
        SELECT 1 FROM public.travel_groups WHERE id = group_id AND owner_id = auth.uid()
    ));

-- Enable Realtime for memories
ALTER PUBLICATION supabase_realtime ADD TABLE public.memory_photos;

-- Storage setup (Bucket: waylo-memories)
INSERT INTO storage.buckets (id, name, public)
VALUES ('waylo-memories', 'waylo-memories', true)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Group members can upload to waylo-memories"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (bucket_id = 'waylo-memories');

CREATE POLICY "Anyone with link can read photos"
    ON storage.objects FOR SELECT
    TO authenticated
    USING (bucket_id = 'waylo-memories');
