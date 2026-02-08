import 'package:wavezly/config/supabase_config.dart';
import 'package:wavezly/models/announcement.dart';

class AnnouncementRepository {
  final _supabase = SupabaseConfig.client;

  Future<List<Announcement>> getAnnouncements() async {
    final response = await _supabase
      .from('announcements')
      .select()
      .order('created_at', ascending: false);
    return (response as List).map((a) => Announcement.fromJson(a)).toList();
  }

  Future<void> markAsRead(String announcementId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    await _supabase.from('announcement_reads').insert({
      'announcement_id': announcementId,
      'user_id': userId,
    });
  }

  Future<Set<String>> getReadAnnouncementIds() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return {};

    final response = await _supabase
      .from('announcement_reads')
      .select('announcement_id')
      .eq('user_id', userId);

    return (response as List).map((r) => r['announcement_id'] as String).toSet();
  }

  Future<int> getUnreadCount() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return 0;

    final userProfile = await _supabase
      .from('profiles')
      .select('role')
      .eq('id', userId)
      .single();

    final userRole = userProfile['role'] as String?;

    // Get all announcements visible to this user
    var query = _supabase.from('announcements').select('id');
    if (userRole != null) {
      query = query.or('target_role.is.null,target_role.eq.$userRole');
    } else {
      query = query.isFilter('target_role', null);
    }

    final announcements = await query;
    final allIds = (announcements as List).map((a) => a['id'] as String).toSet();

    // Get read IDs
    final readIds = await getReadAnnouncementIds();

    return allIds.difference(readIds).length;
  }
}
