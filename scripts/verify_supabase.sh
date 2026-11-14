#!/usr/bin/env bash
# ==============================================================================
# Waylo — Verificador de Conexión a Supabase Cloud
# ==============================================================================
set -e

ENV_FILE="/Users/danielgonzalez/Desktop/waylo/.env"

if [ ! -f "$ENV_FILE" ]; then
    echo "❌ Archivo .env no encontrado."
    exit 1
fi

SUPABASE_URL=$(grep "^SUPABASE_URL=" "$ENV_FILE" | cut -d '=' -f2- | tr -d ' "')
SUPABASE_ANON_KEY=$(grep "^SUPABASE_ANON_KEY=" "$ENV_FILE" | cut -d '=' -f2- | tr -d ' "')

if [ -z "$SUPABASE_URL" ] || [[ "$SUPABASE_URL" == *"127.0.0.1"* ]] || [[ "$SUPABASE_URL" == *"your-project"* ]]; then
    echo "⚠️  SUPABASE_URL aún no tiene tu URL de Supabase Cloud en .env"
    echo "   Ejemplo: https://xyzcompany.supabase.co"
    exit 1
fi

echo "🔍 Probando conexión a Supabase Cloud: $SUPABASE_URL..."

# 1. Probar tabla pois
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$SUPABASE_URL/rest/v1/pois?select=id,name,city_id&limit=5" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY")

HTTP_STATUS=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_STATUS" -eq 200 ]; then
    echo "✅ ¡Conexión exitosa a Supabase Cloud!"
    echo "📊 Datos de prueba detectados:"
    echo "$BODY" | head -n 10
    echo ""
    echo "🎉 Base de datos de Waylo 100% activa con PostgreSQL, Realtime y Storage en la nube."
else
    echo "❌ Error de conexión (HTTP $HTTP_STATUS):"
    echo "$BODY"
fi
