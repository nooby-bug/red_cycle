import 'package:flutter/material.dart';

class AffirmationList extends StatelessWidget {
  final List<String> affirmations;
  final bool isEnabled;
  final Function(int index) onDelete;

  const AffirmationList({
    super.key,
    required this.affirmations,
    required this.isEnabled,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (affirmations.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'No affirmations yet. Add one above!',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: affirmations.length,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            title: Text(affirmations[index]),
            trailing: IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: Colors.grey.shade400,
              ),
              onPressed: isEnabled ? () => onDelete(index) : null,
            ),
          ),
        );
      },
    );
  }
}