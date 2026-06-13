import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:logilearn/main.dart';

void main() {
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    dotenv.loadFromString(envString: 'VITE_API_URL=http://localhost:3030');
  });

  testWidgets('shows splash then login form', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const QuizApp());

    expect(find.text('LogiLearn'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    final finder = find.text('Selamat Datang di LogiLearn!');
    if (finder.evaluate().isEmpty) {
      debugDumpApp();
    }

    expect(finder, findsOneWidget);
    expect(
      find.widgetWithText(TextFormField, 'Masukkan Username Anda'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(TextFormField, 'Masukkan Password Anda'),
      findsOneWidget,
    );
    expect(find.widgetWithText(ElevatedButton, 'LANJUTKAN'), findsOneWidget);
  });

  testWidgets('empty login shows validation message', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const QuizApp());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'LANJUTKAN'));
    await tester.pump();

    expect(find.text('Username dan password wajib diisi'), findsOneWidget);
  });
}

