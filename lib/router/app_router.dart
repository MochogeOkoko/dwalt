import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import 'routes.dart';

/// Provider for the router
final routerProvider = Provider<GoRouter>((ref) {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);

  return GoRouter(
    initialLocation: isAuthenticated ? AppRoutes.homePath : AppRoutes.loginPath,
    redirect: (context, state) {
      // If user is not authenticated and trying to access protected routes
      if (!isAuthenticated &&
          AppRoutes.isProtectedRoute(state.matchedLocation)) {
        return AppRoutes.loginPath;
      }

      // If user is authenticated and on login page, redirect to home
      if (isAuthenticated && state.matchedLocation == AppRoutes.loginPath) {
        return AppRoutes.homePath;
      }

      return null;
    },
    routes: AppRoutes.routes,
  );
});
