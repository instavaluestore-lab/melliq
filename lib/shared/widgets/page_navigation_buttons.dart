import 'package:flutter/material.dart';

class PageNavigationButtons extends StatelessWidget {
  const PageNavigationButtons({
    super.key,
    this.showBack = true,
    this.showHome = true,
  });

  final bool showBack;
  final bool showHome;

  @override
  Widget build(BuildContext context) {
    if (!showBack && !showHome) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        if (showBack)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).maybePop();
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        if (showBack && showHome) const SizedBox(width: 12),
        if (showHome)
          Expanded(
            child: FilledButton.icon(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              icon: const Icon(Icons.home_outlined),
              label: const Text('Home'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
