import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_space/features/appliances_decor/presentation/pages/appliances_decor_home_page.dart';
import 'package:market_space/features/cars_maintenance/presentation/pages/cars_maintenance_home_page.dart';
import 'package:market_space/features/construction_electrical/presentation/pages/construction_electrical_home_page.dart';
import 'package:market_space/features/fashion_accessories/presentation/pages/fashion_accessories_home_page.dart';
import 'package:market_space/features/main_hub/presentation/pages/main_hub_page.dart';
import 'package:market_space/features/real_estate/presentation/pages/real_estate_home_page.dart';
import 'package:market_space/features/services_engineering/presentation/pages/services_engineering_home_page.dart';

import 'device_matrix_responsive_test.dart' as matrix;

/// Captures and verifies Golden PNG baselines (`test/responsive/goldens/*.png`)
/// and RepaintBoundary layout geometry across all 7 Home screens at 393x873.
void main() {
  final homes = <(String, Widget Function())>[
    ('home_1_main_hub', () => const MainHubPage()),
    ('home_2_real_estate', () => const RealEstateHomePage()),
    ('home_3_appliances_decor', () => const AppliancesDecorHomePage()),
    ('home_4_services_engineering', () => const ServicesEngineeringHomePage()),
    ('home_5_construction_electrical', () => const ConstructionElectricalHomePage()),
    ('home_6_cars_maintenance', () => const CarsMaintenanceHomePage()),
    ('home_7_fashion_accessories', () => const FashionAccessoriesHomePage()),
  ];

  testWidgets('Phase 10 — Verifies Golden PNG baselines and layout geometry for all 7 Home screens', (tester) async {
    tester.view.physicalSize = const Size(393, 873);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    for (final (slug, builder) in homes) {
      final boundaryKey = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundaryKey,
          child: matrix.buildResponsiveTestApp(
            child: builder(),
            direction: TextDirection.rtl,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'No exception on $slug');

      final boundary = boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      expect(boundary, isNotNull);
      expect(boundary!.size, const Size(393, 873));

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/$slug.png'),
      );
    }
  });
}
