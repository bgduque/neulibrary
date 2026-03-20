import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_router.dart';
import 'core/api_service.dart';
import 'core/auth_service.dart';

final apiService = ApiService();
final authService = AuthService(apiService);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Restore any previously saved session (JWT + user) from local storage.
  await authService.tryRestoreSession();

  runApp(const NeuLibraryApp());
}

class NeuLibraryApp extends StatelessWidget {
  const NeuLibraryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: authService,
      builder: (context, _) {
        return MaterialApp.router(
          title: 'NEU Library',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1B5E20),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            textTheme: GoogleFonts.interTextTheme(),
          ),
          routerConfig: appRouter,
        );
      },
    );
  }
}
