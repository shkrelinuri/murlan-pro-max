import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:murlan_pro/main.dart';

void main() {
  testWidgets('Murlan home screen renders and starts the matchmaking flow', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MurlanApp()));

    expect(find.text('MURLAN PRO'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Username'), 'alice');
    await tester.enterText(find.widgetWithText(TextField, 'Password'), 'pass1234');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Find players'), findsOneWidget);
    expect(find.text('Find a game'), findsOneWidget);

    await tester.ensureVisible(find.text('Find a game'));
    await tester.tap(find.text('Find a game'));
    await tester.pump();

    expect(find.text('Searching for players...'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1400));
    await tester.pump();

    expect(find.text('No players found'), findsOneWidget);
  });
}
