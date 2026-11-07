import 'package:flutter/material.dart';

import '../../screens/auth/forgot_password_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/auth/welcome_screen.dart';
import '../../screens/onboarding/buyer_onboarding_screen.dart';
import '../../screens/shell/home_shell.dart';

/// Rutas nombradas de nivel superior (flujo de auth + shell principal).
/// Las pantallas con argumentos se abren con MaterialPageRoute directo.
class Routes {
  static const welcome = '/welcome';
  static const register = '/register';
  static const login = '/login';
  static const forgot = '/forgot';
  static const onboarding = '/onboarding';
  static const home = '/home';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case welcome:
        return _route(const WelcomeScreen(), settings);
      case register:
        return _route(const RegisterScreen(), settings);
      case login:
        return _route(const LoginScreen(), settings);
      case forgot:
        return _route(const ForgotPasswordScreen(), settings);
      case onboarding:
        return _route(const BuyerOnboardingScreen(), settings);
      case home:
        return _route(const HomeShell(), settings);
      default:
        return _route(const WelcomeScreen(), settings);
    }
  }

  static MaterialPageRoute<dynamic> _route(Widget child, RouteSettings s) {
    return MaterialPageRoute<dynamic>(builder: (_) => child, settings: s);
  }
}
