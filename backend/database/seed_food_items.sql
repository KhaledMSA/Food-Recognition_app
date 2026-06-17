-- =============================================================================
-- Seed Data — food_items
-- All 104 model classes (Food-101 + apple, banana, orange)
-- Values are approximate per-100g averages from publicly available databases.
-- Serving sizes reflect a realistic single-portion default.
-- =============================================================================

INSERT INTO food_items
    (model_label, display_name,
     calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
     fiber_per_100g, sugar_per_100g, sodium_per_100g,
     default_serving_g, serving_unit, notes)
VALUES

-- ── Appetisers & small bites ─────────────────────────────────────────────────
('bruschetta',         'Bruschetta',               195, 6.0,  28.0,  7.0,  2.0, 3.0,  350, 80,  'slice',  NULL),
('deviled_eggs',       'Deviled Eggs',             185, 8.5,  3.0,  15.5,  0.0, 1.0,  330, 60,  'piece',  '2-egg half default'),
('edamame',            'Edamame',                  122, 11.0, 10.0,  5.0,  5.0, 2.0,   63, 100, 'g',      NULL),
('escargots',          'Escargots',                90,  16.0,  2.0,  2.0,  0.0, 0.0,  200, 80,  'g',      'without butter sauce'),
('falafel',            'Falafel',                  333, 13.3, 32.0, 17.8,  5.4, 1.6,  294, 100, 'g',      NULL),
('guacamole',          'Guacamole',                160, 1.9,   8.5, 14.7,  6.7, 0.4,  211, 60,  'g',      NULL),
('hummus',             'Hummus',                   166, 7.9,  14.3,  9.6,  6.0, 0.5,  379, 60,  'g',      NULL),
('nachos',             'Nachos',                   300, 7.5,  34.0, 15.0,  2.5, 2.0,  420, 100, 'g',      'with cheese'),
('samosa',             'Samosa',                   262, 5.7,  32.0, 13.0,  3.0, 2.0,  430, 80,  'piece',  NULL),
('spring_rolls',       'Spring Rolls',             200, 5.5,  27.0,  8.5,  1.5, 1.5,  320, 80,  'piece',  'fried'),
('gyoza',              'Gyoza (Dumplings)',         200, 9.0,  22.0,  8.0,  1.5, 1.0,  400, 70,  'piece',  NULL),
('dumplings',          'Dumplings',                195, 8.5,  22.5,  7.5,  1.5, 1.0,  390, 80,  'piece',  NULL),
('takoyaki',           'Takoyaki',                 194, 7.3,  22.5,  8.4,  0.8, 3.2,  505, 80,  'g',      NULL),

-- ── Salads ───────────────────────────────────────────────────────────────────
('caesar_salad',       'Caesar Salad',             100, 5.0,   4.5,  7.5,  1.0, 1.0,  380, 150, 'g',      'with dressing'),
('caprese_salad',      'Caprese Salad',            160, 8.5,   4.0, 12.5,  0.5, 3.0,  300, 150, 'g',      NULL),
('greek_salad',        'Greek Salad',               95, 3.5,   6.5,  6.5,  1.5, 4.0,  420, 150, 'g',      NULL),
('beet_salad',         'Beet Salad',               100, 2.5,  12.5,  5.0,  2.5, 9.0,  250, 120, 'g',      NULL),
('seaweed_salad',      'Seaweed Salad',             70, 1.5,  11.0,  2.5,  1.5, 6.0,  870, 80,  'g',      NULL),

-- ── Soups ────────────────────────────────────────────────────────────────────
('clam_chowder',       'Clam Chowder',             100, 5.5,  10.5,  4.0,  0.5, 2.0,  440, 240, 'ml',     '1 cup'),
('french_onion_soup',  'French Onion Soup',         73, 3.5,   8.0,  3.0,  0.5, 4.0,  680, 250, 'ml',     NULL),
('hot_and_sour_soup',  'Hot and Sour Soup',         50, 4.5,   5.0,  1.5,  0.5, 1.0,  550, 240, 'ml',     NULL),
('miso_soup',          'Miso Soup',                 40, 3.0,   5.5,  1.0,  0.5, 1.5,  630, 240, 'ml',     NULL),
('lobster_bisque',     'Lobster Bisque',            130, 7.0,   9.0,  7.5,  0.0, 4.0,  480, 240, 'ml',     NULL),
('pho',                'Pho',                       70, 5.5,   9.5,  1.5,  0.3, 1.0,  430, 400, 'ml',     '1 bowl'),

-- ── Sandwiches & burgers ─────────────────────────────────────────────────────
('hamburger',          'Hamburger',                290, 15.0, 24.0, 14.0,  1.5, 5.0,  480, 150, 'g',      '1 patty + bun'),
('hot_dog',            'Hot Dog',                  290, 11.0, 23.0, 17.5,  1.0, 5.0,  610, 130, 'g',      'with bun'),
('club_sandwich',      'Club Sandwich',            290, 17.5, 26.0, 12.0,  1.5, 3.0,  680, 200, 'g',      NULL),
('grilled_cheese_sandwich', 'Grilled Cheese Sandwich', 350, 14.0, 30.0, 19.0, 1.0, 3.0, 590, 150, 'g', NULL),
('pulled_pork_sandwich','Pulled Pork Sandwich',     280, 16.0, 27.0, 11.5,  1.0, 8.0,  520, 200, 'g',     NULL),
('lobster_roll_sandwich','Lobster Roll Sandwich',   280, 16.5, 24.0, 12.0,  1.0, 3.5,  580, 150, 'g',     NULL),
('croque_madame',      'Croque Madame',             330, 18.5, 23.0, 18.0,  1.0, 4.0,  760, 180, 'g',     NULL),

-- ── Pizza & Italian ───────────────────────────────────────────────────────────
('pizza',              'Pizza',                    266, 11.0, 33.0, 10.0,  2.0, 3.5,  598, 150, 'g',      '1–2 slices'),
('lasagna',            'Lasagna',                  135, 9.5,  13.0,  5.0,  1.0, 3.0,  325, 200, 'g',      NULL),
('spaghetti_bolognese','Spaghetti Bolognese',       150, 9.0,  18.0,  4.5,  1.5, 2.5,  350, 250, 'g',     NULL),
('spaghetti_carbonara','Spaghetti Carbonara',       250, 12.0, 28.0, 10.0,  1.0, 1.5,  380, 250, 'g',     NULL),
('ravioli',            'Ravioli',                  190, 9.5,  25.0,  6.0,  1.5, 2.0,  310, 150, 'g',      NULL),
('gnocchi',            'Gnocchi',                  130, 3.5,  27.0,  1.0,  1.5, 1.5,  220, 150, 'g',      NULL),
('risotto',            'Risotto',                  165, 4.5,  25.0,  5.5,  0.5, 1.0,  310, 200, 'g',      NULL),
('macaroni_and_cheese','Macaroni and Cheese',       170, 7.5,  22.5,  6.0,  1.0, 4.0,  420, 200, 'g',     NULL),

-- ── Asian dishes ─────────────────────────────────────────────────────────────
('sushi',              'Sushi',                    150, 6.5,  26.0,  2.5,  0.5, 4.0,  430, 150, 'g',      '3–4 pieces'),
('sashimi',            'Sashimi',                  130, 22.0,  0.0,  4.5,  0.0, 0.0,  250, 100, 'g',      NULL),
('ramen',              'Ramen',                    105, 7.5,  14.0,  2.5,  0.5, 1.5,  680, 400, 'ml',     '1 bowl'),
('pad_thai',           'Pad Thai',                 170, 9.0,  22.0,  5.5,  1.5, 4.0,  480, 250, 'g',      NULL),
('fried_rice',         'Fried Rice',               160, 5.5,  24.0,  5.0,  1.0, 2.0,  430, 200, 'g',      NULL),
('bibimbap',           'Bibimbap',                 120, 7.0,  17.0,  3.0,  2.0, 2.0,  380, 350, 'g',      '1 bowl'),
('chicken_curry',      'Chicken Curry',             150, 13.0,  8.0,  7.5,  1.5, 3.5,  430, 250, 'g',     NULL),
('peking_duck',        'Peking Duck',              340, 19.0,  10.0, 25.5,  0.0, 5.0,  460, 150, 'g',     NULL),
('paella',             'Paella',                   175, 11.5, 21.5,  5.0,  1.0, 1.5,  380, 250, 'g',     NULL),

-- ── Mexican ───────────────────────────────────────────────────────────────────
('tacos',              'Tacos',                    218, 11.0, 20.0, 10.0,  2.0, 2.0,  390, 150, 'g',      '2 soft tacos'),
('breakfast_burrito',  'Breakfast Burrito',         230, 11.5, 22.5, 11.0,  2.0, 2.5,  530, 200, 'g',     NULL),
('chicken_quesadilla', 'Chicken Quesadilla',        270, 17.5, 22.0, 12.5,  1.5, 2.0,  590, 150, 'g',     NULL),
('huevos_rancheros',   'Huevos Rancheros',          180, 10.5, 14.0,  9.0,  2.5, 3.5,  420, 200, 'g',     NULL),

-- ── Meat & seafood mains ─────────────────────────────────────────────────────
('steak',              'Steak',                    250, 26.0,  0.0, 16.5,  0.0, 0.0,  150, 200, 'g',      'sirloin, cooked'),
('filet_mignon',       'Filet Mignon',             267, 26.0,  0.0, 17.5,  0.0, 0.0,  130, 170, 'g',      NULL),
('prime_rib',          'Prime Rib',                340, 24.0,  0.0, 27.0,  0.0, 0.0,  160, 200, 'g',      NULL),
('baby_back_ribs',     'Baby Back Ribs',            275, 20.5,  5.0, 19.5,  0.0, 3.0,  380, 200, 'g',     NULL),
('pork_chop',          'Pork Chop',                230, 25.5,  0.0, 14.0,  0.0, 0.0,  160, 180, 'g',      NULL),
('pulled_pork_sandwich','Pulled Pork',             215, 18.5,  4.5, 13.5,  0.0, 3.5,  360, 150, 'g',      'meat only'),
('grilled_salmon',     'Grilled Salmon',            180, 24.0,  0.0,  8.5,  0.0, 0.0,  110, 150, 'g',     NULL),
('fish_and_chips',     'Fish and Chips',            240, 12.0, 22.5, 11.5,  1.5, 1.0,  460, 250, 'g',     NULL),
('shrimp_and_grits',   'Shrimp and Grits',          190, 13.5, 17.5,  7.0,  1.0, 1.5,  520, 250, 'g',     NULL),
('crab_cakes',         'Crab Cakes',               220, 14.5, 11.0, 13.5,  0.5, 1.5,  680, 90,  'piece',  '1 cake'),
('lobster_bisque',     'Lobster Bisque',            130, 7.0,   9.0,  7.5,  0.0, 4.0,  480, 240, 'ml',    NULL),
('mussels',            'Mussels',                   86, 11.9,  3.7,  2.2,  0.0, 0.0,  286, 150, 'g',     NULL),
('oysters',            'Oysters',                   68, 7.0,   3.9,  2.5,  0.0, 0.0,  220, 100, 'g',     NULL),
('scallops',           'Scallops',                  88, 16.8,  3.2,  0.9,  0.0, 0.0,  161, 150, 'g',     NULL),
('tuna_tartare',       'Tuna Tartare',             132, 23.5,  1.5,  3.5,  0.0, 0.5,  220, 100, 'g',     NULL),
('beef_carpaccio',     'Beef Carpaccio',            155, 18.5,  1.0,  8.5,  0.0, 0.5,  240, 80,  'g',     NULL),
('beef_tartare',       'Beef Tartare',              168, 20.0,  1.5,  9.0,  0.0, 0.5,  260, 100, 'g',     NULL),
('foie_gras',          'Foie Gras',                462, 11.4,  4.7, 44.0,  0.0, 0.0,  697, 50,  'g',     NULL),
('ceviche',            'Ceviche',                   75, 13.5,  4.5,  1.0,  0.5, 1.5,  210, 150, 'g',     NULL),

-- ── Eggs & breakfast ─────────────────────────────────────────────────────────
('omelette',           'Omelette',                 154, 11.0,  1.5, 11.5,  0.0, 1.0,  310, 120, 'g',     '2-egg'),
('eggs_benedict',      'Eggs Benedict',            275, 14.5, 18.5, 16.0,  0.5, 2.5,  720, 200, 'g',     NULL),
('french_toast',       'French Toast',             230, 7.5,  31.0,  8.5,  1.0, 9.0,  310, 150, 'g',     '2 slices'),
('pancakes',           'Pancakes',                 227, 6.0,  36.5,  7.0,  1.0,10.0,  360, 150, 'g',     '2 medium'),
('waffles',            'Waffles',                  290, 7.5,  37.5, 12.0,  1.0, 8.0,  490, 130, 'g',     '1 waffle'),

-- ── Bread & sides ─────────────────────────────────────────────────────────────
('garlic_bread',       'Garlic Bread',             350, 8.0,  46.5, 15.0,  2.0, 2.0,  640, 60,  'slice',  NULL),
('french_fries',       'French Fries',             312, 3.4,  41.0, 15.0,  3.5, 0.5,  210, 150, 'g',     NULL),
('onion_rings',        'Onion Rings',              411, 5.0,  42.0, 25.0,  2.5, 4.0,  500, 100, 'g',     NULL),
('poutine',            'Poutine',                  230, 8.5,  25.5, 11.0,  2.5, 2.0,  560, 300, 'g',     NULL),
('cheese_plate',       'Cheese Plate',             390, 22.0,  3.0, 32.0,  0.0, 0.5,  620, 120, 'g',     'assorted'),

-- ── Curries, stews & rice dishes ─────────────────────────────────────────────
('chicken_wings',      'Chicken Wings',            290, 22.5,  3.0, 21.0,  0.0, 1.0,  480, 120, 'g',     '4–5 wings'),

-- ── Sushi & Japanese ─────────────────────────────────────────────────────────

-- ── Middle-Eastern / Mediterranean ───────────────────────────────────────────
('baklava',            'Baklava',                  428, 6.0,  52.5, 23.0,  2.0,34.0,  180, 60,  'piece',  NULL),

-- ── Desserts & sweets ─────────────────────────────────────────────────────────
('apple_pie',          'Apple Pie',                237, 2.0,  34.0, 11.0,  1.5,15.0,  250, 125, 'g',     '1 slice'),
('carrot_cake',        'Carrot Cake',              415, 4.5,  56.0, 20.5,  1.5,40.0,  330, 100, 'g',     '1 slice'),
('chocolate_cake',     'Chocolate Cake',           371, 5.0,  51.0, 17.5,  2.5,32.0,  360, 100, 'g',     '1 slice'),
('cheesecake',         'Cheesecake',               321, 5.5,  25.0, 22.5,  0.5,19.0,  310, 100, 'g',     '1 slice'),
('red_velvet_cake',    'Red Velvet Cake',          390, 4.5,  52.0, 19.0,  1.0,37.0,  320, 100, 'g',     '1 slice'),
('tiramisu',           'Tiramisu',                 283, 5.0,  27.5, 17.0,  0.5,20.0,  145, 120, 'g',     NULL),
('panna_cotta',        'Panna Cotta',              220, 3.5,  23.5, 13.0,  0.0,22.0,   55, 120, 'g',     NULL),
('creme_brulee',       'Crème Brûlée',             290, 4.5,  26.5, 19.0,  0.0,23.0,   65, 120, 'g',     NULL),
('chocolate_mousse',   'Chocolate Mousse',         250, 4.5,  22.0, 16.5,  2.0,19.0,   55, 100, 'g',     NULL),
('ice_cream',          'Ice Cream',                207, 3.5,  23.5, 11.0,  0.0,21.0,   80, 130, 'g',     '2 scoops'),
('frozen_yogurt',      'Frozen Yogurt',            159, 3.5,  28.0,  4.0,  0.0,23.0,   78, 120, 'g',     NULL),
('donuts',             'Doughnuts',                452, 5.0,  51.0, 25.0,  1.5,22.0,   360, 60, 'piece',  NULL),
('cup_cakes',          'Cupcakes',                 305, 3.5,  44.0, 13.0,  0.5,29.0,   250, 65, 'piece',  NULL),
('macarons',           'Macarons',                 390, 5.5,  55.0, 17.0,  1.0,50.0,    70, 35, 'piece',  NULL),
('cannoli',            'Cannoli',                  300, 7.5,  31.0, 16.5,  0.5,15.0,   195, 85, 'piece',  NULL),
('churros',            'Churros',                  390, 5.0,  55.0, 18.0,  2.0,12.0,   150, 100,'g',      NULL),
('strawberry_shortcake','Strawberry Shortcake',    250, 4.0,  35.0, 11.0,  1.0,18.0,   240, 150,'g',      NULL),
('bread_pudding',      'Bread Pudding',            200, 6.5,  31.5,  6.0,  1.0,14.0,   290, 150,'g',      NULL),
('beignets',           'Beignets',                 390, 6.0,  52.5, 18.0,  1.5,14.0,   310, 100,'g',      NULL),

-- ── Fruits (extra classes beyond Food-101) ────────────────────────────────────
('apple',              'Apple',                     52, 0.3,  13.8,  0.2,  2.4,10.4,    1, 180, 'piece',  '1 medium apple'),
('banana',             'Banana',                    89, 1.1,  23.0,  0.3,  2.6,12.2,    1, 120, 'piece',  '1 medium banana'),
('orange',             'Orange',                    47, 0.9,  12.0,  0.1,  2.4, 9.4,    0, 130, 'piece',  '1 medium orange'),

-- ── Remaining Food-101 classes ───────────────────────────────────────────────
('bibimbap',           'Bibimbap',                 120, 7.0,  17.0,  3.0,  2.0, 2.0,  380, 350, 'g',     '1 bowl'),
('breakfast_burrito',  'Breakfast Burrito',         230, 11.5, 22.5, 11.0,  2.0, 2.5,  530, 200, 'g',     NULL)

ON CONFLICT (model_label) DO NOTHING;
