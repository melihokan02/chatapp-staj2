import 'package:flutter/material.dart';

InputDecoration modernTextInputDecoration(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return InputDecoration(
    labelStyle: TextStyle(
      color: isDark ? Colors.white60 : Colors.black54, 
      fontSize: 14,
    ),
    filled: true,
    fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFF6A11CB), width: 2),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: isDark ? Colors.white12 : Colors.grey.withOpacity(0.2), 
        width: 1,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Colors.redAccent, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
  );
}