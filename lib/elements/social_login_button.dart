import 'package:flutter/material.dart';

class SocialLoginButton extends StatelessWidget {
  final String label;
  final String iconAsset;
  final VoidCallback onPressed;
  final bool isApple; // Flag for potential specific styling

  const SocialLoginButton({
    super.key,
    required this.label,
    required this.iconAsset,
    required this.onPressed,
    this.isApple = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get theme for text style

    // Determine colors based on theme
    final Color effectiveButtonColor = theme.colorScheme.surface; // Use surface color
    final Color effectiveTextColor = theme.colorScheme.onSurface; // Use text color for surface
    final Color borderColor = theme.brightness == Brightness.light
        ? Colors.grey.shade300 // Light border for light theme
        : Colors.grey.shade700; // Darker border for dark theme

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: effectiveButtonColor, // Use themed background
        padding: const EdgeInsets.symmetric(vertical: 14.0), // Adjust padding
        side: BorderSide(color: borderColor), // Use themed border
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            iconAsset,
            height: 20.0, // Adjust icon size
            width: 20.0,
            // Consider adding colorFilter for dark mode if icons are black
            color: theme.brightness == Brightness.dark && isApple ? Colors.white : null, // Example for Apple logo
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: effectiveTextColor, // Use themed text color
            ),
          ),
        ],
      ),
    );
  }
} 