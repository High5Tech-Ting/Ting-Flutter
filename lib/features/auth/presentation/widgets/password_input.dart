import 'package:flutter/material.dart';
import 'package:ting/shared/theme.dart';

class PasswordInput extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;

  const PasswordInput({
    super.key,
    required this.controller,
    this.labelText = 'Password',
  });

  @override
  State<PasswordInput> createState() => _PasswordInputState();
}

class _PasswordInputState extends State<PasswordInput> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: widget.labelText,
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
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
    );
  }
}