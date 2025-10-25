import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../ViewsModels/auth_viewmodel.dart';
import '../../navigation/route.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ForgotPasswordScreenState createState() => ForgotPasswordScreenState();
}

class ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateForm);
  }

  void _validateForm() {
    setState(() {
      _isButtonEnabled = _emailController.text.isNotEmpty &&
          RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
              .hasMatch(_emailController.text);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleForgotPassword() async {
    if (_formKey.currentState!.validate()) {
      final viewModel = Provider.of<AuthViewModel>(context, listen: false);

      // Afficher snackbar de chargement
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              SizedBox(width: 16),
              Text('Envoi du code...'),
            ],
          ),
          backgroundColor: Color(0xFF7ED957),
          duration: Duration(seconds: 3),
        ),
      );

      final userId = await viewModel.forgotPassword(_emailController.text);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Debug logs
      print('🔍 DEBUG - userId reçu: $userId');
      print('🔍 DEBUG - errorMessage: ${viewModel.errorMessage}');

      if (viewModel.errorMessage != null) {
        print('❌ ERREUR détectée: ${viewModel.errorMessage}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(viewModel.errorMessage!),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
            ),
          ),
        );
      } else if (userId != null) {
        print('✅ SUCCÈS - Navigation vers VerifyOtp avec userId: $userId');

        // Afficher le message de succès
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Code envoyé à votre email !'),
            backgroundColor: Color(0xFF7ED957),
            duration: Duration(seconds: 2),
          ),
        );

        // Navigation automatique après 1.5 secondes
        await Future.delayed(const Duration(milliseconds: 1500));

        // Vérifier que le contexte est toujours valide
        if (mounted) {
          Navigator.pushNamed(context, AppRoutes.verifyOtp, arguments: userId);
          print('🚀 Navigation exécutée vers VerifyOtp');
        }
      } else {
        print('⚠️ ATTENTION - userId est null mais pas d\'errorMessage');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Une erreur inattendue s\'est produite'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<AuthViewModel>(context);

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
                      child: _buildForm(context, viewModel),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),

          // Loading overlay
          if (viewModel.isLoading)
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
                      'Envoi du code...',
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
                    Icons.lock_reset,
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
          'Réinitialiser le mot de passe',
          style: TextStyle(
            fontSize: 24,
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
          'Entrez votre adresse e-mail pour recevoir un code de vérification',
          textAlign: TextAlign.center,
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
            _buildEmailField(),
            const SizedBox(height: 24),
            _buildSendLinkButton(viewModel),
            const SizedBox(height: 20),
            _buildBackToSignInButton(context),
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
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) => _handleForgotPassword(),
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

  Widget _buildSendLinkButton(AuthViewModel viewModel) {
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
        onPressed: isEnabled ? _handleForgotPassword : null,
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
          'Envoyer le code',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildBackToSignInButton(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.white.withOpacity(0.8),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextButton(
        onPressed: () {
          Navigator.pushReplacementNamed(context, AppRoutes.signIn);
        },
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Retour à la connexion',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}