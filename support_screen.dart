import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../data/services/firebase_service.dart';
import '../../../domain/providers/auth_provider.dart';

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSending = false;

  static const String _whatsappNumber = '22200000000';

  Future<void> _openWhatsapp() async {
    final url = Uri.parse('https://wa.me/$_whatsappNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح واتساب')),
      );
    }
  }

  Future<void> _sendMessage() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    setState(() => _isSending = true);
    try {
      await FirebaseService().sendSupportMessage(
        userId: user.uid,
        email: user.email ?? '',
        subject: _subjectController.text.trim(),
        message: _messageController.text.trim(),
      );
      if (!mounted) return;
      _subjectController.clear();
      _messageController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إرسال رسالتك بنجاح'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('الدعم الفني'),
        leading: IconButton(
          onPressed: () => context.go('/home'),
          icon: const Icon(Icons.arrow_back_ios_new),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                children: [
                  Icon(Icons.headset_mic, color: Colors.white, size: 48),
                  SizedBox(height: 12),
                  Text(
                    'نحن هنا لمساعدتك',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'تواصل معنا في أي وقت وسنرد عليك في أسرع وقت',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95)),

            const SizedBox(height: 24),

            // WhatsApp button
            Text(
              'تواصل مباشر',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ).animate(delay: 100.ms).fadeIn(duration: 300.ms),
            const SizedBox(height: 12),

            GestureDetector(
              onTap: _openWhatsapp,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF25D366).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFF25D366).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chat, color: Color(0xFF25D366), size: 28),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تواصل عبر واتساب',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          Text(
                            'متاح من 8 صباحاً حتى 11 مساءً',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Color(0xFF25D366), size: 16),
                  ],
                ),
              ),
            ).animate(delay: 150.ms).fadeIn(duration: 300.ms),

            const SizedBox(height: 24),

            // Send message form
            Text(
              'إرسال رسالة',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ).animate(delay: 200.ms).fadeIn(duration: 300.ms),
            const SizedBox(height: 12),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _subjectController,
                    validator: Validators.required,
                    decoration: const InputDecoration(
                      labelText: 'الموضوع',
                      hintText: 'موضوع رسالتك',
                      prefixIcon: Icon(Icons.subject_outlined),
                    ),
                  ).animate(delay: 250.ms).fadeIn(duration: 300.ms),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _messageController,
                    validator: Validators.message,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'الرسالة',
                      hintText: 'اكتب رسالتك هنا...',
                      alignLabelWithHint: true,
                    ),
                  ).animate(delay: 300.ms).fadeIn(duration: 300.ms),
                  const SizedBox(height: 20),
                  CustomButton(
                    text: 'إرسال الرسالة',
                    onPressed: _sendMessage,
                    isLoading: _isSending,
                    icon: Icons.send_outlined,
                  ).animate(delay: 350.ms).fadeIn(duration: 300.ms),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // FAQ
            Text(
              'الأسئلة الشائعة',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ).animate(delay: 400.ms).fadeIn(duration: 300.ms),
            const SizedBox(height: 12),

            ..._faqs.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _FAQTile(faq: e.value).animate(delay: Duration(milliseconds: 450 + e.key * 60)).fadeIn(duration: 300.ms),
                )),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  static final List<Map<String, String>> _faqs = [
    {'q': 'كم يستغرق وقت الشحن؟', 'a': 'يتم الشحن عادةً خلال 1-24 ساعة بعد التحقق من الدفع.'},
    {'q': 'ماذا أفعل إذا لم يصل الشحن؟', 'a': 'تواصل معنا عبر واتساب مع رقم طلبك وسنتحقق فوراً.'},
    {'q': 'هل يمكن إلغاء الطلب؟', 'a': 'يمكن الإلغاء قبل البدء في تنفيذ الطلب فقط.'},
    {'q': 'ما هي طرق الدفع المتاحة؟', 'a': 'نقبل Bankily وMasrivi وSedad.'},
  ];
}

class _FAQTile extends StatefulWidget {
  final Map<String, String> faq;
  const _FAQTile({required this.faq});

  @override
  State<_FAQTile> createState() => _FAQTileState();
}

class _FAQTileState extends State<_FAQTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        onExpansionChanged: (v) => setState(() => _expanded = v),
        trailing: Icon(
          _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
          color: AppColors.primary,
        ),
        title: Text(
          widget.faq['q']!,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              widget.faq['a']!,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
