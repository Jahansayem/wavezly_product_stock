-- SQL Schema for GIVE Due Transactions
-- Run this in Supabase SQL Editor

-- Add additional columns to customer_transactions table for GIVE functionality
ALTER TABLE customer_transactions 
ADD COLUMN IF NOT EXISTS transaction_subtype VARCHAR(20) DEFAULT 'manual',
ADD COLUMN IF NOT EXISTS attachment_url TEXT,
ADD COLUMN IF NOT EXISTS sms_cost DECIMAL(8,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS reference_id TEXT;

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_customer_transactions_subtype 
ON customer_transactions(transaction_subtype);

-- Drop existing functions first to avoid conflicts (all possible signatures)
DROP FUNCTION IF EXISTS record_give_due_transaction CASCADE;
DROP FUNCTION IF EXISTS record_take_due_transaction CASCADE;
DROP FUNCTION IF EXISTS get_due_transaction_summary CASCADE;

-- Create function to record GIVE due transaction (customer owes MORE money)
CREATE OR REPLACE FUNCTION record_give_due_transaction(
    p_customer_id UUID,
    p_amount DECIMAL(10,2),
    p_note TEXT DEFAULT '',
    p_transaction_date DATE DEFAULT CURRENT_DATE,
    p_sms_enabled BOOLEAN DEFAULT FALSE,
    p_attachment_url TEXT DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    v_user_id UUID;
    v_transaction_id UUID;
    v_old_due DECIMAL(10,2);
    v_new_due DECIMAL(10,2);
    v_customer_phone TEXT;
    v_customer_name TEXT;
    v_sms_log_id UUID;
    v_sms_cost DECIMAL(8,2) := 30.00; -- SMS cost in BDT
    v_result JSON;
BEGIN
    -- Get current user ID
    v_user_id := auth.uid();
    
    -- Validate user is authenticated
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not authenticated';
    END IF;
    
    -- Validate amount is positive
    IF p_amount <= 0 THEN
        RAISE EXCEPTION 'Amount must be greater than zero';
    END IF;
    
    -- Get customer details and current due amount
    SELECT total_due, phone, name 
    INTO v_old_due, v_customer_phone, v_customer_name
    FROM customers 
    WHERE id = p_customer_id AND user_id = v_user_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Customer not found or access denied';
    END IF;
    
    -- Calculate new due amount (GIVE = customer owes MORE money)
    v_new_due := v_old_due + p_amount;
    
    -- Insert GIVE transaction record
    INSERT INTO customer_transactions (
        customer_id,
        user_id,
        transaction_type,
        amount,
        description,
        transaction_date,
        sms_enabled,
        transaction_subtype,
        attachment_url,
        sms_cost,
        created_at
    ) VALUES (
        p_customer_id,
        v_user_id,
        'debit',  -- GIVE = customer owes more (debit increases customer debt)
        p_amount,
        COALESCE(NULLIF(p_note, ''), 'Money given to ' || v_customer_name),
        p_transaction_date,
        p_sms_enabled,
        'give_due',
        p_attachment_url,
        CASE WHEN p_sms_enabled THEN v_sms_cost ELSE 0 END,
        NOW()
    ) RETURNING id INTO v_transaction_id;
    
    -- Update customer's total due amount
    UPDATE customers 
    SET 
        total_due = v_new_due,
        last_transaction_date = p_transaction_date,
        updated_at = NOW()
    WHERE id = p_customer_id AND user_id = v_user_id;
    
    -- If SMS is enabled and customer has phone number, create SMS log entry
    IF p_sms_enabled AND v_customer_phone IS NOT NULL AND v_customer_phone != '' THEN
        INSERT INTO sms_logs (
            user_id,
            customer_id,
            transaction_id,
            phone_number,
            message,
            status,
            cost_amount,
            created_at
        ) VALUES (
            v_user_id,
            p_customer_id,
            v_transaction_id,
            v_customer_phone,
            'প্রিয় ' || v_customer_name || ', আপনি ৳' || p_amount || ' টাকা বাকি নিয়েছেন। মোট বাকি: ৳' || v_new_due || '। ধন্যবাদ।',
            'pending',
            v_sms_cost,
            NOW()
        ) RETURNING id INTO v_sms_log_id;
    END IF;
    
    -- Prepare result JSON
    v_result := json_build_object(
        'success', true,
        'transaction_id', v_transaction_id,
        'transaction_type', 'give_due',
        'old_due', v_old_due,
        'new_due', v_new_due,
        'amount_given', p_amount,
        'sms_log_id', v_sms_log_id,
        'sms_cost', CASE WHEN p_sms_enabled THEN v_sms_cost ELSE 0 END,
        'message', 'GIVE due transaction recorded successfully - customer now owes more'
    );
    
    RETURN v_result;
    
EXCEPTION
    WHEN OTHERS THEN
        -- Return error details
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM,
            'message', 'Failed to record GIVE due transaction'
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to record TAKE due transaction (customer owes LESS money)
CREATE OR REPLACE FUNCTION record_take_due_transaction(
    p_customer_id UUID,
    p_amount DECIMAL(10,2),
    p_note TEXT DEFAULT '',
    p_transaction_date DATE DEFAULT CURRENT_DATE,
    p_sms_enabled BOOLEAN DEFAULT FALSE,
    p_attachment_url TEXT DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    v_user_id UUID;
    v_transaction_id UUID;
    v_old_due DECIMAL(10,2);
    v_new_due DECIMAL(10,2);
    v_customer_phone TEXT;
    v_customer_name TEXT;
    v_sms_log_id UUID;
    v_sms_cost DECIMAL(8,2) := 30.00; -- SMS cost in BDT
    v_result JSON;
BEGIN
    -- Get current user ID
    v_user_id := auth.uid();
    
    -- Validate user is authenticated
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not authenticated';
    END IF;
    
    -- Validate amount is positive
    IF p_amount <= 0 THEN
        RAISE EXCEPTION 'Amount must be greater than zero';
    END IF;
    
    -- Get customer details and current due amount
    SELECT total_due, phone, name 
    INTO v_old_due, v_customer_phone, v_customer_name
    FROM customers 
    WHERE id = p_customer_id AND user_id = v_user_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Customer not found or access denied';
    END IF;
    
    -- Calculate new due amount (TAKE = customer owes LESS money)
    v_new_due := v_old_due - p_amount;
    
    -- Insert TAKE transaction record
    INSERT INTO customer_transactions (
        customer_id,
        user_id,
        transaction_type,
        amount,
        description,
        transaction_date,
        sms_enabled,
        transaction_subtype,
        attachment_url,
        sms_cost,
        created_at
    ) VALUES (
        p_customer_id,
        v_user_id,
        'credit',  -- TAKE = customer owes less (credit reduces customer debt)
        -p_amount,  -- Negative amount for credit
        COALESCE(NULLIF(p_note, ''), 'Money received from ' || v_customer_name),
        p_transaction_date,
        p_sms_enabled,
        'take_due',
        p_attachment_url,
        CASE WHEN p_sms_enabled THEN v_sms_cost ELSE 0 END,
        NOW()
    ) RETURNING id INTO v_transaction_id;
    
    -- Update customer's total due amount
    UPDATE customers 
    SET 
        total_due = v_new_due,
        last_transaction_date = p_transaction_date,
        updated_at = NOW()
    WHERE id = p_customer_id AND user_id = v_user_id;
    
    -- If SMS is enabled and customer has phone number, create SMS log entry
    IF p_sms_enabled AND v_customer_phone IS NOT NULL AND v_customer_phone != '' THEN
        INSERT INTO sms_logs (
            user_id,
            customer_id,
            transaction_id,
            phone_number,
            message,
            status,
            cost_amount,
            created_at
        ) VALUES (
            v_user_id,
            p_customer_id,
            v_transaction_id,
            v_customer_phone,
            'প্রিয় ' || v_customer_name || ', আপনার ৳' || p_amount || ' টাকা পেমেন্ট গৃহীত হয়েছে। বর্তমান বাকি: ৳' || v_new_due || '। ধন্যবাদ।',
            'pending',
            v_sms_cost,
            NOW()
        ) RETURNING id INTO v_sms_log_id;
    END IF;
    
    -- Prepare result JSON
    v_result := json_build_object(
        'success', true,
        'transaction_id', v_transaction_id,
        'transaction_type', 'take_due',
        'old_due', v_old_due,
        'new_due', v_new_due,
        'amount_received', p_amount,
        'sms_log_id', v_sms_log_id,
        'sms_cost', CASE WHEN p_sms_enabled THEN v_sms_cost ELSE 0 END,
        'message', 'TAKE due transaction recorded successfully - customer now owes less'
    );
    
    RETURN v_result;
    
EXCEPTION
    WHEN OTHERS THEN
        -- Return error details
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM,
            'message', 'Failed to record TAKE due transaction'
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to get due transaction summary
CREATE OR REPLACE FUNCTION get_due_transaction_summary(
    p_start_date DATE DEFAULT NULL,
    p_end_date DATE DEFAULT NULL
)
RETURNS TABLE (
    total_given DECIMAL(10,2),
    total_received DECIMAL(10,2),
    net_amount DECIMAL(10,2),
    transaction_count INTEGER,
    sms_cost_total DECIMAL(10,2)
) AS $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Get current user ID
    v_user_id := auth.uid();
    
    -- Validate user is authenticated
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not authenticated';
    END IF;
    
    -- Set default dates if not provided
    IF p_start_date IS NULL THEN
        p_start_date := CURRENT_DATE - INTERVAL '30 days';
    END IF;
    
    IF p_end_date IS NULL THEN
        p_end_date := CURRENT_DATE;
    END IF;
    
    -- Return summary
    RETURN QUERY
    SELECT 
        COALESCE(SUM(CASE WHEN ct.transaction_subtype = 'give_due' THEN ct.amount ELSE 0 END), 0) as total_given,
        COALESCE(SUM(CASE WHEN ct.transaction_subtype = 'take_due' THEN ABS(ct.amount) ELSE 0 END), 0) as total_received,
        COALESCE(SUM(CASE WHEN ct.transaction_subtype = 'give_due' THEN ct.amount ELSE -ABS(ct.amount) END), 0) as net_amount,
        COUNT(*)::INTEGER as transaction_count,
        COALESCE(SUM(ct.sms_cost), 0) as sms_cost_total
    FROM customer_transactions ct
    WHERE 
        ct.user_id = v_user_id
        AND ct.transaction_subtype IN ('give_due', 'take_due')
        AND ct.transaction_date >= p_start_date
        AND ct.transaction_date <= p_end_date;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION record_give_due_transaction TO authenticated;
GRANT EXECUTE ON FUNCTION record_take_due_transaction TO authenticated;
GRANT EXECUTE ON FUNCTION get_due_transaction_summary TO authenticated;

-- Create helpful views for reporting
CREATE OR REPLACE VIEW customer_due_summary AS
SELECT 
    c.id,
    c.name,
    c.phone,
    c.total_due,
    c.last_transaction_date,
    COUNT(ct.id) as transaction_count,
    COALESCE(SUM(CASE WHEN ct.transaction_subtype = 'give_due' THEN ct.amount ELSE 0 END), 0) as total_given,
    COALESCE(SUM(CASE WHEN ct.transaction_subtype = 'take_due' THEN ABS(ct.amount) ELSE 0 END), 0) as total_received,
    COALESCE(MAX(ct.created_at), c.created_at) as last_activity
FROM customers c
LEFT JOIN customer_transactions ct ON c.id = ct.customer_id 
    AND ct.transaction_subtype IN ('give_due', 'take_due')
WHERE c.user_id = auth.uid()
GROUP BY c.id, c.name, c.phone, c.total_due, c.last_transaction_date, c.created_at
ORDER BY c.total_due DESC;

-- Add helpful comments
COMMENT ON FUNCTION record_give_due_transaction IS 'Records GIVE due transaction - increases customer debt (you give money to customer)';
COMMENT ON FUNCTION record_take_due_transaction IS 'Records TAKE due transaction - decreases customer debt (customer pays you back)';
COMMENT ON FUNCTION get_due_transaction_summary IS 'Gets summary of GIVE/TAKE transactions for a date range';
COMMENT ON VIEW customer_due_summary IS 'Summary view of customer dues with transaction counts';

-- Sample usage:
/*
-- Record GIVE due (customer owes MORE money):
SELECT record_give_due_transaction(
    'customer-uuid-here',
    1000.00,
    'Monthly advance',
    CURRENT_DATE,
    true,
    'path/to/receipt.jpg'
);

-- Record TAKE due (customer owes LESS money):  
SELECT record_take_due_transaction(
    'customer-uuid-here',
    500.00,
    'Partial payment received',
    CURRENT_DATE,
    true
);

-- Get transaction summary:
SELECT * FROM get_due_transaction_summary('2025-01-01', '2025-01-31');

-- Get customer due summary:
SELECT * FROM customer_due_summary WHERE total_due > 0;
*/