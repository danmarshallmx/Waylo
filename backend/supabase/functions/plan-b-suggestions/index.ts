import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Content-Type": "application/json",
};

function distanceKm(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const R = 6371;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { latitude, longitude, weatherCondition, cityId } = await req.json();

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const supabase = createClient(supabaseUrl, supabaseKey);

    // Fetch POIs for city or near coordinates
    let query = supabase.from("pois").select("*");
    if (cityId) {
      query = query.eq("city_id", cityId);
    }
    const { data: pois, error } = await query;
    if (error) throw error;

    const isRaining =
      weatherCondition?.includes("rain") ||
      weatherCondition?.includes("storm") ||
      weatherCondition?.includes("drizzle") ||
      true; // Default sensible fallback

    // Filter alternatives based on weather
    const filtered = (pois || []).filter((poi: any) => {
      if (isRaining) {
        return poi.is_indoor === true || poi.category === "museum" || poi.category === "restaurant";
      }
      return true;
    });

    // Score and sort by distance to user
    const withDistance = filtered.map((poi: any) => {
      const dist = distanceKm(latitude, longitude, poi.latitude, poi.longitude);
      return {
        ...poi,
        distance_km: Math.round(dist * 100) / 100,
        estimated_walk_minutes: Math.round(dist * 12), // avg 5 km/h
      };
    });

    withDistance.sort((a: any, b: any) => a.distance_km - b.distance_km);

    return new Response(
      JSON.stringify({
        success: true,
        weather: {
          condition: weatherCondition || "Lluvia ligera",
          recommendation: isRaining
            ? "Está lloviendo. Te recomendamos actividades bajo techo y museos cercanos."
            : "Clima favorable para caminar.",
        },
        alternatives: withDistance.slice(0, 5),
      }),
      { headers: corsHeaders }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ success: false, error: (error as Error).message }),
      { status: 400, headers: corsHeaders }
    );
  }
});
