import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/firebase_service.dart';
import '../../../domain/providers/games_provider.dart';

class PaymentSettingsScreen extends ConsumerStatefulWidget {
  const PaymentSettingsScreen({super.key});

  @override
  ConsumerState<PaymentSettingsScreen> createState() =>
      _PaymentSettingsScreenState();
}

class _PaymentSettingsScreenState
    extends ConsumerState<PaymentSettingsScreen> {
  final Map<String, TextEditingController> _numberCtrl = {};
  final Map<String, TextEditingController> _nameCtrl = {};
  bool _saving = false;

  static const _methods = ['bankily', 'masrivi', 'sedad'];
  static const _labels = {
    'bankily': 'Bankily',
    'masrivi': 'Masrivi',
    'sedad': 'Sedad',
  };

  @override
  void initState() {
    super.initState();
    for (final m in _methods) {
      _numberCtrl[m] = TextEditingController();
      _nameCtrl[m] = TextEditingController();
    }
    _load();
  }

  Future<void> _load() async {
    final settings = await FirebaseService().getPaymentSettingsStream().first;
    for (final m in _methods) {
      final data = settings[m] as Map? ?? {};
      _numberCtrl[m]?.text = data['accountNumber']?.toString() ?? '';
      _nameCtrl[m]?.text = data['accountName']?.toString() ?? '';
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final c in _numberCtrl.values) c.dispose();
    for (final c in _nameCtrl.values) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final data = <String, dynamic>{};
      for (final m in _methods) {
        data[m] = {
          'accountNumber': _numberCtrl[m]?.text.trim() ?? '',
          'accountName': _nameCtrl[m]?.text.trim() ?? '',
        };
      }
      await FirebaseService().updatePaymentSettings(data);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('تم حفظ الإعدادات'),
            backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('معلومات حسابات الدفع',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold))
              .animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 4),
          const Text('هذه المعلومات ستظهر للعملاء عند اختيار طريقة الدفع',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 20),

          ..._methods.asMap().entries.map((e) {
            final m = e.value;
            final label = _labels[m] ?? m;
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.primary)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _numberCtrl[m],
                      decoration: const InputDecoration(
                        labelText: 'رقم الحساب',
                        hintText: '22XXXXXXXX',
                        prefixIcon: Icon(Icons.tag),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _nameCtrl[m],
                      decoration: const InputDecoration(
                        labelText: 'اسم الحساب',
                        hintText: 'الاسم كما يظهر في التطبيق',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                  ],
                ),
              ),
            ).animate(delay: Duration(milliseconds: e.key * 80))
                .fadeIn(duration: 300.ms);
          }),

          const SizedBox(height: 8),

          ElevatedButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.save_outlined),
            label: Text(_saving ? 'جارٍ الحفظ...' : 'حفظ الإعدادات'),
          ).animate(delay: 300.ms).fadeIn(duration: 300.ms),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
