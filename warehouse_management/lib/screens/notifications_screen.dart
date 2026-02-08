import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:wavezly/models/announcement.dart';
import 'package:wavezly/repositories/announcement_repository.dart';
import 'package:wavezly/utils/color_palette.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final AnnouncementRepository _repository = AnnouncementRepository();
  List<Announcement> _announcements = [];
  Set<String> _readIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    setState(() => _isLoading = true);
    try {
      final announcements = await _repository.getAnnouncements();
      final readIds = await _repository.getReadAnnouncementIds();
      setState(() {
        _announcements = announcements;
        _readIds = readIds;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load: $e')),
        );
      }
    }
  }

  Future<void> _markAsRead(String id) async {
    if (_readIds.contains(id)) return;
    try {
      await _repository.markAsRead(id);
      setState(() => _readIds.add(id));
    } catch (e) {
      // Silent fail for read tracking
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.slate50,
      appBar: AppBar(
        backgroundColor: ColorPalette.tealAccent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ColorPalette.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: GoogleFonts.anekBangla(
            color: ColorPalette.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _announcements.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: ColorPalette.gray400),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: GoogleFonts.anekBangla(
                      fontSize: 16,
                      color: ColorPalette.gray500,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadAnnouncements,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _announcements.length,
                itemBuilder: (context, index) {
                  final announcement = _announcements[index];
                  final isRead = _readIds.contains(announcement.id);

                  return _AnnouncementCard(
                    announcement: announcement,
                    isRead: isRead,
                    onTap: () => _markAsRead(announcement.id),
                  );
                },
              ),
            ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final Announcement announcement;
  final bool isRead;
  final VoidCallback onTap;

  const _AnnouncementCard({
    required this.announcement,
    required this.isRead,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isRead ? 0 : 2,
      color: isRead ? ColorPalette.gray50 : ColorPalette.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isRead ? Colors.transparent : ColorPalette.tealAccent.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (!isRead)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: const BoxDecoration(
                        color: ColorPalette.tealAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      announcement.title,
                      style: GoogleFonts.anekBangla(
                        fontSize: 16,
                        fontWeight: isRead ? FontWeight.w400 : FontWeight.w700,
                        color: ColorPalette.slate800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                announcement.body,
                style: GoogleFonts.anekBangla(
                  fontSize: 14,
                  color: ColorPalette.slate600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 12, color: ColorPalette.slate400),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(announcement.createdAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: ColorPalette.slate400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return DateFormat('MMM dd, yyyy').format(date);
  }
}
