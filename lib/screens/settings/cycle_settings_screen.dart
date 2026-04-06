import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/user_preferences.dart';

class CycleSettingsScreen extends StatefulWidget {
  const CycleSettingsScreen({super.key});

  @override
  State<CycleSettingsScreen> createState() => _CycleSettingsScreenState();
}

class _CycleSettingsScreenState extends State<CycleSettingsScreen> {
  // Local state variables
  int _cycleLength = 28;
  int _periodLength = 5;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // --- LOAD DATA ---
  Future<void> _loadData() async {
    final cycle = await UserPreferences.getCycleLength();
    final period = await UserPreferences.getPeriodLength();

    if (!mounted) return;

    setState(() {
      _cycleLength = cycle ?? 28;
      _periodLength = period ?? 5;
    });
  }

  // --- INTERACTION: Edit Cycle Length ---
  Future<void> _editCycleLength() async {
    final TextEditingController controller = TextEditingController(text: _cycleLength.toString());
    String? errorMsg;

    final newLength = await showDialog<int>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Cycle Length', style: TextStyle(fontWeight: FontWeight.bold)),
              content: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Enter days (20–40)',
                  errorText: errorMsg,
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFF06292), width: 2),
                  ),
                ),
                onChanged: (_) {
                  if (errorMsg != null) setStateDialog(() => errorMsg = null);
                },
              ),
              actions:[
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: () {
                    final val = int.tryParse(controller.text.trim());
                    if (val == null || val < 20 || val > 40) {
                      setStateDialog(() => errorMsg = 'Please enter a value between 20 and 40');
                    } else {
                      Navigator.pop(context, val);
                    }
                  },
                  child: const Text(
                    'Save',
                    style: TextStyle(color: Color(0xFFF06292), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (newLength != null && newLength != _cycleLength) {
      // Save persistently
      await UserPreferences.saveCycleLength(newLength);

      if (!mounted) return;

      // Update UI
      setState(() {
        _cycleLength = newLength;
      });
    }
  }

  // --- INTERACTION: Edit Period Length ---
  Future<void> _editPeriodLength() async {
    final TextEditingController controller = TextEditingController(text: _periodLength.toString());
    String? errorMsg;

    final newLength = await showDialog<int>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Period Length', style: TextStyle(fontWeight: FontWeight.bold)),
              content: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Enter days (2–10)',
                  errorText: errorMsg,
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFF06292), width: 2),
                  ),
                ),
                onChanged: (_) {
                  if (errorMsg != null) setStateDialog(() => errorMsg = null);
                },
              ),
              actions:[
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: () {
                    final val = int.tryParse(controller.text.trim());
                    if (val == null || val < 2 || val > 10) {
                      setStateDialog(() => errorMsg = 'Please enter a value between 2 and 10');
                    } else {
                      Navigator.pop(context, val);
                    }
                  },
                  child: const Text(
                    'Save',
                    style: TextStyle(color: Color(0xFFF06292), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (newLength != null && newLength != _periodLength) {
      // Save persistently
      await UserPreferences.savePeriodLength(newLength);

      if (!mounted) return;

      // Update UI
      setState(() {
        _periodLength = newLength;
      });
    }
  }

  // --- UI: Reusable Field Card ---
  Widget _buildFieldCard({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(
                  Icons.edit_outlined,
                  color: Color(0xFFF06292),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F6), // Match settings background
      appBar: AppBar(
        title: const Text(
          'Cycle Settings',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87), // Dark back arrow
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children:[
            const SizedBox(height: 10),
            _buildFieldCard(
              label: 'Cycle Length',
              value: '$_cycleLength days',
              onTap: _editCycleLength,
            ),
            _buildFieldCard(
              label: 'Period Length',
              value: '$_periodLength days',
              onTap: _editPeriodLength,
            ),
          ],
        ),
      ),
    );
  }
}