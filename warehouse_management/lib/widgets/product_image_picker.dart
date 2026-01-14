import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wavezly/functions/toast.dart';
import 'package:wavezly/services/image_storage_service.dart';
import 'package:wavezly/utils/color_palette.dart';

class ProductImagePicker extends StatefulWidget {
  final String? currentImageUrl;
  final Function(File?) onImageSelected;
  final Function()? onImageDeleted;

  const ProductImagePicker({
    Key? key,
    this.currentImageUrl,
    required this.onImageSelected,
    this.onImageDeleted,
  }) : super(key: key);

  @override
  _ProductImagePickerState createState() => _ProductImagePickerState();
}

class _ProductImagePickerState extends State<ProductImagePicker> {
  File? _selectedImage;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();
  final ImageStorageService _imageService = ImageStorageService();

  void _showImageSourceBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: ColorPalette.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Image Source',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: ColorPalette.timberGreen,
                ),
              ),
              const SizedBox(height: 20),
              _buildSourceOption(
                icon: Icons.camera_alt,
                label: 'Take Photo',
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 12),
              _buildSourceOption(
                icon: Icons.photo_library,
                label: 'Choose from Gallery',
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (widget.currentImageUrl != null || _selectedImage != null) ...[
                const SizedBox(height: 12),
                _buildSourceOption(
                  icon: Icons.delete,
                  label: 'Remove Image',
                  onTap: () {
                    Navigator.pop(context);
                    _removeImage();
                  },
                  isDestructive: true,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: isDestructive
              ? ColorPalette.mandy.withOpacity(0.1)
              : ColorPalette.aquaHaze,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? ColorPalette.mandy : ColorPalette.pacificBlue,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 16,
                color: isDestructive ? ColorPalette.mandy : ColorPalette.timberGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() => _isLoading = true);

      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        setState(() => _isLoading = false);
        return;
      }

      final File imageFile = File(pickedFile.path);

      // Validate file size
      final isValid = await _imageService.validateFileSize(imageFile);
      if (!isValid) {
        showTextToast('Image size must be less than 5MB');
        setState(() => _isLoading = false);
        return;
      }

      setState(() {
        _selectedImage = imageFile;
        _isLoading = false;
      });

      widget.onImageSelected(imageFile);
    } catch (e) {
      setState(() => _isLoading = false);
      showTextToast('Failed to pick image');
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
    widget.onImageSelected(null);
    if (widget.onImageDeleted != null) {
      widget.onImageDeleted!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isLoading ? null : _showImageSourceBottomSheet,
      child: Stack(
        children: [
          SizedBox(
            height: 100,
            width: 100,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Container(
                color: ColorPalette.white,
                child: Container(
                  color: ColorPalette.timberGreen.withOpacity(0.1),
                  child: _buildImageContent(),
                ),
              ),
            ),
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: ColorPalette.nileBlue.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(ColorPalette.white),
                  ),
                ),
              ),
            ),
          // Camera icon overlay hint
          if (_selectedImage == null && widget.currentImageUrl == null && !_isLoading)
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: ColorPalette.tealAccent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.add_a_photo,
                  size: 16,
                  color: ColorPalette.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageContent() {
    // Show selected local image
    if (_selectedImage != null) {
      return Image.file(
        _selectedImage!,
        fit: BoxFit.cover,
      );
    }

    // Show existing network image
    if (widget.currentImageUrl != null && widget.currentImageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        fit: BoxFit.cover,
        imageUrl: widget.currentImageUrl!,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(ColorPalette.tealAccent),
          ),
        ),
        errorWidget: (context, url, error) {
          return Icon(
            Icons.image,
            color: ColorPalette.nileBlue.withOpacity(0.5),
          );
        },
      );
    }

    // Show placeholder
    return Center(
      child: Icon(
        Icons.image,
        color: ColorPalette.nileBlue.withOpacity(0.5),
      ),
    );
  }
}
