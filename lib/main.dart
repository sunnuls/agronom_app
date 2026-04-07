import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'import_bridge.dart';
import 'providers/app_provider.dart';
import 'screens/profiles_screen.dart';
import 'screens/journal_screen.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const AgronApp(),
    ),
  );
}

class AgronApp extends StatelessWidget {
  const AgronApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: 'Агроном — Опрыскиватель',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1976D2),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0D1B2E),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;

  final _screens = const [
    ProfilesScreen(),
    JournalScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final ctx = appNavigatorKey.currentContext;
      if (ctx != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ImportBridge.tryConsumePendingImport(ctx);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF1565C0),
        indicatorColor: const Color(0xFF1976D2),
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.agriculture_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.agriculture, color: Colors.white),
            label: 'Профили',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.history, color: Colors.white),
            label: 'Журнал',
          ),
        ],
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }
}
