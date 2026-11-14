# 🧭 Waylo (AuraTour) — Arquitectura de Software & Guía de Implementación

## 1. Visión del Sistema
**Waylo** es una aplicación móvil y backend integral orientada a eliminar la fricción del turismo moderno mediante automatización, geocercas nativas de bajo consumo, coordinación social en tiempo real y preservación fotográfica georreferenciada.

---

## 2. Los 5 Módulos Fundamentales

### Módulo 1: Stack & Arquitectura Modular por Ciudades
- **Estrategia Offline-First:** Los paquetes de ciudad agrupan mapas vectoriales (`.mbtiles` Mapbox), POIs relacionales indexados localmente y cápsulas de audio (`.mp3` comprimidas a 64 kbps).
- **Almacenamiento Local:** Hive para metadata rápida y versionado; SQLite para consultas espaciales en dispositivo.
- **Rutas de Archivos Clave:**
  - `mobile/lib/features/city_packages/repositories/city_packages_repository.dart`
  - `mobile/lib/features/city_packages/bloc/city_packages_bloc.dart`
  - `mobile/lib/features/city_packages/screens/city_packages_screen.dart`
  - `backend/supabase/migrations/002_city_packages.sql`

### Módulo 2: Planeación Inteligente (Vuelos y Hospedaje con Afiliados)
- **Deep Linking Inteligente:** Construcción reactiva de URLs con parámetros de seguimiento UTM y códigos de afiliado (Skyscanner, Booking.com, Kayak, Hostelworld) según destino, fechas y número de viajeros.
- **Centroide Ponderado de Hospedaje:** Algoritmo que calcula el baricentro geográfico óptimo ponderado por popularidad y tiempo promedio de visita de las atracciones:
  $$C = \frac{\sum w_i \cdot P_i}{\sum w_i}$$
  Recomienda una zona de alojamiento estratégica que minimiza tiempos y costos de desplazamiento a pie.
- **Rutas de Archivos Clave:**
  - `mobile/lib/core/utils/geo_utils.dart`
  - `mobile/lib/features/planning/repositories/planning_repository.dart`
  - `mobile/lib/features/planning/widgets/hotel_zone_map.dart`
  - `backend/supabase/functions/generate-affiliate-link/index.ts`

### Módulo 3: Núcleo de Geolocalización y Geofencing (En Destino)
- **Geocercas de Bajo Consumo:** Radio nativo de proximidad (40 metros) monitoreado mediante filtros de distancia (`distanceFilter: 15m`). Al entrar en la geocerca:
  1. Envío de notificación push local vía `flutter_local_notifications`.
  2. Carga y reproducción automática de la cápsula de audio didáctica mediante `just_audio`.
- **Botón "Plan B Instantáneo":** Evalúa el clima en tiempo real (OpenWeather API) y la ubicación para sugerir alternativas inmediatas bajo techo (museos, cafés culturales) si llueve o refrescantes si hace calor.
- **Rutas de Archivos Clave:**
  - `mobile/lib/features/geolocation/services/geofence_service.dart`
  - `mobile/lib/features/geolocation/services/audio_player_service.dart`
  - `mobile/lib/features/geolocation/screens/geolocation_screen.dart`
  - `mobile/lib/features/geolocation/screens/plan_b_screen.dart`
  - `backend/supabase/functions/plan-b-suggestions/index.ts`

### Módulo 4: Grupos de Viaje en Tiempo Real
- **Topología Social:** Grupos de hasta 5 miembros asociados a cuentas Pro con código único de invitación (alfanumérico de 6 caracteres).
- **Sincronización WebSockets (Supabase Realtime):**
  - Canal de itinerario maestro: inserciones, cambios de estado (`planned` → `in_progress` → `completed`) propagados a todos los miembros instantáneamente.
  - Minimapa/Radar grupal: transmisión throttled de coordenadas con opción de privacidad individual (`location_sharing`).
- **Rutas de Archivos Clave:**
  - `backend/supabase/migrations/004_groups.sql`
  - `mobile/lib/features/groups/repositories/groups_repository.dart`
  - `mobile/lib/features/groups/widgets/group_radar_map.dart`
  - `mobile/lib/features/groups/screens/group_detail_screen.dart`

### Módulo 5: Bóveda de Recuerdos Colaborativa
- **Pipeline de Fotos:** Subida en segundo plano con extracción client-side de metadatos EXIF (coordenadas GPS y timestamp UTC).
- **Matching Automático con POIs:** Asociación automática de fotos al monumento o atracción más cercana visitada (<200m).
- **Timeline Unificado:** Visualización cronológica agrupada por día y por atracción turística que unifica las tomas de todos los viajeros del grupo.
- **Rutas de Archivos Clave:**
  - `mobile/lib/features/memories/repositories/memories_repository.dart`
  - `mobile/lib/features/memories/screens/memories_screen.dart`
  - `mobile/lib/features/memories/screens/photo_detail_screen.dart`
  - `backend/supabase/functions/process-photo-exif/index.ts`

---

## 3. Puesta en Marcha (Desarrollo Local)

### Backend (Supabase):
```bash
cd backend
supabase start
supabase db reset # Aplica migraciones 001-005 y seed.sql
supabase functions serve
```

### Mobile (Flutter):
```bash
cd mobile
flutter pub get
flutter run
```
