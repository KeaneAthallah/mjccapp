import 'package:flutter/material.dart';

import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/home/main_scaffold.dart';
import '../presentation/screens/root_screen.dart';

/// Central route table for the app.
class Routes {
  Routes._();

  static const String root = '/';
  static const String login = '/login';
  static const String home = '/home';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const MainScaffold());
      default:
        return MaterialPageRoute(builder: (_) => const RootScreen());
    }
  }
}
