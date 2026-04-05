import 'package:flutter/material.dart';

import '../../models/hero_state.dart';

class CycleHeroCard extends StatelessWidget {
  final HeroState state;
  final bool isPeriodActive;
  final VoidCallback onLogPeriod;

  const CycleHeroCard({
    super.key,
    required this.state,
    required this.isPeriodActive,
    required this.onLogPeriod,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF2F5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children:[
          Text(
            state.primaryText,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF333333),
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),

          if (state.secondaryText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text(
                state.secondaryText,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF777777),
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          if (state.infoText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(
                state.infoText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF777777),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          if (state.showLogButton)
            Padding(
              padding: const EdgeInsets.only(top: 32.0),
              child: ElevatedButton(
                onPressed: onLogPeriod,
                style: ElevatedButton.styleFrom(
                  // Slightly different color when ending a period for visual feedback
                  backgroundColor: isPeriodActive ? const Color(0xFFD81B60) : const Color(0xFFF48FB1),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  isPeriodActive ? "End Period" : "Log Period",
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}