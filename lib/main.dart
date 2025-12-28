import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'services/api_client.dart';
import 'services/storage_service.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const OpenShockApp());
}

class OpenShockApp extends StatelessWidget {
  const OpenShockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            apiClient: ApiClient(),
            storageService: StorageService(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'OpenShock',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0A0A0A),
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
            surface: const Color(0xFF1A1A1A),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1A1A1A),
            elevation: 0,
          ),
          cardTheme: CardThemeData(
            color: Colors.white.withValues(alpha: 0.05),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
