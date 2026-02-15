import 'package:flutter/material.dart';
import 'presentation/screens/gallery/gallery_screen.dart';
import 'presentation/screens/record/record_screen.dart';
import 'presentation/screens/playback/playback_screen.dart';
import 'data/models/video_entry.dart';

void main() {
  runApp(const VideoJournalApp());
}

class VideoJournalApp extends StatelessWidget {
  const VideoJournalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Journal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.cyan),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          elevation: 6,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      // Initial route
      home: const GalleryScreen(),

      routes: {
        '/gallery': (context) => const GalleryScreen(),
        '/record': (context) => const RecordScreen(),
        '/playback': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as VideoEntry;
          return PlaybackScreen(videoEntry: args);
        },
      },

      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const GalleryScreen(),
        );
      },
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  final String title;
  final String message;

  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}
