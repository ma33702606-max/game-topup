import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/providers/games_provider.dart';
import '../../../domain/providers/orders_provider.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  String? _selectedMethodId;
  File? _proofFile;
  final ImagePicker _picker = ImagePicker();

  static const List<Map<String, dynamic>> _methods = [
    {
      'id': 'bankily',
      'name': 'Bankily',
      'icon': Icons.account_balance_wallet,
      'color': Color(0xFF1E88E5),
    },
    {
      'id': 'masrivi',
      'name': 'Masrivi',
      'icon': Icons.credit_card,
      'color': Color(0xFF43A047),
    },
    {
      'id': 'sedad',
      'name': 'Sedad',
      'icon': Icons.payment,
      'color': Color(0xFFE53935),
    },
  ];

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked =
          await _picker.pickImage(source: source, imageQuality: 85);
      if (picked == null) return;
      setState(() => _proofFile = File(picked.path));
      ref.read(orderFormProvider.notifier).setPaymentProof(_proofFile!);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('تعذّر اختيار الصورة: $e'),
            backgroundColor: AppColors.error),
      );
    }
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: AppColors.primary),
                title: const Text('اختيار من المعرض'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined,
                    color: AppColors.primary),
                title: const Text('التقاط صورة'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم النسخ')),
    );
  }

  void _continue() {
    if (_selectedMethodId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار طريقة الدفع')),
      );
      return;
    }
    if (_proofFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى رفع صورة إثبات الدفع')),
      );
      return;
    }
    ref.read(orderFormProvider.notifier).setPaymentMethod(_selectedMethodId!);
    context.go('/confirmation');
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(paymentSettingsStreamProvider);
    final orderState = ref.watch(orderFormProvider);
    final selectedMethod =
        _methods.where((m) => m['id'] == _selectedMethodId).firstOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('الدفع'),
        leading: IconButton(
          onPressed: () =>
              context.go('/topup/${orderState.gameId ?? ''}'),
          icon: const Icon(Icons.arrow_back_ios_new),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount reminder
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_outlined,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${orderState.packageName ?? ''}',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                      Text(
                          '${(orderState.packagePrice ?? 0).toStringAsFixed(0)} MRU',
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18)),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),

            const SizedBox(height: 20),

            // Payment methods
            Text('اختر طريقة الدفع',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold))
                .animate().fadeIn(duration: 300.ms),
            const SizedBox(height: 12),

            ..._methods.asMap().entries.map((e) {
              final m = e.value;
              final isSelected = _selectedMethodId == m['id'];
              final color = m['color'] as Color;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedMethodId = m['id']),
                  child: AnimatedContainer(
                    duration: 200.ms,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withOpacity(0.1)
                          : AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: isSelected ? color : AppColors.divider,
                          width: isSelected ? 2 : 1),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12)),
                          child: Icon(m['icon'] as IconData,
                              color: color, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Text(m['name'] as String,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isSelected
                                    ? color
                                    : AppColors.textPrimary)),
                        const Spacer(),
                        AnimatedContainer(
                          duration: 200.ms,
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: isSelected
                                    ? color
                                    : AppColors.textHint,
                                width: 2),
                            color: isSelected ? color : Colors.transparent,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 14)
                              : null,
                        ),
                      ],
                    ),
                  ),
                ).animate(delay: Duration(milliseconds: e.key * 80))
                    .fadeIn(duration: 300.ms),
              );
            }),

            // Payment info from Firestore
            if (_selectedMethodId != null && selectedMethod != null) ...[
              const SizedBox(height: 20),
              Text('معلومات الدفع',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold))
                  .animate().fadeIn(duration: 300.ms),
              const SizedBox(height: 12),
              settingsAsync.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary)),
                error: (e, _) => Text('خطأ في تحميل معلومات الدفع: $e',
                    style: const TextStyle(color: AppColors.error)),
                data: (settings) {
                  final methodData =
                      settings[_selectedMethodId] as Map? ?? {};
                  final color = selectedMethod['color'] as Color;
                  final accountNum =
                      methodData['accountNumber']?.toString() ??
                          '—';
                  final accountName =
                      methodData['accountName']?.toString() ?? '—';
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        _infoRow('رقم الحساب', accountNum,
                            onCopy: () => _copy(accountNum),
                            color: color),
                        const Divider(
                            color: AppColors.divider, height: 20),
                        _infoRow('اسم الحساب', accountName,
                            color: color),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_outline,
                                  color: AppColors.warning, size: 16),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'أرسل المبلغ الدقيق ثم ارفع صورة الإيصال',
                                  style: TextStyle(
                                      color: AppColors.warning,
                                      fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1);
                },
              ),
            ],

            const SizedBox(height: 20),

            // Upload proof
            Text('رفع إثبات الدفع',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold))
                .animate(delay: 200.ms).fadeIn(duration: 300.ms),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _showImagePicker,
              child: AnimatedContainer(
                duration: 300.ms,
                width: double.infinity,
                height: 160,
                decoration: BoxDecoration(
                  color: _proofFile != null
                      ? AppColors.success.withOpacity(0.08)
                      : AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _proofFile != null
                        ? AppColors.success
                        : AppColors.inputBorder,
                    width: _proofFile != null ? 2 : 1,
                  ),
                ),
                child: _proofFile != null
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.file(_proofFile!,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                  color: AppColors.success,
                                  borderRadius:
                                      BorderRadius.circular(8)),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check,
                                      color: Colors.white, size: 14),
                                  SizedBox(width: 4),
                                  Text('تم الرفع',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: _showImagePicker,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                    color: AppColors.surface.withOpacity(0.8),
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.edit,
                                    size: 16, color: AppColors.primary),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.cloud_upload_outlined,
                              color: AppColors.textHint, size: 44),
                          const SizedBox(height: 10),
                          const Text('انقر لرفع صورة إثبات الدفع',
                              style: TextStyle(
                                  color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          Text('PNG, JPG مدعوم',
                              style:
                                  Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
              ),
            ).animate(delay: 250.ms).fadeIn(duration: 300.ms),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _continue,
              child: const Text('متابعة لتأكيد الطلب'),
            ).animate(delay: 300.ms).fadeIn(duration: 300.ms)
                .slideY(begin: 0.2),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value,
      {VoidCallback? onCopy, Color? color}) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 4),
              Text(value,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: color ?? AppColors.textPrimary)),
            ],
          ),
        ),
        if (onCopy != null)
          IconButton(
            onPressed: onCopy,
            icon: const Icon(Icons.copy_outlined, size: 18),
            color: AppColors.textSecondary,
          ),
      ],
    );
  }
}
