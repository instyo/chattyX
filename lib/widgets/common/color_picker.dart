import 'package:flutter/material.dart';

class ColorPicker extends StatefulWidget {
  final String initialColorHex;
  final ValueChanged<String>? onColorSelected;

  const ColorPicker({
    super.key,
    required this.initialColorHex,
    this.onColorSelected,
  });

  @override
  State<StatefulWidget> createState() => _ColorPickerState();
}

class _ColorPickerState extends State<ColorPicker> {
  late String selectedColorHex;

  final List<String> colorHexList = [
    'F1BA88',
    'E9F5BE',
    '81E7AF',
    '03A791',
    'FFBF78',
    '4F959D',
    '1F509A',
    'F72C5B',
  ];

  @override
  void initState() {
    super.initState();
    selectedColorHex = widget.initialColorHex;
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          colorHexList.map((hex) {
            bool isSelected = hex == selectedColorHex;
            Color color = Color(int.parse('0xFF$hex'));
            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedColorHex = hex;
                });
                if (widget.onColorSelected != null) {
                  widget.onColorSelected!(hex);
                }
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
                child:
                    isSelected
                        ? Center(child: Icon(Icons.check, color: Colors.white))
                        : null,
              ),
            );
          }).toList(),
    );
  }
}
