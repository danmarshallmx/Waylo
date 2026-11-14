-- ============================================================
-- 004_groups.sql: Travel Groups, Members & Realtime Itinerary
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
    role TEXT NOT NULL DEFAULT 'member', -- owner, admin, member
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
    scheduled_time TEXT, -- HH:mm format
    duration_minutes INT DEFAULT 60,
    status TEXT NOT NULL DEFAULT 'planned', -- planned, in_progress, completed, skipped
    notes TEXT,
    sort_order INT DEFAULT 0,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_group_members_group ON public.group_members(group_id);
CREATE INDEX IF NOT EXISTS idx_group_members_user ON public.group_members(user_id);
CREATE INDEX IF NOT EXISTS idx_itinerary_group ON public.itinerary_items(group_id);
CREATE INDEX IF NOT EXISTS idx_itinerary_date ON public.itinerary_items(group_id, scheduled_date);

-- Security: Row Level Security
ALTER TABLE public.travel_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.itinerary_items ENABLE ROW LEVEL SECURITY;

-- Helper function to check if user is in group
CREATE OR REPLACE FUNCTION public.is_group_member(check_group_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.group_members
        WHERE group_id = check_group_id AND user_id = auth.uid()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Policies for travel_groups
CREATE POLICY "Members can view their groups"
    ON public.travel_groups FOR SELECT
    TO authenticated
    USING (public.is_group_member(id) OR owner_id = auth.uid());

CREATE POLICY "Authenticated users can create groups"
    ON public.travel_groups FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Owners and admins can update groups"
    ON public.travel_groups FOR UPDATE
    TO authenticated
    USING (owner_id = auth.uid());

-- Policies for group_members
CREATE POLICY "Members can view peers in same group"
    ON public.group_members FOR SELECT
    TO authenticated
    USING (public.is_group_member(group_id));

CREATE POLICY "Users can join group"
    ON public.group_members FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own member state (like location sharing)"
    ON public.group_members FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id);

CREATE POLICY "Members can leave or owner can remove"
    ON public.group_members FOR DELETE
    TO authenticated
    USING (auth.uid() = user_id OR EXISTS (
        SELECT 1 FROM public.travel_groups WHERE id = group_id AND owner_id = auth.uid()
    ));

-- Policies for itinerary_items
CREATE POLICY "Group members can view itinerary"
    ON public.itinerary_items FOR SELECT
    TO authenticated
    USING (public.is_group_member(group_id));

CREATE POLICY "Group members can insert/edit itinerary"
    ON public.itinerary_items FOR ALL
    TO authenticated
    USING (public.is_group_member(group_id))
    WITH CHECK (public.is_group_member(group_id));

-- Realtime Setup: enable realtime on tables
ALTER PUBLICATION supabase_realtime ADD TABLE public.itinerary_items;
ALTER PUBLICATION supabase_realtime ADD TABLE public.group_members;
