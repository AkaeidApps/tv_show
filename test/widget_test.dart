import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tv_show/app/app.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('splash screen shows the brand and call to action', (
    tester,
  ) async {
    await tester.pumpWidget(const TvShowApp());
    await tester.pump();

    expect(find.text('TV Show'), findsOneWidget);
    expect(find.text('Start watching'), findsOneWidget);

    // Tear the tree down so the splash timer and animations are disposed.
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('bottom navigation exposes the four tabs', (tester) async {
    await tester.pumpWidget(const TvShowApp());
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Favorite'), findsOneWidget);
    expect(find.text('Sports'), findsOneWidget);
    expect(find.text('Saved'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
