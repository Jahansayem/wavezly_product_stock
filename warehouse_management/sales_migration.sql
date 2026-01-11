-- Sales Migration SQL
-- Run this in Supabase SQL Editor to create sales tables and functions

-- Sales table
CREATE TABLE IF NOT EXISTS sales (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  sale_number TEXT NOT NULL,
  total_amount DECIMAL(10, 2) NOT NULL,
  tax_amount DECIMAL(10, 2) DEFAULT 0,
  subtotal DECIMAL(10, 2) NOT NULL,
  customer_name TEXT DEFAULT 'Walk-in Customer',
  customer_phone TEXT,
  payment_method TEXT DEFAULT 'cash',
  payment_status TEXT DEFAULT 'paid',
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  UNIQUE(sale_number, user_id)
);

CREATE INDEX idx_sales_user_id ON sales(user_id);
CREATE INDEX idx_sales_created_at ON sales(created_at DESC);

-- Sale items table
CREATE TABLE IF NOT EXISTS sale_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  sale_id UUID NOT NULL REFERENCES sales(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id),
  product_name TEXT NOT NULL,
  quantity INTEGER NOT NULL CHECK (quantity > 0),
  unit_price DECIMAL(10, 2) NOT NULL,
  subtotal DECIMAL(10, 2) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_sale_items_sale_id ON sale_items(sale_id);

-- Add barcode to products table
ALTER TABLE products ADD COLUMN IF NOT EXISTS barcode TEXT;
CREATE INDEX IF NOT EXISTS idx_products_barcode ON products(barcode);

-- Enable RLS on sales and sale_items
ALTER TABLE sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE sale_items ENABLE ROW LEVEL SECURITY;

-- RLS Policies for sales
CREATE POLICY "Users view own sales" ON sales FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users insert own sales" ON sales FOR INSERT WITH CHECK (auth.uid() = user_id);

-- RLS Policies for sale_items
CREATE POLICY "Users view own sale_items" ON sale_items FOR SELECT
  USING (EXISTS (SELECT 1 FROM sales WHERE sales.id = sale_items.sale_id AND sales.user_id = auth.uid()));

CREATE POLICY "Users insert own sale_items" ON sale_items FOR INSERT
  WITH CHECK (EXISTS (SELECT 1 FROM sales WHERE sales.id = sale_items.sale_id AND sales.user_id = auth.uid()));

-- Function to generate unique sale numbers
CREATE OR REPLACE FUNCTION generate_sale_number()
RETURNS TEXT AS $$
DECLARE
  v_date TEXT;
  v_count INT;
BEGIN
  v_date := TO_CHAR(NOW(), 'YYYYMMDD');
  SELECT COUNT(*) INTO v_count FROM sales
  WHERE user_id = auth.uid() AND DATE(created_at) = CURRENT_DATE;
  RETURN 'SALE-' || v_date || '-' || LPAD((v_count + 1)::TEXT, 4, '0');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to process sale with inventory deduction
CREATE OR REPLACE FUNCTION process_sale(
  p_sale_data JSONB,
  p_sale_items JSONB[]
) RETURNS UUID AS $$
DECLARE
  v_sale_id UUID;
  v_item JSONB;
  v_product_id UUID;
  v_quantity INT;
BEGIN
  -- Insert sale record
  INSERT INTO sales (
    sale_number, total_amount, tax_amount, subtotal,
    customer_name, payment_method, user_id
  ) VALUES (
    p_sale_data->>'sale_number',
    (p_sale_data->>'total_amount')::DECIMAL,
    (p_sale_data->>'tax_amount')::DECIMAL,
    (p_sale_data->>'subtotal')::DECIMAL,
    p_sale_data->>'customer_name',
    p_sale_data->>'payment_method',
    auth.uid()
  ) RETURNING id INTO v_sale_id;

  -- Process each sale item
  FOREACH v_item IN ARRAY p_sale_items LOOP
    v_product_id := (v_item->>'product_id')::UUID;
    v_quantity := (v_item->>'quantity')::INT;

    -- Insert sale item
    INSERT INTO sale_items (
      sale_id, product_id, product_name, quantity, unit_price, subtotal
    ) VALUES (
      v_sale_id, v_product_id, v_item->>'product_name',
      v_quantity, (v_item->>'unit_price')::DECIMAL, (v_item->>'subtotal')::DECIMAL
    );

    -- Deduct from inventory
    UPDATE products SET quantity = quantity - v_quantity
    WHERE id = v_product_id AND user_id = auth.uid() AND quantity >= v_quantity;

    -- Check if update affected any rows (sufficient stock check)
    IF NOT FOUND THEN
      RAISE EXCEPTION 'Insufficient stock for product %', v_item->>'product_name';
    END IF;
  END LOOP;

  RETURN v_sale_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
