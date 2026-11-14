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
    const { photoId, groupId, latitude, longitude, capturedAt, exifData } = await req.json();

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const supabase = createClient(supabaseUrl, supabaseKey);

    let matchedPoiId: string | null = null;

    if (latitude && longitude) {
      // Find nearest POI within 250 meters (0.25 km)
      const { data: pois } = await supabase.from("pois").select("id, name, latitude, longitude");

      if (pois && pois.length > 0) {
        let minDistance = Infinity;
        for (const poi of pois) {
          const d = distanceKm(latitude, longitude, poi.latitude, poi.longitude);
          if (d < minDistance && d <= 0.25) {
            minDistance = d;
            matchedPoiId = poi.id;
          }
        }
      }
    }

    // Update memory photo with matched POI
    const { data: updated, error } = await supabase
      .from("memory_photos")
      .update({
        poi_id: matchedPoiId,
        latitude,
        longitude,
        captured_at: capturedAt || new Date().toISOString(),
        exif_data: exifData || {},
      })
      .eq("id", photoId)
      .select()
      .single();

    if (error) throw error;

    return new Response(
      JSON.stringify({
        success: true,
        photo: updated,
        matchedPoiId,
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
