-- OneSignal Push Notifications Schema
-- Creates announcements tables and stock alert trigger

-- ============================================
-- 1. ANNOUNCEMENTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS announcements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  target_role TEXT CHECK (target_role IN ('OWNER', 'STAFF') OR target_role IS NULL),
  created_by UUID REFERENCES auth.users(id) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  scheduled_at TIMESTAMPTZ,
  sent_at TIMESTAMPTZ,
  notification_id TEXT,
  CONSTRAINT valid_schedule CHECK (scheduled_at IS NULL OR scheduled_at > created_at)
);

CREATE INDEX IF NOT EXISTS idx_announcements_created_at ON announcements(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_announcements_target_role ON announcements(target_role);
CREATE INDEX IF NOT EXISTS idx_announcements_sent_at ON announcements(sent_at) WHERE sent_at IS NOT NULL;

-- RLS Policies for announcements
ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users view relevant announcements" ON announcements;
CREATE POLICY "Users view relevant announcements" ON announcements
  FOR SELECT USING (
    target_role IS NULL
    OR target_role = (SELECT role FROM profiles WHERE id = auth.uid())
  );

DROP POLICY IF EXISTS "Owners create announcements" ON announcements;
CREATE POLICY "Owners create announcements" ON announcements
  FOR INSERT WITH CHECK (
    auth.uid() = created_by
    AND (SELECT role FROM profiles WHERE id = auth.uid()) = 'OWNER'
  );

-- ============================================
-- 2. ANNOUNCEMENT READS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS announcement_reads (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  announcement_id UUID REFERENCES announcements(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  read_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(announcement_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_announcement_reads_user_id ON announcement_reads(user_id);
CREATE INDEX IF NOT EXISTS idx_announcement_reads_announcement_id ON announcement_reads(announcement_id);

-- RLS Policies for announcement_reads
ALTER TABLE announcement_reads ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users view own reads" ON announcement_reads;
CREATE POLICY "Users view own reads" ON announcement_reads
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users mark own reads" ON announcement_reads;
CREATE POLICY "Users mark own reads" ON announcement_reads
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ============================================
-- 3. STOCK ALERT TRIGGER
-- ============================================

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS trigger_check_stock_alert ON products;
DROP FUNCTION IF EXISTS check_stock_alert();

-- Create stock alert check function
CREATE OR REPLACE FUNCTION check_stock_alert()
RETURNS TRIGGER AS $$
DECLARE
  alert_level TEXT;
  project_url TEXT;
BEGIN
  -- Only check if stock alerts enabled for this product
  IF NEW.stock_alert_enabled = FALSE THEN
    RETURN NEW;
  END IF;

  -- Only trigger if quantity decreased
  IF NEW.quantity < OLD.quantity THEN
    -- Determine alert level
    IF NEW.quantity = 0 THEN
      alert_level := 'out';
    ELSIF NEW.quantity <= NEW.min_stock_level THEN
      alert_level := 'low';
    ELSE
      RETURN NEW;
    END IF;

    -- Get Supabase project URL
    SELECT current_setting('app.settings.supabase_url', true) INTO project_url;
    IF project_url IS NULL THEN
      project_url := 'YOUR-PROJECT-URL';  -- Fallback, should be configured
    END IF;

    -- Call Edge Function via webhook (async, non-blocking)
    PERFORM net.http_post(
      url := project_url || '/functions/v1/trigger_stock_alert',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key', true)
      ),
      body := jsonb_build_object(
        'product_id', NEW.id,
        'product_name', NEW.name,
        'quantity', NEW.quantity,
        'level', alert_level,
        'min_stock_level', NEW.min_stock_level,
        'user_id', NEW.user_id
      )
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger
CREATE TRIGGER trigger_check_stock_alert
  AFTER UPDATE OF quantity ON products
  FOR EACH ROW
  EXECUTE FUNCTION check_stock_alert();

-- ============================================
-- NOTES
-- ============================================
-- After running this migration:
-- 1. Configure Supabase settings:
--    ALTER DATABASE postgres SET "app.settings.supabase_url" TO 'https://YOUR-PROJECT-ID.supabase.co';
--    ALTER DATABASE postgres SET "app.settings.service_role_key" TO 'YOUR-SERVICE-ROLE-KEY';
--
-- 2. Deploy Edge Functions:
--    - supabase/functions/trigger_stock_alert
--    - supabase/functions/send_announcement
--
-- 3. Enable pg_net extension if not already enabled:
--    CREATE EXTENSION IF NOT EXISTS pg_net;
