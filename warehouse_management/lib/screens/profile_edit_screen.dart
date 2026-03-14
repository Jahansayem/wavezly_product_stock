import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:wavezly/models/user_profile.dart';
import 'package:wavezly/services/image_storage_service.dart';
import 'package:wavezly/services/user_service.dart';
import 'package:wavezly/utils/color_palette.dart';

class ProfileEditScreen extends StatefulWidget {
  final UserProfile initialProfile;

  const ProfileEditScreen({
    super.key,
    required this.initialProfile,
  });

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final _userService = UserService();
  final _imageStorageService = ImageStorageService();
  final _imagePicker = ImagePicker();
  final _dateFormat = DateFormat('dd MMMM, yyyy');

  File? _selectedAvatar;
  DateTime? _birthday;
  String? _gender;
  bool _removeAvatar = false;
  bool _isSaving = false;
  bool _isAvatarPicking = false;

  @override
  void initState() {
    super.initState();
    final profile = widget.initialProfile;
    _nameController.text = profile.name;
    _phoneController.text = profile.phone ?? '';
    _addressController.text = profile.address ?? '';
    _emailController.text = profile.email ?? '';
    _birthday =
        profile.birthday != null ? DateUtils.dateOnly(profile.birthday!) : null;
    _gender = profile.gender;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _showImageSourceSheet() async {
    if (_isAvatarPicking || _isSaving) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'প্রোফাইল ছবি',
                    style: _headingStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: ColorPalette.gray800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSheetAction(
                    icon: Icons.photo_camera_outlined,
                    label: 'ক্যামেরা থেকে তুলুন',
                    onTap: () {
                      Navigator.pop(context);
                      _pickAvatar(ImageSource.camera);
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildSheetAction(
                    icon: Icons.photo_library_outlined,
                    label: 'গ্যালারি থেকে নিন',
                    onTap: () {
                      Navigator.pop(context);
                      _pickAvatar(ImageSource.gallery);
                    },
                  ),
                  if (_hasAnyAvatar) ...[
                    const SizedBox(height: 10),
                    _buildSheetAction(
                      icon: Icons.delete_outline_rounded,
                      label: 'ছবি মুছে ফেলুন',
                      destructive: true,
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _selectedAvatar = null;
                          _removeAvatar = true;
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSheetAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool destructive = false,
  }) {
    final foreground = destructive ? ColorPalette.red600 : ColorPalette.gray800;

    return Material(
      color: destructive
          ? ColorPalette.red100.withValues(alpha: 0.35)
          : ColorPalette.gray100,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: foreground),
              const SizedBox(width: 12),
              Text(
                label,
                style: _bodyStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAvatar(ImageSource source) async {
    try {
      setState(() => _isAvatarPicking = true);

      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 900,
        maxHeight: 900,
        imageQuality: 60,
      );

      if (pickedFile == null) {
        if (mounted) {
          setState(() => _isAvatarPicking = false);
        }
        return;
      }

      final avatarFile = File(pickedFile.path);
      final isValid = await _imageStorageService.validateFileSize(avatarFile);
      if (!isValid) {
        _showSnackBar(
          'ছবির সাইজ ৫ এমবি এর কম হতে হবে।',
          isError: true,
        );
        if (mounted) {
          setState(() => _isAvatarPicking = false);
        }
        return;
      }

      if (!mounted) return;
      setState(() {
        _selectedAvatar = avatarFile;
        _removeAvatar = false;
        _isAvatarPicking = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isAvatarPicking = false);
      _showSnackBar('ছবি নির্বাচন করা যায়নি।', isError: true);
    }
  }

  Future<void> _pickBirthday() async {
    if (_isSaving) return;

    final now = DateTime.now();
    final initialDate =
        _birthday ?? DateTime(now.year - 18, now.month, now.day);

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'জন্মদিন নির্বাচন করুন',
    );

    if (pickedDate == null) return;

    setState(() {
      _birthday = DateUtils.dateOnly(pickedDate);
    });
  }

  Future<void> _saveProfile() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    final currentAvatarUrl = widget.initialProfile.avatarUrl;

    try {
      String? avatarUrl = currentAvatarUrl;

      if (_selectedAvatar != null) {
        avatarUrl = currentAvatarUrl != null && currentAvatarUrl.isNotEmpty
            ? await _imageStorageService.replaceProfileImage(
                newImageFile: _selectedAvatar!,
                oldImageUrl: currentAvatarUrl,
              )
            : await _imageStorageService.uploadProfileImage(_selectedAvatar!);
      } else if (_removeAvatar &&
          currentAvatarUrl != null &&
          currentAvatarUrl.isNotEmpty) {
        await _imageStorageService.deleteProfileImage(currentAvatarUrl);
        avatarUrl = null;
      }

      final updatedProfile = widget.initialProfile.copyWith(
        name: _cleanText(_nameController.text) ?? widget.initialProfile.name,
        phone: _cleanText(_phoneController.text),
        address: _cleanText(_addressController.text),
        email: _cleanText(_emailController.text),
        birthday: _birthday,
        clearBirthday: _birthday == null,
        gender: _gender,
        clearGender: _gender == null,
        avatarUrl: avatarUrl,
        clearAvatarUrl: avatarUrl == null,
      );

      await _userService.updateUser(updatedProfile);

      if (!mounted) return;
      _showSnackBar('প্রোফাইল আপডেট হয়েছে।');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('প্রোফাইল আপডেট করা যায়নি। আবার চেষ্টা করুন।',
          isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? ColorPalette.mandy : ColorPalette.nileBlue,
        content: Text(
          message,
          style: _bodyStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String? _cleanText(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  bool get _hasAnyAvatar {
    return _selectedAvatar != null ||
        (!_removeAvatar &&
            widget.initialProfile.avatarUrl != null &&
            widget.initialProfile.avatarUrl!.isNotEmpty);
  }

  String get _birthdayLabel {
    if (_birthday == null) {
      return 'জন্মদিন নির্বাচন করুন';
    }
    return _dateFormat.format(_birthday!);
  }

  Widget _buildAvatarPreview() {
    if (_selectedAvatar != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.file(
          _selectedAvatar!,
          width: 128,
          height: 128,
          fit: BoxFit.cover,
        ),
      );
    }

    final avatarUrl = widget.initialProfile.avatarUrl;
    if (!_removeAvatar && avatarUrl != null && avatarUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: CachedNetworkImage(
          imageUrl: avatarUrl,
          width: 128,
          height: 128,
          fit: BoxFit.cover,
          placeholder: (context, _) => _buildAvatarPlaceholder(),
          errorWidget: (context, _, __) => _buildAvatarPlaceholder(),
        ),
      );
    }

    return _buildAvatarPlaceholder();
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      width: 128,
      height: 128,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFC107), width: 2),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_outlined,
        size: 42,
        color: Color(0xFFFFC107),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: _bodyStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: ColorPalette.gray800,
            ),
            children: validator == null
                ? const []
                : [
                    TextSpan(
                      text: ' *',
                      style: _bodyStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: ColorPalette.red600,
                      ),
                    ),
                  ],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: _bodyStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: ColorPalette.gray800,
          ),
          decoration: _inputDecoration(),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    String? hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: _bodyStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: ColorPalette.gray400,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: ColorPalette.gray300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: ColorPalette.gray300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFFFC107), width: 1.4),
      ),
      suffixIcon: suffixIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: ColorPalette.gray50,
          appBar: AppBar(
            backgroundColor: const Color(0xFFFFC107),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: _isSaving ? null : () => Navigator.pop(context),
            ),
            title: Text(
              'প্রোফাইল এডিট',
              style: _headingStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorPalette.blue600,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      ColorPalette.blue600.withValues(alpha: 0.7),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  _isSaving ? 'আপডেট হচ্ছে...' : 'আপডেট',
                  style: _bodyStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          body: SafeArea(
            top: false,
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                children: [
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.bottomCenter,
                          children: [
                            _buildAvatarPreview(),
                            Positioned(
                              bottom: -8,
                              child: GestureDetector(
                                onTap: _showImageSourceSheet,
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: ColorPalette.blue600,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: _isAvatarPicking
                                      ? const Padding(
                                          padding: EdgeInsets.all(8),
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.add,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'ছবি যোগ করুন',
                          style: _bodyStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: ColorPalette.gray700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildInputField(
                    label: 'নাম',
                    controller: _nameController,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'নাম লিখুন';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  _buildInputField(
                    label: 'ফোন নম্বর',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 18),
                  _buildInputField(
                    label: 'ঠিকানা',
                    controller: _addressController,
                  ),
                  const SizedBox(height: 18),
                  _buildInputField(
                    label: 'ইমেইল',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      final email = value?.trim();
                      if (email == null || email.isEmpty) {
                        return null;
                      }

                      final emailRegex = RegExp(
                        r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                      );
                      if (!emailRegex.hasMatch(email)) {
                        return 'সঠিক ইমেইল দিন';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'জন্মদিন নির্বাচন করুন',
                        style: _bodyStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: ColorPalette.gray800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _pickBirthday,
                        borderRadius: BorderRadius.circular(16),
                        child: InputDecorator(
                          decoration: _inputDecoration(
                            suffixIcon: const Icon(
                              Icons.calendar_month_outlined,
                              color: ColorPalette.gray500,
                            ),
                          ),
                          child: Text(
                            _birthdayLabel,
                            style: _bodyStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _birthday == null
                                  ? ColorPalette.gray400
                                  : ColorPalette.gray800,
                            ),
                          ),
                        ),
                      ),
                      if (_birthday != null)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => setState(() => _birthday = null),
                            child: Text(
                              'মুছুন',
                              style: _bodyStyle(
                                fontWeight: FontWeight.w700,
                                color: ColorPalette.blue600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'লিঙ্গ নির্বাচন করুন',
                        style: _bodyStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: ColorPalette.gray800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _gender,
                        decoration: _inputDecoration(),
                        style: _bodyStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: ColorPalette.gray800,
                        ),
                        items: const [
                          DropdownMenuItem<String>(
                            value: 'male',
                            child: Text('পুরুষ'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'female',
                            child: Text('মহিলা'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'other',
                            child: Text('অন্যান্য'),
                          ),
                        ],
                        hint: Text(
                          'লিঙ্গ নির্বাচন করুন',
                          style: _bodyStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: ColorPalette.gray400,
                          ),
                        ),
                        onChanged: _isSaving
                            ? null
                            : (value) {
                                setState(() => _gender = value);
                              },
                      ),
                      if (_gender != null)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => setState(() => _gender = null),
                            child: Text(
                              'মুছুন',
                              style: _bodyStyle(
                                fontWeight: FontWeight.w700,
                                color: ColorPalette.blue600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_isSaving)
          ColoredBox(
            color: Colors.black45,
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}

TextStyle _headingStyle({
  required double fontSize,
  required FontWeight fontWeight,
  required Color color,
}) {
  return GoogleFonts.hindSiliguri(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: 1.1,
  );
}

TextStyle _bodyStyle({
  double fontSize = 14,
  FontWeight fontWeight = FontWeight.w500,
  Color color = ColorPalette.gray700,
}) {
  return GoogleFonts.hindSiliguri(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: 1.2,
  );
}
