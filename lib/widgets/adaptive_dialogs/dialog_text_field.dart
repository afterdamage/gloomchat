import 'package:flutter/material.dart';

class DialogTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final String? initialText;
  final String? counterText;
  final String? prefixText;
  final String? suffixText;
  final String? errorText;
  final bool obscureText;
  final bool isDestructive = false;
  final int? minLines;
  final int? maxLines;
  final TextInputType? keyboardType;
  final int? maxLength;
  final bool autocorrect = true;

  const DialogTextField({
    super.key,
    this.hintText,
    this.labelText,
    this.initialText,
    this.prefixText,
    this.suffixText,
    this.minLines,
    this.maxLines,
    this.keyboardType,
    this.maxLength,
    this.controller,
    this.counterText,
    this.errorText,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      minLines: minLines,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      autocorrect: autocorrect,
      decoration: InputDecoration(
        errorText: errorText,
        hintText: hintText,
        labelText: labelText,
        prefixText: prefixText,
        suffixText: suffixText,
        counterText: counterText,
      ),
    );
  }
}
