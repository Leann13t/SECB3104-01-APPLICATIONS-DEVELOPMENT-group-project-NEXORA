
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


const String supabaseUrl =
    'https://lpkbcvlylrboqczywcgc.supabase.co';

const String supabasePublishableKey =
    'sb_publishable_hN4EEp472DJeZxUoUPGeDg_PIlf8bJG';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
  url: supabaseUrl,
  publishableKey: supabasePublishableKey,
  );

  await testSupabaseConnection();

  runApp(const MyApp());
}

// Test Supabase initialization
Future<void> testSupabaseConnection() async {
  try {
    final supabase = Supabase.instance.client;

    debugPrint('Supabase connection initialized!');
    debugPrint('Project URL: ${supabase.rest.url}');
  } catch (e) {
    debugPrint('Supabase connection error: $e');
  }
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
