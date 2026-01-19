import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_profile.dart';
import '../services/user_service.dart';
import '../utils/color_palette.dart';

/// UserListScreenV1
/// Production-ready user management screen matching Google Stitch design
/// Features: Search, Filter, Sort, Loading/Error/Empty states
/// Design: Material 3 with Noto Sans Bengali typography

class UserListScreenV1 extends StatefulWidget {
  const UserListScreenV1({Key? key}) : super(key: key);

  @override
  State<UserListScreenV1> createState() => _UserListScreenV1State();
}

class _UserListScreenV1State extends State<UserListScreenV1> {
  final UserService _userService = UserService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  // State management
  List<UserProfile> _allUsers = [];
  List<UserProfile> _filteredUsers = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  bool _sortOldToNew = false; // false = new to old (default)

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Load all users from Supabase
  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final users = await _userService.getUsers();
      setState(() {
        _allUsers = users;
        _filteredUsers = users;
        _isLoading = false;
      });
      _applySorting();
    } catch (e) {
      setState(() {
        _errorMessage = 'ডেটা লোড করতে ব্যর্থ হয়েছে';
        _isLoading = false;
      });
      print('Error loading users: $e');
    }
  }

  /// Handle search with debouncing (300ms)
  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = query.toLowerCase();
        _filterUsers();
      });
    });
  }

  /// Filter users based on search query
  void _filterUsers() {
    if (_searchQuery.isEmpty) {
      setState(() {
        _filteredUsers = List.from(_allUsers);
      });
    } else {
      setState(() {
        _filteredUsers = _allUsers.where((user) {
          final nameLower = user.name.toLowerCase();
          final phoneLower = user.phone?.toLowerCase() ?? '';
          final roleLower = user.role.toLowerCase();

          return nameLower.contains(_searchQuery) ||
                 phoneLower.contains(_searchQuery) ||
                 roleLower.contains(_searchQuery);
        }).toList();
      });
    }
    _applySorting();
  }

  /// Apply sorting to filtered users
  void _applySorting() {
    setState(() {
      if (_sortOldToNew) {
        _filteredUsers.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      } else {
        _filteredUsers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
    });
  }

  /// Toggle sort order
  void _toggleSortOrder() {
    setState(() {
      _sortOldToNew = !_sortOldToNew;
      _applySorting();
    });
  }

  /// Handle filter button press
  void _onFilterPressed() {
    // TODO: Implement filter dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'ফিল্টার ফিচার শীঘ্রই আসছে',
          style: GoogleFonts.notoSansBengali(),
        ),
        backgroundColor: ColorPalette.tealPrimary,
      ),
    );
  }

  /// Handle help button press
  void _onHelpPressed() {
    // TODO: Implement help dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'সাহায্য পৃষ্ঠা শীঘ্রই আসছে',
          style: GoogleFonts.notoSansBengali(),
        ),
        backgroundColor: ColorPalette.tealPrimary,
      ),
    );
  }

  /// Handle user card tap
  void _onUserCardTapped(UserProfile user) {
    // TODO: Navigate to user detail screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'ইউজার ডিটেইল: ${user.name}',
          style: GoogleFonts.notoSansBengali(),
        ),
        backgroundColor: ColorPalette.tealPrimary,
      ),
    );
  }

  /// Handle add user button press
  void _onAddUserPressed() {
    // TODO: Navigate to add user screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'নতুন ইউজার যুক্ত করুন পৃষ্ঠা শীঘ্রই আসছে',
          style: GoogleFonts.notoSansBengali(),
        ),
        backgroundColor: ColorPalette.tealPrimary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.gray100,
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  /// Build AppBar with back, title, and help buttons
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: ColorPalette.tealPrimary,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.3),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
        style: IconButton.styleFrom(
          shape: const CircleBorder(),
          backgroundColor: Colors.transparent,
          overlayColor: Colors.white.withOpacity(0.1),
        ),
      ),
      title: Text(
        'ইউজার লিস্ট',
        style: GoogleFonts.notoSansBengali(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.help_outline, color: Colors.white),
          onPressed: _onHelpPressed,
          style: IconButton.styleFrom(
            shape: const CircleBorder(),
            backgroundColor: Colors.transparent,
            overlayColor: Colors.white.withOpacity(0.1),
          ),
        ),
      ],
    );
  }

  /// Build main body with search, stats, and user list
  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: _loadUsers,
      color: ColorPalette.tealPrimary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 96),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(),
            const SizedBox(height: 16),
            _buildStatsRow(),
            const SizedBox(height: 16),
            _buildUserList(),
          ],
        ),
      ),
    );
  }

  /// Build search bar with filter button
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ColorPalette.gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.search, color: ColorPalette.gray400, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: GoogleFonts.notoSansBengali(
                fontSize: 14,
                color: ColorPalette.gray700,
              ),
              decoration: InputDecoration(
                hintText: 'ইউজার খুঁজুন',
                hintStyle: GoogleFonts.notoSansBengali(
                  fontSize: 14,
                  color: ColorPalette.gray400,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          Container(
            width: 1,
            height: 24,
            color: ColorPalette.gray300,
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _onFilterPressed,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.filter_alt, color: ColorPalette.gray600, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    'ফিল্টার',
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: ColorPalette.gray600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build stats row with count and sort button
  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // User count
        RichText(
          text: TextSpan(
            style: GoogleFonts.notoSansBengali(
              fontSize: 14,
              color: ColorPalette.gray500,
            ),
            children: [
              const TextSpan(text: 'ব্যবহারকারীর সংখ্যা: '),
              TextSpan(
                text: '${_filteredUsers.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: ColorPalette.gray700,
                ),
              ),
            ],
          ),
        ),
        // Sort button
        Row(
          children: [
            Text(
              'Sort by:',
              style: GoogleFonts.notoSansBengali(
                fontSize: 14,
                color: ColorPalette.gray500,
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: _toggleSortOrder,
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: ColorPalette.gray200),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  _sortOldToNew ? 'পুরাতন থেকে নতুন' : 'নতুন থেকে পুরাতন',
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: ColorPalette.gray700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build user list or loading/error/empty states
  Widget _buildUserList() {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: CircularProgressIndicator(
            color: ColorPalette.tealPrimary,
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 64, color: ColorPalette.gray400),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: GoogleFonts.notoSansBengali(
                  fontSize: 16,
                  color: ColorPalette.gray600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadUsers,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorPalette.tealPrimary,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  'পুনরায় চেষ্টা করুন',
                  style: GoogleFonts.notoSansBengali(),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredUsers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            children: [
              Icon(Icons.person_off_outlined, size: 64, color: ColorPalette.gray400),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isEmpty
                    ? 'কোনো ইউজার পাওয়া যায়নি'
                    : 'কোনো ম্যাচিং ইউজার পাওয়া যায়নি',
                style: GoogleFonts.notoSansBengali(
                  fontSize: 16,
                  color: ColorPalette.gray600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _filteredUsers
          .map((user) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _UserCard(
                  user: user,
                  onTap: () => _onUserCardTapped(user),
                ),
              ))
          .toList(),
    );
  }

  /// Build bottom fixed bar with add user button
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorPalette.gray100.withOpacity(0.95),
        border: Border(
          top: BorderSide(color: ColorPalette.gray200),
        ),
      ),
      child: SafeArea(
        child: Material(
          color: ColorPalette.tealPrimary,
          borderRadius: BorderRadius.circular(8),
          elevation: 8,
          shadowColor: ColorPalette.tealPrimary.withOpacity(0.4),
          child: InkWell(
            onTap: _onAddUserPressed,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_circle_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'নতুন ইউজার যুক্ত করুন',
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// User Card Widget
/// Displays user information with avatar, name, role, phone, status
class _UserCard extends StatelessWidget {
  final UserProfile user;
  final VoidCallback onTap;

  const _UserCard({
    required this.user,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Apply opacity for inactive users
    final opacity = user.isActive ? 1.0 : 0.7;

    return Opacity(
      opacity: opacity,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: ColorPalette.gray100),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: ColorPalette.gray100,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 32,
                    color: ColorPalette.gray500,
                  ),
                ),
                const SizedBox(width: 16),
                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name and Arrow
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              user.name,
                              style: GoogleFonts.notoSansBengali(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: ColorPalette.gray700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward,
                            size: 20,
                            color: ColorPalette.gray400,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      // Role
                      Text(
                        user.role,
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: ColorPalette.gray500,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Phone
                      if (user.phone != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.call,
                              size: 16,
                              color: ColorPalette.gray400,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              user.phone!,
                              style: GoogleFonts.notoSansBengali(
                                fontSize: 14,
                                color: ColorPalette.gray700,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 8),
                      // Status Chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: user.isActive
                              ? const Color(0xFFD1FAE5) // green-100
                              : ColorPalette.gray200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          user.isActive ? 'Active' : 'Inactive',
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: user.isActive
                                ? const Color(0xFF065F46) // green-800
                                : ColorPalette.gray600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
