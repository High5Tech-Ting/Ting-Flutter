import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ting/features/auth/data/auth_repository.dart';
import 'package:ting/shared/widgets/custom_clip_path.dart';
import 'package:ting/features/auth/presentation/widgets/password_input.dart';
import 'package:ting/shared/theme.dart';
import 'package:ting/shared/widgets/primary_button.dart';
import 'package:ting/shared/widgets/text_input.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _signIn() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please fill in all fields')));
      return;
    }
    try {
      var user = await AuthRepository.signIn(email: email, password: password);

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign in failed. Please try again.')),
        );
        return;
      }
    } on FirebaseAuthException catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid credentials. Please try again.')),
      );
    }
  }

  Future<void> _resetPassword() async {
    var email = _emailController.text;
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter your email address.')),
      );
      return;
    }

    try {
      await AuthRepository.resetPassword(context, email);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send password reset email.')),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipPath(
                clipper: CustomClipPath(),
                child: Image.asset(
                  'assets/images/auth_image.png',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 400,
                ),
              ),

              Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  children: [
                    RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.headlineLarge,
                        children: [
                          const TextSpan(text: "Stay connected. Stay in the "),
                          TextSpan(
                            text: "loop",
                            style: TextStyle(color: AppTheme.primary),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 32),

                    TextInput(controller: _emailController, labelText: 'Email'),

                    SizedBox(height: 16),

                    PasswordInput(controller: _passwordController),

                    SizedBox(height: 32),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () async {
                            await _resetPassword();
                          },
                          child: Text(
                            "Forgot your password?",

                            style: AppTheme.linkText.copyWith(
                              decoration: TextDecoration.underline,
                              decorationThickness: 1.5,
                            ),
                          ),
                        ),

                        PrimaryButton(
                          onPressed: _signIn,
                          child: SizedBox(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("Login"),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_forward,
                                  color: AppTheme.buttonText,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
