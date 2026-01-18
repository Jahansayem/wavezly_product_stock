-- StockBookScreen Database Migration
-- Execute this in Supabase SQL Editor

-- Add icon column to products table for Material Icons mapping
ALTER TABLE products ADD COLUMN IF NOT EXISTS icon_name TEXT;

-- Create index for icon lookup
CREATE INDEX IF NOT EXISTS idx_products_icon_name ON products(icon_name);

-- Insert/Update 7 sample products matching Stitch spec
-- Note: Replace (SELECT id FROM auth.users LIMIT 1) with your actual user_id
-- You can find your user_id by running: SELECT id FROM auth.users WHERE email = 'your@email.com';

INSERT INTO products (name, name_bn, cost, quantity, product_group, icon_name, user_id)
VALUES
  ('Kinley 2L', 'Kinley 2L', 26.0, 12, 'Beverages', 'inventory_2',
   (SELECT id FROM auth.users LIMIT 1)),
  ('Kinley 500ml', 'kinley 500mili', 12.0, 24, 'Beverages', 'water_drop',
   (SELECT id FROM auth.users LIMIT 1)),
  ('Grapes', 'আঙ্গুর', 256.4, 43, 'Fruits', 'grape',
   (SELECT id FROM auth.users LIMIT 1)),
  ('Apple', 'আপেল', 127.2, 11, 'Fruits', 'apple',
   (SELECT id FROM auth.users LIMIT 1)),
  ('Mango', 'আম', 292.7, 14, 'Fruits', 'spa',
   (SELECT id FROM auth.users LIMIT 1)),
  ('Biscuit (Packet)', 'বিস্কুট (প্যাকেট)', 20.0, 56, 'Snacks', 'fastfood',
   (SELECT id FROM auth.users LIMIT 1)),
  ('Paracetamol 500mg', 'প্যারাসিটামল ৫০০মিগ্রা', 2.0, 200, 'Medicine', 'medication',
   (SELECT id FROM auth.users LIMIT 1))
ON CONFLICT (id) DO UPDATE SET
  name_bn = EXCLUDED.name_bn,
  cost = EXCLUDED.cost,
  quantity = EXCLUDED.quantity,
  icon_name = EXCLUDED.icon_name;

-- Verification query
SELECT name, name_bn, cost, quantity, icon_name,
       (cost * quantity) as total_value
FROM products
WHERE icon_name IS NOT NULL
ORDER BY id;
