
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://lpkbcvlylrboqczywcgc.supabase.co',
    publishableKey: 'sb_publishable_hN4EEp472DJeZxUoUPGeDg_PIlf8bJG',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nexora',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Nexora'),
        ),
        body: const Center(
          child: Text('Welcome to Nexora!'),
        ),
      ),
    );
  }
}
