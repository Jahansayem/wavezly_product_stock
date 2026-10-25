import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wavezly/screens/stock_book_screen_v2.dart';
import 'package:wavezly/utils/color_palette.dart';

/// Pumps [BottomActionBar] the same way `StockBookScreenV2` hosts it:
/// pinned to the bottom of a `Stack` inside `Scaffold.body`, with the given
/// system bottom inset (what the Android navigation bar reports).
Future<void> _pumpBar(WidgetTester tester, {required double bottomInset}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: EdgeInsets.only(bottom: bottomInset),
          ),
          child: Scaffold(
            body: Stack(
              children: [
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: BottomActionBar(
                    primaryColor: ColorPalette.tealAccent,
                    cardColor: ColorPalette.white,
                    borderColor: ColorPalette.slate200,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('buttons sit above the system navigation bar inset',
      (tester) async {
    const inset = 48.0;
    await _pumpBar(tester, bottomInset: inset);

    final screenBottom = tester.getSize(find.byType(Scaffold)).height;
    final bar = find.byType(BottomActionBar);

    // The white card still reaches the physical screen edge (no grey gap).
    expect(tester.getBottomLeft(bar).dy, screenBottom);

    // Both buttons are fully clear of the navigation bar area.
    for (final button in [
      find.byType(OutlinedButton),
      find.byType(ElevatedButton),
    ]) {
      expect(button, findsOneWidget);
      expect(
        tester.getRect(button).bottom,
        lessThanOrEqualTo(screenBottom - inset),
      );
    }

    // The bar reserves exactly the inset plus its own 16 padding below the
    // button row.
    final row = find.descendant(of: bar, matching: find.byType(Row));
    expect(tester.getBottomLeft(row).dy, screenBottom - inset - 16);
  });

  testWidgets('layout is unchanged when there is no bottom inset',
      (tester) async {
    await _pumpBar(tester, bottomInset: 0);

    final screenBottom = tester.getSize(find.byType(Scaffold)).height;
    final row = find.descendant(
      of: find.byType(BottomActionBar),
      matching: find.byType(Row),
    );
    expect(tester.getBottomLeft(row).dy, screenBottom - 16);
  });
}
