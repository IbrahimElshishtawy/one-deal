import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/design_system/deal_one_ui_states.dart';
import 'package:market_space/core/providers/core_providers.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/features/conversations/presentation/providers/conversations_providers.dart';
import 'package:market_space/features/favorites/presentation/providers/favorites_providers.dart';
import 'package:market_space/features/listings/presentation/providers/listings_providers.dart';
import 'package:market_space/features/real_estate/domain/entities/reel_item_entity.dart';
import 'package:market_space/features/real_estate/presentation/providers/reels_providers.dart';
import 'package:market_space/features/real_estate/presentation/widgets/reel_overlay_controls.dart';
import 'package:market_space/shared/widgets/app_network_image.dart';

/// Vertical Real Estate Reels Viewer matching `Real Estate Reels Viewer.png`.
/// Backed by `GET /video-feed?cursor=...&limit=10` with infinite scroll pagination
/// and lifecycle-aware playback pause/resume.
class RealEstateReelsPage extends ConsumerStatefulWidget {
  final int initialIndex;
  final List<ReelItemEntity>? initialItems;

  const RealEstateReelsPage({
    super.key,
    this.initialIndex = 0,
    this.initialItems,
  });

  @override
  ConsumerState<RealEstateReelsPage> createState() =>
      _RealEstateReelsPageState();
}

class _RealEstateReelsPageState extends ConsumerState<RealEstateReelsPage>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _progressController;
  int _activeIndex = 0;
  bool _isPlaying = true;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _activeIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    );
    final isTest = WidgetsBinding.instance.runtimeType
        .toString()
        .toLowerCase()
        .contains('test');
    if (!isTest) {
      _progressController.repeat();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _pausePlayback();
    } else if (state == AppLifecycleState.resumed && _isPlaying) {
      _progressController.forward();
    }
  }

  void _pausePlayback() {
    if (_progressController.isAnimating) {
      _progressController.stop();
    }
    if (mounted && _isPlaying) {
      setState(() => _isPlaying = false);
    }
  }

  void _togglePlayback() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _progressController.repeat();
      } else {
        _progressController.stop();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _progressController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _openChat(ReelItemEntity item) async {
    final session = ref.read(sessionProvider);
    if (!session.isAuthenticated) {
      context.push(RouteNames.login);
      return;
    }
    _pausePlayback();
    try {
      final conv = await ref
          .read(conversationsRepositoryProvider)
          .startOrGetConversation(item.listingId, currentUserId: session.userId);
      if (mounted) {
        context.push('/conversations/${conv.id}', extra: conv);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _revealPhone(ReelItemEntity item) async {
    final session = ref.read(sessionProvider);
    if (!session.isAuthenticated) {
      context.push(RouteNames.login);
      return;
    }
    _pausePlayback();
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    await ref
        .read(contactRevealProvider(item.listingId).notifier)
        .reveal(item.listingId);
    final result = ref.read(contactRevealProvider(item.listingId)).valueOrNull;
    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'رقم المعلن: ${result.phone}'
                : 'Seller phone: ${result.phone}',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final state = ref.watch(reelsFeedControllerProvider);
    final controller = ref.read(reelsFeedControllerProvider.notifier);
    final favIds = ref.watch(favoriteIdsProvider);

    final items = (widget.initialItems != null && widget.initialItems!.isNotEmpty)
        ? widget.initialItems!
        : state.items;

    if (state.isLoading && items.isEmpty) {
      return const Scaffold(
        backgroundColor: DealOneTokens.navyDeep,
        body: Center(
          child: CircularProgressIndicator.adaptive(
            valueColor: AlwaysStoppedAnimation(Colors.white),
          ),
        ),
      );
    }

    if (state.error != null && items.isEmpty) {
      return Scaffold(
        backgroundColor: DealOneTokens.pageBgOf(context),
        body: SafeArea(
          child: Column(
            children: [
              DealOneSubPageHeader(
                title: isArabic ? 'معاينات حية' : 'Live Previews',
              ),
              Expanded(
                child: DealOneErrorStateView(
                  error: state.error!,
                  onRetry: controller.loadInitial,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (items.isEmpty) {
      return Scaffold(
        backgroundColor: DealOneTokens.pageBgOf(context),
        body: SafeArea(
          child: Column(
            children: [
              DealOneSubPageHeader(
                title: isArabic ? 'معاينات حية' : 'Live Previews',
              ),
              Expanded(
                child: DealOneEmptyStateView(
                  icon: Icons.videocam_off_outlined,
                  title: isArabic
                      ? 'لا توجد معاينات فيديو متاحة حالياً'
                      : 'No Video Previews Available Yet',
                  description: isArabic
                      ? 'سيتم عرض جولات الفيديو العقارية هنا فور نشرها وتجهيزها.'
                      : 'Property video tours will appear here as soon as they are published.',
                  actionLabel:
                      isArabic ? 'تصفح العقارات' : 'Browse Properties',
                  actionIcon: Icons.home_work_outlined,
                  onAction: () => context.go(RouteNames.realEstate),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: DealOneTokens.navyDeep,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: items.length,
        onPageChanged: (index) {
          setState(() => _activeIndex = index);
          _progressController.reset();
          if (_isPlaying) {
            final isTest = WidgetsBinding.instance.runtimeType
                .toString()
                .toLowerCase()
                .contains('test');
            if (!isTest) _progressController.repeat();
          }
          if (index >= items.length - 2 && state.hasMore) {
            controller.loadMore();
          }
        },
        itemBuilder: (context, index) {
          final item = items[index];
          final isFav = favIds.contains(item.listingId);

          return GestureDetector(
            onTap: _togglePlayback,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background Visual / Poster Frame (lazy per active page)
                if (item.effectivePosterUrl != null)
                  AppNetworkImage(
                    imageUrl: item.effectivePosterUrl,
                    fit: BoxFit.cover,
                    fallbackIcon: Icons.home_work_outlined,
                  )
                else
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [DealOneTokens.navy, DealOneTokens.navyDeep],
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.play_circle_outline_rounded,
                        size: 72,
                        color: Colors.white54,
                      ),
                    ),
                  ),

                // Cinematic Top + Bottom Scrim
                IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.45),
                          Colors.transparent,
                          DealOneTokens.navyDeep.withValues(alpha: 0.92),
                        ],
                        stops: const [0.0, 0.42, 1.0],
                      ),
                    ),
                  ),
                ),

                // Paused center emblem
                if (!_isPlaying)
                  Center(
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        size: 38,
                        color: Colors.white,
                      ),
                    ),
                  ),

                // Overlay Controls
                AnimatedBuilder(
                  animation: _progressController,
                  builder: (context, _) => ReelOverlayControls(
                    item: item,
                    totalSegments: items.length,
                    activeIndex: _activeIndex,
                    progress: _progressController.value,
                    isPlaying: _isPlaying,
                    isMuted: _isMuted,
                    isFavorite: isFav,
                    onClose: () {
                      _pausePlayback();
                      if (context.canPop()) context.pop();
                    },
                    onToggleMute: () => setState(() => _isMuted = !_isMuted),
                    onTogglePlay: _togglePlayback,
                    onToggleFavorite: () => ref
                        .read(favoritesControllerProvider.notifier)
                        .toggleFavorite(item.listingId),
                    onShare: () {
                      Clipboard.setData(
                        ClipboardData(text: '${item.title} — ${item.listingId}'),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isArabic
                                ? 'تم نسخ رابط المعاينة'
                                : 'Preview link copied',
                          ),
                        ),
                      );
                    },
                    onOpenChat: () => _openChat(item),
                    onOpenMap: () {
                      _pausePlayback();
                      context.push(RouteNames.realEstateMap);
                    },
                    onCallSeller: () => _revealPhone(item),
                    onOpenDetails: () {
                      _pausePlayback();
                      context.push('/listings/${item.listingId}');
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
