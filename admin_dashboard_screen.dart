import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/order.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/orders_provider.dart';
import '../../../data/services/firebase_service.dart';
import '../../../data/services/notification_service.dart';
import '../../widgets/order_status_badge.dart';
import '../../../core/widgets/loading_widget.dart';
import 'manage_games_screen.dart';
import 'manage_banners_screen.dart';
import 'payment_settings_screen.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  OrderStatus? _filterStatus;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('لوحة الإدارة'),
        leading: IconButton(
          onPressed: () => context.go('/home'),
          icon: const Icon(Icons.arrow_back_ios_new),
        ),
        actions: [
          IconButton(
            onPressed: _confirmLogout,
            icon: const Icon(Icons.logout, color: AppColors.error),
            tooltip: 'تسجيل الخروج',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          tabs: const [
            Tab(text: 'الطلبات', icon: Icon(Icons.receipt_long, size: 18)),
            Tab(text: 'الألعاب', icon: Icon(Icons.videogame_asset, size: 18)),
            Tab(text: 'البنرات', icon: Icon(Icons.campaign, size: 18)),
            Tab(text: 'الدفع', icon: Icon(Icons.payment, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OrdersTab(
            searchQuery: _searchQuery,
            filterStatus: _filterStatus,
            searchCtrl: _searchCtrl,
            onSearchChanged: (v) => setState(() => _searchQuery = v),
            onFilterChanged: (s) => setState(() => _filterStatus = s),
          ),
          const ManageGamesScreen(),
          const ManageBannersScreen(),
          const PaymentSettingsScreen(),
        ],
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل تريد تسجيل الخروج؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authNotifierProvider.notifier).signOut();
              if (!mounted) return;
              context.go('/login');
            },
            child: const Text('خروج'),
          ),
        ],
      ),
    );
  }
}

// ─── Orders Tab ──────────────────────────────────────────────────────────────

class _OrdersTab extends ConsumerWidget {
  final String searchQuery;
  final OrderStatus? filterStatus;
  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<OrderStatus?> onFilterChanged;

  const _OrdersTab({
    required this.searchQuery,
    required this.filterStatus,
    required this.searchCtrl,
    required this.onSearchChanged,
    required this.onFilterChanged,
  });

  List<OrderModel> _filtered(List<OrderModel> orders) {
    var list = orders;
    if (filterStatus != null) {
      list = list.where((o) => o.status == filterStatus).toList();
    }
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list
          .where((o) =>
              o.userEmail.toLowerCase().contains(q) ||
              o.gameName.toLowerCase().contains(q) ||
              o.playerId.toLowerCase().contains(q) ||
              o.id.toLowerCase().contains(q) ||
              o.whatsapp.contains(q))
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(allOrdersProvider);

    return ordersAsync.when(
      loading: () => const LoadingWidget(),
      error: (e, _) => ErrorWidget2(message: 'خطأ: $e'),
      data: (orders) {
        final filtered = _filtered(orders);
        final pending =
            orders.where((o) => o.status == OrderStatus.pending).length;
        final processing =
            orders.where((o) => o.status == OrderStatus.processing).length;
        final completed =
            orders.where((o) => o.status == OrderStatus.completed).length;

        return Column(
          children: [
            // Stats
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _Stat('الكل', '${orders.length}', Icons.all_inbox,
                      AppColors.primary),
                  const SizedBox(width: 8),
                  _Stat('انتظار', '$pending', Icons.schedule,
                      AppColors.warning),
                  const SizedBox(width: 8),
                  _Stat('تنفيذ', '$processing', Icons.sync,
                      AppColors.info),
                  const SizedBox(width: 8),
                  _Stat('مكتملة', '$completed', Icons.check_circle,
                      AppColors.success),
                ],
              ),
            ),

            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: searchCtrl,
                onChanged: onSearchChanged,
                decoration: const InputDecoration(
                  hintText: 'بحث بالبريد أو اللعبة أو Player ID...',
                  prefixIcon: Icon(Icons.search),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Filters
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _Chip('الكل', filterStatus == null,
                      () => onFilterChanged(null)),
                  ...OrderStatus.values.map((s) => _Chip(
                      s.label, filterStatus == s, () => onFilterChanged(s))),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // List
            Expanded(
              child: filtered.isEmpty
                  ? const EmptyStateWidget(
                      message: 'لا توجد طلبات',
                      icon: Icons.receipt_long_outlined)
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => _AdminOrderCard(
                        order: filtered[i],
                        index: i,
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _Stat(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 10),
                textAlign: TextAlign.center),
          ],
        ),
      ).animate().fadeIn(duration: 300.ms),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _Chip(this.label, this.isSelected, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 200.ms,
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.divider),
        ),
        child: Text(
          label,
          style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontSize: 13,
              fontWeight:
                  isSelected ? FontWeight.bold : FontWeight.normal),
        ),
      ),
    );
  }
}

// ─── Admin Order Card ────────────────────────────────────────────────────────

class _AdminOrderCard extends ConsumerWidget {
  final OrderModel order;
  final int index;
  const _AdminOrderCard({required this.order, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = DateFormat('dd/MM/yyyy – HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${order.gameName} — ${order.packageName}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(order.userEmail,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              OrderStatusBadge(status: order.status),
            ]),
            const Divider(color: AppColors.divider, height: 16),
            Wrap(spacing: 6, runSpacing: 6, children: [
              _chip(Icons.person_outline, 'ID: ${order.playerId}'),
              _chip(Icons.phone_outlined, order.whatsapp),
              _chip(Icons.payment_outlined, order.paymentMethod),
              _chip(Icons.attach_money,
                  '${order.price.toStringAsFixed(0)} MRU'),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Text(fmt.format(order.createdAt),
                  style:
                      const TextStyle(color: AppColors.textHint, fontSize: 11)),
              const Spacer(),
              if (order.paymentProofUrl != null)
                TextButton.icon(
                  onPressed: () =>
                      _showProof(context, order.paymentProofUrl!),
                  icon: const Icon(Icons.image_outlined, size: 15),
                  label: const Text('إثبات',
                      style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                      minimumSize: const Size(0, 30),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8)),
                ),
              const SizedBox(width: 4),
              ElevatedButton.icon(
                onPressed: () => _showUpdateDialog(context),
                icon: const Icon(Icons.edit_outlined, size: 14),
                label:
                    const Text('تحديث', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 32),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12)),
              ),
            ]),
            if (order.adminNote != null && order.adminNote!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    const Icon(Icons.admin_panel_settings_outlined,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(order.adminNote!,
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate(delay: Duration(milliseconds: index * 40))
        .fadeIn(duration: 300.ms);
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(6)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: AppColors.textHint),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 11)),
      ]),
    );
  }

  void _showProof(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('إثبات الدفع',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          Image.network(url,
              fit: BoxFit.contain,
              loadingBuilder: (_, child, p) =>
                  p == null ? child : const CircularProgressIndicator(),
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.broken_image, size: 80)),
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إغلاق')),
        ]),
      ),
    );
  }

  void _showUpdateDialog(BuildContext context) {
    OrderStatus selected = order.status;
    final noteCtrl =
        TextEditingController(text: order.adminNote ?? '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('تحديث حالة الطلب'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...OrderStatus.values.map((s) => RadioListTile<OrderStatus>(
                      value: s,
                      groupValue: selected,
                      onChanged: (v) => setState(() => selected = v!),
                      title: Text(s.label),
                      dense: true,
                    )),
                const SizedBox(height: 8),
                TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظة للعميل',
                    hintText: 'مثال: تم الشحن بنجاح',
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final note = noteCtrl.text.trim();
                await FirebaseService().updateOrderStatus(
                  order.id,
                  selected,
                  note: note.isEmpty ? null : note,
                );
                // Notify user
                try {
                  final tokens = await FirebaseService()
                      .getUserFcmTokens(order.userId);
                  if (tokens.isNotEmpty) {
                    await NotificationService().sendToTokens(
                      tokens: tokens,
                      title: _statusTitle(selected),
                      body: '${order.gameName} — ${order.packageName}',
                      data: {
                        'type': 'order_update',
                        'orderId': order.id
                      },
                    );
                  }
                } catch (_) {}
              },
              child: const Text('تحديث'),
            ),
          ],
        ),
      ),
    );
  }

  String _statusTitle(OrderStatus s) {
    switch (s) {
      case OrderStatus.processing:
        return '⚙️ طلبك قيد التنفيذ';
      case OrderStatus.completed:
        return '✅ تم شحن طلبك!';
      case OrderStatus.rejected:
        return '❌ تم رفض طلبك';
      default:
        return '📋 تحديث طلبك';
    }
  }
}
