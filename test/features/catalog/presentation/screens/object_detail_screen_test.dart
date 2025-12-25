import 'package:astr/features/catalog/domain/entities/celestial_object.dart';
import 'package:astr/features/catalog/domain/entities/celestial_type.dart';
import 'package:astr/features/catalog/domain/entities/graph_point.dart';
import 'package:astr/features/catalog/domain/entities/time_range.dart';
import 'package:astr/features/catalog/domain/entities/visibility_graph_data.dart';
import 'package:astr/features/catalog/presentation/providers/object_detail_notifier.dart';
import 'package:astr/features/catalog/presentation/providers/visibility_graph_notifier.dart';
import 'package:astr/features/catalog/presentation/screens/object_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Mock object data
  const CelestialObject tObject = CelestialObject(
    id: 'mars',
    name: 'Mars',
    type: CelestialType.planet,
    iconPath: 'assets/icons/planets/mars.png',
    magnitude: -2.9,
    ephemerisId: 4,
  );

  testWidgets('Object detail page displays object name and type', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Arrange
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          // Override object detail to return data immediately
          objectDetailNotifierProvider('mars').overrideWith(
            (StateNotifierProviderRef<ObjectDetailNotifier, ObjectDetailState> ref) => FakeObjectDetailNotifier(tObject),
          ),
          // Override visibility graph to avoid async hang
          visibilityGraphProvider('mars').overrideWith(
            (StateNotifierProviderRef<VisibilityGraphNotifier, VisibilityGraphState> ref) => FakeVisibilityGraphNotifier(),
          ),
        ],
        child: const MaterialApp(
          home: ObjectDetailScreen(objectId: 'mars'),
        ),
      ),
    );

    // Wait for loading
    await tester.pumpAndSettle();

    // Assert: Object name is displayed
    expect(find.text('Mars'), findsOneWidget);

    // Assert: Type badge is displayed
    expect(find.text('Planet'), findsOneWidget);
  });

  testWidgets('Detail page shows Visibility Graph', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Arrange
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          objectDetailNotifierProvider('mars').overrideWith(
            (StateNotifierProviderRef<ObjectDetailNotifier, ObjectDetailState> ref) => FakeObjectDetailNotifier(tObject),
          ),
          visibilityGraphProvider('mars').overrideWith(
            (StateNotifierProviderRef<VisibilityGraphNotifier, VisibilityGraphState> ref) => FakeVisibilityGraphNotifier(),
          ),
        ],
        child: const MaterialApp(
          home: ObjectDetailScreen(objectId: 'mars'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Assert: Visibility Graph title is visible (updated from "Coming Soon")
    expect(find.text('Visibility'), findsOneWidget);
  });

  testWidgets('Detail page displays magnitude', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Arrange
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          objectDetailNotifierProvider('mars').overrideWith(
            (StateNotifierProviderRef<ObjectDetailNotifier, ObjectDetailState> ref) => FakeObjectDetailNotifier(tObject),
          ),
          visibilityGraphProvider('mars').overrideWith(
            (StateNotifierProviderRef<VisibilityGraphNotifier, VisibilityGraphState> ref) => FakeVisibilityGraphNotifier(),
          ),
        ],
        child: const MaterialApp(
          home: ObjectDetailScreen(objectId: 'mars'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Assert: Magnitude label is displayed
    expect(find.text('Magnitude'), findsOneWidget);
  });
}

class FakeObjectDetailNotifier extends StateNotifier<ObjectDetailState> 
    implements ObjectDetailNotifier {
  FakeObjectDetailNotifier(CelestialObject object) 
      : super(ObjectDetailState(object: object));
      
  @override
  Future<void> loadObject() async {} // No-op
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeVisibilityGraphNotifier extends StateNotifier<VisibilityGraphState> 
    implements VisibilityGraphNotifier {
  FakeVisibilityGraphNotifier() 
      : super(const VisibilityGraphState(
          graphData: VisibilityGraphData(objectCurve: <GraphPoint>[], moonCurve: <GraphPoint>[], optimalWindows: <TimeRange>[])
        ));
        
  @override
  Future<void> calculateGraph() async {} // No-op
  
  @override
  Future<void> refresh() async {}
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}