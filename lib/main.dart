import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app_config.dart';
import 'app/route.dart';
import 'features/auth/login/deep_link_listener.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  runApp(
    const ProviderScope(
      child: DeepLinkListener(
        child: MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Student Management',
      theme: ThemeData(primarySwatch: Colors.blue),
      routerConfig: appRouter,
      builder: (context, child) {
        return DeepLinkListener(child: child!);
      },
    );
  }
}
