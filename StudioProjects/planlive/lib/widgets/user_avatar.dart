import 'dart:io';
import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? assetPath;
  final File? file;
  final double radius;

  const UserAvatar({
    super.key,
    this.imageUrl,
    this.assetPath,
    this.file,
    this.radius = 40,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = radius * 0.9;

    ImageProvider? imageProvider;
    if (file != null) {
      imageProvider = FileImage(file!);
    } else if (assetPath != null && assetPath!.isNotEmpty) {
      imageProvider = AssetImage(assetPath!);
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      imageProvider = NetworkImage(imageUrl!);
    }

    if (imageProvider == null) {
      return _defaultAvatar(iconSize);
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[200],
      child: ClipOval(
        child: _buildImage(imageProvider, iconSize),
      ),
    );
  }

  Widget _buildImage(ImageProvider imageProvider, double iconSize) {
    if (imageProvider is NetworkImage) {
      return Image(
        image: imageProvider,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _defaultAvatar(iconSize);
        },
      );
    }

    // For AssetImage and FileImage (no loadingBuilder needed)
    return Image(
      image: imageProvider,
      width: radius * 2,
      height: radius * 2,
      fit: BoxFit.cover,
    );
  }

  Widget _defaultAvatar(double iconSize) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.deepPurple.shade200,
      child: Icon(Icons.person, size: iconSize, color: Colors.white),
    );
  }
}

