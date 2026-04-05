import 'package:flutter/material.dart';

class DateStrip extends StatelessWidget {
  const DateStrip({super.key});

  @override
  Widget build(BuildContext context) {
    // Desaturated dummy colors for calm aesthetic
    final List<Map<String, dynamic>> days =[
      {"day": "Mon", "date": "30", "isCurrent": false, "dotColor": const Color(0xFFEF9A9A)},
      {"day": "Tue", "date": "31", "isCurrent": false, "dotColor": const Color(0xFFEF9A9A)},
      {"day": "Wed", "date": "1", "isCurrent": false, "dotColor": const Color(0xFF90CAF9)},
      {"day": "Thu", "date": "2", "isCurrent": false, "dotColor": const Color(0xFF90CAF9)},
      {"day": "Fri", "date": "3", "isCurrent": true, "dotColor": const Color(0xFFA5D6A7)},
      {"day": "Sat", "date": "4", "isCurrent": false, "dotColor": const Color(0xFFA5D6A7)},
      {"day": "Sun", "date": "5", "isCurrent": false, "dotColor": const Color(0xFFA5D6A7)},
    ];

    return SizedBox(
      height: 80, // Slightly more compact
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: days.length,
        itemBuilder: (context, index) {
          final dayData = days[index];
          final isCurrent = dayData["isCurrent"] as bool;

          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 54,
              decoration: BoxDecoration(
                color: isCurrent ? const Color(0xFFFDF2F5) : Colors.transparent, // Extremely soft highlight
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayData["day"],
                    style: TextStyle(
                      color: const Color(0xFF777777), // Muted grey for all days
                      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    dayData["date"],
                    style: TextStyle(
                      color: const Color(0xFF333333), // Near black
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 4, // Smaller, subtle dot
                    height: 4,
                    decoration: BoxDecoration(
                      color: dayData["dotColor"] as Color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}