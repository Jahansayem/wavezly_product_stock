-- =====================================================================
-- Selling Cart Migration SQL
-- For Product Selling Selection Screen
-- =====================================================================
--
-- IMPORTANT: The existing sales_migration.sql already provides:
--   - sales table (sale header)
--   - sale_items table (line items)
--   - process_sale() function
--
-- This migration is OPTIONAL and only needed if you want cart persistence
-- (saving incomplete sales across sessions).
--
-- For the MVP implementation, cart is stored in local state only.
-- Execute this SQL only if you need database-backed cart persistence.
-- =====================================================================

-- =====================================================================
-- 1. SELLING_CARTS TABLE (Optional - Cart Persistence)
-- =====================================================================

-- Drop existing table if needed (use with caution in production)
-- DROP TABLE IF EXISTS selling_carts CASCADE;

CREATE TABLE IF NOT EXISTS selling_carts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  quantity INTEGER NOT NULL CHECK (quantity > 0),
  unit_price DECIMAL(10, 2) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Ensure unique product per user cart
  UNIQUE(user_id, product_id)
);

-- =====================================================================
-- 2. INDEXES for Performance
-- =====================================================================

CREATE INDEX IF NOT EXISTS idx_selling_carts_user_id ON selling_carts(user_id);
CREATE INDEX IF NOT EXISTS idx_selling_carts_product_id ON selling_carts(product_id);
CREATE INDEX IF NOT EXISTS idx_selling_carts_created_at ON selling_carts(created_at);

-- =====================================================================
-- 3. ROW LEVEL SECURITY (RLS)
-- =====================================================================

ALTER TABLE selling_carts ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only manage their own cart items
DROP POLICY IF EXISTS "Users manage own cart" ON selling_carts;
CREATE POLICY "Users manage own cart" ON selling_carts
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- =====================================================================
-- 4. TRIGGERS for Updated_at Timestamp
-- =====================================================================

-- Create trigger function if not exists
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to selling_carts
DROP TRIGGER IF EXISTS update_selling_carts_updated_at ON selling_carts;
CREATE TRIGGER update_selling_carts_updated_at
  BEFORE UPDATE ON selling_carts
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- =====================================================================
-- 5. HELPER FUNCTIONS
-- =====================================================================

-- Function: Get user's cart items with product details
CREATE OR REPLACE FUNCTION get_user_cart(p_user_id UUID)
RETURNS TABLE (
  cart_item_id UUID,
  product_id UUID,
  product_name TEXT,
  unit_price DECIMAL(10, 2),
  quantity INTEGER,
  subtotal DECIMAL(10, 2),
  stock_available INTEGER,
  product_image TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    sc.id AS cart_item_id,
    sc.product_id,
    p.name AS product_name,
    sc.unit_price,
    sc.quantity,
    (sc.unit_price * sc.quantity) AS subtotal,
    p.quantity AS stock_available,
    p.image_url AS product_image
  FROM selling_carts sc
  JOIN products p ON sc.product_id = p.id
  WHERE sc.user_id = p_user_id
  ORDER BY sc.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Add or update cart item
CREATE OR REPLACE FUNCTION upsert_cart_item(
  p_user_id UUID,
  p_product_id UUID,
  p_quantity INTEGER,
  p_unit_price DECIMAL(10, 2)
)
RETURNS UUID AS $$
DECLARE
  v_cart_item_id UUID;
BEGIN
  -- Validate product exists and has stock
  IF NOT EXISTS (SELECT 1 FROM products WHERE id = p_product_id AND quantity >= p_quantity) THEN
    RAISE EXCEPTION 'Product not available or insufficient stock';
  END IF;

  -- Insert or update cart item
  INSERT INTO selling_carts (user_id, product_id, quantity, unit_price)
  VALUES (p_user_id, p_product_id, p_quantity, p_unit_price)
  ON CONFLICT (user_id, product_id)
  DO UPDATE SET
    quantity = EXCLUDED.quantity,
    unit_price = EXCLUDED.unit_price,
    updated_at = NOW()
  RETURNING id INTO v_cart_item_id;

  RETURN v_cart_item_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Remove cart item
CREATE OR REPLACE FUNCTION remove_cart_item(
  p_user_id UUID,
  p_cart_item_id UUID
)
RETURNS BOOLEAN AS $$
BEGIN
  DELETE FROM selling_carts
  WHERE id = p_cart_item_id AND user_id = p_user_id;

  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Clear entire cart
CREATE OR REPLACE FUNCTION clear_cart(p_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  DELETE FROM selling_carts WHERE user_id = p_user_id;
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Get cart total
CREATE OR REPLACE FUNCTION get_cart_total(p_user_id UUID)
RETURNS TABLE (
  total_items INTEGER,
  total_amount DECIMAL(10, 2)
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    COALESCE(SUM(quantity)::INTEGER, 0) AS total_items,
    COALESCE(SUM(unit_price * quantity), 0) AS total_amount
  FROM selling_carts
  WHERE user_id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================================
-- 6. SAMPLE QUERIES (For Testing)
-- =====================================================================

-- Get current user's cart
-- SELECT * FROM get_user_cart(auth.uid());

-- Add item to cart
-- SELECT upsert_cart_item(
--   auth.uid(),
--   'product-uuid-here',
--   2,
--   50.00
-- );

-- Get cart total
-- SELECT * FROM get_cart_total(auth.uid());

-- Clear cart
-- SELECT clear_cart(auth.uid());

-- Remove specific item
-- SELECT remove_cart_item(auth.uid(), 'cart-item-uuid-here');

-- =====================================================================
-- 7. INTEGRATION WITH SALES (Convert Cart to Sale)
-- =====================================================================

-- Function: Convert cart to sale (uses existing process_sale)
CREATE OR REPLACE FUNCTION checkout_cart(
  p_user_id UUID,
  p_customer_id UUID DEFAULT NULL,
  p_payment_method TEXT DEFAULT 'cash',
  p_notes TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_sale_id UUID;
  v_cart_items RECORD;
  v_sale_items JSONB := '[]'::JSONB;
BEGIN
  -- Build sale items from cart
  FOR v_cart_items IN
    SELECT product_id, quantity, unit_price
    FROM selling_carts
    WHERE user_id = p_user_id
  LOOP
    v_sale_items := v_sale_items || jsonb_build_object(
      'product_id', v_cart_items.product_id,
      'quantity', v_cart_items.quantity,
      'unit_price', v_cart_items.unit_price
    );
  END LOOP;

  -- Check if cart is empty
  IF jsonb_array_length(v_sale_items) = 0 THEN
    RAISE EXCEPTION 'Cart is empty';
  END IF;

  -- Process sale using existing function (if available)
  -- INSERT INTO sales (user_id, customer_id, payment_method, notes, status)
  -- VALUES (p_user_id, p_customer_id, p_payment_method, p_notes, 'completed')
  -- RETURNING id INTO v_sale_id;

  -- Insert sale items
  -- INSERT INTO sale_items (sale_id, product_id, quantity, unit_price, subtotal)
  -- SELECT v_sale_id, product_id, quantity, unit_price, (quantity * unit_price)
  -- FROM jsonb_to_recordset(v_sale_items) AS x(
  --   product_id UUID, quantity INTEGER, unit_price DECIMAL
  -- );

  -- Clear cart after successful sale
  PERFORM clear_cart(p_user_id);

  RETURN v_sale_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================================
-- 8. CLEANUP (Optional - Use with Caution)
-- =====================================================================

-- Remove old abandoned carts (older than 7 days)
-- DELETE FROM selling_carts WHERE updated_at < NOW() - INTERVAL '7 days';

-- =====================================================================
-- END OF MIGRATION
-- =====================================================================

-- Verify tables
-- SELECT table_name FROM information_schema.tables
-- WHERE table_schema = 'public' AND table_name = 'selling_carts';

-- Verify RLS policies
-- SELECT * FROM pg_policies WHERE tablename = 'selling_carts';

-- Verify functions
-- SELECT routine_name FROM information_schema.routines
-- WHERE routine_schema = 'public'
-- AND routine_name IN ('get_user_cart', 'upsert_cart_item', 'remove_cart_item', 'clear_cart', 'get_cart_total', 'checkout_cart');
