import 'package:flutter/material.dart';

class FeaturePageScaffold extends StatelessWidget {
  const FeaturePageScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
    this.floatingActionButton,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> children;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      floatingActionButton: floatingActionButton,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
                ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                : [const Color(0xFFF8F9FA), const Color(0xFFE9ECEF)],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            children: [
              _FeatureHeader(
                title: title,
                subtitle: subtitle,
                icon: icon,
              ),
              const SizedBox(height: 20),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureHeader extends StatelessWidget {
  const _FeatureHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(icon, size: 42, color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF24354E),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            height: 1.4,
            color: Color(0xFF8B8B8B),
          ),
        ),
      ],
    );
  }
}

class FeatureCard extends StatelessWidget {
  const FeatureCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.leadingIcon,
    this.trailing,
    this.onTap,
    this.badge,
  });

  final String title;
  final String subtitle;
  final IconData leadingIcon;
  final Widget? trailing;
  final VoidCallback? onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.15),
                  Theme.of(context).colorScheme.secondary.withOpacity(0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(leadingIcon, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF24354E),
                        ),
                      ),
                    ),
                    if (badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          badge!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.3,
                    color: Color(0xFF8B8B8B),
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );

    if (onTap == null) {
      return card;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: card,
    );
  }
}

class InputChipButton extends StatelessWidget {
  const InputChipButton({
    super.key,
    required this.label,
    required this.icon,
    this.onTap,
    this.selected = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected 
              ? const Color(0xFF6A11CB) 
              : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected 
                ? const Color(0xFF6A11CB) 
                : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE2D5F8)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? Colors.white : const Color(0xFF6A11CB),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected 
                    ? Colors.white 
                    : (isDark ? Colors.white : const Color(0xFF24354E)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
