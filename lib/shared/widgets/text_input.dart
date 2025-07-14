import 'package:flutter/material.dart';
import 'package:ting/shared/theme.dart';

class TextInput extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;

  const TextInput({
    super.key,
    required this.controller,
    required this.labelText,
  });

  @override
  State<TextInput> createState() => _TextInputState();
}

class _TextInputState extends State<TextInput> {
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      decoration: InputDecoration(
        labelText: widget.labelText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.inputBorderRadius),
          borderSide: BorderSide(color: AppTheme.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.inputBorderRadius),
          borderSide: BorderSide(color: AppTheme.focusedInputBorder),
        ),
      ),
    );
  }
}
