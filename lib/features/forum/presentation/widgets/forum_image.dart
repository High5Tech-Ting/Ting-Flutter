import 'package:flutter/material.dart';

class ForumImage extends StatelessWidget {
  const ForumImage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8.0)),
      clipBehavior: Clip.hardEdge,
      child: Image.network(
        'https://images.unsplash.com/photo-1599009434802-ca1dd09895e7',
        fit: BoxFit.fitWidth,
        width: double.infinity,
        loadingBuilder:
            (
              BuildContext context,
              Widget child,
              ImageChunkEvent? loadingProgress,
            ) {
              if (loadingProgress == null) {
                return child;
              }
              return Center(
                child: Container(
                  width: double.infinity,
                  height: 200,
                  color: Colors.grey[200],
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                ),
              );
            },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: double.infinity,
            height: 200,
            color: Colors.grey[200],
            child: const Center(
              child: Icon(Icons.error_outline, color: Colors.red, size: 40),
            ),
          );
        },
      ),
    );
  }
}
