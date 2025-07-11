import 'package:flutter/material.dart';
import 'package:ting/auth/presentation/widgets/custom_clip_path.dart';
import 'package:ting/auth/presentation/widgets/password_input.dart';
import 'package:ting/shared/theme.dart';
import 'package:ting/shared/widgets/primary_button.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

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

                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.inputBorderRadius,
                          ),
                          borderSide: BorderSide(color: AppTheme.inputBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.inputBorderRadius,
                          ),
                          borderSide: BorderSide(
                            color: AppTheme.focusedInputBorder,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 16),

                    PasswordInput(controller: _passwordController),

                    SizedBox(height: 32),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () {},
                          child: Text(
                            "Forgot your password?",
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.black54,
                            ),
                          ),
                        ),

                        PrimaryButton(
                          onPressed: () {},
                          child: SizedBox(
                            width: 64,
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
