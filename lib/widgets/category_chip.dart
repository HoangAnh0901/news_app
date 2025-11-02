import 'package:flutter/material.dart';

class CategoryChip extends StatelessWidget {
  final String category;
  final bool isSelected;
  final VoidCallback onSelected;

  const CategoryChip({
    Key? key,
    required this.category,
    required this.isSelected,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8),
      child: FilterChip(
        label: Text(
          category,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.blue,
            fontWeight: FontWeight.w500,
          ),
        ),
        selected: isSelected,
        selectedColor: Colors.blue,
        checkmarkColor: Colors.white,
        backgroundColor: Colors.blue[50],
        onSelected: (selected) => onSelected(),
        shape: StadiumBorder(
          side: BorderSide(
            color: isSelected ? Colors.blue : Colors.blue[300]!,
            width: 1,
          ),
        ),
      ),
    );
  }
}