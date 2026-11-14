#!/usr/bin/env bash
# ==============================================================================
# Waylo (AuraTour) — Backend Quickstart Script
# ==============================================================================
set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_DIR="$PROJECT_ROOT/backend"

echo "🧭 ====================================================="
echo "    Iniciando Configuración del Backend de Waylo"
echo "====================================================="
echo ""

# 1. Verificar Homebrew y Supabase CLI
if ! command -v supabase &> /dev/null; then
    echo "⚠️  Supabase CLI no encontrado."
    if command -v brew &> /dev/null; then
        echo "📦 Instalando Supabase CLI vía Homebrew..."
        brew install supabase/tap/supabase
    else
        echo "❌ Homebrew no encontrado. Instala Supabase CLI manualmente desde:"
        echo "   https://supabase.com/docs/guides/cli"
        exit 1
    fi
fi

# 2. Verificar Docker
if ! command -v docker &> /dev/null; then
    echo "⚠️  Docker no encontrado en PATH."
    echo "👉 Asegúrate de tener Docker Desktop instalado y corriendo en tu Mac:"
    echo "   https://www.docker.com/products/docker-desktop/"
    echo ""
    echo "💡 Alternativa: Puedes conectar directamente Waylo a un proyecto gratuito de Supabase Cloud"
    echo "   creando un proyecto en https://database.new y pegando SUPABASE_URL en tu archivo .env"
    exit 1
fi

# 3. Arrancar Supabase Local
echo "🚀 Arrancando contenedores locales de Supabase (PostgreSQL, Realtime, Storage)..."
cd "$BACKEND_DIR"
supabase start

# 4. Aplicar Migraciones y Seed Data
echo "📊 Aplicando las 5 migraciones SQL (Users, City Packages, Planning, Groups, Memories) y Seed..."
supabase db reset

# 5. Desplegar Edge Functions
echo "⚡ Desplegando Edge Functions de prueba localmente..."
supabase functions serve --no-verify-jwt &

echo ""
echo "✅ Backend listo y corriendo exitosamente:"
echo "   - API Gateway:    http://127.0.0.1:54321"
echo "   - Supabase Studio: http://127.0.0.1:54323 (Dashboard visual)"
echo "   - Database Port:  54322"
echo ""
