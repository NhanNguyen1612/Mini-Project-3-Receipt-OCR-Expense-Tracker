import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: ExpenseApp()));
}

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

class ExpenseApp extends ConsumerWidget {
  const ExpenseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    ThemeData theme(Brightness brightness) => ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2C4570),
            brightness: brightness,
          ),
          appBarTheme: const AppBarTheme(centerTitle: false),
        );
    return MaterialApp(
      title: 'VKU Expense OCR',
      debugShowCheckedModeBanner: false,
      theme: theme(Brightness.light),
      darkTheme: theme(Brightness.dark),
      themeMode: mode,
      home: const HomeScreen(),
    );
  }
}
