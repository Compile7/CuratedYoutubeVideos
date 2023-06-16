import 'package:flutter/material.dart';

class VideoItem extends StatelessWidget {
  final Map<String, dynamic> video;
  final VoidCallback onTap;

  const VideoItem({
    required this.video,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Image.network(video['thumbnailUrl']),
              Text(
                video['title'],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
