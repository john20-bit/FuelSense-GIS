import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ProviderScope(child: FuelSenseApp()));
}

class FuelSenseApp extends ConsumerWidget {
  const FuelSenseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(themeControllerProvider);
    final mode = controller.mode;

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'FuelSense GIS',

      // Used whenever the selected mode resolves to Light.
      theme: AppTheme.light,

      // Used for Dark and the custom FuelSense signature theme.
      darkTheme: mode == FuelSenseThemeMode.fuelSense
          ? AppTheme.fuelSense
          : AppTheme.dark,

      themeMode: controller.materialThemeMode,

      routerConfig: appRouter,
    );
  }
}
