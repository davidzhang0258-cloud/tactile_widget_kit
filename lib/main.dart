import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ce/hive.dart';
import 'package:path_provider/path_provider.dart';

import 'services/notifications.dart';
import 'ui/wonder_console_pages.dart';

const wonderChannel = MethodChannel('com.tactile.widgetkit/wonder_channel');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Immersive edge-to-edge so the console shell fills the full screen.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  final dir = await getApplicationSupportDirectory();
  Hive.init(dir.path);
  final cartridgeBox = await Hive.openBox('cartridges');

  await NotificationService.instance.init();

  // Preload the tactile console textures.
  await initWonderTextures();

  // If launched from the widget's "+ QUICK" hot zone, jump straight to page 2.
  String? pendingRoute;
  try {
    final r = await wonderChannel.invokeMethod('getPendingAction');
    if (r is Map) pendingRoute = r['action'] as String?;
  } catch (_) {
    // Channel is unavailable on non-widget launches; ignore.
  }

  runApp(TactileWidgetKitApp(
    initialRoute: pendingRoute,
    cartridgeBox: cartridgeBox,
  ));
}

/// Root widget: page 1 is the full-screen calendar console, and a widget tap
/// can deep-link straight into page 2 (the day-slot workbench).
class TactileWidgetKitApp extends StatefulWidget {
  final String? initialRoute;
  final Box? cartridgeBox;
  const TactileWidgetKitApp({super.key, this.initialRoute, this.cartridgeBox});

  @override
  State<TactileWidgetKitApp> createState() => _TactileWidgetKitAppState();
}

class _TactileWidgetKitAppState extends State<TactileWidgetKitApp> {
  late final WonderCalendarStore _store;

  @override
  void initState() {
    super.initState();
    _store = WonderCalendarStore(box: widget.cartridgeBox);
    if (widget.initialRoute == 'day_slot_quick_add') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final cards = _store.cartridgesFor(today);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => WonderDaySlotPage(
              store: _store,
              date: today,
              initialCartridge: cards.isNotEmpty ? cards.first : null,
            ),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tactile Widget Kit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1D4B9E)),
      ),
      home: WonderCalendarHomePage(store: _store),
    );
  }
}
