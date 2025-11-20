import 'package:flutter/material.dart';

class AutoMenuSelection<T extends Enum> extends StatelessWidget {
  const AutoMenuSelection({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.label,
  });

  final T value;
  final List<T> items;
  final ValueChanged<T?>? onChanged;
  final String Function(T) label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20),
      child: DropdownButton<T>(
        value: value,
        items: items.map((T item) {
          return DropdownMenuItem(
            value: item,
            child: Text(label(item)),
          );
        }).toList(), 
        onChanged: onChanged
      ),
    );
  }
}