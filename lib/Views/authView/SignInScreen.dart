import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safesiteconnect/navigation/route.dart';

import '../../ViewsModels/auth_viewmodel.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  SignInScreenState createState() => SignInScreenState();
}

class SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isButtonEnabled = false;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
  }

  void _validateForm() {
    setState(() {
      _isButtonEnabled = _emailController.text.isNotEmpty &&
          _passwordController.text.isNotEmpty &&
          RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
              .hasMatch(_emailController.text);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final viewModel = Provider.of<AuthViewModel>(context, listen: false);

      // Afficher un snackbar de chargement
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              SizedBox(width: 16),
              Text('Connexion en cours...'),
            ],
          ),
          backgroundColor: Color(0xFF7ED957),
          duration: Duration(seconds: 2),
        ),
      );

      // Appeler le service de login
      await viewModel.login(_emailController.text, _passwordController.text);

      // Fermer le snackbar de chargement
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Vérifier s'il y a une erreur
      if (viewModel.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(viewModel.errorMessage!),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                viewModel.clearError();
              },
            ),
          ),
        );
        return;
      }

      // Navigation basée sur le rôle
      if (viewModel.user != null) {
        final role = viewModel.user!.role.toLowerCase();

        // Succès de connexion - afficher message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bienvenue ${viewModel.user!.nom} !'),
            backgroundColor: Color(0xFF7ED957),
            duration: const Duration(seconds: 2),
          ),
        );

        // Délai pour une meilleure UX
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          switch (role) {
            case 'admin':
              Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
              break;
            case 'employee':
              Navigator.pushReplacementNamed(context, AppRoutes.home);
              break;
            default:
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Rôle non reconnu. Contactez l\'administrateur.'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 3),
                ),
              );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la connexion'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Background gradient
          Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF005B96),
                  Color(0xFFE8F5E8),
                  Color(0xFFF0F0F0),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildHeader(),
                    const SizedBox(height: 30),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: _buildForm(context, authViewModel),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),

          // Loading overlay
          if (authViewModel.isLoading)
            Container(
              color: Colors.black.withOpacity(0.6),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Color(0xFF7ED957),
                      strokeWidth: 4,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Connexion en cours...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.15),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/1024.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF005B96),
                        Color(0xFF7ED957),
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 40,
                    color: Colors.white,
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'SafeSiteConnect',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Connectez-vous à votre compte',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context, AuthViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Email Field
            _buildEmailField(),
            const SizedBox(height: 16),

            // Password Field
            _buildPasswordField(),
            const SizedBox(height: 12),

            // Forgot Password
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.forgotPassword);
                },
                child: Text(
                  'Mot de passe oublié ?',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Login Button
            _buildSignInButton(viewModel),




          ],
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: _emailController,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: 'Email',
          labelStyle: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF7ED957).withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.email_outlined,
              color: Colors.white.withOpacity(0.9),
              size: 18,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF7ED957),
              width: 2,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        ),
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Veuillez entrer un email';
          }
          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
            return 'Format d\'email invalide';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: _passwordController,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: 'Mot de passe',
          labelStyle: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF005B96).withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.lock_outline,
              color: Colors.white.withOpacity(0.9),
              size: 18,
            ),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
              color: Colors.white.withOpacity(0.8),
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _isPasswordVisible = !_isPasswordVisible;
              });
            },
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF7ED957),
              width: 2,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding:
          const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        ),
        obscureText: !_isPasswordVisible,
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) => _handleLogin(),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Veuillez entrer un mot de passe';
          }
          if (value.length < 6) {
            return 'Le mot de passe doit contenir au moins 6 caractères';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildSignInButton(AuthViewModel viewModel) {
    final isEnabled = _isButtonEnabled && !viewModel.isLoading;

    return Container(
      height: 50,
      decoration: BoxDecoration(
        gradient: isEnabled
            ? const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF7ED957),
            Color(0xFF005B96),
          ],
        )
            : LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.white.withOpacity(0.3),
            Colors.white.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: isEnabled
            ? [
          BoxShadow(
            color: const Color(0xFF7ED957).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: isEnabled ? _handleLogin : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: viewModel.isLoading
            ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : const Text(
          'Se connecter',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

}