import 'package:flutter/material.dart';

class LikeButton extends StatelessWidget {
  final bool liked;
  final int likeCount;
  final VoidCallback onTap;

  const LikeButton({
    super.key,
    required this.liked,
    required this.likeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            liked ? Icons.favorite : Icons.favorite_border,
            color: liked ? Colors.red : Colors.grey,
          ),
          onPressed: onTap,
        ),
        Text('$likeCount'),
      ],
    );
  }
}
