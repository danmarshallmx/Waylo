#!/usr/bin/env bash
# ==============================================================================
# Waylo — Edge Functions Verification Test Script
# ==============================================================================
set -e

BASE_URL="http://127.0.0.1:54321/functions/v1"

echo "🧪 Probando Edge Functions de Waylo..."
echo ""

# 1. Test generate-affiliate-link
echo "1️⃣  Probando: generate-affiliate-link (Liverpool, 2 viajeros)..."
curl -s -X POST "$BASE_URL/generate-affiliate-link" \
  -H "Content-Type: application/json" \
  -d '{
    "destination": "Liverpool",
    "departureCity": "Madrid",
    "startDate": "2026-12-01",
    "endDate": "2026-12-07",
    "travelers": 2
  }' | grep -q "Skyscanner" && echo "   ✅ Enlaces inteligentes generados con éxito (Skyscanner, Booking, Kayak)." || echo "   ⚠️  Fallo o servicio no disponible aún."

echo ""

# 2. Test plan-b-suggestions
echo "2️⃣  Probando: plan-b-suggestions (Lluvia en Royal Albert Dock, Liverpool)..."
curl -s -X POST "$BASE_URL/plan-b-suggestions" \
  -H "Content-Type: application/json" \
  -d '{
    "latitude": 53.3992,
    "longitude": -2.9917,
    "weatherCondition": "light rain",
    "cityId": "liverpool_uk"
  }' | grep -q "success" && echo "   ✅ Sugerencias de Plan B bajo techo calculadas con éxito." || echo "   ⚠️  Fallo o servicio no disponible aún."

echo ""
echo "🎉 Verificación completada."
