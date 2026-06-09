import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/game.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/games_provider.dart';
import '../../../domain/providers/orders_provider.dart';
import '../../widgets/game_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _currentBanner = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final isAdmin = ref.watch(isAdminProvider).valueOrNull ?? false;
    final gamesAsync = ref.watch(gamesProvider);
    final bannersAsync = ref.watch(bannersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // AppBar
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: AppColors.surface,
            title: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.videogame_asset_rounded,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                const Text('GameTopup',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 19)),
              ],
            ),
            actions: [
              if (isAdmin)
                IconButton(
                  onPressed: () => context.go('/admin'),
                  icon: const Icon(Icons.admin_panel_settings,
                      color: AppColors.warning),
                  tooltip: 'لوحة الإدارة',
                ),
              IconButton(
                onPressed: () => context.go('/orders'),
                icon: const Icon(Icons.receipt_long_outlined),
              ),
              const SizedBox(width: 4),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome
                  Text(
                    'مرحباً، ${user?.displayName ?? 'بك'} 👋',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
                  const SizedBox(height: 4),
                  Text('اشحن لعبتك المفضلة الآن',
                          style: Theme.of(context).textTheme.bodyMedium)
                      .animate(delay: 100.ms)
                      .fadeIn(duration: 400.ms),
                  const SizedBox(height: 16),

                  // Search bar
                  TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v.trim()),
                    decoration: const InputDecoration(
                      hintText: 'ابحث عن لعبة...',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ).animate(delay: 150.ms).fadeIn(duration: 400.ms),

                  const SizedBox(height: 20),

                  // Banners carousel
                  bannersAsync.when(
                    loading: () => _shimmerBanner(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (banners) {
                      if (banners.isEmpty) return _defaultBanner();
                      return _buildCarousel(banners);
                    },
                  ),

                  const SizedBox(height: 24),

                  // Section title
                  gamesAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (games) {
                      final filtered = _filterGames(games);
                      return Row(
                        children: [
                          Text('الألعاب المتاحة',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const Spacer(),
                          Text('${filtered.length} لعبة',
                              style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // Games grid
          gamesAsync.when(
            loading: () => SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.0,
                ),
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _shimmerCard(),
                  childCount: 4,
                ),
              ),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      const Icon(Icons.wifi_off, color: AppColors.textHint, size: 48),
                      const SizedBox(height: 12),
                      Text('تعذّر تحميل الألعاب',
                          style: Theme.of(context).textTheme.bodyLarge),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(gamesProvider),
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            data: (games) {
              final filtered = _filterGames(games);
              if (filtered.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Text('لا توجد ألعاب مطابقة للبحث',
                          style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.0,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      final game = filtered[i];
                      return GameCard(
                        game: game,
                        index: i,
                        onTap: () {
                          ref
                              .read(orderFormProvider.notifier)
                              .setGame(game.id, game.name);
                          context.go('/topup/${game.id}');
                        },
                      );
                    },
                    childCount: filtered.length,
                  ),
                ),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  List<GameModel> _filterGames(List<GameModel> games) {
    if (_searchQuery.isEmpty) return games;
    final q = _searchQuery.toLowerCase();
    return games.where((g) => g.name.toLowerCase().contains(q)).toList();
  }

  Widget _buildCarousel(List<BannerModel> banners) {
    return Column(
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: 150,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 4),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            enlargeCenterPage: true,
            enlargeFactor: 0.15,
            viewportFraction: 0.9,
            onPageChanged: (i, _) => setState(() => _currentBanner = i),
          ),
          items: banners.map((b) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                gradient: b.gradient,
                borderRadius: BorderRadius.circular(18),
              ),
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(b.title,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(b.subtitle,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('اشحن الآن',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.videogame_asset,
                      size: 72, color: Colors.white.withOpacity(0.25)),
                ],
              ),
            );
          }).toList(),
        ).animate(delay: 200.ms).fadeIn(duration: 400.ms),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            banners.length,
            (i) => AnimatedContainer(
              duration: 300.ms,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _currentBanner == i ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _currentBanner == i
                    ? AppColors.primary
                    : AppColors.textHint,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _defaultBanner() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(20),
      child: const Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('أهلاً بك في GameTopup',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('شحن الألعاب بكل سهولة',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          Icon(Icons.videogame_asset_rounded,
              size: 64, color: Colors.white24),
        ],
      ),
    );
  }

  Widget _shimmerBanner() {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: AppColors.shimmerBase,
        borderRadius: BorderRadius.circular(18),
      ),
    );
  }

  Widget _shimmerCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.shimmerBase,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}
