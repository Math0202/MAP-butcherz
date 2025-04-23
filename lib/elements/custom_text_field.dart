import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  // final TextEditingController? controller; // Uncomment if using controllers
  final String hintText;
  final IconData prefixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged; // Optional: Add if needed

  const CustomTextField({
    super.key,
    // this.controller, // Uncomment if using controllers
    required this.hintText,
    required this.prefixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
    this.onChanged, // Optional: Add if needed
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextFormField(
        // controller: controller, // Uncomment if using controllers
        obscureText: obscureText,
        keyboardType: keyboardType,
        onChanged: onChanged, // Optional: Add if needed
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(prefixIcon),
          suffixIcon: suffixIcon,
          border: InputBorder.none, // Remove default border
        ),
      ),
    );
  }
} 