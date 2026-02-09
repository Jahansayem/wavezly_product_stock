import 'package:flutter/material.dart';
import 'package:wavezly/utils/color_palette.dart';

/// A reusable AppBar with yellow gradient background (Halkhata/Wavezly brand style).
///
/// Used across multiple screens to maintain consistent branding with:
/// - Yellow gradient (amber-400 to amber-500)
/// - Toolbar height: 72
/// - Elevation: 4
/// - Automatic back button if Navigator can pop
/// - Configurable title and actions
class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// The title widget to display in the AppBar.
  /// Can be a Text widget, Column with title+subtitle, or any custom widget.
  final Widget title;

  /// Optional list of action widgets (e.g., IconButtons) to display on the right.
  final List<Widget>? actions;

  /// Whether to show the back button. Defaults to automatic detection.
  /// If null, shows back button when Navigator.canPop returns true.
  final bool? showBackButton;

  /// Custom leading widget. If provided, overrides the automatic back button.
  final Widget? leading;

  const GradientAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.showBackButton,
    this.leading,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    // Determine if we should show back button
    final bool canPop = ModalRoute.of(context)?.canPop ?? false;
    final bool shouldShowBack = showBackButton ?? canPop;

    return AppBar(
      backgroundColor: Colors.transparent,
      toolbarHeight: 72,
      elevation: 4,
      automaticallyImplyLeading: false, // We handle leading manually
      leading: leading ??
          (shouldShowBack
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  onPressed: () => Navigator.pop(context),
                )
              : null),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              ColorPalette.offerYellowStart, // #FBBF24 (amber-400)
              ColorPalette.offerYellowEnd,   // #F59E0B (amber-500)
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
      ),
      title: title,
      actions: actions,
    );
  }
}
