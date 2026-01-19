CREATE TABLE auction_items (
    item_id SERIAL PRIMARY KEY,
    item_name  TEXT NOT NULL,
    item_type  TEXT NOT NULL,
    rarity     TEXT NOT NULL,
    item_level INT NOT NULL,
    stackable BOOLEAN NOT NULL DEFAULT false,
    max_stack INT,
    UNIQUE (item_name, item_level, rarity)
);

CREATE TABLE auction_listings (
    listing_id  SERIAL PRIMARY KEY,
    item_id     INT NOT NULL REFERENCES auction_items(item_id),
    seller_name TEXT NOT NULL,
    quantity    INT NOT NULL DEFAULT 1 CHECK (quantity > 0),
    unit_price  INT NOT NULL CHECK (unit_price >= 0),
    created_at  TIMESTAMP NOT NULL DEFAULT NOW(),
    expires_at  TIMESTAMP NOT NULL,
    status      TEXT NOT NULL DEFAULT 'active'
);

SELECT *
FROM auction_listings;

CREATE TABLE item_types (
    item_type_id SERIAL PRIMARY KEY,
    type_name    TEXT UNIQUE NOT NULL
);

CREATE TABLE rarities (
    rarity_id   SERIAL PRIMARY KEY,
    rarity_name TEXT UNIQUE NOT NULL
);

INSERT INTO item_types (type_name) VALUES
('weapon'),
('trinket'),
('gem'),
('armor'),
('consumable'),
('material'),
('recipe'),
('mount');

INSERT INTO rarities (rarity_name) VALUES
('common'),
('uncommon'),
('rare'),
('epic'),
('legendary');

INSERT INTO auction_items
(item_name, item_type, rarity, item_level, stackable, max_stack)
VALUES
-- Weapons
('Ashen Longsword',           'weapon',     'epic',      42, false, NULL),
('Frostbite Dagger',          'weapon',     'rare',      28, false, NULL),
('Oakbound Greatbow',         'weapon',     'uncommon',  18, false, NULL),

-- Trinkets
('Band of the Fox',           'trinket',    'legendary', 55, false, NULL),
('Charm of Quick Hands',      'trinket',    'rare',      33, false, NULL),
('Worn Lucky Coin',           'trinket',    'common',     5, false, NULL),

-- Gems (stackable)
('Ruby of Swiftness',         'gem',        'rare',      30, true,  20),
('Sapphire of Insight',       'gem',        'uncommon',  20, true,  20),
('Onyx Shard',                'gem',        'common',    10, true,  50),

-- Armor
('Ironhide Helm',             'armor',      'uncommon',  16, false, NULL),
('Shadowweave Cloak',         'armor',      'epic',      44, false, NULL),
('Traveler''s Leather Boots',  'armor',      'common',     8, false, NULL),

-- Consumables (stackable)
('Healing Potion',            'consumable', 'common',    12, true,  20),
('Greater Healing Potion',    'consumable', 'uncommon',  25, true,  20),
('Elixir of Battle Focus',    'consumable', 'rare',      40, true,  10),

-- Materials (stackable)
('Iron Ore',                  'material',   'common',    10, true,  200),
('Enchanted Thread',          'material',   'uncommon',  22, true,  100),
('Phoenix Ash',               'material',   'epic',      50, true,  25),

-- Recipes
('Recipe: Ember Stew',        'recipe',     'uncommon',  15, false, NULL),
('Recipe: Kingsbread',        'recipe',     'rare',      35, false, NULL),

-- Mount
('Whistle of the Dune Strider','mount',     'legendary', 60, false, NULL);

SELECT *
FROM auction_items;

SELECT *
FROM item_types;

INSERT INTO auction_listings
(item_id, seller_name, quantity, unit_price, expires_at, status)
SELECT
  ai.item_id,
  sellers.seller_name,
  CASE WHEN ai.stackable THEN qty.qty ELSE 1 END AS quantity,
  prices.unit_price,
  NOW() + (exp.hours || ' hours')::interval AS expires_at,
  'active'
FROM auction_items ai
CROSS JOIN LATERAL (SELECT (ARRAY['Jeremy','Aldric','Mira','Thorne','Vexa','Karn','Sable','Nyx'])[
  1 + floor(random()*8)::int
] AS seller_name) sellers -- Picks a random name from the array
CROSS JOIN LATERAL (SELECT (ARRAY[1,2,3,5,10,15,20,25,50,100])[
  1 + floor(random()*10)::int
] AS qty) qty -- Picks a random quantity from the array
CROSS JOIN LATERAL (SELECT (50 + floor(random()*950))::int AS unit_price) prices
CROSS JOIN LATERAL (SELECT (6 + floor(random()*72))::int AS hours) exp
LIMIT 40;

SELECT *
FROM rarities;

ALTER TABLE auction_items
    ADD COLUMN item_type_id INT,
    ADD COLUMN rarity_id INT;

UPDATE auction_items ai
SET item_type_id = it.item_type_id
FROM item_types it
WHERE ai.item_type = it.type_name;

UPDATE auction_items ai
SET rarity_id = r.rarity_id
FROM rarities r
WHERE ai.rarity = r.rarity_name;

SELECT *
FROM auction_items
WHERE item_type_id IS NULL OR rarity_id IS NULL;

ALTER TABLE auction_items
  ALTER COLUMN item_type_id SET NOT NULL,
  ALTER COLUMN rarity_id SET NOT NULL;

ALTER TABLE auction_items
  ADD CONSTRAINT fk_item_type
    FOREIGN KEY (item_type_id) REFERENCES item_types(item_type_id),
  ADD CONSTRAINT fk_rarity
    FOREIGN KEY (rarity_id) REFERENCES rarities(rarity_id);

ALTER TABLE auction_items
  DROP COLUMN item_type,
  DROP COLUMN rarity;

ALTER TABLE auction_items
  DROP CONSTRAINT IF EXISTS auction_items_item_name_item_level_rarity_key;

ALTER TABLE auction_items
  ADD CONSTRAINT auction_items_unique_item
  UNIQUE (item_name, item_level, rarity_id);

INSERT INTO auction_items (item_name, item_type_id, rarity_id, item_level, stackable, max_stack)
SELECT
  'Ashen Longsword',
  it.item_type_id,
  r.rarity_id,
  42,
  false,
  NULL
FROM item_types it
JOIN rarities r ON r.rarity_name = 'epic'
WHERE it.type_name = 'weapon'
ON CONFLICT ON CONSTRAINT auction_items_unique_item DO NOTHING;

SELECT
  al.listing_id,
  al.seller_name,
  ai.item_name,
  it.type_name   AS item_type,
  r.rarity_name  AS rarity,
  ai.item_level,
  al.quantity,
  al.unit_price,
  al.expires_at,
  al.status
FROM auction_listings al
JOIN auction_items ai ON ai.item_id = al.item_id
JOIN item_types it ON it.item_type_id = ai.item_type_id
JOIN rarities r ON r.rarity_id = ai.rarity_id
ORDER BY al.created_at DESC;

TRUNCATE TABLE auction_listings RESTART IDENTITY;

-- then run the seeding INSERT


INSERT INTO auction_listings (item_id, seller_name, quantity, unit_price, expires_at, status)
SELECT
  ai.item_id,
  (ARRAY['Jeremy','Aldric','Mira','Thorne','Vexa','Karn','Sable','Nyx'])[
    1 + floor(random()*8)::int
  ] AS seller_name,
  CASE
    WHEN ai.stackable THEN (ARRAY[1,2,3,5,10,15,20,25,50,100])[
      1 + floor(random()*10)::int
    ]
    ELSE 1
  END AS quantity,
  (50 + floor(random()*950))::int AS unit_price,
  NOW() + ((6 + floor(random()*72))::int || ' hours')::interval AS expires_at,
  'active' AS status
FROM auction_items ai
ORDER BY random()
LIMIT 40;

SELECT
  al.listing_id,
  al.seller_name,
  ai.item_name,
  it.type_name   AS item_type,
  r.rarity_name  AS rarity,
  ai.item_level,
  al.quantity,
  al.unit_price,
  al.expires_at,
  al.status
FROM auction_listings al
JOIN auction_items ai ON ai.item_id = al.item_id
JOIN item_types it ON it.item_type_id = ai.item_type_id
JOIN rarities r ON r.rarity_id = ai.rarity_id
ORDER BY al.created_at DESC;

ALTER TABLE rarities
ADD COLUMN price_multiplier NUMERIC(6,2) NOT NULL DEFAULT 1.00;

UPDATE rarities
SET price_multiplier = CASE rarity_name
  WHEN 'common'    THEN 1.00
  WHEN 'uncommon'  THEN 1.40
  WHEN 'rare'      THEN 2.10
  WHEN 'epic'      THEN 3.50
  WHEN 'legendary' THEN 6.00
  ELSE 1.00
END;

INSERT INTO auction_listings (item_id, seller_name, quantity, unit_price, expires_at, status)
SELECT
  ai.item_id,
  (ARRAY['Jeremy','Aldric','Mira','Thorne','Vexa','Karn','Sable','Nyx'])[
    1 + floor(random()*8)::int
  ] AS seller_name,

  CASE
    WHEN ai.stackable THEN (ARRAY[1,2,3,5,10,15,20,25,50,100])[
      1 + floor(random()*10)::int
    ]
    ELSE 1
  END AS quantity,

  -- 💰 base price grows with item_level + rarity multiplier + market noise
  GREATEST(
    1,
    ROUND(
      (10 + ai.item_level * 4)                 -- base by level
      * r.price_multiplier                     -- rarity boost
      * (0.80 + random() * 0.60)               -- noise: 0.80x to 1.40x
    )::int
  ) AS unit_price,

  NOW() + ((6 + floor(random()*72))::int || ' hours')::interval AS expires_at,
  'active' AS status
FROM auction_items ai
JOIN rarities r ON r.rarity_id = ai.rarity_id
ORDER BY random()
LIMIT 40;

SELECT
  r.rarity_name,
  ROUND(AVG(al.unit_price)) AS avg_unit_price,
  COUNT(*) AS listings
FROM auction_listings al
JOIN auction_items ai ON ai.item_id = al.item_id
JOIN rarities r ON r.rarity_id = ai.rarity_id
GROUP BY r.rarity_name
ORDER BY avg_unit_price;
