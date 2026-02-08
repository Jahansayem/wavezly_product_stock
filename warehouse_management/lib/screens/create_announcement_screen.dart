import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wavezly/config/supabase_config.dart';
import 'package:wavezly/functions/toast.dart';
import 'package:wavezly/utils/color_palette.dart';

class CreateAnnouncementScreen extends StatefulWidget {
  const CreateAnnouncementScreen({Key? key}) : super(key: key);

  @override
  State<CreateAnnouncementScreen> createState() => _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState extends State<CreateAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String? _targetRole;
  bool _isSending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _sendAnnouncement() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);

    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;

      // Create announcement in database
      final response = await SupabaseConfig.client
        .from('announcements')
        .insert({
          'title': _titleController.text,
          'body': _bodyController.text,
          'target_role': _targetRole,
          'created_by': userId,
        })
        .select()
        .single();

      final announcementId = response['id'];

      // Trigger Edge Function to send push
      await SupabaseConfig.client.functions.invoke(
        'send_announcement',
        body: {
          'announcement_id': announcementId,
          'title': _titleController.text,
          'body': _bodyController.text,
          'target_role': _targetRole,
        },
      );

      if (mounted) {
        showTextToast('Announcement sent successfully');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        showTextToast('Failed to send: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
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
          'Create Announcement',
          style: GoogleFonts.anekBangla(
            color: ColorPalette.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title field
            TextFormField(
              controller: _titleController,
              style: GoogleFonts.anekBangla(),
              decoration: InputDecoration(
                labelText: 'Title',
                labelStyle: GoogleFonts.anekBangla(),
                filled: true,
                fillColor: ColorPalette.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: ColorPalette.slate200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: ColorPalette.slate200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: ColorPalette.tealAccent, width: 2),
                ),
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),

            // Body field
            TextFormField(
              controller: _bodyController,
              style: GoogleFonts.anekBangla(),
              decoration: InputDecoration(
                labelText: 'Message',
                labelStyle: GoogleFonts.anekBangla(),
                filled: true,
                fillColor: ColorPalette.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: ColorPalette.slate200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: ColorPalette.slate200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: ColorPalette.tealAccent, width: 2),
                ),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              validator: (v) => v?.isEmpty ?? true ? 'Message is required' : null,
            ),
            const SizedBox(height: 16),

            // Target audience dropdown
            DropdownButtonFormField<String?>(
              value: _targetRole,
              style: GoogleFonts.anekBangla(color: ColorPalette.slate800),
              decoration: InputDecoration(
                labelText: 'Send To',
                labelStyle: GoogleFonts.anekBangla(),
                filled: true,
                fillColor: ColorPalette.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: ColorPalette.slate200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: ColorPalette.slate200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: ColorPalette.tealAccent, width: 2),
                ),
              ),
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text('All Users', style: GoogleFonts.anekBangla()),
                ),
                DropdownMenuItem(
                  value: 'OWNER',
                  child: Text('Owners Only', style: GoogleFonts.anekBangla()),
                ),
                DropdownMenuItem(
                  value: 'STAFF',
                  child: Text('Staff Only', style: GoogleFonts.anekBangla()),
                ),
              ],
              onChanged: (v) => setState(() => _targetRole = v),
            ),
            const SizedBox(height: 24),

            // Send button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isSending ? null : _sendAnnouncement,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorPalette.tealAccent,
                  disabledBackgroundColor: ColorPalette.gray300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: ColorPalette.white,
                      ),
                    )
                  : Text(
                      'Send Announcement',
                      style: GoogleFonts.anekBangla(
                        color: ColorPalette.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
