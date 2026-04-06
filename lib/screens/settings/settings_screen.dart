import 'package:flutter/material.dart';
import 'package:red/screens/settings/profile_details_screen.dart';
import 'package:red/screens/settings/cycle_settings_screen.dart'; // Adjust path if needed

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Soft feminine pastel background
      backgroundColor: const Color(0xFFFFF5F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        // LEFT: Circular Profile Icon
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: const Color(0xFFFFD1DC), // Soft pastel pink
            child: const Icon(
              Icons.person,
              color: Colors.white,
            ),
          ),
        ),
        // RIGHT: Arrow icon to pop the screen
        actions:[
          IconButton(
            icon: const Icon(Icons.arrow_forward, color: Colors.black87),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: ConstrainedBox(
              // Ensures the column takes up at least the full screen height
              // to push the "About" section to the very bottom naturally.
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 40,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children:[
                    const SizedBox(height: 10),

                    // 1. Profile Section
// 1. Profile Section
                    SettingsTile(
                      icon: Icons.person_outline,
                      title: 'Profile',
                      onTap: () {
                        // Navigate to the new ProfileDetailsScreen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfileDetailsScreen(),
                          ),
                        );
                      },
                    ),

                    // 2. Cycle Section

                    SettingsTile(
                      icon: Icons.water_drop_outlined,
                      title: 'Cycle',
                      onTap: () {
                        // Navigate to the new CycleSettingsScreen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CycleSettingsScreen(),
                          ),
                        );
                      },
                    ),

                    // 3. Reminders Section
                    SettingsTile(
                      icon: Icons.notifications_none_outlined,
                      title: 'Reminders',
                      onTap: () => debugPrint('Reminders clicked'),
                    ),

                    // 4. Data Section
                    SettingsTile(
                      icon: Icons.pie_chart_outline,
                      title: 'Data',
                      onTap: () => debugPrint('Data clicked'),
                    ),

                    // Pushes the footer to the bottom of the screen
                    const Spacer(),

                    const SizedBox(height: 40),

                    // BOTTOM: About Section
                    Column(
                      children:[
                        Text(
                          'Period tracker v1.0',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Made with ❤️ by Red Cycle',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A clean, reusable widget for the settings menu tiles.
class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        // Soft pastel shadow for a floating, gentle look
        boxShadow:[
          BoxShadow(
            color: const Color(0xFFFFB6C1).withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
            child: Row(
              children:[
                // Left Icon with soft pink accent
                Icon(
                  icon,
                  color: const Color(0xFFF06292), // Deeper soft pink for contrast
                  size: 26,
                ),
                const SizedBox(width: 16),

                // Title Text
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),

                // Right Arrow (Chevron)
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey.shade400,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}