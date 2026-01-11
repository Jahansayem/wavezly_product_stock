-- SQL Schema for Give Due Functionality
-- Run this in Supabase SQL Editor

-- Ensure the customer_transactions table exists and has proper structure
-- This extends the existing table to support give due functionality

-- Add columns to customer_transactions if not exists
ALTER TABLE customer_transactions 
ADD COLUMN IF NOT EXISTS transaction_date DATE DEFAULT CURRENT_DATE,
ADD COLUMN IF NOT EXISTS sms_enabled BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS image_url TEXT,
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Create index for better query performance
CREATE INDEX IF NOT EXISTS idx_customer_transactions_customer_date 
ON customer_transactions(customer_id, transaction_date DESC);

CREATE INDEX IF NOT EXISTS idx_customer_transactions_type 
ON customer_transactions(transaction_type);

-- Create trigger to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_customer_transaction_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_customer_transaction_timestamp
    BEFORE UPDATE ON customer_transactions
    FOR EACH ROW
    EXECUTE FUNCTION update_customer_transaction_timestamp();

-- Create SMS logs table for tracking SMS reminders
CREATE TABLE IF NOT EXISTS sms_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    transaction_id UUID REFERENCES customer_transactions(id) ON DELETE SET NULL,
    phone_number TEXT NOT NULL,
    message TEXT NOT NULL,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'failed')),
    cost_amount DECIMAL(10,2) DEFAULT 0,
    sent_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    error_message TEXT
);

-- Create indexes for SMS logs
CREATE INDEX IF NOT EXISTS idx_sms_logs_user_id ON sms_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_sms_logs_customer_id ON sms_logs(customer_id);
CREATE INDEX IF NOT EXISTS idx_sms_logs_status ON sms_logs(status);
CREATE INDEX IF NOT EXISTS idx_sms_logs_created_at ON sms_logs(created_at DESC);

-- Enable Row Level Security (RLS)
ALTER TABLE sms_logs ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for SMS logs
CREATE POLICY "Users can view their own SMS logs" ON sms_logs
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own SMS logs" ON sms_logs
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own SMS logs" ON sms_logs
    FOR UPDATE USING (auth.uid() = user_id);

-- Create function to record give due transaction
CREATE OR REPLACE FUNCTION record_give_due_transaction(
    p_customer_id UUID,
    p_amount DECIMAL(10,2),
    p_note TEXT DEFAULT '',
    p_transaction_date DATE DEFAULT CURRENT_DATE,
    p_sms_enabled BOOLEAN DEFAULT FALSE
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
    
    -- Calculate new due amount (positive amount means customer owes more)
    v_new_due := v_old_due + p_amount;
    
    -- Insert transaction record
    INSERT INTO customer_transactions (
        customer_id,
        user_id,
        transaction_type,
        amount,
        description,
        transaction_date,
        sms_enabled,
        created_at
    ) VALUES (
        p_customer_id,
        v_user_id,
        'debit',  -- Customer owes more money
        p_amount,
        COALESCE(NULLIF(p_note, ''), 'Given to ' || v_customer_name),
        p_transaction_date,
        p_sms_enabled,
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
            'Dear ' || v_customer_name || ', you have received ৳' || p_amount || ' as due. Total due: ৳' || v_new_due || '. Thank you.',
            'pending',
            30, -- SMS cost in currency units
            NOW()
        ) RETURNING id INTO v_sms_log_id;
    END IF;
    
    -- Prepare result JSON
    v_result := json_build_object(
        'success', true,
        'transaction_id', v_transaction_id,
        'old_due', v_old_due,
        'new_due', v_new_due,
        'amount_given', p_amount,
        'sms_log_id', v_sms_log_id,
        'message', 'Give due transaction recorded successfully'
    );
    
    RETURN v_result;
    
EXCEPTION
    WHEN OTHERS THEN
        -- Return error details
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM,
            'message', 'Failed to record give due transaction'
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION record_give_due_transaction TO authenticated;

-- Create function to get due transaction history
CREATE OR REPLACE FUNCTION get_customer_due_history(
    p_customer_id UUID,
    p_start_date DATE DEFAULT NULL,
    p_end_date DATE DEFAULT NULL,
    p_limit INTEGER DEFAULT 50
)
RETURNS TABLE (
    transaction_id UUID,
    transaction_type TEXT,
    amount DECIMAL(10,2),
    description TEXT,
    transaction_date DATE,
    sms_enabled BOOLEAN,
    created_at TIMESTAMP WITH TIME ZONE
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
    
    -- Return transaction history
    RETURN QUERY
    SELECT 
        ct.id,
        ct.transaction_type,
        ct.amount,
        ct.description,
        ct.transaction_date,
        ct.sms_enabled,
        ct.created_at
    FROM customer_transactions ct
    WHERE 
        ct.customer_id = p_customer_id 
        AND ct.user_id = v_user_id
        AND (p_start_date IS NULL OR ct.transaction_date >= p_start_date)
        AND (p_end_date IS NULL OR ct.transaction_date <= p_end_date)
    ORDER BY ct.created_at DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_customer_due_history TO authenticated;

-- Add helpful comments
COMMENT ON FUNCTION record_give_due_transaction IS 'Records a give due transaction and optionally creates SMS log';
COMMENT ON FUNCTION get_customer_due_history IS 'Gets customer transaction history with optional date filtering';
COMMENT ON TABLE sms_logs IS 'Tracks SMS reminders sent to customers';

-- Sample usage comments
/*
-- To record a give due transaction:
SELECT record_give_due_transaction(
    'customer-uuid-here',
    500.00,
    'Monthly due payment',
    CURRENT_DATE,
    true
);

-- To get customer transaction history:
SELECT * FROM get_customer_due_history(
    'customer-uuid-here',
    '2025-01-01'::DATE,
    '2025-01-31'::DATE,
    25
);
*/