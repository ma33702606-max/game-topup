import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/game.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // ─── Auth ────────────────────────────────────────────────────────────────

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signIn(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await _saveFcmToken(credential.user!.uid);
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _authError(e.code);
    }
  }

  Future<UserCredential> register(
      String email, String password, String name) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await credential.user?.updateDisplayName(name);
      await _db.collection('users').doc(credential.user!.uid).set({
        'uid': credential.user!.uid,
        'email': email.trim(),
        'name': name.trim(),
        'role': 'user',
        'fcmTokens': [],
        'createdAt': FieldValue.serverTimestamp(),
      });
      await _saveFcmToken(credential.user!.uid);
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _authError(e.code);
    }
  }

  Future<void> signOut() async {
    final uid = currentUser?.uid;
    if (uid != null) await _removeFcmToken(uid);
    await _auth.signOut();
  }

  Future<bool> isAdmin() async {
    final user = currentUser;
    if (user == null) return false;
    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      return doc.data()?['role'] == 'admin';
    } catch (_) {
      return false;
    }
  }

  String _authError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'البريد الإلكتروني غير مسجل';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة';
      case 'email-already-in-use':
        return 'البريد الإلكتروني مستخدم بالفعل';
      case 'weak-password':
        return 'كلمة المرور ضعيفة جداً';
      case 'invalid-email':
        return 'البريد الإلكتروني غير صحيح';
      case 'too-many-requests':
        return 'محاولات كثيرة، حاول لاحقاً';
      default:
        return 'حدث خطأ في المصادقة';
    }
  }

  // ─── FCM Tokens ──────────────────────────────────────────────────────────

  Future<void> _saveFcmToken(String uid) async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;
      await _db.collection('users').doc(uid).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Future<void> _removeFcmToken(String uid) async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;
      await _db.collection('users').doc(uid).update({
        'fcmTokens': FieldValue.arrayRemove([token]),
      });
    } catch (_) {}
  }

  Future<List<String>> getAdminFcmTokens() async {
    try {
      final snap = await _db
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();
      final tokens = <String>[];
      for (final doc in snap.docs) {
        final list = List<String>.from(doc.data()['fcmTokens'] ?? []);
        tokens.addAll(list);
      }
      return tokens;
    } catch (_) {
      return [];
    }
  }

  Future<List<String>> getUserFcmTokens(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      return List<String>.from(doc.data()?['fcmTokens'] ?? []);
    } catch (_) {
      return [];
    }
  }

  // ─── Games (Firestore) ───────────────────────────────────────────────────

  Stream<List<GameModel>> getGames() {
    return _db
        .collection('games')
        .where('isActive', isEqualTo: true)
        .orderBy('sortOrder')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => GameModel.fromFirestore(d)).toList());
  }

  Stream<List<PackageModel>> getPackages(String gameId) {
    return _db
        .collection('games')
        .doc(gameId)
        .collection('packages')
        .where('isActive', isEqualTo: true)
        .orderBy('price')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => PackageModel.fromFirestore(d)).toList());
  }

  Future<void> addGame(Map<String, dynamic> data) async {
    await _db.collection('games').add({
      ...data,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateGame(String gameId, Map<String, dynamic> data) async {
    await _db.collection('games').doc(gameId).update(data);
  }

  Future<void> deleteGame(String gameId) async {
    await _db.collection('games').doc(gameId).update({'isActive': false});
  }

  Future<void> addPackage(String gameId, Map<String, dynamic> data) async {
    await _db
        .collection('games')
        .doc(gameId)
        .collection('packages')
        .add({...data, 'isActive': true, 'createdAt': FieldValue.serverTimestamp()});
  }

  Future<void> updatePackage(
      String gameId, String pkgId, Map<String, dynamic> data) async {
    await _db
        .collection('games')
        .doc(gameId)
        .collection('packages')
        .doc(pkgId)
        .update(data);
  }

  Future<void> deletePackage(String gameId, String pkgId) async {
    await _db
        .collection('games')
        .doc(gameId)
        .collection('packages')
        .doc(pkgId)
        .update({'isActive': false});
  }

  // ─── Banners ─────────────────────────────────────────────────────────────

  Stream<List<BannerModel>> getBanners() {
    return _db
        .collection('banners')
        .where('isActive', isEqualTo: true)
        .orderBy('sortOrder')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => BannerModel.fromFirestore(d)).toList());
  }

  Future<void> addBanner(Map<String, dynamic> data) async {
    await _db.collection('banners').add({
      ...data,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateBanner(String id, Map<String, dynamic> data) async {
    await _db.collection('banners').doc(id).update(data);
  }

  Future<void> deleteBanner(String id) async {
    await _db.collection('banners').doc(id).update({'isActive': false});
  }

  // ─── Orders ──────────────────────────────────────────────────────────────

  Future<String> createOrder(OrderModel order) async {
    final docRef = await _db.collection('orders').add(order.toFirestore());
    return docRef.id;
  }

  Stream<List<OrderModel>> getUserOrders(String userId) {
    return _db
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => OrderModel.fromFirestore(d)).toList());
  }

  Stream<List<OrderModel>> getAllOrders() {
    return _db
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => OrderModel.fromFirestore(d)).toList());
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status,
      {String? note}) async {
    final data = <String, dynamic>{
      'status': status.value,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (note != null && note.isNotEmpty) data['adminNote'] = note;
    await _db.collection('orders').doc(orderId).update(data);
  }

  // ─── Storage ─────────────────────────────────────────────────────────────

  Future<String> uploadPaymentProof(String userId, String orderId, File file) async {
    final ext = file.path.split('.').last.toLowerCase();
    final ref = _storage
        .ref()
        .child('payment_proofs/$userId/$orderId/proof.$ext');
    final metadata = SettableMetadata(
      contentType: 'image/$ext',
      customMetadata: {'userId': userId, 'orderId': orderId},
    );
    final task = await ref.putFile(file, metadata);
    return await task.ref.getDownloadURL();
  }

  // ─── Payment Settings ────────────────────────────────────────────────────

  Stream<Map<String, dynamic>> getPaymentSettingsStream() {
    return _db
        .collection('settings')
        .doc('payment')
        .snapshots()
        .map((doc) => doc.data() ?? {});
  }

  Future<void> updatePaymentSettings(Map<String, dynamic> data) async {
    await _db
        .collection('settings')
        .doc('payment')
        .set(data, SetOptions(merge: true));
  }

  // ─── Support ─────────────────────────────────────────────────────────────

  Future<void> sendSupportMessage({
    required String userId,
    required String email,
    required String subject,
    required String message,
  }) async {
    await _db.collection('support').add({
      'userId': userId,
      'email': email,
      'subject': subject,
      'message': message,
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
