import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/entities/game.dart';
import '../../../domain/providers/games_provider.dart';
import '../../../domain/providers/orders_provider.dart';

class TopupScreen extends ConsumerStatefulWidget {
  final String gameId;
  const TopupScreen({super.key, required this.gameId});

  @override
  ConsumerState<TopupScreen> createState() => _TopupScreenState();
}

class _TopupScreenState extends ConsumerState<TopupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _playerIdCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  String? _selectedPackageId;

  @override
  void initState() {
    super.initState();
    final s = ref.read(orderFormProvider);
    _playerIdCtrl.text = s.playerId;
    _whatsappCtrl.text = s.whatsapp;
    _selectedPackageId = s.packageId;
  }

  @override
  void dispose() {
    _playerIdCtrl.dispose();
    _whatsappCtrl.dispose();
    super.dispose();
  }

  void _continue(GameModel game, PackageModel pkg) {
    if (!_formKey.currentState!.validate()) return;
    final n = ref.read(orderFormProvider.notifier);
    n.setGame(game.id, game.name);
    n.setPackage(pkg.id, pkg.name, pkg.price);
    n.setPlayerId(_playerIdCtrl.text.trim());
    n.setWhatsapp(_whatsappCtrl.text.trim());
    context.go('/payment');
  }

  @override
  Widget build(BuildContext context) {
    final gamesAsync = ref.watch(gamesProvider);
    final packagesAsync = ref.watch(packagesProvider(widget.gameId));

    return gamesAsync.when(
      loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator(color: AppColors.primary))),
      error: (e, _) => Scaffold(
          body: Center(child: Text('خطأ: $e'))),
      data: (games) {
        final game = games.firstWhere(
          (g) => g.id == widget.gameId,
          orElse: () => games.isNotEmpty ? games.first : GameModel(
            id: widget.gameId, name: '', shortName: '', currency: '',
            gradientKey: 'primary', sortOrder: 0, isActive: true),
        );

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 160,
                pinned: true,
                backgroundColor: AppColors.surface,
                leading: IconButton(
                  onPressed: () => context.go('/home'),
                  icon: const Icon(Icons.arrow_back_ios_new),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(game.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  background: Container(
                    decoration: BoxDecoration(gradient: game.gradient),
                    child: Stack(children: [
                      Positioned(
                        right: 20, bottom: 20,
                        child: Icon(Icons.videogame_asset, size: 100,
                            color: Colors.white.withOpacity(0.15)),
                      ),
                      Positioned(
                        left: 16, bottom: 48,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(game.currency,
                              style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Form(
                  key: _formKey,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Player data
                        Text('بيانات اللاعب',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold))
                            .animate().fadeIn(duration: 300.ms),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _playerIdCtrl,
                          validator: Validators.playerId,
                          decoration: const InputDecoration(
                            labelText: 'Player ID',
                            hintText: 'أدخل معرّف اللاعب',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ).animate(delay: 50.ms).fadeIn(duration: 300.ms),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _whatsappCtrl,
                          validator: Validators.phone,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'رقم واتساب',
                            hintText: 'مثال: 22XXXXXXXX',
                            prefixIcon: Icon(Icons.phone_outlined),
                            helperText: 'سنتواصل معك على هذا الرقم',
                          ),
                        ).animate(delay: 100.ms).fadeIn(duration: 300.ms),

                        const SizedBox(height: 24),

                        // Packages
                        Text('اختر الباقة',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold))
                            .animate(delay: 150.ms).fadeIn(duration: 300.ms),
                        const SizedBox(height: 12),

                        packagesAsync.when(
                          loading: () => Column(
                            children: List.generate(4, (i) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Container(
                                height: 60,
                                decoration: BoxDecoration(
                                  color: AppColors.shimmerBase,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            )),
                          ),
                          error: (e, _) => Center(
                            child: Text('خطأ في تحميل الباقات: $e',
                                style: const TextStyle(color: AppColors.error)),
                          ),
                          data: (packages) {
                            if (packages.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(20),
                                child: Center(
                                  child: Text('لا توجد باقات متاحة حالياً',
                                      style: TextStyle(color: AppColors.textSecondary)),
                                ),
                              );
                            }

                            return Column(
                              children: packages.asMap().entries.map((e) {
                                final pkg = e.value;
                                final isSelected = _selectedPackageId == pkg.id;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _PackageCard(
                                    package: pkg,
                                    accentColor: game.accentColor,
                                    isSelected: isSelected,
                                    onTap: () => setState(
                                        () => _selectedPackageId = pkg.id),
                                  ).animate(
                                    delay: Duration(
                                        milliseconds: 200 + e.key * 60))
                                      .fadeIn(duration: 300.ms),
                                );
                              }).toList(),
                            );
                          },
                        ),

                        // Price summary
                        packagesAsync.whenData((pkgs) {
                          final selected = pkgs
                              .where((p) => p.id == _selectedPackageId)
                              .firstOrNull;
                          if (selected == null) return const SizedBox.shrink();
                          return Column(
                            children: [
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: AppColors.primary.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('المجموع',
                                        style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w500)),
                                    Text(
                                        '${selected.price.toStringAsFixed(0)} MRU',
                                        style: const TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20)),
                                  ],
                                ),
                              ).animate().fadeIn(duration: 300.ms).scale(),
                            ],
                          );
                        }).valueOrNull ?? const SizedBox.shrink(),

                        const SizedBox(height: 24),

                        ElevatedButton(
                          onPressed: () {
                            final pkgs =
                                ref.read(packagesProvider(widget.gameId)).valueOrNull;
                            if (_selectedPackageId == null || pkgs == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('يرجى اختيار باقة')),
                              );
                              return;
                            }
                            final pkg = pkgs.firstWhere(
                                (p) => p.id == _selectedPackageId,
                                orElse: () => pkgs.first);
                            _continue(game, pkg);
                          },
                          child: const Text('متابعة للدفع'),
                        ).animate(delay: 300.ms).fadeIn(duration: 300.ms)
                            .slideY(begin: 0.2),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PackageCard extends StatelessWidget {
  final PackageModel package;
  final Color accentColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _PackageCard({
    required this.package,
    required this.accentColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 200.ms,
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withOpacity(0.1)
              : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? accentColor : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: 200.ms,
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: isSelected ? accentColor : AppColors.textHint,
                    width: 2),
                color: isSelected ? accentColor : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  Text(
                    package.name,
                    style: TextStyle(
                      color: isSelected ? accentColor : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  if (package.isPopular) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('الأكثر طلباً',
                          style: TextStyle(
                              color: AppColors.warning,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              '${package.price.toStringAsFixed(0)} MRU',
              style: TextStyle(
                color: isSelected ? accentColor : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
