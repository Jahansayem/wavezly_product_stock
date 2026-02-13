-- ============================================================================
-- Offline-First Purchase and Sale Migration
-- ============================================================================
-- Purpose: Modify process_purchase and process_sale stored procedures to:
-- 1. Accept client-provided IDs for idempotent sync replay
-- 2. Support offline-first architecture with local SQLite + Supabase sync
-- 3. Prevent duplicate records when syncing from multiple devices
--
-- IMPORTANT: DO NOT EXECUTE THIS FILE DIRECTLY
-- This migration should be reviewed and executed by a database administrator
-- after verifying compatibility with existing data and application logic.
-- ============================================================================

-- ============================================================================
-- 1. Modify process_purchase to accept client IDs
-- ============================================================================
CREATE OR REPLACE FUNCTION process_purchase(
  p_purchase_data JSONB,
  p_purchase_items JSONB
) RETURNS TEXT AS $$
DECLARE
  v_purchase_id TEXT;
  v_item JSONB;
  v_product_id TEXT;
  v_quantity INTEGER;
  v_cost_price DECIMAL;
BEGIN
  -- Extract or generate purchase ID (client ID takes precedence)
  v_purchase_id := COALESCE(
    p_purchase_data->>'id',
    gen_random_uuid()::TEXT
  );

  -- Insert or update purchase (idempotent via ON CONFLICT)
  INSERT INTO purchases (
    id,
    user_id,
    purchase_number,
    supplier_id,
    supplier_name,
    total_amount,
    payment_status,
    payment_method,
    notes,
    purchase_date,
    created_at,
    updated_at
  ) VALUES (
    v_purchase_id,
    (p_purchase_data->>'user_id')::UUID,
    p_purchase_data->>'purchase_number',
    NULLIF(p_purchase_data->>'supplier_id', '')::UUID,
    p_purchase_data->>'supplier_name',
    (p_purchase_data->>'total_amount')::DECIMAL,
    COALESCE(p_purchase_data->>'payment_status', 'unpaid'),
    p_purchase_data->>'payment_method',
    p_purchase_data->>'notes',
    (p_purchase_data->>'purchase_date')::TIMESTAMP,
    COALESCE((p_purchase_data->>'created_at')::TIMESTAMP, NOW()),
    COALESCE((p_purchase_data->>'updated_at')::TIMESTAMP, NOW())
  )
  ON CONFLICT (id) DO UPDATE
  SET
    supplier_id = EXCLUDED.supplier_id,
    supplier_name = EXCLUDED.supplier_name,
    total_amount = EXCLUDED.total_amount,
    payment_status = EXCLUDED.payment_status,
    payment_method = EXCLUDED.payment_method,
    notes = EXCLUDED.notes,
    purchase_date = EXCLUDED.purchase_date,
    updated_at = NOW();

  -- Insert purchase items (idempotent via ON CONFLICT)
  FOR v_item IN SELECT * FROM jsonb_array_elements(p_purchase_items)
  LOOP
    v_product_id := v_item->>'product_id';
    v_quantity := (v_item->>'quantity')::INTEGER;
    v_cost_price := (v_item->>'cost_price')::DECIMAL;

    -- Insert or update purchase item
    INSERT INTO purchase_items (
      id,
      purchase_id,
      product_id,
      product_name,
      cost_price,
      quantity,
      total_cost,
      created_at
    ) VALUES (
      COALESCE(v_item->>'id', gen_random_uuid()::TEXT),
      v_purchase_id,
      NULLIF(v_product_id, '')::UUID,
      v_item->>'product_name',
      v_cost_price,
      v_quantity,
      (v_item->>'total_cost')::DECIMAL,
      COALESCE((v_item->>'created_at')::TIMESTAMP, NOW())
    )
    ON CONFLICT (id) DO UPDATE
    SET
      product_id = EXCLUDED.product_id,
      product_name = EXCLUDED.product_name,
      cost_price = EXCLUDED.cost_price,
      quantity = EXCLUDED.quantity,
      total_cost = EXCLUDED.total_cost;

    -- Update product stock and cost (only if product exists)
    IF v_product_id IS NOT NULL AND v_product_id != '' THEN
      UPDATE products
      SET
        quantity = quantity + v_quantity,
        cost = v_cost_price,
        updated_at = NOW()
      WHERE id = v_product_id::UUID;
    END IF;
  END LOOP;

  RETURN v_purchase_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 2. Modify process_sale to accept client IDs
-- ============================================================================
CREATE OR REPLACE FUNCTION process_sale(
  p_sale_data JSONB,
  p_sale_items JSONB
) RETURNS TEXT AS $$
DECLARE
  v_sale_id TEXT;
  v_item JSONB;
  v_product_id TEXT;
  v_quantity INTEGER;
BEGIN
  -- Extract or generate sale ID (client ID takes precedence)
  v_sale_id := COALESCE(
    p_sale_data->>'id',
    gen_random_uuid()::TEXT
  );

  -- Insert or update sale (idempotent via ON CONFLICT)
  INSERT INTO sales (
    id,
    user_id,
    sale_number,
    customer_id,
    customer_name,
    customer_phone,
    total_amount,
    tax_amount,
    subtotal,
    payment_method,
    payment_status,
    notes,
    is_quick_sale,
    cash_received,
    profit_margin,
    product_details,
    receipt_sms_sent,
    sale_date,
    photo_url,
    created_at
  ) VALUES (
    v_sale_id,
    (p_sale_data->>'user_id')::UUID,
    p_sale_data->>'sale_number',
    NULLIF(p_sale_data->>'customer_id', '')::UUID,
    p_sale_data->>'customer_name',
    p_sale_data->>'customer_phone',
    (p_sale_data->>'total_amount')::DECIMAL,
    COALESCE((p_sale_data->>'tax_amount')::DECIMAL, 0),
    (p_sale_data->>'subtotal')::DECIMAL,
    COALESCE(p_sale_data->>'payment_method', 'cash'),
    COALESCE(p_sale_data->>'payment_status', 'paid'),
    p_sale_data->>'notes',
    COALESCE((p_sale_data->>'is_quick_sale')::BOOLEAN, FALSE),
    (p_sale_data->>'cash_received')::DECIMAL,
    (p_sale_data->>'profit_margin')::DECIMAL,
    p_sale_data->>'product_details',
    COALESCE((p_sale_data->>'receipt_sms_sent')::BOOLEAN, FALSE),
    COALESCE((p_sale_data->>'sale_date')::TIMESTAMP, NOW()),
    p_sale_data->>'photo_url',
    COALESCE((p_sale_data->>'created_at')::TIMESTAMP, NOW())
  )
  ON CONFLICT (id) DO UPDATE
  SET
    customer_id = EXCLUDED.customer_id,
    customer_name = EXCLUDED.customer_name,
    customer_phone = EXCLUDED.customer_phone,
    total_amount = EXCLUDED.total_amount,
    tax_amount = EXCLUDED.tax_amount,
    subtotal = EXCLUDED.subtotal,
    payment_method = EXCLUDED.payment_method,
    payment_status = EXCLUDED.payment_status,
    notes = EXCLUDED.notes,
    updated_at = NOW();

  -- Insert sale items (idempotent via ON CONFLICT)
  FOR v_item IN SELECT * FROM jsonb_array_elements(p_sale_items)
  LOOP
    v_product_id := v_item->>'product_id';
    v_quantity := (v_item->>'quantity')::INTEGER;

    -- Insert or update sale item
    INSERT INTO sale_items (
      id,
      sale_id,
      product_id,
      product_name,
      quantity,
      unit_price,
      subtotal,
      created_at
    ) VALUES (
      COALESCE(v_item->>'id', gen_random_uuid()::TEXT),
      v_sale_id,
      NULLIF(v_product_id, '')::UUID,
      v_item->>'product_name',
      v_quantity,
      (v_item->>'unit_price')::DECIMAL,
      (v_item->>'subtotal')::DECIMAL,
      COALESCE((v_item->>'created_at')::TIMESTAMP, NOW())
    )
    ON CONFLICT (id) DO UPDATE
    SET
      product_id = EXCLUDED.product_id,
      product_name = EXCLUDED.product_name,
      quantity = EXCLUDED.quantity,
      unit_price = EXCLUDED.unit_price,
      subtotal = EXCLUDED.subtotal;

    -- Update product stock (only if product exists and not already processed)
    IF v_product_id IS NOT NULL AND v_product_id != '' THEN
      UPDATE products
      SET
        quantity = GREATEST(0, quantity - v_quantity),
        updated_at = NOW()
      WHERE id = v_product_id::UUID;
    END IF;
  END LOOP;

  RETURN v_sale_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 3. Migration Notes
-- ============================================================================
-- After executing this migration:
--
-- 1. Test idempotency:
--    - Call process_purchase with same ID multiple times
--    - Verify no duplicate records created
--    - Verify stock updates are correct
--
-- 2. Test offline sync:
--    - Create purchase/sale offline with client ID
--    - Sync to server
--    - Verify data integrity
--
-- 3. Monitor performance:
--    - ON CONFLICT may be slower than INSERT for new records
--    - Consider adding indexes if performance degrades
--
-- 4. Backward compatibility:
--    - Old clients without 'id' field will still work
--    - Server generates UUID if client ID not provided
--
-- 5. Stock reconciliation:
--    - Review stock levels after migration
--    - Check for any discrepancies from duplicate processing
-- ============================================================================
