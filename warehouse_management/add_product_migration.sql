-- ============================================================================
-- Add Product Screen - Supabase Migration
-- Run this SQL in your Supabase SQL Editor
-- ============================================================================

-- Add new columns to the products table for advanced product features

-- Online selling flag
ALTER TABLE products ADD COLUMN IF NOT EXISTS sell_online BOOLEAN DEFAULT false;

-- Wholesale settings
ALTER TABLE products ADD COLUMN IF NOT EXISTS wholesale_enabled BOOLEAN DEFAULT false;
ALTER TABLE products ADD COLUMN IF NOT EXISTS wholesale_price DECIMAL(12,2);
ALTER TABLE products ADD COLUMN IF NOT EXISTS wholesale_min_qty INTEGER;

-- Stock alert settings
ALTER TABLE products ADD COLUMN IF NOT EXISTS stock_alert_enabled BOOLEAN DEFAULT true;
ALTER TABLE products ADD COLUMN IF NOT EXISTS min_stock_level INTEGER DEFAULT 10;

-- VAT settings
ALTER TABLE products ADD COLUMN IF NOT EXISTS vat_enabled BOOLEAN DEFAULT false;
ALTER TABLE products ADD COLUMN IF NOT EXISTS vat_percent DECIMAL(5,2);

-- Warranty settings
ALTER TABLE products ADD COLUMN IF NOT EXISTS warranty_enabled BOOLEAN DEFAULT false;
ALTER TABLE products ADD COLUMN IF NOT EXISTS warranty_duration INTEGER;
ALTER TABLE products ADD COLUMN IF NOT EXISTS warranty_unit VARCHAR(10); -- 'day', 'month', 'year'

-- Discount settings
ALTER TABLE products ADD COLUMN IF NOT EXISTS discount_enabled BOOLEAN DEFAULT false;
ALTER TABLE products ADD COLUMN IF NOT EXISTS discount_value DECIMAL(12,2);
ALTER TABLE products ADD COLUMN IF NOT EXISTS discount_type VARCHAR(10); -- 'percent', 'amount'

-- Product details text
ALTER TABLE products ADD COLUMN IF NOT EXISTS details TEXT;

-- Multiple product images (array of URLs)
ALTER TABLE products ADD COLUMN IF NOT EXISTS images TEXT[];

-- ============================================================================
-- Create indexes for frequently queried columns
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_products_sell_online ON products(sell_online) WHERE sell_online = true;
CREATE INDEX IF NOT EXISTS idx_products_wholesale ON products(wholesale_enabled) WHERE wholesale_enabled = true;
CREATE INDEX IF NOT EXISTS idx_products_stock_alert ON products(stock_alert_enabled, min_stock_level);

-- ============================================================================
-- Add comments for documentation
-- ============================================================================

COMMENT ON COLUMN products.sell_online IS 'Flag to indicate if product is available for online selling';
COMMENT ON COLUMN products.wholesale_enabled IS 'Flag to enable wholesale pricing for this product';
COMMENT ON COLUMN products.wholesale_price IS 'Special price for wholesale purchases';
COMMENT ON COLUMN products.wholesale_min_qty IS 'Minimum quantity required for wholesale price';
COMMENT ON COLUMN products.stock_alert_enabled IS 'Enable low stock alerts for this product';
COMMENT ON COLUMN products.min_stock_level IS 'Stock level below which alert is triggered';
COMMENT ON COLUMN products.vat_enabled IS 'Flag to indicate if VAT applies to this product';
COMMENT ON COLUMN products.vat_percent IS 'VAT percentage for this product';
COMMENT ON COLUMN products.warranty_enabled IS 'Flag to indicate if product has warranty';
COMMENT ON COLUMN products.warranty_duration IS 'Duration of warranty period';
COMMENT ON COLUMN products.warranty_unit IS 'Unit for warranty duration: day, month, or year';
COMMENT ON COLUMN products.discount_enabled IS 'Flag to indicate if product has active discount';
COMMENT ON COLUMN products.discount_value IS 'Discount amount or percentage value';
COMMENT ON COLUMN products.discount_type IS 'Type of discount: percent or amount (fixed)';
COMMENT ON COLUMN products.details IS 'Detailed description of the product';
COMMENT ON COLUMN products.images IS 'Array of image URLs for the product';

-- ============================================================================
-- RLS Policy update (if needed)
-- Ensure users can only see/edit their own product data
-- ============================================================================

-- The existing RLS policies should already cover these new columns
-- as they operate on row-level, not column-level

-- ============================================================================
-- Verify migration
-- ============================================================================

-- Run this query to verify all columns exist:
-- SELECT column_name, data_type, column_default
-- FROM information_schema.columns
-- WHERE table_name = 'products'
-- AND column_name IN (
--   'sell_online', 'wholesale_enabled', 'wholesale_price', 'wholesale_min_qty',
--   'stock_alert_enabled', 'min_stock_level', 'vat_enabled', 'vat_percent',
--   'warranty_enabled', 'warranty_duration', 'warranty_unit',
--   'discount_enabled', 'discount_value', 'discount_type', 'details', 'images'
-- );
