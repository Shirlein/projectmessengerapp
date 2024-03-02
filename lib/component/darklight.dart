import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ThemeModeNotifier>(
      create: (_) => ThemeModeNotifier(),
      child: Consumer<ThemeModeNotifier>(
        builder: (context, themeNotifier, child) {
          return MaterialApp(
            title: 'Dark Mode Demo',
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: themeNotifier.themeMode,
            home: MyHomePage(),
          );
        },
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dark Mode Demo'),
      ),
      body: const Center(
        child: Text('Dark Mode and Light Mode'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Toggle between light and dark mode
          ThemeModeNotifier themeNotifier =
              Provider.of<ThemeModeNotifier>(context, listen: false);
          themeNotifier.toggleTheme();
        },
        child: const Icon(Icons.brightness_4),
      ),
    );
  }
}

class ThemeModeNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}
