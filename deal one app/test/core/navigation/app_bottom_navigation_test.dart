import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_space/core/navigation/config/section_navigation_registry.dart';
import 'package:market_space/core/navigation/widgets/app_bottom_navigation/app_bottom_navigation.dart';
import 'package:market_space/core/navigation/widgets/app_bottom_navigation/navigation_tab_item.dart';

void main() {
  group('Section Navigation Registry', () {
    test('Default config has items and floating action', () {
      final config = SectionNavigationRegistry.defaultConfig;
      expect(config.items.length, equals(4));
      expect(config.floatingAction, isNotNull);
    });
  });

  group('AppBottomNavigation Widget Tests', () {
    testWidgets(
      'renders navigation tab items and FAB',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              bottomNavigationBar: AppBottomNavigation(
                config: SectionNavigationRegistry.defaultConfig,
              ),
            ),
          ),
        );

        expect(find.byType(NavigationTabItem), findsNWidgets(4));
        expect(find.text('الرئيسية'), findsOneWidget);
        expect(find.text('الأقسام'), findsOneWidget);
        expect(find.text('المفضلة'), findsOneWidget);
        expect(find.text('حسابي'), findsOneWidget);
      },
    );
  });
}
