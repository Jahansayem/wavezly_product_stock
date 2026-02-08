import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const ONESIGNAL_APP_ID = "38885689-4f43-4d42-8c17-cbcd852fba07";
const ONESIGNAL_API_KEY = "os_v2_app_hcefnckpingufdaxzpgykl52a73j2oqrgheuornroyyjekrzhadtyfzslssya7xxpohlvuctv6sn6iufh5h3u4mkaftvakce6iv2maq";

serve(async (req) => {
  try {
    const { product_id, product_name, quantity, level, min_stock_level, user_id } = await req.json();

    // Initialize Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    // Get all users for this business (owner + staff)
    const { data: users, error } = await supabaseClient
      .from('profiles')
      .select('id')
      .or(`id.eq.${user_id},owner_id.eq.${user_id}`);

    if (error) throw error;

    const externalIds = users.map(u => u.id);

    // Send OneSignal notification
    const notifTitle = level === 'out'
      ? `⚠️ OUT OF STOCK: ${product_name}`
      : `📦 Low Stock: ${product_name}`;

    const notifBody = level === 'out'
      ? `${product_name} is completely out of stock. Restock immediately!`
      : `${product_name} is running low (${quantity} left, threshold: ${min_stock_level})`;

    const oneSignalResponse = await fetch('https://onesignal.com/api/v1/notifications', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Basic ${ONESIGNAL_API_KEY}`,
      },
      body: JSON.stringify({
        app_id: ONESIGNAL_APP_ID,
        include_external_user_ids: externalIds,
        contents: { en: notifBody },
        headings: { en: notifTitle },
        priority: level === 'out' ? 10 : 5,
        data: {
          type: 'stock_alert',
          product_id,
          product_name,
          quantity,
          level,
          min_stock_level,
        },
      }),
    });

    const result = await oneSignalResponse.json();

    return new Response(
      JSON.stringify({ success: true, notification_id: result.id }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Error sending stock alert:', error);
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
});
