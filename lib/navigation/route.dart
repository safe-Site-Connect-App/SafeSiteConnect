import 'package:flutter/material.dart';
import 'package:safesiteconnect/Views/HomeViews/AdminViews/PointageEmployScreen.dart';
import 'package:safesiteconnect/Views/HomeViews/AdminViews/TacheEmployScreen.dart';
import 'package:safesiteconnect/Views/HomeViews/EmployeeSpace/PageAlertes.dart';
import 'package:safesiteconnect/Views/HomeViews/EmployeeSpace/ProfilEmployePage.dart';
// CORRECTION : Importez le bon fichier
import '../Views/HomeViews/AdminViews/HomeAdmin.dart';
import '../Views/HomeViews/AdminViews/IncidentScreen.dart';
import '../Views/HomeViews/AdminViews/UsersScreen.dart';
import '../Views/HomeViews/EmployeeSpace/HomeEmployee.dart';
import '../Views/HomeViews/EmployeeSpace/PointageScreen.dart';
import '../Views/HomeViews/EmployeeSpace/taskScreen.dart';
import '../Views/authView/ChangePasswordScreen.dart';
import '../Views/authView/ForgotPasswordScreen.dart';
import '../Views/authView/SignInScreen.dart' hide HomeScreen;
import '../Views/authView/VerifyOtpScreen.dart';

class AppRoutes {
  static const String signIn = '/signin';
  static const String home = '/home';
  static const String pointage = '/pointage';
  static const String signUp = '/signup';
  static const String forgotPassword = '/forgot';
  static const String taskscreen = '/tasks';
  static const String alert = '/alert';
  static const String profile = '/profile';
  static const String verifyOtp = '/verifyOtp';
  static const String adminDashboard = '/dashboard';
  static const String usersScreen = '/user_management';
  static const String incident_management = '/incident_management';
  static const String task_management = '/task_management';
  static const String attendance_tracking = '/attendance_tracking';
  static const String changePassword = '/change-password';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case signIn:
        return MaterialPageRoute(builder: (_) => const SignInScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case pointage:
        return MaterialPageRoute(builder: (_) => const PointageScreen());
      case changePassword:
        return MaterialPageRoute(
          builder: (_) => const ChangePasswordScreen(),
          settings: settings, // ← Important pour passer les arguments
        );
      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
      case taskscreen:
        return MaterialPageRoute(builder: (_) => const TaskScreen());
      case alert:
        return MaterialPageRoute(builder: (_) => const PageAlertes());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfilEmployePage());
      case verifyOtp:
        return MaterialPageRoute(
          builder: (_) => const VerifyCodeScreen(), // ← Nom correct
          settings: settings, // ← CRUCIAL : Ajout pour passer les arguments
        );
      case adminDashboard:
        return MaterialPageRoute(builder: (_) => const AdminDashboard());
      case usersScreen:
        return MaterialPageRoute(builder: (_) => const UsersScreen());
      case incident_management:
        return MaterialPageRoute(builder: (_) => const IncidentScreen());
      case task_management:
        return MaterialPageRoute(builder: (_) => const TacheEmployScreen());
      case attendance_tracking:
        return MaterialPageRoute(builder: (_) => const PointageEmployScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Page non trouvée')),
          ),
        );
    }
  }
}