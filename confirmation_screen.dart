import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/providers/games_provider.dart';
import '../../../domain/providers/orders_provider.dart';

class ConfirmationScreen extends ConsumerWidget {
  const ConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(orderFormProvider);
    final notifier = ref.read(orderFormProvider.notifier);
    final gameAsync = ref.watch(gamesProvider);

    final game = gameAsync.valueOrNull
        ?.firstWhere((g) => g.id == s.gameId, orElse: () => gameAsync.valueOrNull!.first);

    Future<void> onSubmit() async {
      final orderId = await notifier.submitOrder();
      if (!context.mounted) return;
      if (orderId != null) {
        _showSuccessDialog(context, ref, orderId);
      } else {
        final error = ref.read(orderFormProvider).error ?? 'حدث خطأ';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.error),
        );
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('تأكيد الطلب'),
        leading: IconButton(
          onPressed: () => context.go('/payment'),
          icon: const Icon(Icons.arrow_back_ios_new),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: game?.gradient ?? AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.receipt_long,
                        color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 12),
                  const Text('مراجعة الطلب',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('تحقق من جميع البيانات قبل الإرسال',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.8), fontSize: 13)),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms)
                .scale(begin: const Offset(0.95, 0.95)),

            const SizedBox(height: 20),

            Text('تفاصيل الطلب',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold))
                .animate(delay: 100.ms).fadeIn(duration: 300.ms),
            const SizedBox(height: 12),

            // Details card
            Container(
              decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                _row(Icons.videogame_asset_outlined, 'اللعبة',
                    s.gameName ?? ''),
                _div(),
                _row(Icons.inventory_2_outlined, 'الباقة',
                    s.packageName ?? ''),
                _div(),
                _row(Icons.person_outline, 'Player ID', s.playerId),
                _div(),
                _row(Icons.phone_outlined, 'واتساب', s.whatsapp),
                _div(),
                _row(Icons.payment_outlined, 'طريقة الدفع', s.paymentMethod),
                _div(),
                _row(
                  Icons.image_outlined,
                  'إثبات الدفع',
                  s.paymentProofFile != null ? 'تم الرفع ✓' : 'لم يرفع ✗',
                  valueColor: s.paymentProofFile != null
                      ? AppColors.success
                      : AppColors.error,
                ),
              ]),
            ).animate(delay: 150.ms).fadeIn(duration: 300.ms),

            const SizedBox(height: 14),

            // Price
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('المبلغ الإجمالي',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(
                      '${(s.packagePrice ?? 0).toStringAsFixed(0)} MRU',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 22)),
                ],
              ),
            ).animate(delay: 200.ms).fadeIn(duration: 300.ms),

            const SizedBox(height: 12),

            // Note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      color: AppColors.warning, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'بعد الإرسال سيتم مراجعة طلبك يدوياً من قبل المشرف وتنفيذ الشحن في أقرب وقت. ستصلك إشعارات بتحديثات الحالة.',
                      style: TextStyle(
                          color: AppColors.warning,
                          fontSize: 12,
                          height: 1.5),
                    ),
                  ),
                ],
              ),
            ).animate(delay: 250.ms).fadeIn(duration: 300.ms),

            const SizedBox(height: 24),

            // Error message
            if (s.error != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(s.error!,
                          style: const TextStyle(
                              color: AppColors.error, fontSize: 13)),
                    ),
                  ],
                ),
              ),

            ElevatedButton(
              onPressed: s.isLoading ? null : onSubmit,
              child: s.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('إرسال الطلب'),
            ).animate(delay: 300.ms).fadeIn(duration: 300.ms)
                .slideY(begin: 0.2),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textHint),
          const SizedBox(width: 12),
          Text(label,
              style: const TextStyle(color: AppColors.textSecondary)),
          const Spacer(),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _div() => const Divider(
      height: 1, color: AppColors.divider, indent: 16, endIndent: 16);

  void _showSuccessDialog(
      BuildContext context, WidgetRef ref, String orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle,
                  color: AppColors.success, size: 48),
            ).animate()
                .scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 16),
            const Text('تم إرسال طلبك بنجاح!',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text(
                'سيتم مراجعة طلبك يدوياً وشحنه في أقرب وقت. ستصلك إشعارات بالتحديثات.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.5)),
            const SizedBox(height: 8),
            Text('#${orderId.substring(0, 8).toUpperCase()}',
                style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                ref.read(orderFormProvider.notifier).reset();
                context.go('/home');
              },
              child: const Text('العودة للرئيسية'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                ref.read(orderFormProvider.notifier).reset();
                context.go('/orders');
              },
              child: const Text('عرض طلباتي'),
            ),
          ],
        ),
      ),
    );
  }
}
