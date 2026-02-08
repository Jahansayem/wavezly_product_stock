import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const ONESIGNAL_APP_ID = "38885689-4f43-4d42-8c17-cbcd852fba07";
const ONESIGNAL_API_KEY = "os_v2_app_hcefnckpingufdaxzpgykl52a73j2oqrgheuornroyyjekrzhadtyfzslssya7xxpohlvuctv6sn6iufh5h3u4mkaftvakce6iv2maq";

serve(async (req) => {
  try {
    const { announcement_id, title, body, target_role } = await req.json();

    // Initialize Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    // Get target users
    let query = supabaseClient.from('profiles').select('id');
    if (target_role) {
      query = query.eq('role', target_role);
    }
    const { data: users, error } = await query;

    if (error) throw error;

    const externalIds = users.map(u => u.id);

    // Send OneSignal notification
    const oneSignalResponse = await fetch('https://onesignal.com/api/v1/notifications', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Basic ${ONESIGNAL_API_KEY}`,
      },
      body: JSON.stringify({
        app_id: ONESIGNAL_APP_ID,
        include_external_user_ids: externalIds,
        contents: { en: body },
        headings: { en: title },
        data: {
          type: 'announcement',
          announcement_id,
        },
      }),
    });

    const result = await oneSignalResponse.json();

    // Update announcement with sent status
    await supabaseClient
      .from('announcements')
      .update({
        sent_at: new Date().toISOString(),
        notification_id: result.id,
      })
      .eq('id', announcement_id);

    return new Response(
      JSON.stringify({ success: true, notification_id: result.id }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Error sending announcement:', error);
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
});
