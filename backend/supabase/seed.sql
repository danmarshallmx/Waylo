-- ============================================================
-- seed.sql: Demo Seed Data (Liverpool & Barcelona)
-- ============================================================

-- 1. City Packages
INSERT INTO public.city_packages (id, city_name, country_code, map_style_url, bounds_ne_lat, bounds_ne_lng, bounds_sw_lat, bounds_sw_lng, version, size_mb, package_url, checksum_sha256)
VALUES 
(
    'liverpool_uk',
    'Liverpool',
    'GBR',
    'mapbox://styles/mapbox/outdoors-v12',
    53.4350, -2.9300,
    53.3800, -3.0150,
    1,
    42,
    'https://assets.waylo.app/packs/liverpool_v1.zip',
    'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'
),
(
    'barcelona_es',
    'Barcelona',
    'ESP',
    'mapbox://styles/mapbox/outdoors-v12',
    41.4400, 2.2300,
    41.3500, 2.1100,
    1,
    65,
    'https://assets.waylo.app/packs/barcelona_v1.zip',
    'ca978112ca1bbdcafac231b39a23dc4da786eff8147c4e72b9807785afee48bb'
)
ON CONFLICT (id) DO NOTHING;

-- 2. POIs for Liverpool
INSERT INTO public.pois (id, city_id, name, description, latitude, longitude, category, rating, image_url, audio_url, weight, is_indoor, tags)
VALUES
(
    'poi_liv_albert_dock',
    'liverpool_uk',
    'Royal Albert Dock',
    'Histórico complejo de muelles y almacenes inaugurado en 1846, repleto de museos, bares y restaurantes frente al río Mersey.',
    53.3992, -2.9917,
    'monument',
    4.8,
    'https://images.unsplash.com/photo-1579273166657-6e696348325a?auto=format&fit=crop&w=800&q=80',
    'https://assets.waylo.app/audio/liv_albert_dock_es.mp3',
    5,
    false,
    ARRAY['history', 'unesco', 'waterfront', 'dining']
),
(
    'poi_liv_beatles_story',
    'liverpool_uk',
    'The Beatles Story',
    'La exposición permanente más grande del mundo dedicada exclusivamente a las vidas y la época de The Beatles.',
    53.3990, -2.9919,
    'museum',
    4.9,
    'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?auto=format&fit=crop&w=800&q=80',
    'https://assets.waylo.app/audio/liv_beatles_story_es.mp3',
    5,
    true,
    ARRAY['music', 'beatles', 'indoor', 'culture']
),
(
    'poi_liv_cavern_club',
    'liverpool_uk',
    'The Cavern Club',
    'El legendario club subterráneo en Mathew Street donde The Beatles tocaron en sus primeros años.',
    53.4063, -2.9878,
    'monument',
    4.7,
    'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?auto=format&fit=crop&w=800&q=80',
    'https://assets.waylo.app/audio/liv_cavern_club_es.mp3',
    4,
    true,
    ARRAY['music', 'nightlife', 'historic', 'indoor']
),
(
    'poi_liv_cathedral',
    'liverpool_uk',
    'Liverpool Anglican Cathedral',
    'La catedral más grande de Gran Bretaña y la quinta más grande del mundo, con imponentes vistas desde la torre.',
    53.3975, -2.9733,
    'church',
    4.8,
    'https://images.unsplash.com/photo-1548625361-195fe57871b6?auto=format&fit=crop&w=800&q=80',
    'https://assets.waylo.app/audio/liv_cathedral_es.mp3',
    3,
    true,
    ARRAY['architecture', 'viewpoint', 'gothic', 'indoor']
),
(
    'poi_liv_world_museum',
    'liverpool_uk',
    'World Museum & Walker Art Gallery',
    'Museo que abarca arqueología, etnología y ciencias naturales con acuario y planetario.',
    53.4098, -2.9818,
    'museum',
    4.6,
    'https://images.unsplash.com/photo-1566127444979-b3d2b654e3d7?auto=format&fit=crop&w=800&q=80',
    'https://assets.waylo.app/audio/liv_world_museum_es.mp3',
    4,
    true,
    ARRAY['art', 'museum', 'family', 'indoor']
),
(
    'poi_liv_liver_building',
    'liverpool_uk',
    'Royal Liver Building (Three Graces)',
    'Edificio emblemático catalogado de Grado I en Pier Head coronado por las dos míticas aves Liver Bird.',
    53.4058, -2.9959,
    'monument',
    4.7,
    'https://images.unsplash.com/photo-1509316975850-ff9c5deb0cd9?auto=format&fit=crop&w=800&q=80',
    'https://assets.waylo.app/audio/liv_liver_building_es.mp3',
    4,
    false,
    ARRAY['landmark', 'architecture', 'waterfront']
),
(
    'poi_liv_sefton_park',
    'liverpool_uk',
    'Sefton Park & Palm House',
    'Parque victoriano de 235 acres con un impresionante invernadero de cristal catalogado de Grado II.',
    53.3833, -2.9360,
    'park',
    4.8,
    'https://images.unsplash.com/photo-1519331379826-f10be5486c6f?auto=format&fit=crop&w=800&q=80',
    'https://assets.waylo.app/audio/liv_sefton_park_es.mp3',
    2,
    false,
    ARRAY['nature', 'park', 'outdoor', 'botanical']
)
ON CONFLICT (id) DO NOTHING;

-- 3. Audio Capsules for Liverpool
INSERT INTO public.audio_capsules (id, poi_id, language, title, duration_seconds, file_path, file_size_kb, bitrate_kbps)
VALUES
(
    'aud_liv_dock_01',
    'poi_liv_albert_dock',
    'es',
    'El Corazón del Imperio Marítimo de Liverpool',
    95,
    'audio/liverpool/albert_dock_es.mp3',
    760,
    64
),
(
    'aud_liv_beatles_01',
    'poi_liv_beatles_story',
    'es',
    'De The Quarrymen a la Beatlemanía Mundial',
    110,
    'audio/liverpool/beatles_story_es.mp3',
    880,
    64
),
(
    'aud_liv_cavern_01',
    'poi_liv_cavern_club',
    'es',
    'El Sótano más famoso de la Historia del Rock',
    85,
    'audio/liverpool/cavern_club_es.mp3',
    680,
    64
),
(
    'aud_liv_liver_01',
    'poi_liv_liver_building',
    'es',
    'El Vuelo Guardián de las Dos Liver Birds',
    75,
    'audio/liverpool/liver_building_es.mp3',
    600,
    64
)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- Guadalajara, Jalisco, México City Package & POIs
-- ============================================================

INSERT INTO public.city_packages (id, city_name, country_code, map_style_url, bounds_ne_lat, bounds_ne_lng, bounds_sw_lat, bounds_sw_lng, version, size_mb, package_url, checksum_sha256)
VALUES 
(
    'guadalajara_mx',
    'Guadalajara',
    'MEX',
    'mapbox://styles/mapbox/outdoors-v12',
    20.7500, -103.2500,
    20.6000, -103.4500,
    1,
    58,
    'https://assets.waylo.app/packs/guadalajara_v1.zip',
    'f3c988b488bc8a98b4c77c68b8e0c8b9194bb89e81b6c59b66a5b28d6c7b9194'
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.pois (id, city_id, name, description, latitude, longitude, category, rating, image_url, audio_url, weight, is_indoor, tags)
VALUES
(
    'poi_gdl_catedral',
    'guadalajara_mx',
    'Catedral Basílica de Guadalajara',
    'Emblemática catedral con sus icónicas torres neo-góticas de color amarillo, criptas coloniales y el corazón histórico de la Perla Tapatía.',
    20.6770, -103.3469,
    'church',
    4.9,
    'https://images.unsplash.com/photo-1512813195386-6cf811ad3542?auto=format&fit=crop&w=800&q=80',
    'https://assets.waylo.app/audio/gdl_catedral_es.mp3',
    5,
    true,
    ARRAY['historic', 'architecture', 'iconic', 'indoor']
),
(
    'poi_gdl_cabanas',
    'guadalajara_mx',
    'Hospicio Cabañas (Museo Cabañas)',
    'Patrimonio de la Humanidad por la UNESCO con los monumentales murales de José Clemente Orozco, destacando "El Hombre de Fuego" en la cúpula.',
    20.6773, -103.3376,
    'museum',
    5.0,
    'https://images.unsplash.com/photo-1584646098378-0874589d76b1?auto=format&fit=crop&w=800&q=80',
    'https://assets.waylo.app/audio/gdl_cabanas_es.mp3',
    5,
    true,
    ARRAY['unesco', 'art', 'orozco', 'museum', 'indoor']
),
(
    'poi_gdl_degollado',
    'guadalajara_mx',
    'Teatro Degollado',
    'Joya neoclásica sede de la Orquesta Filarmónica de Jalisco, famosa por el fresco de la Divina Comedia y la leyenda del águila en el arco.',
    20.6769, -103.3444,
    'monument',
    4.8,
    'https://images.unsplash.com/photo-1568605117036-5fe5e7bab0b7?auto=format&fit=crop&w=800&q=80',
    'https://assets.waylo.app/audio/gdl_degollado_es.mp3',
    4,
    true,
    ARRAY['theatre', 'architecture', 'music', 'historic', 'indoor']
),
(
    'poi_gdl_expiatorio',
    'guadalajara_mx',
    'Templo Expiatorio del Santísimo Sacramento',
    'Máxima obra del estilo neogótico en México, construido en cantera tallada con vitrales franceses y reloj carillón con figuras de los apóstoles.',
    20.6728, -103.3592,
    'church',
    4.9,
    'https://images.unsplash.com/photo-1548625361-195fe57871b6?auto=format&fit=crop&w=800&q=80',
    'https://assets.waylo.app/audio/gdl_expiatorio_es.mp3',
    4,
    true,
    ARRAY['gothic', 'architecture', 'plaza', 'indoor']
),
(
    'poi_gdl_minerva',
    'guadalajara_mx',
    'Glorieta La Minerva',
    'Monumento emblemático de la diosa romana de la sabiduría y protectora de la ciudad, en el cruce de las avenidas Vallarta, López Mateos y Golfo de Cortés.',
    20.6744, -103.3874,
    'monument',
    4.7,
    'https://images.unsplash.com/photo-1509316975850-ff9c5deb0cd9?auto=format&fit=crop&w=800&q=80',
    'https://assets.waylo.app/audio/gdl_minerva_es.mp3',
    4,
    false,
    ARRAY['landmark', 'monument', 'outdoor']
),
(
    'poi_gdl_san_juan',
    'guadalajara_mx',
    'Mercado San Juan de Dios (Mercado Libertad)',
    'El mercado techado más grande de América Latina, diseñado por Alejandro Zohn, epicentro de la gastronomía tapatía (birria, tortas ahogadas y artesanías).',
    20.6750, -103.3400,
    'market',
    4.7,
    'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=800&q=80',
    'https://assets.waylo.app/audio/gdl_san_juan_es.mp3',
    4,
    true,
    ARRAY['food', 'market', 'tradition', 'indoor']
),
(
    'poi_gdl_colomos',
    'guadalajara_mx',
    'Bosque Los Colomos & Jardín Japonés',
    'Parque ecológico urbano con senderos boscosos, lagos y un tradicional jardín japonés donado por la ciudad hermana de Kioto.',
    20.7067, -103.3917,
    'park',
    4.8,
    'https://images.unsplash.com/photo-1519331379826-f10be5486c6f?auto=format&fit=crop&w=800&q=80',
    'https://assets.waylo.app/audio/gdl_colomos_es.mp3',
    3,
    false,
    ARRAY['nature', 'park', 'japanese_garden', 'outdoor']
),
(
    'poi_gdl_tlaquepaque',
    'guadalajara_mx',
    'Pueblo Mágico de Tlaquepaque (El Parián)',
    'Corazón del mariachi y artesanías en barro y vidrio soplado, con restaurantes tradicionales y serenatas bajo los portales de El Parián.',
    20.6400, -103.3150,
    'monument',
    4.9,
    'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?auto=format&fit=crop&w=800&q=80',
    'https://assets.waylo.app/audio/gdl_tlaquepaque_es.mp3',
    4,
    false,
    ARRAY['mariachi', 'artisan', 'tradition', 'tequila', 'outdoor']
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.audio_capsules (id, poi_id, language, title, duration_seconds, file_path, file_size_kb, bitrate_kbps)
VALUES
(
    'aud_gdl_cabanas_01',
    'poi_gdl_cabanas',
    'es',
    'El Hombre de Fuego y los Murales de Orozco',
    115,
    'audio/guadalajara/cabanas_es.mp3',
    920,
    64
),
(
    'aud_gdl_catedral_01',
    'poi_gdl_catedral',
    'es',
    'Las Torres Doradas y los Secretos del Centro Histórico',
    90,
    'audio/guadalajara/catedral_es.mp3',
    720,
    64
),
(
    'aud_gdl_degollado_01',
    'poi_gdl_degollado',
    'es',
    'La Leyenda del Águila y la Bóveda Teatral',
    80,
    'audio/guadalajara/degollado_es.mp3',
    640,
    64
),
(
    'aud_gdl_minerva_01',
    'poi_gdl_minerva',
    'es',
    'Justicia, Sabiduría y Fortaleza de la Perla Tapatía',
    75,
    'audio/guadalajara/minerva_es.mp3',
    600,
    64
)
ON CONFLICT (id) DO NOTHING;
