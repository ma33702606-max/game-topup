import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/firebase_service.dart';
import '../../../domain/entities/game.dart';
import '../../../domain/providers/games_provider.dart';
import '../../../core/widgets/loading_widget.dart';

class ManageBannersScreen extends ConsumerWidget {
  const ManageBannersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bannersAsync = ref.watch(bannersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBannerDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('إضافة بنر'),
        backgroundColor: AppColors.primary,
      ),
      body: bannersAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => ErrorWidget2(message: 'خطأ: $e'),
        data: (banners) => banners.isEmpty
            ? const EmptyStateWidget(
                message: 'لا توجد بنرات بعد',
                icon: Icons.campaign_outlined,
                subtitle: 'أضف أول بنر من الزر أعلاه',
              )
            : ListView.builder(
                padding:
                    const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: banners.length,
                itemBuilder: (_, i) => _BannerTile(
                  banner: banners[i],
                  index: i,
                  onEdit: () =>
                      _showBannerDialog(context, banner: banners[i]),
                ),
              ),
      ),
    );
  }

  void _showBannerDialog(BuildContext context, {BannerModel? banner}) {
    final titleCtrl =
        TextEditingController(text: banner?.title ?? '');
    final subtitleCtrl =
        TextEditingController(text: banner?.subtitle ?? '');
    final sortCtrl =
        TextEditingController(text: '${banner?.sortOrder ?? 0}');
    String gradientKey = banner?.gradientKey ?? 'primary';

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
          title: Text(banner == null ? 'إضافة بنر' : 'تعديل البنر'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                      labelText: 'العنوان',
                      hintText: 'مثال: عروض حصرية على PUBG'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: subtitleCtrl,
                  decoration: const InputDecoration(
                      labelText: 'النص الفرعي',
                      hintText: 'مثال: أسعار لا تُفوَّت'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: sortCtrl,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'الترتيب'),
                ),
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
            if (banner != null)
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await FirebaseService().deleteBanner(banner.id);
                },
                child: const Text('حذف',
                    style: TextStyle(color: AppColors.error)),
              ),
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                final data = {
                  'title': titleCtrl.text.trim(),
                  'subtitle': subtitleCtrl.text.trim(),
                  'gradientKey': gradientKey,
                  'sortOrder': int.tryParse(sortCtrl.text) ?? 0,
                };
                if (banner == null) {
                  await FirebaseService().addBanner(data);
                } else {
                  await FirebaseService()
                      .updateBanner(banner.id, data);
                }
              },
              child: Text(banner == null ? 'إضافة' : 'حفظ'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BannerTile extends StatelessWidget {
  final BannerModel banner;
  final int index;
  final VoidCallback onEdit;
  const _BannerTile(
      {required this.banner, required this.index, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: Container(
        height: 90,
        decoration: BoxDecoration(gradient: banner.gradient),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              top: -10,
              child: Icon(Icons.campaign,
                  size: 80, color: Colors.white.withOpacity(0.1)),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(banner.title,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                        if (banner.subtitle.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(banner.subtitle,
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12)),
                        ],
                        const SizedBox(height: 4),
                        Text('ترتيب: ${banner.sortOrder}',
                            style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 11)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onEdit,
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle),
                      child: const Icon(Icons.edit,
                          color: Colors.white, size: 18),
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
}
