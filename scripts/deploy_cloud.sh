#!/usr/bin/env bash
# ==============================================================================
# Waylo — Despliegue en Supabase Cloud (Sin necesidad de Docker Local)
# ==============================================================================
set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "☁️ ====================================================="
echo "    Despliegue de Waylo a Supabase Cloud"
echo "====================================================="
echo ""
echo "Instrucciones de 3 minutos:"
echo ""
echo "1. Ve a https://database.new y crea un proyecto gratuito llamado 'waylo-backend'."
echo "2. En el menú izquierdo ve a 'SQL Editor' -> 'New query'."
echo "3. Copia y ejecuta en orden las 5 migraciones ubicadas en:"
echo "   - $PROJECT_ROOT/backend/supabase/migrations/001_users_profiles.sql"
echo "   - $PROJECT_ROOT/backend/supabase/migrations/002_city_packages.sql"
echo "   - $PROJECT_ROOT/backend/supabase/migrations/003_planning.sql"
echo "   - $PROJECT_ROOT/backend/supabase/migrations/004_groups.sql"
echo "   - $PROJECT_ROOT/backend/supabase/migrations/005_memories.sql"
echo "   - $PROJECT_ROOT/backend/supabase/seed.sql"
echo ""
echo "4. En 'Project Settings' -> 'API', copia:"
echo "   - Project URL (ej. https://xyz.supabase.co)"
echo "   - anon / public key (eyJ...)"
echo ""
echo "5. Pégalos en tu archivo: $PROJECT_ROOT/.env"
echo ""
echo "¡Y listo! Tu app Flutter estará conectada a PostgreSQL en la nube con Realtime y Storage activos."
