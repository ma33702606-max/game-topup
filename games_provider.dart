import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/firebase_service.dart';
import '../entities/game.dart';
import 'auth_provider.dart';

final gamesProvider = StreamProvider<List<GameModel>>((ref) {
  return ref.watch(firebaseServiceProvider).getGames();
});

final packagesProvider =
    StreamProvider.family<List<PackageModel>, String>((ref, gameId) {
  return ref.watch(firebaseServiceProvider).getPackages(gameId);
});

final bannersProvider = StreamProvider<List<BannerModel>>((ref) {
  return ref.watch(firebaseServiceProvider).getBanners();
});

final paymentSettingsStreamProvider =
    StreamProvider<Map<String, dynamic>>((ref) {
  return ref.watch(firebaseServiceProvider).getPaymentSettingsStream();
});
