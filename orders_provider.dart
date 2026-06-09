import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/firebase_service.dart';
import '../../data/services/notification_service.dart';
import '../../domain/entities/order.dart';
import 'auth_provider.dart';

final userOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return const Stream.empty();
  return ref.watch(firebaseServiceProvider).getUserOrders(user.uid);
});

final allOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  return ref.watch(firebaseServiceProvider).getAllOrders();
});

// ─── Order form state ────────────────────────────────────────────────────────

class OrderFormState {
  final String? gameId;
  final String? gameName;
  final String? packageId;
  final String? packageName;
  final double? packagePrice;
  final String playerId;
  final String whatsapp;
  final String paymentMethod;
  final File? paymentProofFile;
  final bool isLoading;
  final String? error;

  const OrderFormState({
    this.gameId,
    this.gameName,
    this.packageId,
    this.packageName,
    this.packagePrice,
    this.playerId = '',
    this.whatsapp = '',
    this.paymentMethod = '',
    this.paymentProofFile,
    this.isLoading = false,
    this.error,
  });

  OrderFormState copyWith({
    String? gameId,
    String? gameName,
    String? packageId,
    String? packageName,
    double? packagePrice,
    String? playerId,
    String? whatsapp,
    String? paymentMethod,
    File? paymentProofFile,
    bool? isLoading,
    String? error,
  }) {
    return OrderFormState(
      gameId: gameId ?? this.gameId,
      gameName: gameName ?? this.gameName,
      packageId: packageId ?? this.packageId,
      packageName: packageName ?? this.packageName,
      packagePrice: packagePrice ?? this.packagePrice,
      playerId: playerId ?? this.playerId,
      whatsapp: whatsapp ?? this.whatsapp,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentProofFile: paymentProofFile ?? this.paymentProofFile,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool get isComplete =>
      gameId != null &&
      packageId != null &&
      playerId.isNotEmpty &&
      whatsapp.isNotEmpty &&
      paymentMethod.isNotEmpty;
}

class OrderFormNotifier extends StateNotifier<OrderFormState> {
  final FirebaseService _service;
  final Ref _ref;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  OrderFormNotifier(this._service, this._ref) : super(const OrderFormState());

  void setGame(String id, String name) => state = state.copyWith(
      gameId: id,
      gameName: name,
      packageId: null,
      packageName: null,
      packagePrice: null);

  void setPackage(String id, String name, double price) =>
      state = state.copyWith(packageId: id, packageName: name, packagePrice: price);

  void setPlayerId(String v) => state = state.copyWith(playerId: v);
  void setWhatsapp(String v) => state = state.copyWith(whatsapp: v);
  void setPaymentMethod(String v) => state = state.copyWith(paymentMethod: v);
  void setPaymentProof(File f) => state = state.copyWith(paymentProofFile: f);

  void clearError() => state = state.copyWith(error: null);
  void reset() => state = const OrderFormState();

  Future<String?> submitOrder() async {
    final user = _ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      state = state.copyWith(error: 'يجب تسجيل الدخول أولاً');
      return null;
    }
    if (!state.isComplete) {
      state = state.copyWith(error: 'يرجى إكمال جميع الحقول المطلوبة');
      return null;
    }
    if (state.paymentProofFile == null) {
      state = state.copyWith(error: 'يرجى رفع صورة إثبات الدفع');
      return null;
    }

    try {
      state = state.copyWith(isLoading: true, error: null);

      // 1. Create order document
      final order = OrderModel(
        id: '',
        userId: user.uid,
        userEmail: user.email ?? '',
        gameId: state.gameId!,
        gameName: state.gameName!,
        packageId: state.packageId!,
        packageName: state.packageName!,
        price: state.packagePrice!,
        playerId: state.playerId,
        whatsapp: state.whatsapp,
        paymentMethod: state.paymentMethod,
        paymentProofUrl: null,
        status: OrderStatus.pending,
        createdAt: DateTime.now(),
      );

      final orderId = await _service.createOrder(order);

      // 2. Upload proof image
      final proofUrl = await _service.uploadPaymentProof(
        user.uid,
        orderId,
        state.paymentProofFile!,
      );

      // 3. Update order with proof URL
      await _db.collection('orders').doc(orderId).update({
        'paymentProofUrl': proofUrl,
      });

      // 4. Notify admins
      try {
        final adminTokens = await _service.getAdminFcmTokens();
        if (adminTokens.isNotEmpty) {
          await NotificationService().sendToTokens(
            tokens: adminTokens,
            title: '🎮 طلب شحن جديد',
            body: '${state.gameName} — ${state.packageName}',
            data: {'type': 'new_order', 'orderId': orderId},
          );
        }
      } catch (_) {
        // Non-fatal: notification failure should not block order
      }

      state = state.copyWith(isLoading: false);
      return orderId;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _friendlyError(e.toString()),
      );
      return null;
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('storage')) return 'فشل رفع صورة إثبات الدفع، تحقق من الاتصال';
    if (raw.contains('permission')) return 'ليس لديك صلاحية لإجراء هذه العملية';
    if (raw.contains('network')) return 'تحقق من اتصال الإنترنت وحاول مجدداً';
    return 'حدث خطأ غير متوقع، حاول مجدداً';
  }
}

final orderFormProvider =
    StateNotifierProvider<OrderFormNotifier, OrderFormState>((ref) {
  return OrderFormNotifier(ref.watch(firebaseServiceProvider), ref);
});
