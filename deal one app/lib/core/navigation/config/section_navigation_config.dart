import 'package:market_space/core/navigation/config/floating_action_config.dart';
import 'package:market_space/core/navigation/config/navigation_item_config.dart';

class SectionNavigationConfig {
  final String sectionId;
  final String sectionName;
  final List<NavigationItemConfig> items;
  final FloatingActionConfig? floatingAction;

  const SectionNavigationConfig({
    required this.sectionId,
    required this.sectionName,
    required this.items,
    this.floatingAction,
  });
}
