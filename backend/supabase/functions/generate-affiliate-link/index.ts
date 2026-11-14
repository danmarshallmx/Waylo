import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Content-Type": "application/json",
};

interface AffiliateRequest {
  destination: string;
  departureCity?: string;
  startDate?: string;
  endDate?: string;
  travelers?: number;
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { destination, departureCity, startDate, endDate, travelers = 1 }: AffiliateRequest =
      await req.json();

    const destClean = encodeURIComponent(destination.trim());
    const originClean = departureCity ? encodeURIComponent(departureCity.trim()) : "";
    const sDate = startDate || new Date().toISOString().split("T")[0];
    const eDate =
      endDate || new Date(Date.now() + 7 * 86400000).toISOString().split("T")[0];

    const affiliateIdWaylo = "waylo_partner_pro";

    const links = [
      {
        id: "aff_skyscanner_flights",
        provider: "Skyscanner",
        provider_logo_url: "https://logos-world.net/wp-content/uploads/2021/08/Skyscanner-Logo.png",
        category: "flight",
        destination,
        departure_city: departureCity,
        start_date: sDate,
        end_date: eDate,
        travelers,
        price_estimate: "Vuelos desde €49",
        description: "Compara vuelos directos y con escalas al mejor precio con alertas de tarifa.",
        url: `https://www.skyscanner.com/transport/flights/${originClean}/${destClean}/${sDate.replace(/-/g, "").slice(2)}/${eDate.replace(/-/g, "").slice(2)}/?adultsv2=${travelers}&associateid=${affiliateIdWaylo}&utm_source=waylo&utm_medium=affiliate`,
      },
      {
        id: "aff_booking_hotels",
        provider: "Booking.com",
        provider_logo_url: "https://upload.wikimedia.org/wikipedia/commons/b/be/Booking.com_logo.svg",
        category: "hotel",
        destination,
        start_date: sDate,
        end_date: eDate,
        travelers,
        price_estimate: "Hoteles céntricos desde €65/noche",
        description: "Alojamientos con cancelación gratis y ubicaciones verificadas cerca de las atracciones.",
        url: `https://www.booking.com/searchresults.html?ss=${destClean}&checkin=${sDate}&checkout=${eDate}&group_adults=${travelers}&aid=${affiliateIdWaylo}&utm_source=waylo&utm_medium=app_referral`,
      },
      {
        id: "aff_kayak_packages",
        provider: "Kayak",
        provider_logo_url: "https://logos-world.net/wp-content/uploads/2023/04/Kayak-Logo.png",
        category: "package",
        destination,
        start_date: sDate,
        end_date: eDate,
        travelers,
        price_estimate: "Vuelo + Hotel ahorro hasta 25%",
        description: "Paquetes combinados inteligentes con traslado incluido.",
        url: `https://www.kayak.com/packages/${destClean}?checkin=${sDate}&checkout=${eDate}&adults=${travelers}&affiliate_id=${affiliateIdWaylo}&utm_source=waylo`,
      },
      {
        id: "aff_hostelworld",
        provider: "Hostelworld",
        provider_logo_url: "https://seeklogo.com/images/H/hostelworld-logo-E92607BAF8-seeklogo.com.png",
        category: "hotel",
        destination,
        start_date: sDate,
        end_date: eDate,
        travelers,
        price_estimate: "Hostels y estancias sociales desde €22/noche",
        description: "Ideal para grupos de amigos y viajeros con presupuesto dinámico.",
        url: `https://www.hostelworld.com/s?q=${destClean}&dateFrom=${sDate}&dateTo=${eDate}&number_of_guests=${travelers}&affiliate=${affiliateIdWaylo}`,
      },
    ];

    return new Response(JSON.stringify({ success: true, links }), {
      headers: corsHeaders,
    });
  } catch (error) {
    return new Response(
      JSON.stringify({ success: false, error: (error as Error).message }),
      { status: 400, headers: corsHeaders }
    );
  }
});
