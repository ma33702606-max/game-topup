import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/providers/auth_provider.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/topup/topup_screen.dart';
import '../../presentation/screens/payment/payment_screen.dart';
import '../../presentation/screens/confirmation/confirmation_screen.dart';
import '../../presentation/screens/orders/my_orders_screen.dart';
import '../../presentation/screens/support/support_screen.dart';
import '../../presentation/screens/admin/admin_dashboard_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/register';

      if (!isLoggedIn && !isAuthRoute && state.matchedLocation != '/') {
        return '/login';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _buildPage(const LoginScreen(), state),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => _buildPage(const RegisterScreen(), state),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) => _buildPage(const HomeScreen(), state),
      ),
      GoRoute(
        path: '/topup/:gameId',
        pageBuilder: (context, state) => _buildPage(
          TopupScreen(gameId: state.pathParameters['gameId'] ?? ''),
          state,
        ),
      ),
      GoRoute(
        path: '/payment',
        pageBuilder: (context, state) => _buildPage(const PaymentScreen(), state),
      ),
      GoRoute(
        path: '/confirmation',
        pageBuilder: (context, state) => _buildPage(const ConfirmationScreen(), state),
      ),
      GoRoute(
        path: '/orders',
        pageBuilder: (context, state) => _buildPage(const MyOrdersScreen(), state),
      ),
      GoRoute(
        path: '/support',
        pageBuilder: (context, state) => _buildPage(const SupportScreen(), state),
      ),
      GoRoute(
        path: '/admin',
        pageBuilder: (context, state) => _buildPage(const AdminDashboardScreen(), state),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Color(0xFFE53935)),
            const SizedBox(height: 16),
            Text('الصفحة غير موجودة', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('العودة للرئيسية'),
            ),
          ],
        ),
      ),
    ),
  );
});

CustomTransitionPage<void> _buildPage(Widget child, GoRouterState state) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeIn).animate(animation),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 250),
  );
}
