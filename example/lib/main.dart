import 'package:flutter/material.dart';
import 'package:pixora/pixora.dart';

void main() => runApp(const PixoraExample());

class PixoraExample extends StatelessWidget {
  const PixoraExample({super.key});

  @override
  Widget build(BuildContext context) {
    const url =
        'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=900';
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Pixora')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PixoraImage(
                url: url,
                width: 280,
                height: 280,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(24),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => PixoraImage.prefetch(url),
                child: const Text('Prefetch'),
              ),
              OutlinedButton(
                onPressed: PixoraImage.clearCache,
                child: const Text('Clear cache'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
