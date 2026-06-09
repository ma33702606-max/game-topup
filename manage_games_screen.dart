import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/firebase_service.dart';
import '../../../domain/entities/game.dart';
import '../../../domain/providers/games_provider.dart';
import '../../../core/widgets/loading_widget.dart';

class ManageGamesScreen extends ConsumerWidget {
  const ManageGamesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamesAsync = ref.watch(gamesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showGameDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('إضافة لعبة'),
        backgroundColor: AppColors.primary,
      ),
      body: gamesAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => ErrorWidget2(message: 'خطأ: $e'),
        data: (games) => games.isEmpty
            ? const EmptyStateWidget(
                message: 'لا توجد ألعاب بعد',
                icon: Icons.videogame_asset_outlined,
                subtitle: 'أضف أول لعبة من الزر أعلاه',
              )
            : ListView.builder(
                padding:
                    const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: games.length,
                itemBuilder: (_, i) => _GameTile(
                  game: games[i],
                  index: i,
                  onEdit: () => _showGameDialog(context, ref, game: games[i]),
                ),
              ),
      ),
    );
  }

  void _showGameDialog(BuildContext context, WidgetRef ref,
      {GameModel? game}) {
    final nameCtrl =
        TextEditingController(text: game?.name ?? '');
    final shortCtrl =
        TextEditingController(text: game?.shortName ?? '');
    final currencyCtrl =
        TextEditingController(text: game?.currency ?? '');
    String gradientKey = game?.gradientKey ?? 'primary';
    final sortCtrl =
        TextEditingController(text: '${game?.sortOrder ?? 0}');

    final gradients = [
      {'key': 'pubg', 'label': 'PUBG (ذهبي)'},
      {'key': 'freeFire', 'label': 'Free Fire (أحمر)'},
      {'key': 'efootball', 'label': 'eFootball (أزرق)'},
      {'key': 'eafc', 'label': 'EA FC (أخضر)'},
      {'key': 'primary', 'label': 'افتراضي (بنفسجي)'},
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(game == null ? 'إضافة لعبة' : 'تعديل اللعبة'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(nameCtrl, 'اسم اللعبة', 'مثال: PUBG Mobile'),
                const SizedBox(height: 10),
                _field(shortCtrl, 'الاسم المختصر', 'مثال: PUBG'),
                const SizedBox(height: 10),
                _field(currencyCtrl, 'العملة', 'مثال: UC'),
                const SizedBox(height: 10),
                _field(sortCtrl, 'الترتيب', '0', isNumber: true),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: gradientKey,
                  decoration: const InputDecoration(labelText: 'اللون'),
                  items: gradients
                      .map((g) => DropdownMenuItem(
                            value: g['key'],
                            child: Text(g['label']!),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => gradientKey = v ?? 'primary'),
                ),
              ],
            ),
          ),
          actions: [
            if (game != null)
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await FirebaseService().deleteGame(game.id);
                },
                child: const Text('حذف',
                    style: TextStyle(color: AppColors.error)),
              ),
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                final data = {
                  'name': nameCtrl.text.trim(),
                  'shortName': shortCtrl.text.trim(),
                  'currency': currencyCtrl.text.trim(),
                  'gradientKey': gradientKey,
                  'sortOrder':
                      int.tryParse(sortCtrl.text) ?? 0,
                };
                if (game == null) {
                  await FirebaseService().addGame(data);
                } else {
                  await FirebaseService()
                      .updateGame(game.id, data);
                }
              },
              child: Text(game == null ? 'إضافة' : 'حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  TextField _field(TextEditingController c, String label, String hint,
      {bool isNumber = false}) {
    return TextField(
      controller: c,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }
}

class _GameTile extends ConsumerWidget {
  final GameModel game;
  final int index;
  final VoidCallback onEdit;
  const _GameTile(
      {required this.game, required this.index, required this.onEdit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packagesAsync = ref.watch(packagesProvider(game.id));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: game.gradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(game.shortName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11)),
            ),
          ),
          title: Text(game.name,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${game.currency} • ترتيب: ${game.sortOrder}',
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          trailing: IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined,
                color: AppColors.primary, size: 20),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('الباقات',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      TextButton.icon(
                        onPressed: () =>
                            _showPackageDialog(context, game.id),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('إضافة باقة',
                            style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  packagesAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                          color: AppColors.primary, strokeWidth: 2),
                    ),
                    error: (e, _) => Text('خطأ: $e',
                        style:
                            const TextStyle(color: AppColors.error)),
                    data: (pkgs) => pkgs.isEmpty
                        ? const Text('لا توجد باقات',
                            style: TextStyle(
                                color: AppColors.textSecondary))
                        : Column(
                            children: pkgs
                                .map((p) => ListTile(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      leading: const Icon(
                                          Icons.inventory_2_outlined,
                                          size: 18,
                                          color: AppColors.textHint),
                                      title: Text(p.name,
                                          style: const TextStyle(
                                              fontSize: 14)),
                                      subtitle: Text(
                                          '${p.price.toStringAsFixed(0)} MRU${p.isPopular ? ' • الأكثر طلباً' : ''}',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary)),
                                      trailing: Row(
                                        mainAxisSize:
                                            MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            onPressed: () =>
                                                _showPackageDialog(
                                                    context, game.id,
                                                    pkg: p),
                                            icon: const Icon(
                                                Icons.edit_outlined,
                                                size: 16,
                                                color:
                                                    AppColors.primary),
                                          ),
                                        ],
                                      ),
                                    ))
                                .toList(),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: Duration(milliseconds: index * 60)).fadeIn(duration: 300.ms);
  }

  void _showPackageDialog(BuildContext context, String gameId,
      {PackageModel? pkg}) {
    final nameCtrl =
        TextEditingController(text: pkg?.name ?? '');
    final priceCtrl = TextEditingController(
        text: pkg != null ? '${pkg.price.toStringAsFixed(0)}' : '');
    final amountCtrl =
        TextEditingController(text: '${pkg?.amount ?? 0}');
    bool isPopular = pkg?.isPopular ?? false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(pkg == null ? 'إضافة باقة' : 'تعديل الباقة'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'اسم الباقة',
                      hintText: 'مثال: 325 UC'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'السعر (MRU)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'الكمية'),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: isPopular,
                  onChanged: (v) => setState(() => isPopular = v),
                  title: const Text('الأكثر طلباً'),
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.warning,
                ),
              ],
            ),
          ),
          actions: [
            if (pkg != null)
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await FirebaseService()
                      .deletePackage(gameId, pkg.id);
                },
                child: const Text('حذف',
                    style: TextStyle(color: AppColors.error)),
              ),
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty ||
                    priceCtrl.text.isEmpty) return;
                Navigator.pop(ctx);
                final data = {
                  'name': nameCtrl.text.trim(),
                  'price': double.tryParse(priceCtrl.text) ?? 0,
                  'amount': int.tryParse(amountCtrl.text) ?? 0,
                  'isPopular': isPopular,
                };
                if (pkg == null) {
                  await FirebaseService()
                      .addPackage(gameId, data);
                } else {
                  await FirebaseService()
                      .updatePackage(gameId, pkg.id, data);
                }
              },
              child: Text(pkg == null ? 'إضافة' : 'حفظ'),
            ),
          ],
        ),
      ),
    );
  }
}
