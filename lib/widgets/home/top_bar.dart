import 'package:flutter/material.dart';

import '../../screens/calendar_screen.dart';

class TopBar extends StatelessWidget {
  final DateTime today;

  const TopBar({
    super.key,
    required this.today,
  });

  String _monthName(int month) {
    const months = [
      "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final formattedDate = "${today.day} ${_monthName(today.month)}";

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: const Color(0xFFF5F5F5),
          child: const Icon(
            Icons.person,
            size: 20,
            color: Color(0xFF9E9E9E),
          ),
        ),
        Text(
          formattedDate,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF333333),
            letterSpacing: 0.3,
          ),
        ),
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CalendarScreen(),
              ),
            );
          },
          iconSize: 22,
          icon: const Icon(
            Icons.calendar_today_outlined,
            color: Color(0xFF777777),
          ),
          tooltip: 'Calendar',
        ),
      ],
    );
  }
}