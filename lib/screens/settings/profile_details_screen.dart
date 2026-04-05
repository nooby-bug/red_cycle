import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProfileDetailsScreen extends StatefulWidget {
  const ProfileDetailsScreen({super.key});

  @override
  State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
  // Local state (No persistence yet)
  String _name = 'User';
  DateTime? _birthdate;

  // --- INTERACTION: Edit Name ---
  Future<void> _editName() async {
    final TextEditingController controller = TextEditingController(text: _name);

    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Edit Name', style: TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            textCapitalization: TextCapitalization.words,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Enter your name',
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: const Color(0xFFF06292), width: 2),
              ),
            ),
          ),
          actions:[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isNotEmpty) {
                  Navigator.pop(context, text);
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

    if (newName != null && newName != _name) {
      setState(() {
        _name = newName;
      });
    }
  }

  // --- INTERACTION: Edit Birthdate ---
  Future<void> _editBirthdate() async {
    final now = DateTime.now();
    final initialDate = _birthdate ?? DateTime(now.year - 25);

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFF06292), // Header background color
              onPrimary: Colors.white,    // Header text color
              onSurface: Colors.black87,  // Body text color
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && pickedDate != _birthdate) {
      setState(() {
        _birthdate = pickedDate;
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
                    style: TextStyle(
                      fontSize: 16,
                      color: value == 'Not set' ? Colors.grey : Colors.black54,
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
          'Profile',
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
              label: 'Name',
              value: _name,
              onTap: _editName,
            ),
            _buildFieldCard(
              label: 'Birthdate',
              value: _birthdate != null
                  ? DateFormat('MMMM d, yyyy').format(_birthdate!)
                  : 'Not set',
              onTap: _editBirthdate,
            ),
          ],
        ),
      ),
    );
  }
}