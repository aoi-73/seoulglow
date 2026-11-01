-- ============================================================================
--  Seoul Glow — 02_seed.sql
--  Datos de ejemplo. Ejecutar DESPUÉS de 01_schema.sql.
--
--  Contraseñas de demostración (formato PBKDF2-HMAC-SHA256, 120.000 iteraciones):
--    admin    / Admin123!
--    gerente  / Gerente123!
--    vendedor / Vendedor123!
--    soporte  / Soporte123!
--  Ver sql/README.md para el código Java de verificación.
-- ============================================================================

SET NAMES utf8mb4;
USE seoulglow_db;

-- ---------------------------------------------------------------------------
-- Usuarios del sistema
-- ---------------------------------------------------------------------------
INSERT INTO usuarios
  (id_usuario, nombre_completo, usuario, email, password_hash, rol, activo)
VALUES
  (1, 'Ana Torres',        'admin',    'ana.torres@seoulglow.com',
      'pbkdf2_sha256$120000$caLVWoU8fTCVbBLvqEhtCg==$tE+6YedYqoFf9yGoyU3qS+eEkJn3aPQr5RYOVxkDSQo=', 'admin',    1),
  (2, 'Bruno Salinas',     'gerente',  'bruno.salinas@seoulglow.com',
      'pbkdf2_sha256$120000$sfzImhVhl8Fk/vmhE07r8A==$ke0vVWor++b3t7g3ncxbcPvl36vzBCH7liT0S9+eQzw=', 'gerente',  1),
  (3, 'Carla Zambrano',    'vendedor', 'carla.zambrano@seoulglow.com',
      'pbkdf2_sha256$120000$i/JcxnheNv//voSAaFHHLg==$6ZK8koB+ilQqiFE3k0CEeK/uimzJbMLfgqcQieSCaC4=', 'vendedor', 1),
  (4, 'Diego Alvarado',    'soporte',  'diego.alvarado@seoulglow.com',
      'pbkdf2_sha256$120000$CzRES1a8Ua6NFy5fAqDjuQ==$M5ay4wuv2zkYKq2aCSvGKvLR5YZX2fsLJirWZ74nvHM=', 'soporte',  1);

-- ---------------------------------------------------------------------------
-- Categorías (1-9 principales, 10-12 subcategorías)
-- ---------------------------------------------------------------------------
INSERT INTO categorias (id_categoria, nombre, slug, descripcion, id_padre, activa) VALUES
  (1,  'Limpiadores',           'limpiadores',           'Geles, espumas y bálsamos para el primer paso de la rutina', NULL, 1),
  (2,  'Tónicos',               'tonicos',               'Preparan la piel y equilibran el pH después de limpiar',     NULL, 1),
  (3,  'Esencias y sérums',     'esencias-serums',       'Concentrados de activos para tratar necesidades concretas',  NULL, 1),
  (4,  'Hidratantes',           'hidratantes',           'Cremas y emulsiones que sellan la hidratación',              NULL, 1),
  (5,  'Protectores solares',   'protectores-solares',   'Fotoprotección diaria, el paso que no se salta',             NULL, 1),
  (6,  'Mascarillas',           'mascarillas',           'Tratamientos puntuales de 10 a 20 minutos',                  NULL, 1),
  (7,  'Contorno de ojos',      'contorno-ojos',         'Cuidado específico de la zona ocular',                       NULL, 1),
  (8,  'Exfoliantes',           'exfoliantes',           'Renuevan la superficie de la piel',                          NULL, 1),
  (9,  'Kits',                  'kits',                  'Rutinas completas para regalar o empezar',                   NULL, 1),
  (10, 'Limpiadores en gel',    'limpiadores-gel',       'Subcategoría de limpiadores',                                1,    1),
  (11, 'Sérums faciales',       'serums-faciales',       'Subcategoría de esencias y sérums',                          3,    1),
  (12, 'Mascarillas de tela',   'mascarillas-tela',      'Subcategoría de mascarillas',                                6,    1);

-- ---------------------------------------------------------------------------
-- Marcas
-- ---------------------------------------------------------------------------
INSERT INTO marcas (id_marca, nombre, pais_origen, sitio_web, descripcion, activa) VALUES
  (1,  'COSRX',             'Corea del Sur', 'https://cosrx.com',            'Marca coreana conocida por sus fórmulas sencillas y efectivas.', 1),
  (2,  'Laneige',           'Corea del Sur', 'https://laneige.com',          'Especialista en hidratación con tecnología de agua mineral.',    1),
  (3,  'Innisfree',         'Corea del Sur', 'https://innisfree.com',        'Cosmética natural inspirada en la isla de Jeju.',                1),
  (4,  'Beauty of Joseon',  'Corea del Sur', 'https://beautyofjoseon.com',   'Fórmulas inspiradas en la estética de la dinastía Joseon.',      1),
  (5,  'Anua',              'Corea del Sur', 'https://anua.com',             'Enfocada en calmar la piel sensible con ingredientes botánicos.', 1),
  (6,  'Torriden',          'Corea del Sur', 'https://torriden.com',         'Hidratación con ácido hialurónico de bajo peso molecular.',      1),
  (7,  'Round Lab',         'Corea del Sur', 'https://roundlab.com',         'Ingredientes limpios y agua de mar profunda.',                   1),
  (8,  'Some By Mi',        'Corea del Sur', 'https://somebymi.com',         'Tratamientos para piel con tendencia acneica.',                  1),
  (9,  'Dr. Jart+',         'Corea del Sur', 'https://drjart.com',           'Dermocosmética con centella asiática.',                          1),
  (10, 'Sulwhasoo',         'Corea del Sur', 'https://sulwhasoo.com',        'Cosmética premium con ginseng coreano.',                         1);

-- ---------------------------------------------------------------------------
-- Ingredientes
-- ---------------------------------------------------------------------------
INSERT INTO ingredientes (id_ingrediente, nombre, beneficio, descripcion) VALUES
  (1,  'Centella asiática',        'Calmante y reparador',   'Reduce el enrojecimiento y ayuda a reparar la barrera cutánea.'),
  (2,  'Niacinamida',              'Iluminador y seborregulador', 'Unifica el tono y ayuda a controlar el exceso de sebo.'),
  (3,  'Ácido hialurónico',        'Hidratante',             'Retiene agua en la piel y mejora la sensación de confort.'),
  (4,  'Mucina de caracol',        'Reparador',              'Favorece la regeneración y aporta hidratación profunda.'),
  (5,  'Té verde',                 'Antioxidante',           'Protege frente al estrés oxidativo y calma la piel.'),
  (6,  'Extracto de arroz',        'Iluminador',             'Aporta luminosidad y suavidad a la piel.'),
  (7,  'Ceramidas',                'Barrera cutánea',        'Refuerzan la barrera y reducen la pérdida de agua.'),
  (8,  'Vitamina C',               'Antioxidante',           'Ayuda a unificar el tono y aporta luminosidad.'),
  (9,  'Retinol',                  'Antiedad',               'Estimula la renovación celular y mejora las líneas finas.'),
  (10, 'Pantenol',                 'Calmante',               'Calma la piel irritada y mejora la hidratación.'),
  (11, 'Heartleaf',                'Calmante',               'Extracto de Houttuynia cordata, ideal para piel reactiva.'),
  (12, 'Probióticos',              'Equilibrio del microbioma', 'Ayudan a mantener el equilibrio de la flora cutánea.'),
  (13, 'Raíz de ginseng',          'Energizante',            'Aporta vitalidad y mejora la elasticidad de la piel.'),
  (14, 'Ácido salicílico (BHA)',   'Exfoliante',             'Penetra en el poro y ayuda a desobstruirlo.');

-- ---------------------------------------------------------------------------
-- Productos
-- ---------------------------------------------------------------------------
INSERT INTO productos
  (id_producto, sku, nombre, slug, descripcion_corta, descripcion,
   id_marca, id_categoria, precio, precio_oferta, moneda,
   stock, stock_minimo, volumen_ml, tipo_piel, activo, destacado)
VALUES
  (1, 'COS-RS-001', 'Advanced Snail 96 Mucin Power Essence', 'advanced-snail-96-mucin-power-essence',
   'Esencia reparadora con 96% de mucina de caracol.',
   'Hidrata, repara la barrera cutánea y mejora la textura de la piel. Uso diario, mañana y noche.',
   1, 3, 18.90, NULL, 'USD', 60, 10, 100, 'seca,sensible', 1, 1),

  (2, 'COS-GC-002', 'Low pH Good Morning Gel Cleanser', 'low-ph-good-morning-gel-cleanser',
   'Limpiador en gel de pH bajo para uso diario.',
   'Limpia sin resecar y respeta el manto ácido de la piel. Ideal para piel mixta y grasa.',
   1, 10, 12.50, NULL, 'USD', 80, 15, 150, 'grasa,mixta', 1, 0),

  (3, 'COS-AC-003', 'AHA/BHA Clarifying Treatment Toner', 'aha-bha-clarifying-treatment-toner',
   'Tónico exfoliante suave con AHA y BHA.',
   'Refina los poros y mejora la textura. Usar dos o tres veces por semana.',
   1, 2, 16.00, NULL, 'USD', 40, 10, 150, 'grasa,mixta', 1, 0),

  (4, 'LAN-WM-004', 'Water Sleeping Mask', 'water-sleeping-mask',
   'Mascarilla nocturna de hidratación intensa.',
   'Se aplica antes de dormir y se retira por la mañana. Contiene agua de manantial y ceramidas.',
   2, 6, 27.00, NULL, 'USD', 45, 10, 70, 'seca,normal', 1, 0),

  (5, 'LAN-LS-005', 'Lip Sleeping Mask Berry', 'lip-sleeping-mask-berry',
   'Bálsamo labial nocturno con aroma a frutos rojos.',
   'Nutre y suaviza los labios durante la noche. Incluye aplicador.',
   2, 4, 20.00, NULL, 'USD', 6, 5, NULL, 'seca', 1, 0),

  (6, 'LAN-CS-006', 'Cream Skin Refiner', 'cream-skin-refiner',
   'Tónico cremoso que prepara la piel.',
   'Combina tónico e hidratante ligera. Deja la piel suave y luminosa.',
   2, 2, 24.00, NULL, 'USD', 35, 10, 150, 'seca,sensible', 1, 0),

  (7, 'INN-GT-007', 'Green Tea Seed Hyaluronic Serum', 'green-tea-seed-hyaluronic-serum',
   'Sérum de té verde y ácido hialurónico.',
   'Hidrata en profundidad y aporta antioxidantes. Textura ligera de rápida absorción.',
   3, 11, 22.00, NULL, 'USD', 50, 10, 80, 'normal,mixta', 1, 0),

  (8, 'INN-VC-008', 'Vitamin C Brightening Serum', 'vitamin-c-brightening-serum',
   'Sérum iluminador con vitamina C.',
   'Unifica el tono y aporta luminosidad. Usar por la mañana con protector solar.',
   3, 11, 25.00, 19.90, 'USD', 25, 8, 30, 'normal,mixta', 1, 0),

  (9, 'BOJ-RS-009', 'Relief Sun Rice + Probiotics SPF50+', 'relief-sun-rice-probiotics-spf50',
   'Protector solar SPF50+ PA++++ con arroz y probióticos.',
   'Acabado natural, sin residuo blanco. Apto para piel sensible.',
   4, 5, 17.50, NULL, 'USD', 70, 15, 50, 'sensible,normal', 1, 1),

  (10, 'BOJ-GP-010', 'Glow Deep Serum Rice + Arbutin', 'glow-deep-serum-rice-arbutin',
   'Sérum iluminador con extracto de arroz y arbutina.',
   'Ayuda a atenuar manchas y unificar el tono. Textura acuosa.',
   4, 11, 19.00, NULL, 'USD', 30, 8, 30, 'normal,mixta', 1, 0),

  (11, 'BOJ-DY-011', 'Dynasty Cream', 'dynasty-cream',
   'Crema hidratante con arroz, ginseng y ceramidas.',
   'Nutrición intensa para piel seca. Acabado satinado sin sensación grasa.',
   4, 4, 21.00, NULL, 'USD', 28, 8, 50, 'seca,normal', 1, 0),

  (12, 'ANU-HT-012', 'Heartleaf 77% Soothing Toner', 'heartleaf-77-soothing-toner',
   'Tónico calmante con 77% de extracto de heartleaf.',
   'Reduce el enrojecimiento y calma la piel irritada. Sin alcohol.',
   5, 2, 21.50, NULL, 'USD', 55, 12, 250, 'sensible,mixta', 1, 1),

  (13, 'ANU-CA-013', 'Madagascar Centella Ampoule', 'madagascar-centella-ampoule',
   'Ampolla concentrada de centella asiática.',
   'Calma, repara y refuerza la barrera cutánea. Textura ligera.',
   5, 3, 23.00, NULL, 'USD', 40, 10, 30, 'sensible,seca', 1, 0),

  (14, 'ANU-QS-014', 'Quinoa Panthenol Serum', 'quinoa-panthenol-serum',
   'Sérum de quinua y pantenol para piel sensible.',
   'Hidrata y calma. Apto para piel reactiva.',
   5, 3, 24.00, NULL, 'USD', 22, 8, 30, 'sensible', 1, 0),

  (15, 'TOR-DI-015', 'Dive-In Low Molecule Hyaluronic Acid Serum', 'dive-in-low-molecule-hyaluronic-serum',
   'Sérum de ácido hialurónico de bajo peso molecular.',
   'Hidratación profunda y efecto relleno. Textura no pegajosa.',
   6, 3, 20.00, NULL, 'USD', 65, 12, 50, 'seca,normal', 1, 1),

  (16, 'TOR-DC-016', 'Dive-In Low Molecule Hyaluronic Acid Cream', 'dive-in-low-molecule-hyaluronic-cream',
   'Crema hidratante con ácido hialurónico.',
   'Sella la hidratación y deja la piel suave. Uso diario.',
   6, 4, 23.00, NULL, 'USD', 38, 10, 80, 'seca,mixta', 1, 0),

  (17, 'TOR-BT-017', 'Balanceful Cica Toner', 'balanceful-cica-toner',
   'Tónico equilibrante con centella asiática.',
   'Calma y controla el exceso de sebo. Sin fragancia.',
   6, 2, 19.00, NULL, 'USD', 33, 10, 200, 'grasa,mixta', 1, 0),

  (18, 'RND-DK-018', '1025 Dokdo Toner', '1025-dokdo-toner',
   'Tónico de agua de mar profunda de Ulleungdo.',
   'Hidrata y suaviza la piel. Exfoliación enzimática suave.',
   7, 2, 18.50, NULL, 'USD', 48, 12, 200, 'normal,mixta', 1, 0),

  (19, 'RND-DK-019', '1025 Dokdo Cleanser', '1025-dokdo-cleanser',
   'Limpiador suave con agua de mar profunda.',
   'Espuma cremosa que limpia sin resecar. Uso diario.',
   7, 1, 14.00, NULL, 'USD', 42, 10, 150, 'normal,seca', 1, 0),

  (20, 'RND-SP-020', 'Birch Juice Moisturizing Sunscreen SPF50+', 'birch-juice-moisturizing-sunscreen-spf50',
   'Protector solar hidratante con savia de abedul.',
   'SPF50+ PA++++. Textura ligera, sin residuo blanco.',
   7, 5, 19.50, NULL, 'USD', 60, 15, 50, 'seca,normal', 1, 0),

  (21, 'SBM-MT-021', 'AHA BHA PHA 30 Days Miracle Toner', 'aha-bha-pha-30-days-miracle-toner',
   'Tónico exfoliante con AHA, BHA y PHA.',
   'Mejora la textura y controla el acné. Introducir gradualmente.',
   8, 2, 17.00, NULL, 'USD', 36, 10, 150, 'grasa,mixta', 1, 0),

  (22, 'SBM-MC-022', 'AHA BHA PHA 30 Days Miracle Cream', 'aha-bha-pha-30-days-miracle-cream',
   'Crema ligera con centella y ácidos suaves.',
   'Hidrata y calma sin obstruir los poros. Uso diario.',
   8, 4, 21.00, NULL, 'USD', 30, 8, NULL, 'grasa,mixta', 1, 0),

  (23, 'SBM-MK-023', 'Super Matcha Pore Clean Clay Mask', 'super-matcha-pore-clean-clay-mask',
   'Mascarilla de arcilla y matcha para poros.',
   'Absorbe el exceso de sebo y limpia los poros. Uso semanal.',
   8, 6, 16.50, NULL, 'USD', 10, 8, NULL, 'grasa,mixta', 1, 0),

  (24, 'DJ-CP-024', 'Cicapair Tiger Grass Color Correcting Treatment', 'cicapair-tiger-grass-color-correcting-treatment',
   'Crema correctora con centella y SPF30.',
   'Neutraliza rojeces y unifica el tono. Acabado natural.',
   9, 4, 32.00, NULL, 'USD', 20, 6, 50, 'sensible', 1, 0),

  (25, 'DJ-CS-025', 'Cicapair Calming Serum', 'cicapair-calming-serum',
   'Sérum calmante para piel sensible.',
   'Reduce rojeces y refuerza la barrera. Textura ligera.',
   9, 3, 29.00, NULL, 'USD', 18, 6, 30, 'sensible', 1, 0),

  (26, 'SW-GT-026', 'First Care Activating Serum', 'first-care-activating-serum',
   'Sérum activador con extracto de ginseng.',
   'Primer paso después de la limpieza. Mejora la absorción de los siguientes productos.',
   10, 3, 89.00, NULL, 'USD', 12, 5, 60, 'normal,seca', 1, 0),

  (27, 'SW-GC-027', 'Ginseng Cream', 'ginseng-cream',
   'Crema antiedad con ginseng coreano.',
   'Nutre y aporta elasticidad. Textura rica de larga duración.',
   10, 4, 95.00, NULL, 'USD', 10, 5, 50, 'seca,normal', 1, 0),

  (28, 'COS-BP-028', 'BHA Blackhead Power Liquid', 'bha-blackhead-power-liquid',
   'Exfoliante líquido con ácido salicílico.',
   'Ayuda a desobstruir poros y reducir puntos negros. Uso nocturno.',
   1, 8, 17.50, NULL, 'USD', 26, 8, 100, 'grasa,mixta', 1, 0),

  (29, 'BOJ-CM-029', 'Centella Calming Sheet Mask (5 uds)', 'centella-calming-sheet-mask',
   'Mascarilla de tela calmante con centella.',
   'Pack de 5 unidades. Hidrata y calma en 15 minutos.',
   4, 12, 12.00, NULL, 'USD', 5, 5, NULL, 'sensible,normal', 1, 0),

  (30, 'TOR-AM-030', 'All Day Mask Pack', 'all-day-mask-pack',
   'Mascarilla de tela hidratante para uso diario.',
   'Pack de 5 unidades. Aporta hidratación inmediata.',
   6, 6, 15.00, NULL, 'USD', 7, 6, NULL, 'seca,normal', 1, 0),

  (31, 'RND-EY-031', 'Dokdo Eye Cream', 'dokdo-eye-cream',
   'Crema de contorno de ojos con agua de mar.',
   'Hidrata y suaviza las líneas finas. Textura ligera.',
   7, 7, 16.00, NULL, 'USD', 9, 5, 30, 'normal,seca', 1, 0),

  (32, 'SBM-KT-032', 'Miracle Starter Kit', 'miracle-starter-kit',
   'Kit de inicio con tónico, sérum y crema.',
   'Rutina completa para piel con tendencia acneica. Ideal para regalo.',
   8, 9, 29.00, NULL, 'USD', 8, 10, NULL, 'grasa,mixta', 1, 0);

-- ---------------------------------------------------------------------------
-- Imágenes: dos por producto, generadas a partir del SKU
-- (los archivos se colocan en public/img/productos/ del proyecto Next.js)
-- ---------------------------------------------------------------------------
INSERT INTO producto_imagenes (id_producto, url, alt_text, orden, es_principal)
SELECT id_producto,
       CONCAT('/img/productos/', sku, '-1.webp'),
       CONCAT(nombre, ' - vista frontal'),
       0, 1
FROM productos;

INSERT INTO producto_imagenes (id_producto, url, alt_text, orden, es_principal)
SELECT id_producto,
       CONCAT('/img/productos/', sku, '-2.webp'),
       CONCAT(nombre, ' - textura'),
       1, 0
FROM productos;

-- ---------------------------------------------------------------------------
-- Ingredientes por producto
-- ---------------------------------------------------------------------------
INSERT INTO producto_ingredientes (id_producto, id_ingrediente, porcentaje, es_clave) VALUES
  (1, 4, 96.00, 1), (1, 3, NULL, 0), (1, 10, NULL, 0),
  (2, 5, NULL, 0), (2, 1, NULL, 0),
  (3, 5, NULL, 0), (3, 2, NULL, 0),
  (4, 3, NULL, 1), (4, 7, NULL, 0),
  (5, 3, NULL, 0), (5, 7, NULL, 0),
  (6, 7, NULL, 1), (6, 3, NULL, 0),
  (7, 5, NULL, 1), (7, 3, NULL, 0),
  (8, 8, NULL, 1), (8, 2, NULL, 0),
  (9, 6, NULL, 1), (9, 12, NULL, 0),
  (10, 6, NULL, 1), (10, 2, NULL, 0),
  (11, 6, NULL, 0), (11, 7, NULL, 0), (11, 13, NULL, 0),
  (12, 11, 77.00, 1), (12, 1, NULL, 0),
  (13, 1, NULL, 1), (13, 10, NULL, 0),
  (14, 10, NULL, 1), (14, 3, NULL, 0),
  (15, 3, NULL, 1), (15, 10, NULL, 0),
  (16, 3, NULL, 0), (16, 7, NULL, 0),
  (17, 1, NULL, 0), (17, 11, NULL, 0),
  (18, 3, NULL, 0), (18, 10, NULL, 0),
  (19, 3, NULL, 0), (19, 10, NULL, 0),
  (20, 3, NULL, 0), (20, 10, NULL, 0),
  (21, 1, NULL, 0), (21, 2, NULL, 0),
  (22, 1, NULL, 1), (22, 7, NULL, 0),
  (23, 5, NULL, 1), (23, 2, NULL, 0),
  (24, 1, NULL, 1), (24, 2, NULL, 0),
  (25, 1, NULL, 1), (25, 10, NULL, 0),
  (26, 13, NULL, 1), (26, 6, NULL, 0),
  (27, 13, NULL, 1), (27, 7, NULL, 0),
  (28, 14, NULL, 1), (28, 5, NULL, 0),
  (29, 1, NULL, 1), (29, 3, NULL, 0),
  (30, 3, NULL, 0), (30, 10, NULL, 0),
  (31, 3, NULL, 0), (31, 7, NULL, 0),
  (32, 1, NULL, 0), (32, 2, NULL, 0), (32, 3, NULL, 0);

-- ---------------------------------------------------------------------------
-- Clientes
-- ---------------------------------------------------------------------------
INSERT INTO clientes
  (id_cliente, nombre, apellido, email, telefono, direccion, ciudad, pais,
   fecha_nacimiento, acepta_marketing, activo)
VALUES
  (1,  'Laura',      'Gómez',     'laura.gomez@example.com',      '0991234567', 'Av. Amazonas N34-120',  'Quito',      'Ecuador', '1994-03-12', 1, 1),
  (2,  'Andrés',     'Pérez',     'andres.perez@example.com',     '0987654321', 'Calle 10 de Agosto 220', 'Quito',      'Ecuador', '1990-07-25', 1, 1),
  (3,  'María Fernanda', 'Ruiz',  'mfruiz@example.com',           '0976543210', 'Av. 6 de Diciembre 45',  'Quito',      'Ecuador', '1998-11-02', 0, 1),
  (4,  'Carlos',     'Mendoza',   'cmendoza@example.com',         '0965432109', 'Av. América 1500',       'Quito',      'Ecuador', '1988-05-18', 1, 1),
  (5,  'Daniela',    'Torres',    'dtorres@example.com',          '0954321098', 'Calle Bolívar 310',      'Guayaquil',  'Ecuador', '1996-09-09', 1, 1),
  (6,  'Jorge',      'Salazar',   'jsalazar@example.com',         '0943210987', 'Av. 9 de Octubre 800',   'Guayaquil',  'Ecuador', '1985-12-30', 0, 1),
  (7,  'Paola',      'Cárdenas',  'pcardenas@example.com',        '0932109876', 'Av. Los Shyris 120',     'Quito',      'Ecuador', '1999-01-21', 1, 1),
  (8,  'Ricardo',    'Vega',      'rvega@example.com',            '0921098765', 'Calle Sucre 45',         'Cuenca',     'Ecuador', '1992-04-14', 0, 1),
  (9,  'Sofía',      'Herrera',   'sherrera@example.com',         '0910987654', 'Av. Ordóñez Lasso 300',  'Cuenca',     'Ecuador', '2000-08-07', 1, 1),
  (10, 'Miguel Ángel','León',     'mleon@example.com',            '0909876543', 'Av. Universitaria 500',  'Quito',      'Ecuador', '1987-02-11', 0, 1),
  (11, 'Valentina',  'Ríos',      'vrios@example.com',            '0998765432', 'Calle García Moreno 88', 'Quito',      'Ecuador', '1995-06-03', 1, 1),
  (12, 'Sebastián',  'Castro',    'scastro@example.com',          '0987651234', 'Av. Naciones Unidas 77', 'Quito',      'Ecuador', '1993-10-27', 1, 1),
  (13, 'Camila',     'Ortiz',     'cortiz@example.com',           '0976541230', 'Av. Eloy Alfaro 210',    'Quito',      'Ecuador', '1997-03-19', 0, 1),
  (14, 'Diego',      'Morales',   'dmorales@example.com',         '0965431230', 'Calle Espejo 145',       'Quito',      'Ecuador', '1991-12-05', 1, 1),
  (15, 'Isabella',   'Núñez',     'inunez@example.com',           '0954321230', 'Av. Portugal 320',       'Quito',      'Ecuador', '2001-05-23', 1, 1);

-- ---------------------------------------------------------------------------
-- Pedidos (los totales se calculan al final, desde los detalles)
-- ---------------------------------------------------------------------------
INSERT INTO pedidos
  (id_pedido, numero_pedido, id_cliente, id_usuario, fecha_pedido, estado,
   metodo_pago, subtotal, descuento, impuesto, total, notas)
VALUES
  (1,  'PED-2026-000001', 1,  3, '2026-01-12 10:15:00', 'entregado',      'tarjeta',       0, 0, 0, 0, NULL),
  (2,  'PED-2026-000002', 2,  3, '2026-01-20 16:40:00', 'entregado',      'tarjeta',       0, 0, 0, 0, NULL),
  (3,  'PED-2026-000003', 3,  2, '2026-02-03 09:05:00', 'entregado',      'transferencia', 0, 0, 0, 0, 'Entrega en oficina'),
  (4,  'PED-2026-000004', 4,  3, '2026-02-14 18:30:00', 'entregado',      'tarjeta',       0, 0, 0, 0, 'Regalo de San Valentín'),
  (5,  'PED-2026-000005', 5,  3, '2026-02-27 12:00:00', 'cancelado',      'tarjeta',       0, 0, 0, 0, 'Cliente canceló antes del envío'),
  (6,  'PED-2026-000006', 6,  2, '2026-03-05 11:20:00', 'entregado',      'paypal',        0, 0, 0, 0, NULL),
  (7,  'PED-2026-000007', 7,  3, '2026-03-18 15:10:00', 'entregado',      'tarjeta',       0, 0, 0, 0, NULL),
  (8,  'PED-2026-000008', 8,  3, '2026-03-29 10:45:00', 'entregado',      'efectivo',      0, 0, 0, 0, NULL),
  (9,  'PED-2026-000009', 9,  2, '2026-04-07 14:05:00', 'entregado',      'tarjeta',       0, 0, 0, 0, NULL),
  (10, 'PED-2026-000010', 10, 3, '2026-04-21 17:25:00', 'entregado',      'transferencia', 0, 0, 0, 0, NULL),
  (11, 'PED-2026-000011', 1,  3, '2026-05-06 09:50:00', 'enviado',        'tarjeta',       0, 0, 0, 0, 'Guía de envío 001-2026'),
  (12, 'PED-2026-000012', 11, 3, '2026-05-19 13:15:00', 'entregado',      'tarjeta',       0, 0, 0, 0, NULL),
  (13, 'PED-2026-000013', 12, 2, '2026-05-30 11:00:00', 'entregado',      'paypal',        0, 0, 0, 0, NULL),
  (14, 'PED-2026-000014', 13, 3, '2026-06-11 16:35:00', 'entregado',      'tarjeta',       0, 0, 0, 0, NULL),
  (15, 'PED-2026-000015', 14, 3, '2026-06-24 10:20:00', 'entregado',      'transferencia', 0, 5, 0, 0, 'Descuento por compra mayorista'),
  (16, 'PED-2026-000016', 15, 2, '2026-07-08 18:00:00', 'entregado',      'tarjeta',       0, 0, 0, 0, NULL),
  (17, 'PED-2026-000017', 2,  3, '2026-07-22 12:40:00', 'entregado',      'efectivo',      0, 0, 0, 0, NULL),
  (18, 'PED-2026-000018', 4,  3, '2026-08-15 09:30:00', 'en_preparacion', 'tarjeta',       0, 0, 0, 0, NULL),
  (19, 'PED-2026-000019', 6,  3, '2026-09-02 15:55:00', 'pagado',         'paypal',        0, 0, 0, 0, NULL),
  (20, 'PED-2026-000020', 9,  2, '2026-10-10 11:10:00', 'pendiente',      'transferencia', 0, 0, 0, 0, 'Esperando confirmación de pago');

-- ---------------------------------------------------------------------------
-- Detalle de pedidos
-- ---------------------------------------------------------------------------
INSERT INTO pedido_detalles
  (id_detalle, id_pedido, id_producto, cantidad, precio_unitario, descuento_linea)
VALUES
  (1,  1,  1,  2, 18.90, 0), (2,  1,  9,  1, 17.50, 0),
  (3,  2,  12, 1, 21.50, 0), (4,  2,  15, 1, 20.00, 0),
  (5,  3,  26, 1, 89.00, 0),
  (6,  4,  4,  1, 27.00, 0), (7,  4,  5,  1, 20.00, 0),
  (8,  5,  21, 2, 17.00, 0),
  (9,  6,  9,  2, 17.50, 0), (10, 6,  20, 1, 19.50, 0),
  (11, 7,  13, 1, 23.00, 0), (12, 7,  14, 1, 24.00, 0),
  (13, 8,  18, 1, 18.50, 0), (14, 8,  19, 1, 14.00, 0),
  (15, 9,  2,  2, 12.50, 0), (16, 9,  28, 1, 17.50, 0),
  (17, 10, 6,  1, 24.00, 0), (18, 10, 11, 1, 21.00, 0),
  (19, 11, 15, 2, 20.00, 0), (20, 11, 16, 1, 23.00, 0),
  (21, 12, 3,  1, 16.00, 0), (22, 12, 17, 1, 19.00, 0),
  (23, 13, 24, 1, 32.00, 0), (24, 13, 25, 1, 29.00, 0),
  (25, 14, 7,  1, 22.00, 0), (26, 14, 8,  1, 19.90, 0),
  (27, 15, 27, 1, 95.00, 0), (28, 15, 26, 1, 89.00, 0),
  (29, 16, 29, 3, 12.00, 0), (30, 16, 30, 1, 15.00, 0),
  (31, 17, 31, 1, 16.00, 0), (32, 17, 32, 1, 29.00, 0),
  (33, 18, 1,  1, 18.90, 0), (34, 18, 12, 1, 21.50, 0),
  (35, 19, 23, 1, 16.50, 0), (36, 19, 22, 1, 21.00, 0),
  (37, 20, 9,  1, 17.50, 0), (38, 20, 20, 1, 19.50, 0);

-- ---------------------------------------------------------------------------
-- Totales de los pedidos calculados desde los detalles
-- ---------------------------------------------------------------------------
UPDATE pedidos pe
JOIN (
  SELECT id_pedido, SUM(subtotal_linea) AS s
  FROM pedido_detalles
  GROUP BY id_pedido
) d ON d.id_pedido = pe.id_pedido
SET pe.subtotal = d.s,
    pe.total    = d.s - pe.descuento + pe.impuesto;

-- ---------------------------------------------------------------------------
-- Kardex: inventario inicial + salidas por ventas
-- Se hace en tres pasos para que el stock final coincida exactamente
-- con la suma de movimientos (ver consulta de verificación en el README).
-- ---------------------------------------------------------------------------
INSERT INTO movimientos_inventario
  (id_producto, tipo, cantidad, motivo, id_usuario, stock_resultante, created_at)
SELECT id_producto, 'entrada', stock, 'Inventario inicial', 1, stock, '2026-01-05 09:00:00'
FROM productos;

-- Descontar lo vendido (los pedidos cancelados no descuentan)
UPDATE productos p
LEFT JOIN (
  SELECT d.id_producto, SUM(d.cantidad) AS vendidos
  FROM pedido_detalles d
  JOIN pedidos pe ON pe.id_pedido = d.id_pedido
  WHERE pe.estado <> 'cancelado'
  GROUP BY d.id_producto
) v ON v.id_producto = p.id_producto
SET p.stock = p.stock - COALESCE(v.vendidos, 0);

INSERT INTO movimientos_inventario
  (id_producto, tipo, cantidad, motivo, id_usuario, stock_resultante, created_at)
SELECT d.id_producto, 'salida', SUM(d.cantidad), 'Ventas registradas (carga inicial)',
       3, p.stock, '2026-10-31 18:00:00'
FROM pedido_detalles d
JOIN pedidos pe ON pe.id_pedido = d.id_pedido
JOIN productos p ON p.id_producto = d.id_producto
WHERE pe.estado <> 'cancelado'
GROUP BY d.id_producto, p.stock;

-- ============================================================================
--  Fin de 02_seed.sql
--  Siguiente: 03_views.sql
-- ============================================================================
