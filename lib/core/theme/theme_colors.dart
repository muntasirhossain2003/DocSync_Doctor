import 'package:flutter/material.dart';

/// Theme-aware color extensions for BuildContext
/// Automatically adapts colors based on current theme (light/dark)
extension ThemeColors on BuildContext {
  // Core Material 3 colors
  Color get primaryColor => Theme.of(this).colorScheme.primary;
  Color get secondaryColor => Theme.of(this).colorScheme.secondary;
  Color get onPrimary => Theme.of(this).colorScheme.onPrimary;
  Color get onSecondary => Theme.of(this).colorScheme.onSecondary;
  Color get secondaryContainer => Theme.of(this).colorScheme.secondaryContainer;
  Color get onSecondaryContainer => Theme.of(this).colorScheme.onSecondaryContainer;
  
  // Surface colors
  Color get surface => Theme.of(this).colorScheme.surface;
  Color get onSurface => Theme.of(this).colorScheme.onSurface;
  Color get surfaceVariant => Theme.of(this).colorScheme.surfaceContainer;
  Color get onSurfaceVariant => Theme.of(this).colorScheme.onSurfaceVariant;
  
  // Background colors  
  Color get background => Theme.of(this).colorScheme.surface;
  Color get onBackground => Theme.of(this).colorScheme.onSurface;
  
  // Text colors
  Color get textPrimary => Theme.of(this).colorScheme.onSurface;
  Color get textSecondary => Theme.of(this).colorScheme.onSurfaceVariant;
  
  // Error colors
  Color get error => Theme.of(this).colorScheme.error;
  Color get onError => Theme.of(this).colorScheme.onError;
  Color get errorContainer => Theme.of(this).colorScheme.errorContainer;
  Color get onErrorContainer => Theme.of(this).colorScheme.onErrorContainer;
  
  // Outline/border colors
  Color get borderColor => Theme.of(this).colorScheme.outline;
  Color get outline => Theme.of(this).colorScheme.outline;
  Color get outlineVariant => Theme.of(this).colorScheme.outlineVariant;
  
  // Inverse colors
  Color get inversePrimary => Theme.of(this).colorScheme.inversePrimary;
  Color get inverseSurface => Theme.of(this).colorScheme.inverseSurface;
  Color get onInverseSurface => Theme.of(this).colorScheme.onInverseSurface;
  
  // Custom semantic colors (from AppTheme extension)
  Color get success => const Color(0xFF2E7D32);
  Color get warning => const Color(0xFFF57C00);
  Color get info => const Color(0xFF1976D2);
  
  // Adaptive grey colors
  Color get grey => isDarkMode ? const Color(0xFF9E9E9E) : const Color(0xFF757575);
  Color get greyLight => isDarkMode ? const Color(0xFF424242) : const Color(0xFFF5F5F5);
  Color get greyDark => isDarkMode ? const Color(0xFFBDBDBD) : const Color(0xFF424242);
  
  // Secondary variants
  Color get secondaryLight => isDarkMode 
      ? secondaryColor.withOpacity(0.2) 
      : secondaryColor.withOpacity(0.1);
  
  // Helper to check if dark mode is active
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
