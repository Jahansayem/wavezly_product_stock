-- Function: verify_pin_by_phone
-- Purpose: Verify user PIN by phone number without requiring authentication
-- Security: SECURITY DEFINER allows bypassing RLS policies
-- Returns: User info if PIN matches, error if not

CREATE OR REPLACE FUNCTION verify_pin_by_phone(
  phone_number TEXT,
  input_pin_hash TEXT
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER -- Bypass RLS, run with function owner's privileges
SET search_path = public, auth
AS $$
DECLARE
  user_record RECORD;
  stored_pin_hash TEXT;
  user_email TEXT;
BEGIN
  -- Construct email from phone number
  user_email := 'phone-' || phone_number || '@halkhata.app';

  -- Find user by email in auth.users
  SELECT id, email INTO user_record
  FROM auth.users
  WHERE email = user_email
  LIMIT 1;

  -- Check if user exists
  IF user_record.id IS NULL THEN
    RETURN json_build_object(
      'success', false,
      'error', 'User not found'
    );
  END IF;

  -- Get stored PIN hash from user_security
  SELECT pin_hash INTO stored_pin_hash
  FROM user_security
  WHERE user_id = user_record.id
  LIMIT 1;

  -- Check if PIN hash exists
  IF stored_pin_hash IS NULL THEN
    RETURN json_build_object(
      'success', false,
      'error', 'PIN not set'
    );
  END IF;

  -- Compare PIN hashes
  IF stored_pin_hash = input_pin_hash THEN
    -- PIN matches - return user info
    RETURN json_build_object(
      'success', true,
      'user_id', user_record.id,
      'email', user_record.email
    );
  ELSE
    -- PIN doesn't match
    RETURN json_build_object(
      'success', false,
      'error', 'Invalid PIN'
    );
  END IF;
END;
$$;

-- Grant execute permission to authenticated and anon users
GRANT EXECUTE ON FUNCTION verify_pin_by_phone(TEXT, TEXT) TO authenticated, anon;

-- Add comment
COMMENT ON FUNCTION verify_pin_by_phone IS 'Verify user PIN by phone number without requiring authentication. Returns user info if PIN matches.';
