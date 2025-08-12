import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../pages/login_page.dart';
import '../pages/home_page.dart';
import '../pages/gmail_page.dart';
import '../pages/tickets_page.dart';
import '../pages/analytics_page.dart';
import '../pages/settings_page.dart';

/// Application routes configuration
class AppRoutes {
  // Route names
  static const String login = '/login';
  static const String home = '/';
  static const String gmail = '/gmail';
  static const String tickets = '/tickets';
  static const String analytics = '/analytics';
  static const String settings = '/settings';

  // Route paths
  static const String loginPath = '/login';
  static const String homePath = '/';
  static const String gmailPath = '/gmail';
  static const String ticketsPath = '/tickets';
  static const String analyticsPath = '/analytics';
  static const String settingsPath = '/settings';

  /// Get all routes for the application
  static List<GoRoute> get routes => [
    // Public routes
    GoRoute(
      path: loginPath,
      name: login,
      builder: (context, state) => const LoginPage(),
    ),

    // Protected routes
    GoRoute(
      path: homePath,
      name: home,
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: gmailPath,
      name: gmail,
      builder: (context, state) => const GmailPage(),
    ),
    GoRoute(
      path: ticketsPath,
      name: tickets,
      builder: (context, state) => const TicketsPage(),
    ),
    GoRoute(
      path: analyticsPath,
      name: analytics,
      builder: (context, state) => const AnalyticsPage(),
    ),
    GoRoute(
      path: settingsPath,
      name: settings,
      builder: (context, state) => const SettingsPage(),
    ),
  ];

  /// Get protected routes that require authentication
  static List<String> get protectedRoutes => [
    homePath,
    gmailPath,
    ticketsPath,
    analyticsPath,
    settingsPath,
  ];

  /// Check if a route requires authentication
  static bool isProtectedRoute(String route) {
    return protectedRoutes.contains(route);
  }
}
