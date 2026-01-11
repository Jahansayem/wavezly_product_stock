-- =====================================================
-- Warehouse Management - Supabase Database Setup
-- =====================================================
-- Run this script in your Supabase SQL Editor
-- URL: https://ozadmtmkrkwbolzbqtif.supabase.co
-- =====================================================

-- 1. Create Products Table
-- =====================================================
CREATE TABLE IF NOT EXISTS products (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  cost DECIMAL(10, 2),
  quantity INTEGER DEFAULT 0,
  product_group TEXT NOT NULL,
  location TEXT,
  company TEXT,
  description TEXT,
  image_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_products_group ON products(product_group);
CREATE INDEX IF NOT EXISTS idx_products_name ON products(name);
CREATE INDEX IF NOT EXISTS idx_products_user_id ON products(user_id);

-- Enable Row Level Security
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- RLS Policies for Products
CREATE POLICY "Users can view their own products"
  ON products FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own products"
  ON products FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own products"
  ON products FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own products"
  ON products FOR DELETE
  USING (auth.uid() = user_id);

-- =====================================================
-- 2. Create Product Groups Table
-- =====================================================
CREATE TABLE IF NOT EXISTS product_groups (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(name, user_id)  -- Prevent duplicate group names per user
);

-- Create index
CREATE INDEX IF NOT EXISTS idx_product_groups_user_id ON product_groups(user_id);
CREATE INDEX IF NOT EXISTS idx_product_groups_name ON product_groups(name);

-- Enable Row Level Security
ALTER TABLE product_groups ENABLE ROW LEVEL SECURITY;

-- RLS Policies for Product Groups
CREATE POLICY "Users can view their own groups"
  ON product_groups FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own groups"
  ON product_groups FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own groups"
  ON product_groups FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own groups"
  ON product_groups FOR DELETE
  USING (auth.uid() = user_id);

-- =====================================================
-- 3. Create Locations Table
-- =====================================================
CREATE TABLE IF NOT EXISTS locations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(name, user_id)  -- Prevent duplicate location names per user
);

-- Create index
CREATE INDEX IF NOT EXISTS idx_locations_user_id ON locations(user_id);

-- Enable Row Level Security
ALTER TABLE locations ENABLE ROW LEVEL SECURITY;

-- RLS Policies for Locations
CREATE POLICY "Users can view their own locations"
  ON locations FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own locations"
  ON locations FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own locations"
  ON locations FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own locations"
  ON locations FOR DELETE
  USING (auth.uid() = user_id);

-- =====================================================
-- 4. Create Trigger for Auto-Update Timestamp
-- =====================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to products table
DROP TRIGGER IF EXISTS update_products_updated_at ON products;
CREATE TRIGGER update_products_updated_at
  BEFORE UPDATE ON products
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- 5. Function to Seed Default Locations for New Users
-- =====================================================
CREATE OR REPLACE FUNCTION seed_default_locations(target_user_id UUID)
RETURNS VOID AS $$
BEGIN
  -- Insert default locations if they don't exist
  INSERT INTO locations (name, user_id) VALUES
    ('Godown 1, 1st Floor', target_user_id),
    ('Godown 1, 2nd Floor', target_user_id),
    ('Godown 2, 1st Floor', target_user_id),
    ('Godown 2, 2nd Floor', target_user_id)
  ON CONFLICT (name, user_id) DO NOTHING;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 6. Optional: Create View for Product Statistics
-- =====================================================
CREATE OR REPLACE VIEW product_statistics AS
SELECT
  user_id,
  product_group,
  COUNT(*) as product_count,
  SUM(quantity) as total_quantity,
  SUM(cost * quantity) as total_value,
  AVG(cost) as average_cost
FROM products
GROUP BY user_id, product_group;

-- RLS for the view
ALTER VIEW product_statistics SET (security_invoker = true);

-- =====================================================
-- 7. Optional: Function to Get Products by Group
-- =====================================================
CREATE OR REPLACE FUNCTION get_products_by_group(group_name TEXT)
RETURNS SETOF products AS $$
BEGIN
  RETURN QUERY
  SELECT * FROM products
  WHERE product_group = group_name
    AND user_id = auth.uid()
  ORDER BY name;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 8. Optional: Function to Search Products
-- =====================================================
CREATE OR REPLACE FUNCTION search_products(search_query TEXT)
RETURNS SETOF products AS $$
BEGIN
  RETURN QUERY
  SELECT * FROM products
  WHERE (
    name ILIKE '%' || search_query || '%'
    OR company ILIKE '%' || search_query || '%'
    OR description ILIKE '%' || search_query || '%'
  )
  AND user_id = auth.uid()
  ORDER BY name;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- Setup Complete!
-- =====================================================
-- Next Steps:
-- 1. Verify all tables are created
-- 2. Test RLS policies by creating a test user
-- 3. Run: SELECT * FROM products; (should return empty initially)
-- 4. Run: SELECT * FROM product_groups;
-- 5. Run: SELECT * FROM locations;
-- =====================================================
