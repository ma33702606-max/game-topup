import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus { pending, processing, completed, rejected }

extension OrderStatusX on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'بانتظار المراجعة';
      case OrderStatus.processing:
        return 'قيد التنفيذ';
      case OrderStatus.completed:
        return 'تم الشحن';
      case OrderStatus.rejected:
        return 'مرفوض';
    }
  }

  String get value => name;

  static OrderStatus fromString(String v) =>
      OrderStatus.values.firstWhere((e) => e.name == v,
          orElse: () => OrderStatus.pending);
}

class OrderModel {
  final String id;
  final String userId;
  final String userEmail;
  final String gameId;
  final String gameName;
  final String packageId;
  final String packageName;
  final double price;
  final String playerId;
  final String whatsapp;
  final String paymentMethod;
  final String? paymentProofUrl;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? adminNote;

  const OrderModel({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.gameId,
    required this.gameName,
    required this.packageId,
    required this.packageName,
    required this.price,
    required this.playerId,
    required this.whatsapp,
    required this.paymentMethod,
    this.paymentProofUrl,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.adminNote,
  });

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return OrderModel(
      id: doc.id,
      userId: d['userId'] ?? '',
      userEmail: d['userEmail'] ?? '',
      gameId: d['gameId'] ?? '',
      gameName: d['gameName'] ?? '',
      packageId: d['packageId'] ?? '',
      packageName: d['packageName'] ?? '',
      price: (d['price'] ?? 0).toDouble(),
      playerId: d['playerId'] ?? '',
      whatsapp: d['whatsapp'] ?? '',
      paymentMethod: d['paymentMethod'] ?? '',
      paymentProofUrl: d['paymentProofUrl'],
      status: OrderStatusX.fromString(d['status'] ?? 'pending'),
      createdAt:
          (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
      adminNote: d['adminNote'],
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'userEmail': userEmail,
        'gameId': gameId,
        'gameName': gameName,
        'packageId': packageId,
        'packageName': packageName,
        'price': price,
        'playerId': playerId,
        'whatsapp': whatsapp,
        'paymentMethod': paymentMethod,
        'paymentProofUrl': paymentProofUrl,
        'status': status.value,
        'createdAt': Timestamp.fromDate(createdAt),
        'adminNote': adminNote,
      };

  OrderModel copyWith({
    String? id,
    String? status,
    String? paymentProofUrl,
    String? adminNote,
    DateTime? updatedAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      userId: userId,
      userEmail: userEmail,
      gameId: gameId,
      gameName: gameName,
      packageId: packageId,
      packageName: packageName,
      price: price,
      playerId: playerId,
      whatsapp: whatsapp,
      paymentMethod: paymentMethod,
      paymentProofUrl: paymentProofUrl ?? this.paymentProofUrl,
      status: status != null ? OrderStatusX.fromString(status) : this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      adminNote: adminNote ?? this.adminNote,
    );
  }
}
