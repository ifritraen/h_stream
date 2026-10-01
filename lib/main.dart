import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'theme/app_theme.dart';
import 'providers/extension_provider.dart';
import 'providers/tag_matrix_provider.dart';
import 'providers/feed_board_provider.dart';
import 'providers/franchise_provider.dart';
import 'providers/download_provider.dart';
import 'providers/vault_provider.dart';
import 'providers/stealth_provider.dart';
import 'providers/lan_stream_provider.dart';
import 'providers/player_provider.dart';

import 'views/home/home_view.dart';
import 'views/stealth/calculator_decoy.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set system UI to immersive OLED dark
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const HStreamApp());
}

class HStreamApp extends StatelessWidget {
  const HStreamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ExtensionProvider()),
        ChangeNotifierProvider(create: (_) => TagMatrixProvider()),
        ChangeNotifierProvider(create: (_) => FeedBoardProvider()),
        ChangeNotifierProvider(create: (_) => FranchiseProvider()),
        ChangeNotifierProvider(create: (_) => DownloadProvider()),
        ChangeNotifierProvider(create: (_) => VaultProvider()),
        ChangeNotifierProvider(create: (_) => StealthProvider()),
        ChangeNotifierProvider(create: (_) => LanStreamProvider()),
        ChangeNotifierProvider(create: (_) => PlayerProvider()),
      ],
      child: Consumer<StealthProvider>(
        builder: (context, stealth, _) {
          return MaterialApp(
            title: 'HStream Neo',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            home: stealth.currentMode == StealthMode.calculatorDecoy
                ? const CalculatorDecoy()
                : const HomeView(),
          );
        },
      ),
    );
  }
}
