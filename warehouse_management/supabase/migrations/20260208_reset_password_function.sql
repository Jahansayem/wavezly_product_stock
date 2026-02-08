-- Migration: Add reset_user_password_by_phone RPC function
-- Purpose: Allow password reset for forgot PIN flow after OTP verification
-- Security: Uses SECURITY DEFINER to run with admin privileges

-- Drop existing function if it exists
DROP FUNCTION IF EXISTS reset_user_password_by_phone(TEXT, TEXT);

-- Create the password reset function
CREATE OR REPLACE FUNCTION reset_user_password_by_phone(
  user_phone TEXT,
  new_password TEXT
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  user_email TEXT;
  user_id UUID;
  result JSON;
BEGIN
  -- Construct email from phone number (lowercase 'phone-')
  user_email := 'phone-' || user_phone || '@halkhata.app';

  -- Find user by email
  SELECT id INTO user_id
  FROM auth.users
  WHERE email = user_email
  LIMIT 1;

  -- Check if user exists
  IF user_id IS NULL THEN
    RETURN json_build_object(
      'success', false,
      'error', 'User not found'
    );
  END IF;

  -- Update password using Supabase auth admin function
  -- Note: This requires the function to run with SECURITY DEFINER
  BEGIN
    -- Update user password in auth.users table using pgcrypto from extensions schema
    UPDATE auth.users
    SET
      encrypted_password = extensions.crypt(new_password, extensions.gen_salt('bf')),
      updated_at = NOW()
    WHERE id = user_id;

    -- Return success
    RETURN json_build_object(
      'success', true,
      'email', user_email,
      'user_id', user_id
    );
  EXCEPTION
    WHEN OTHERS THEN
      RETURN json_build_object(
        'success', false,
        'error', SQLERRM
      );
  END;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION reset_user_password_by_phone(TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION reset_user_password_by_phone(TEXT, TEXT) TO anon;

-- Add comment
COMMENT ON FUNCTION reset_user_password_by_phone IS
'Resets user password by phone number for forgot PIN flow. Requires OTP verification before calling.';
