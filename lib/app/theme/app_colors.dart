import 'package:flutter/material.dart';

/// ChargeMate Design System — Color Palette
///
/// Built on EV industry UX best practices (Tesla, PlugShare, Rivian):
/// - Deep Obsidian background for night driving & OLED power efficiency
/// - Electric Cyan & Indigo for tech and connectivity
/// - Vivid Mint/Emerald for availability and high-power charging
/// - Solar Amber for Charge & Explore recommendations
/// - WCAG AA compliant contrast ratios across all semantic states
abstract final class AppColors {
  // ── Background & Surfaces (Obsidian Layering) ──────────────────────
  static const Color background = Color(0xFF090D16);
  static const Color surface = Color(0xFF111827);
  static const Color surfaceElevated = Color(0xFF1A2338);
  static const Color surfaceVariant = Color(0xFF222F4B);
  static const Color surfaceHighlight = Color(0xFF2B3A5C);
  static const Color surfaceLight = Color(0xFF2A3756); // Shimmer highlight

  // ── Glassmorphism / Translucent Surfaces ──────────────────────────
  static const Color glassBg = Color(0xB3111827);
  static const Color glassStroke = Color(0x1FFFFFFF);
  static const Color glassHighlight = Color(0x0DFFFFFF);

  // ── Primary Brand (Electric Cyan) ──────────────────────────────────
  static const Color primary = Color(0xFF00D4FF);
  static const Color primaryVariant = Color(0xFF00A3CC);
  static const Color primaryDark = Color(0xFF007A99);
  static const Color textOnPrimary = Color(0xFF070B14);

  // ── Secondary (Electric Indigo / Violet) ───────────────────────────
  static const Color secondary = Color(0xFF6366F1);
  static const Color secondaryVariant = Color(0xFF4F46E5);

  // ── Explore / Tourism Accent (Solar Amber) ─────────────────────────
  static const Color explore = Color(0xFFF59E0B);
  static const Color exploreLight = Color(0xFFFBBF24);

  // ── Semantic / Availability (The Traffic Light Standard) ──────────
  static const Color statusOperational = Color(0xFF10B981); // Emerald Green
  static const Color statusIssues = Color(0xFFF59E0B);      // Amber
  static const Color statusOffline = Color(0xFFEF4444);     // Crimson Red
  static const Color statusUnknown = Color(0xFF94A3B8);     // Muted Slate

  // Aliases for general alerts
  static const Color success = statusOperational;
  static const Color warning = statusIssues;
  static const Color error = statusOffline;
  static const Color info = primary;
  static const Color accent = statusOperational;

  // ── Typography Colors ──────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF94A3B8); // High-readability slate
  static const Color textTertiary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF475569);

  // ── Borders, Outlines & Dividers ───────────────────────────────────
  static const Color border = Color(0xFF1E293B);
  static const Color borderHighlight = Color(0xFF334155);
  static const Color divider = Color(0xFF1E293B);

  // ── Gradients ──────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00D4FF), Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient energyGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF00D4FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient exploreGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF141D30), Color(0xFF0F172A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── Charging Speed Tier Colors ─────────────────────────────────────
  // High-glanceability speed color system:
  // Ultra-Fast DC (100kW+) -> Electric Cyan
  // Fast DC (50-99kW)      -> Vivid Mint
  // Medium AC (22-49kW)    -> Sky Blue
  // Standard AC (<22kW)    -> Slate Grey
  static const Color speedUltra = Color(0xFF00D4FF);
  static const Color speedFast = Color(0xFF10B981);
  static const Color speedMedium = Color(0xFF38BDF8);
  static const Color speedStandard = Color(0xFF94A3B8);

  static Color chargingSpeedColor(double kw) {
    if (kw >= 100) return speedUltra;
    if (kw >= 50) return speedFast;
    if (kw >= 22) return speedMedium;
    return speedStandard;
  }
}
