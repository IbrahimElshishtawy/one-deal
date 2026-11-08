import 'package:flutter/material.dart';

import '../../app/app_dependencies.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/responsive_utils.dart';
import '../data/market_repository.dart';
import '../models/home_feed_models.dart';
import '../models/market_sector.dart';
import '../widgets/app_error_view.dart';
import '../widgets/app_loading_indicator.dart';
import 'market_widgets/contractor_promo_banner.dart';
import 'market_widgets/market_bottom_nav_bar.dart';
import 'market_widgets/market_category_grid.dart';
import 'market_widgets/market_header_bar.dart';
import 'market_widgets/market_search_bar.dart';
import 'market_widgets/market_section_header.dart';
import 'market_widgets/market_sector_filter_bar.dart';
import 'market_widgets/material_product_card.dart';
import 'market_widgets/real_estate_card.dart';
import 'market_widgets/safe_network_image.dart';
import 'market_widgets/service_provider_card.dart';
import 'market_widgets/trust_guarantee_card.dart';

class MarketHomeScreen extends StatefulWidget {
  const MarketHomeScreen({super.key});

  @override
  State<MarketHomeScreen> createState() => _MarketHomeScreenState();
}

class _MarketHomeScreenState extends State<MarketHomeScreen> {
  late final MarketRepository _repository;
  bool _isLoading = true;
  String? _errorMessage;

  List<RealEstateItem> _realEstateItems = [];
  List<BuildingMaterialItem> _materials = [];
  List<ServiceProviderItem> _providers = [];
  List<InvestmentProjectItem> _investments = [];

  int _navIndex = 0;
  String _selectedCity = 'القاهرة / الجيزة';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dependencies = AppDependencies.of(context);
      _repository = MarketRepositoryImpl(apiClient: dependencies.apiClient);
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final realEstate = await _repository.getRealEstateListings();
      final materials = await _repository.getBuildingMaterials();
      final providers = await _repository.getServiceProviders();
      final investments = await _repository.getInvestmentProjects();

      if (mounted) {
        setState(() {
          _realEstateItems = realEstate;
          _materials = materials;
          _providers = providers;
          _investments = investments;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dependencies = AppDependencies.of(context);
    final sectorController = dependencies.sectorController;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.backgroundOf(context),
        body: SafeArea(
          bottom: false,
          child: ValueListenableBuilder<MarketSector>(
            valueListenable: sectorController,
            builder: (context, activeSector, _) {
              if (_isLoading) {
                return const Center(child: AppLoadingIndicator());
              }

              if (_errorMessage != null) {
                return Center(
                  child: AppErrorView(
                    message: _errorMessage!,
                    onRetry: _loadData,
                  ),
                );
              }

              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _loadData,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    // 1. Header Bar (Brand, Location, Notifications)
                    SliverToBoxAdapter(
                      child: MarketHeaderBar(
                        selectedCity: _selectedCity,
                        onCityTap: _showCityPicker,
                        onNotificationsTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('لا توجد إشعارات جديدة حالياً'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ),

                    // 2. Search & Filter Bar
                    SliverToBoxAdapter(
                      child: MarketSearchBar(onFilterTap: _showFilterSheet),
                    ),

                    // 3. Sector Filter Bar (الكل، عقارات، مواد بناء...)
                    SliverToBoxAdapter(
                      child: MarketSectorFilterBar(
                        activeSector: activeSector,
                        onSectorChanged: (sector) {
                          sectorController.setSector(sector);
                        },
                      ),
                    ),

                    // 4. Quick Category Shortcut Grid (عقارات للبيع، للإيجار، مُوَن، خدمات)
                    SliverToBoxAdapter(
                      child: MarketCategoryGrid(
                        onSelectSector: (sector) {
                          sectorController.setSector(sector);
                        },
                      ),
                    ),

                    // 5. Wholesale Contractor Promo Banner
                    SliverToBoxAdapter(
                      child: ContractorPromoBanner(
                        onOrderTap: () {
                          sectorController.setSector(
                            MarketSector.buildingMaterials,
                          );
                        },
                      ),
                    ),

                    // 6. Real Estate Section
                    if (activeSector == MarketSector.all ||
                        activeSector == MarketSector.realEstate) ...[
                      SliverToBoxAdapter(
                        child: MarketSectionHeader(
                          title: 'عقارات مميزة (بيع وإيجار)',
                          markerColor: AppColors.secondary,
                          badgeText: 'صكوك موثقة',
                          badgeColor: AppColors.secondaryTint,
                          badgeTextColor: AppColors.secondaryDark,
                          onActionTap: () {},
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: context.isCompactPhone ? 275.0 : 300.0,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: EdgeInsets.symmetric(
                              horizontal: context.horizontalScreenPadding,
                            ),
                            itemCount: _realEstateItems.length,
                            itemBuilder: (context, index) {
                              final item = _realEstateItems[index];
                              return RealEstateCard(item: item);
                            },
                          ),
                        ),
                      ),
                    ],

                    // 7. Building Materials Section
                    if (activeSector == MarketSector.all ||
                        activeSector == MarketSector.buildingMaterials) ...[
                      SliverToBoxAdapter(
                        child: MarketSectionHeader(
                          title: 'سوق المُوَن ومواد البناء',
                          markerColor: AppColors.tertiary,
                          badgeText: 'أسعار الجملة',
                          badgeColor: AppColors.tertiaryTint,
                          badgeTextColor: AppColors.tertiaryDark,
                          actionLabel: 'كل الموردين',
                          onActionTap: () {},
                        ),
                      ),
                      SliverPadding(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.horizontalScreenPadding,
                          vertical: AppSpacing.xs,
                        ),
                        sliver: SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: AppSpacing.sm,
                                crossAxisSpacing: AppSpacing.sm,
                                childAspectRatio: context.isCompactPhone
                                    ? 0.68
                                    : 0.74,
                              ),
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final item = _materials[index];
                            return MaterialProductCard(
                              item: item,
                              onCallTap: () => _callSupplier(item),
                              onChatTap: () => _chatSupplier(item),
                            );
                          }, childCount: _materials.length),
                        ),
                      ),
                    ],

                    // 8. Services & Contracting Section
                    if (activeSector == MarketSector.all ||
                        activeSector == MarketSector.services) ...[
                      SliverToBoxAdapter(
                        child: MarketSectionHeader(
                          title: 'دليل الخدمات والتشطيب والمقاولات',
                          markerColor: AppColors.info,
                          badgeText: 'فنيون معتمدون',
                          badgeColor: AppColors.infoTint,
                          badgeTextColor: AppColors.info,
                          actionLabel: 'كل الخدمات',
                          onActionTap: () {},
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final item = _providers[index];
                          return ServiceProviderCard(
                            item: item,
                            onActionTap: () => _requestQuote(item),
                          );
                        }, childCount: _providers.length),
                      ),
                    ],

                    // 9. Investment Projects Section
                    if (activeSector == MarketSector.all ||
                        activeSector == MarketSector.investments) ...[
                      SliverToBoxAdapter(
                        child: const MarketSectionHeader(
                          title: 'المشروعات والفرص الاستثمارية',
                          markerColor: AppColors.primary,
                          badgeText: 'عوائد مضمونة',
                          actionLabel: 'كل المشروعات',
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final item = _investments[index];
                          return _buildInvestmentCard(context, item);
                        }, childCount: _investments.length),
                      ),
                    ],

                    // 10. Trust & Guarantee Card
                    const SliverToBoxAdapter(child: TrustGuaranteeCard()),

                    // Extra bottom padding for scroll clearance
                    const SliverToBoxAdapter(
                      child: SizedBox(height: AppSpacing.xl),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        bottomNavigationBar: MarketBottomNavBar(
          currentIndex: _navIndex,
          onIndexChanged: (index) {
            setState(() {
              _navIndex = index;
            });
          },
          onAddListingTap: _showAddListingSheet,
        ),
      ),
    );
  }

  Widget _buildInvestmentCard(
    BuildContext context,
    InvestmentProjectItem item,
  ) {
    final isCompact = context.isCompactPhone;
    final horizontalPadding = context.horizontalScreenPadding;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadii.lg,
        border: Border.all(color: AppColors.lightBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SafeNetworkImage(
            imageUrl: item.imageUrl,
            height: isCompact ? 115.0 : 130.0,
            width: double.infinity,
            fit: BoxFit.cover,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16.0),
            ),
            fallbackIcon: Icons.apartment_rounded,
          ),
          Padding(
            padding: EdgeInsets.all(isCompact ? 10.0 : 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: isCompact ? 13.0 : 14.0,
                    fontWeight: FontWeight.w800,
                    color: AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  '${item.location} • الحد الأدنى: ${item.minInvestment}',
                  style: TextStyle(
                    fontSize: isCompact ? 10.5 : 11.5,
                    color: AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 8.0),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: AppRadii.full,
                        child: LinearProgressIndicator(
                          value: item.progressPercent,
                          minHeight: 6.0,
                          backgroundColor: AppColors.lightBorder,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      item.expectedReturn,
                      style: TextStyle(
                        fontSize: isCompact ? 10.0 : 11.0,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _callSupplier(BuildingMaterialItem item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('الاتصال بالمورد: ${item.title}'),
        backgroundColor: AppColors.neutral,
      ),
    );
  }

  void _chatSupplier(BuildingMaterialItem item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('فتح المحادثة مع: ${item.title}'),
        backgroundColor: AppColors.neutral,
      ),
    );
  }

  void _requestQuote(ServiceProviderItem item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم إرسال طلب تسعيرة إلى ${item.name}'),
        backgroundColor: AppColors.neutral,
      ),
    );
  }

  void _showCityPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'اختر المدينة أو المنطقة',
                  style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.md),
                ...[
                  'الرياض / دبي',
                  'الرياض',
                  'جدة',
                  'دبي',
                  'أبوظبي',
                  'الشارقة',
                ].map(
                  (city) => ListTile(
                    title: Text(city),
                    trailing: _selectedCity == city
                        ? const Icon(Icons.check, color: AppColors.primary)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedCity = city;
                      });
                      Navigator.pop(ctx);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'الفلاتر المتقدمة',
                  style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.md),
                const Text('تصفية حسب السعر، الموقع، ونوع العقار أو المادة.'),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('تطبيق الفلتر'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddListingSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'أضف إعلانك في بازار جو',
                  style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.md),
                ListTile(
                  leading: const Icon(
                    Icons.home_work_outlined,
                    color: AppColors.secondary,
                  ),
                  title: const Text('إعلان عقاري (بيع أو إيجار)'),
                  onTap: () => Navigator.pop(ctx),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.handyman_outlined,
                    color: AppColors.tertiary,
                  ),
                  title: const Text('إعلان مواد بناء وتوريد مُوَن'),
                  onTap: () => Navigator.pop(ctx),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.engineering_outlined,
                    color: AppColors.info,
                  ),
                  title: const Text('تسجيل مقدم خدمة ومقاولات'),
                  onTap: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
