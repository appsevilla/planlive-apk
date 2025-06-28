// lib/widgets/custom_back_button.dart

import 'package:flutter/material.dart';

class CustomBackButton extends StatelessWidget {
  final Color iconColor;
  final String? label;

  const CustomBackButton({
    super.key,
    this.iconColor = Colors.white,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: iconColor),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Atrás',
        ),
        if (label != null)
          Text(
            label!,
            style: TextStyle(
              color: iconColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }
}
