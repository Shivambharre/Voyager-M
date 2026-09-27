import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:voyager_learning/features/roadmap/domain/roadmap_repository.dart';
import 'package:voyager_learning/main.dart';

void main() {
  testWidgets('Dashboard opens the focused mock player', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      VoyagerApp(repository: InMemoryRoadmapRepository()),
    );
    await tester.pumpAndSettle();
    expect(find.text('CONTINUE LEARNING'), findsOneWidget);
    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();

    expect(find.text('PLAYER PREVIEW'), findsOneWidget);
    expect(find.text('Gradient Descent, Clearly Explained'), findsOneWidget);
  });

  testWidgets('Primary navigation opens roadmaps and design showcase', (tester) async {
    await tester.pumpWidget(
      VoyagerApp(repository: InMemoryRoadmapRepository()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('ROADMAPS').last);
    await tester.pumpAndSettle();
    expect(find.text('Frontend Foundations'), findsOneWidget);

    await tester.tap(find.byTooltip('Open design system showcase'));
    await tester.pumpAndSettle();
    expect(find.text('NEO-BRUTALIST V1.0'), findsOneWidget);
    expect(find.text('COLOR PALETTE'), findsOneWidget);
  });
}
