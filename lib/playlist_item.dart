import 'package:flutter/material.dart';

class PlaylistItem extends StatelessWidget {
  final Map<String, dynamic> playlist;
  final VoidCallback onTap;

  const PlaylistItem({
    required this.playlist,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(playlist['title']),
      leading: Icon(Icons.video_library),
      onTap: onTap,
    );
  }
}
