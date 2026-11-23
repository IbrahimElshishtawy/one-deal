import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';

/// Floating search bar for the universal category map with debounced text input,
/// active filter badge button, and map layer toggle.
class MapSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final int activeFilterCount;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;
  final VoidCallback onFilterTap;
  final VoidCallback onLayerToggle;
  final VoidCallback? onBackTap;

  const MapSearchBar({
    super.key,
    required this.controller,
    required this.hintText,
    required this.activeFilterCount,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    required this.onFilterTap,
    required this.onLayerToggle,
    this.onBackTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: DealOneTokens.cardDecoration(
        context,
        borderRadius: AppRadii.xl,
      ),
      child: Row(
        children: [
          if (onBackTap != null) ...[
            _SquareIconButton(
              icon: Icons.arrow_back_rounded,
              onTap: onBackTap!,
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          Expanded(
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                return TextField(
                  key: const Key('category_map_search_input'),
                  controller: controller,
                  textInputAction: TextInputAction.search,
                  onChanged: onChanged,
                  onSubmitted: onSubmitted,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: DealOneTokens.textPrimaryOf(context),
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: TextStyle(
                      fontSize: 12.5,
                      color: DealOneTokens.textSecondaryOf(context),
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: DealOneTokens.textSecondaryOf(context),
                    ),
                    suffixIcon: value.text.isNotEmpty
                        ? IconButton(
                            onPressed: onClear,
                            icon: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: DealOneTokens.textSecondaryOf(context),
                            ),
                            visualDensity: VisualDensity.compact,
                          )
                        : null,
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 4),
          Stack(
            clipBehavior: Clip.none,
            children: [
              _SquareIconButton(
                key: const Key('category_map_filter_button'),
                icon: Icons.tune_rounded,
                onTap: onFilterTap,
                highlighted: activeFilterCount > 0,
              ),
              if (activeFilterCount > 0)
                PositionedDirectional(
                  top: -3,
                  end: -3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: const BoxDecoration(
                      color: DealOneTokens.amber,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$activeFilterCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 6),
          _SquareIconButton(
            key: const Key('category_map_layers_button'),
            icon: Icons.layers_outlined,
            onTap: onLayerToggle,
          ),
        ],
      ),
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool highlighted;

  const _SquareIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: highlighted
          ? DealOneTokens.navy
          : DealOneTokens.softTileBgOf(context),
      borderRadius: AppRadii.md,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.md,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(
            icon,
            size: 19,
            color: highlighted
                ? Colors.white
                : DealOneTokens.textPrimaryOf(context),
          ),
        ),
      ),
    );
  }
}
