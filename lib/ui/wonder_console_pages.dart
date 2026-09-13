// lib/ui/wonder_console_pages.dart
//
// 1080x2344 Super-Resolved Zero-Distortion (1:1 Aspect Ratio) Texture-Slice +
// 3D Mechanical Choreography Engine for Wonder Calendar (Page 1 & Page 2):
// - Solves Aspect-Ratio Distortion: Reference space is smart-extended at feature-free straight
//   zones to 702x1524 (matching 1080x2344 = 9:19.5 full-screen phones at 1:1 uniform scale!),
//   so all circles (internal rings, screw bosses, '<' back button), the 4-way D-Pad, screens,
//   cartridges, sliding carriage, and QWERTY keyboard maintain 100% true 1:1 proportions!
// - Solves Low-Resolution Blur: All 9 texture slices are super-sampled to native 1080x2344
//   physical pixel resolution with two-pass UnsharpMask detail restoration, combined with
//   pixel-snapped vector bitmap typography for cartridge labels and terminal text.
// - Fixes Page 2 Layout Details:
//   1) Terminal text "[⚔️] > WRITE API DOCS█" fits cleanly on a single line inside the LCD.
//   2) Cartridge label splits "03" (inside the golden RPG box) from "// DEBUG WIDGET TAP"
//      (to the right of the RPG box) so the RPG frame never overlaps "//".
//   3) Bottom QWERTY keyboard is 100% hidden in Initial State (t = 0.0) and smoothly revealed
//      as the white carriage slides upward (y: 930 -> 566 in 702x1524 space).

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ce/hive.dart';

// ============================================================================
// DATA MODELS & STORE (self-contained demo state for the tactile console)
// ============================================================================

enum CartridgeType {
  todo,
  done,
  idea,
}

class DayCartridge {
  final String id;
  final String title;
  final CartridgeType type;
  final bool translucent;
  final String body;

  const DayCartridge({
    required this.id,
    required this.title,
    required this.type,
    this.translucent = true,
    this.body = '',
  });

  DayCartridge copyWith({
    String? id,
    String? title,
    CartridgeType? type,
    bool? translucent,
    String? body,
  }) {
    return DayCartridge(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      translucent: translucent ?? this.translucent,
      body: body ?? this.body,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type.name,
        'translucent': translucent,
        'body': body,
      };

  factory DayCartridge.fromJson(Map<String, dynamic> json) => DayCartridge(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        type: CartridgeType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => CartridgeType.todo,
        ),
        translucent: json['translucent'] as bool? ?? true,
        body: json['body'] as String? ?? '',
      );
}

class WonderCalendarStore extends ChangeNotifier {
  final Map<String, List<DayCartridge>> _byDate = {};
  final Box? _box;

  WonderCalendarStore({Box? box}) : _box = box {
    if (box != null) _loadFromBox(box);
    // 首次启动（无历史数据）时播种演示数据，之后以持久化数据为准。
    if (_byDate.isEmpty) _seedInitialData();
  }

  void _loadFromBox(Box box) {
    for (final key in box.keys) {
      if (key is! String) continue;
      final raw = box.get(key);
      if (raw is! String) continue;
      try {
        final list = (jsonDecode(raw) as List)
            .map((e) => DayCartridge.fromJson(e as Map<String, dynamic>))
            .toList();
        _byDate[key] = list;
      } catch (_) {
        // 跳过损坏的条目，不影响整体加载
      }
    }
  }

  void _persist(String key) {
    final box = _box;
    if (box == null) return;
    final list = _byDate[key];
    if (list == null || list.isEmpty) {
      box.delete(key);
    } else {
      box.put(key, jsonEncode(list.map((e) => e.toJson()).toList()));
    }
  }

  static String _keyFor(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _seedInitialData() {
    _byDate['2026-10-05'] = const [
      DayCartridge(
        id: '1005-1',
        title: 'MORNING RUN 5KM',
        type: CartridgeType.todo,
      ),
    ];
    _byDate['2026-10-06'] = const [
      DayCartridge(
        id: '1006-1',
        title: 'READ 30 PAGES',
        type: CartridgeType.done,
      ),
    ];
    _byDate['2026-10-07'] = const [
      DayCartridge(
        id: '1007-1',
        title: 'SKETCH PIXEL ICONS',
        type: CartridgeType.todo,
      ),
    ];
    _byDate['2026-10-11'] = const [
      DayCartridge(
        id: '1011-1',
        title: 'CLEAN WORKSPACE',
        type: CartridgeType.done,
      ),
    ];
    _byDate['2026-10-13'] = const [
      DayCartridge(
        id: '1013-1',
        title: 'BUILD PROTOTYPE',
        type: CartridgeType.todo,
      ),
    ];
    _byDate['2026-10-14'] = const [
      DayCartridge(
        id: '1014-1',
        title: 'MORNING RUN 5KM',
        type: CartridgeType.done,
        translucent: true,
        body: 'WRITE API DOCS',
      ),
      DayCartridge(
        id: '1014-2',
        title: 'FINISH UI DESIGN',
        type: CartridgeType.todo,
        translucent: false,
        body: 'WRITE API DOCS',
      ),
      DayCartridge(
        id: '1014-3',
        title: 'DEBUG WIDGET TAP',
        type: CartridgeType.todo,
        translucent: true,
        body: 'WRITE API DOCS',
      ),
    ];
    _byDate['2026-10-25'] = const [
      DayCartridge(
        id: '1025-1',
        title: 'REFACTOR SHADERS',
        type: CartridgeType.todo,
      ),
    ];
    _byDate['2026-10-26'] = const [
      DayCartridge(
        id: '1026-1',
        title: 'WEEKLY REVIEW',
        type: CartridgeType.done,
      ),
    ];
    _byDate['2026-10-28'] = const [
      DayCartridge(
        id: '1028-1',
        title: 'WRITE DEV LOG',
        type: CartridgeType.todo,
      ),
    ];
    _byDate['2026-10-31'] = const [
      DayCartridge(
        id: '1031-1',
        title: 'HALLOWEEN RELEASE',
        type: CartridgeType.done,
      ),
    ];
  }

  List<DayCartridge> cartridgesFor(DateTime date) {
    final key = _keyFor(date);
    return List<DayCartridge>.unmodifiable(_byDate[key] ?? const []);
  }

  void upsertCartridge(DateTime date, DayCartridge cartridge) {
    final key = _keyFor(date);
    final list = List<DayCartridge>.from(_byDate[key] ?? const []);
    final idx = list.indexWhere((c) => c.id == cartridge.id);
    if (idx >= 0) {
      list[idx] = cartridge;
    } else {
      list.add(cartridge);
    }
    _byDate[key] = list;
    _persist(key);
    notifyListeners();
  }

  DayCartridge createCartridge(
    DateTime date, {
    String title = 'WRITE API DOCS',
    CartridgeType type = CartridgeType.todo,
    bool translucent = true,
  }) {
    final key = _keyFor(date);
    final list = List<DayCartridge>.from(_byDate[key] ?? const []);
    final created = DayCartridge(
      id: '${date.millisecondsSinceEpoch}-${list.length + 1}',
      title: title,
      type: type,
      translucent: translucent,
      body: title,
    );
    list.add(created);
    _byDate[key] = list;
    _persist(key);
    notifyListeners();
    return created;
  }
}

// ============================================================================
// PAGE 1: WONDER CALENDAR HOME PAGE (1080x2344 NATIVE 1:1 ZERO-DISTORTION)
// ============================================================================

class WonderCalendarHomePage extends StatefulWidget {
  final WonderCalendarStore store;
  final DateTime? initialDate;

  const WonderCalendarHomePage({
    super.key,
    required this.store,
    this.initialDate,
  });

  @override
  State<WonderCalendarHomePage> createState() => _WonderCalendarHomePageState();
}

class _WonderCalendarHomePageState extends State<WonderCalendarHomePage> {
  // Smart-extended 9:19.5 reference coordinate space (702 x 1524 == 1080 x 2344 at 1:1 scale!)
  static const double _kRefW = 702.0;
  static const double _kRefH = 1524.0;

  late DateTime _focusedMonth;
  late DateTime _selectedDate;
  int _selectedGridIndex = 17; // Center cell "14" (Row 2, Col 3)
  String? _pressedControl;

  @override
  void initState() {
    super.initState();
    final init = widget.initialDate ?? DateTime(2026, 10, 14);
    _selectedDate = DateTime(init.year, init.month, init.day);
    _focusedMonth = DateTime(init.year, init.month, 1);
    widget.store.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    widget.store.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  static const List<String?> _oct2026CellLabels = [
    null, '1', '2', '3', '4', '5', '6',
    '7', '8', '9', '10', '11', '12', '13',
    '14', '15', '16', '14', '18', '19', '10',
    '21', '22', '23', '24', '25', '26', '27',
    '28', '29', '30', '31', null, null, null,
  ];

  bool get _isOct2026 =>
      _focusedMonth.year == 2026 && _focusedMonth.month == 10;

  DateTime? _dateForGridIndex(int idx) {
    if (_isOct2026) {
      final label = _oct2026CellLabels[idx];
      if (label == null) return null;
      if (idx == 17 || idx == 14) return DateTime(2026, 10, 14);
      if (idx == 20) return DateTime(2026, 10, 20);
      final d = int.tryParse(label) ?? 14;
      return DateTime(2026, 10, d);
    }
    final firstWeekday =
        DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday;
    final leading = firstWeekday - 1;
    final daysInMonth =
        DateUtils.getDaysInMonth(_focusedMonth.year, _focusedMonth.month);
    final dayNum = idx - leading + 1;
    if (dayNum < 1 || dayNum > daysInMonth) return null;
    return DateTime(_focusedMonth.year, _focusedMonth.month, dayNum);
  }

  void _moveGridSelection(int delta) {
    HapticFeedback.selectionClick();
    setState(() {
      int next = (_selectedGridIndex + delta).clamp(0, 34);
      if (_dateForGridIndex(next) == null) {
        final step = delta >= 0 ? 1 : -1;
        int probe = next;
        while (probe >= 0 && probe <= 34 && _dateForGridIndex(probe) == null) {
          probe += step;
        }
        if (probe >= 0 && probe <= 34 && _dateForGridIndex(probe) != null) {
          next = probe;
        } else {
          return;
        }
      }
      _selectedGridIndex = next;
      final d = _dateForGridIndex(next);
      if (d != null) _selectedDate = d;
    });
  }

  void _changeMonth(int deltaMonths) {
    HapticFeedback.lightImpact();
    setState(() {
      _focusedMonth =
          DateTime(_focusedMonth.year, _focusedMonth.month + deltaMonths, 1);
      if (_isOct2026) {
        _selectedGridIndex = 17;
        _selectedDate = DateTime(2026, 10, 14);
      } else {
        final firstWeekday =
            DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday;
        _selectedGridIndex = (firstWeekday - 1) + 13;
        _selectedDate = DateTime(_focusedMonth.year, _focusedMonth.month, 14);
      }
    });
  }

  void _jumpToToday() {
    HapticFeedback.mediumImpact();
    setState(() {
      _focusedMonth = DateTime(2026, 10, 1);
      _selectedGridIndex = 17;
      _selectedDate = DateTime(2026, 10, 14);
    });
  }

  void _openDayPage({DayCartridge? initialCartridge}) {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: WonderDaySlotPage(
              store: widget.store,
              date: _selectedDate,
              initialCartridge: initialCartridge,
            ),
          );
        },
      ),
    );
  }

  bool get _isDefaultOct14SubScreen {
    if (_selectedDate.year != 2026 ||
        _selectedDate.month != 10 ||
        _selectedDate.day != 14) {
      return false;
    }
    final list = widget.store.cartridgesFor(_selectedDate);
    if (list.length != 3) return false;
    return list[0].title == 'MORNING RUN 5KM' &&
        list[0].type == CartridgeType.done &&
        list[1].title == 'FINISH UI DESIGN' &&
        list[1].type == CartridgeType.todo &&
        list[2].title == 'DEBUG WIDGET TAP' &&
        list[2].type == CartridgeType.todo;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF0A2454),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF0A2454),
        resizeToAvoidBottomInset: false,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final W = constraints.maxWidth;
            final H = constraints.maxHeight;
            double sx(double x) => x * W / _kRefW;
            double sy(double y) => y * H / _kRefH;
            final s = W / 390.0;

            // Upper Calendar Grid is above y = 624, so shift = 0px (100% unstretched 1:1!)
            const gridLeft = 108.0;
            const gridTop = 242.0;
            const cellW = 486.0 / 7.0;
            const cellH = 311.0 / 5.0;

            final selCol = _selectedGridIndex % 7;
            final selRow = _selectedGridIndex ~/ 7;
            final cursorRefX = gridLeft + selCol * cellW - 10.0;
            final cursorRefY = gridTop + selRow * cellH - 8.5;

            return Stack(
              fit: StackFit.expand,
              children: [
                // 1. 1080x2344 Super-Resolved Zero-Distortion Base Console Texture
                Image.memory(
                  _WonderTextures.p1Base,
                  width: W,
                  height: H,
                  fit: BoxFit.fill,
                  gaplessPlayback: true,
                  filterQuality: FilterQuality.high,
                ),

                // 2. Dynamic Month Overlay if user navigated away from 2026.10
                if (!_isOct2026) ...[
                  Positioned(
                    left: sx(405),
                    top: sy(78),
                    width: sx(210),
                    height: sy(66),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8 * s),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFEEEEF5),
                            Color(0xFFE3E5DE),
                          ],
                        ),
                      ),
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.only(right: sx(8)),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: _PixelBitmapText(
                          text:
                              '${_focusedMonth.year}.${_focusedMonth.month.toString().padLeft(2, '0')}',
                          pixelSize: 3.2 * s,
                          letterSpacingPixels: 1,
                          color: const Color(0xFF182A78),
                          shadowColor: const Color(0xFFC5D0E0),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: sx(gridLeft),
                    top: sy(gridTop),
                    width: sx(486),
                    height: sy(311),
                    child: _buildDynamicMonthGrid(s),
                  ),
                ],

                // 3. Interactive 7x5 Calendar Cell Hitboxes
                for (int idx = 0; idx < 35; idx++)
                  Positioned(
                    left: sx(gridLeft + (idx % 7) * cellW),
                    top: sy(gridTop + (idx ~/ 7) * cellH),
                    width: sx(cellW),
                    height: sy(cellH),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        final d = _dateForGridIndex(idx);
                        if (d == null) return;
                        HapticFeedback.selectionClick();
                        if (_selectedGridIndex == idx) {
                          _openDayPage();
                        } else {
                          setState(() {
                            _selectedGridIndex = idx;
                            _selectedDate = d;
                          });
                        }
                      },
                      child: const SizedBox.expand(),
                    ),
                  ),

                // 4. Super-Resolved Movable 3D Golden RPG Cursor (88x80 at 1:1 scale)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 210),
                  curve: Curves.easeOutBack,
                  left: sx(cursorRefX),
                  top: sy(cursorRefY),
                  width: sx(88),
                  height: sy(80),
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFFFFC840).withValues(alpha: 0.28),
                            blurRadius: 8 * s,
                            spreadRadius: 1 * s,
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.30),
                            blurRadius: 4 * s,
                            offset: Offset(0, 2 * s),
                          ),
                        ],
                      ),
                      child: Image.memory(
                        _WonderTextures.p1Cursor,
                        fit: BoxFit.fill,
                        gaplessPlayback: true,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                ),

                // 5. Dynamic Lower Sub-Screen Overlay (y_orig = 877 + 140 = 1017 in 702x1524 space)
                if (!_isDefaultOct14SubScreen)
                  Positioned(
                    left: sx(151),
                    top: sy(1017),
                    width: sx(400),
                    height: sy(216),
                    child: _buildDynamicSubScreenOverlay(s),
                  ),

                // Lower Sub-Screen Tap-to-Enter Hitbox
                Positioned(
                  left: sx(151),
                  top: sy(1017),
                  width: sx(400),
                  height: sy(216),
                  child: _buildSubScreenTapZones(),
                ),

                // 6. Interactive 3D Hardware Controls (shifted by +75px in 702x1524 space)
                // "\ MONTH < >" toggle (y_orig = 602 + 75 = 677)
                Positioned(
                  left: sx(155),
                  top: sy(677),
                  width: sx(130),
                  height: sy(30),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (_) => setState(() => _pressedControl = 'MONTH'),
                    onTapUp: (details) {
                      setState(() => _pressedControl = null);
                      if (details.localPosition.dx < sx(65)) {
                        _changeMonth(-1);
                      } else {
                        _changeMonth(1);
                      }
                    },
                    onTapCancel: () => setState(() => _pressedControl = null),
                    child: const SizedBox.expand(),
                  ),
                ),

                // D-PAD UP (x: 175..256, y: 632 + 75 = 707)
                _build3DHardwareButtonHitbox(
                  id: 'UP',
                  left: sx(175),
                  top: sy(707),
                  width: sx(81),
                  height: sy(80),
                  borderRadius: 16 * s,
                  onTap: () => _moveGridSelection(-7),
                ),
                // D-PAD DOWN (x: 175..256, y: 744 + 75 = 819)
                _build3DHardwareButtonHitbox(
                  id: 'DOWN',
                  left: sx(175),
                  top: sy(819),
                  width: sx(81),
                  height: sy(81),
                  borderRadius: 16 * s,
                  onTap: () => _moveGridSelection(7),
                ),
                // D-PAD LEFT (x: 118..199, y: 688 + 75 = 763)
                _build3DHardwareButtonHitbox(
                  id: 'LEFT',
                  left: sx(118),
                  top: sy(763),
                  width: sx(81),
                  height: sy(81),
                  borderRadius: 16 * s,
                  onTap: () => _moveGridSelection(-1),
                ),
                // D-PAD RIGHT (x: 231..312, y: 688 + 75 = 763)
                _build3DHardwareButtonHitbox(
                  id: 'RIGHT',
                  left: sx(231),
                  top: sy(763),
                  width: sx(81),
                  height: sy(81),
                  borderRadius: 16 * s,
                  onTap: () => _moveGridSelection(1),
                ),

                // "\ TODAY" Pill Button (x: 374..468, y: 638 + 75 = 713)
                _build3DHardwareButtonHitbox(
                  id: 'TODAY',
                  left: sx(374),
                  top: sy(713),
                  width: sx(94),
                  height: sy(50),
                  borderRadius: 24 * s,
                  onTap: _jumpToToday,
                ),

                // "+ ENTER DAY" Angled Orange Capsule (x: 462..602, y: 666 + 75 = 741)
                _build3DHardwareButtonHitbox(
                  id: 'ENTER_DAY',
                  left: sx(462),
                  top: sy(741),
                  width: sx(140),
                  height: sy(118),
                  borderRadius: 32 * s,
                  isAngledOrange: true,
                  onTap: () => _openDayPage(),
                ),

                // 7. Global 3D Directional Lighting & Rim Specular Vignette
                IgnorePointer(
                  child: CustomPaint(
                    size: Size(W, H),
                    painter: _Console3DLightingOverlayPainter(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _build3DHardwareButtonHitbox({
    required String id,
    required double left,
    required double top,
    required double width,
    required double height,
    required double borderRadius,
    bool isAngledOrange = false,
    required VoidCallback onTap,
  }) {
    final isPressed = _pressedControl == id;
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {
          HapticFeedback.lightImpact();
          setState(() => _pressedControl = id);
        },
        onTapUp: (_) {
          setState(() => _pressedControl = null);
          onTap();
        },
        onTapCancel: () => setState(() => _pressedControl = null),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: isPressed
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.black.withValues(alpha: 0.24),
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.28),
                    ],
                  )
                : null,
            boxShadow: isPressed
                ? [
                    BoxShadow(
                      color: (isAngledOrange
                              ? const Color(0xFFFF6D24)
                              : const Color(0xFF90C8FF))
                          .withValues(alpha: 0.35),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildSubScreenTapZones() {
    final cartridges = widget.store.cartridgesFor(_selectedDate);
    final displayItems = <DayCartridge>[
      if (cartridges.isNotEmpty)
        cartridges[0]
      else
        const DayCartridge(
          id: 'default-1',
          title: 'MORNING RUN 5KM',
          type: CartridgeType.done,
        ),
      if (cartridges.length > 1)
        cartridges[1]
      else
        const DayCartridge(
          id: 'default-2',
          title: 'FINISH UI DESIGN',
          type: CartridgeType.todo,
        ),
      if (cartridges.length > 2)
        cartridges[2]
      else
        const DayCartridge(
          id: 'default-3',
          title: 'DEBUG WIDGET TAP',
          type: CartridgeType.todo,
        ),
    ];

    return Column(
      children: [
        Expanded(
          flex: 22,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _openDayPage(),
            child: const SizedBox.expand(),
          ),
        ),
        for (int i = 0; i < 3; i++)
          Expanded(
            flex: 26,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _openDayPage(initialCartridge: displayItems[i]),
              child: const SizedBox.expand(),
            ),
          ),
      ],
    );
  }

  Widget _buildDynamicSubScreenOverlay(double s) {
    final cartridges = widget.store.cartridgesFor(_selectedDate);
    const weekdayNames = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    final wd = weekdayNames[_selectedDate.weekday - 1];
    final dateStr =
        '${_selectedDate.year}.${_selectedDate.month.toString().padLeft(2, '0')}.${_selectedDate.day.toString().padLeft(2, '0')}';

    final displayItems = <DayCartridge>[
      if (cartridges.isNotEmpty)
        cartridges[0]
      else
        const DayCartridge(
          id: 'empty-1',
          title: 'TAP TO ADD IDEA',
          type: CartridgeType.todo,
        ),
      if (cartridges.length > 1)
        cartridges[1]
      else
        const DayCartridge(
          id: 'empty-2',
          title: 'READY FOR INPUT',
          type: CartridgeType.todo,
        ),
      if (cartridges.length > 2)
        cartridges[2]
      else
        const DayCartridge(
          id: 'empty-3',
          title: 'SLIDE OUT KEYPAD',
          type: CartridgeType.done,
        ),
    ];

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.memory(
          _WonderTextures.p1SubscreenClean,
          fit: BoxFit.fill,
          gaplessPlayback: true,
          filterQuality: FilterQuality.high,
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(12 * s, 7.0 * s, 12 * s, 6 * s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 17 * s,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: _PixelBitmapText(
                      text: 'TARGET // $dateStr ($wd)',
                      pixelSize: 1.50 * s,
                      letterSpacingPixels: 1,
                      color: const Color(0xFFF4F7FB),
                      shadowColor: const Color(0xFF09123B),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 3.5 * s),
              for (int i = 0; i < 3; i++)
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _PixelBitmapText(
                        text: '[',
                        pixelSize: 1.55 * s,
                        letterSpacingPixels: 1,
                        color: const Color(0xFF18221A),
                        shadowColor: const Color(0xFFC4D2C5),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 2 * s),
                        child: CustomPaint(
                          size: Size(13.5 * s, 13.5 * s),
                          painter: _PixelSpritePainter(
                            displayItems[i].type,
                            useCrossedSwords:
                                displayItems[i].type != CartridgeType.done,
                          ),
                        ),
                      ),
                      _PixelBitmapText(
                        text: '] ',
                        pixelSize: 1.55 * s,
                        letterSpacingPixels: 1,
                        color: const Color(0xFF18221A),
                        shadowColor: const Color(0xFFC4D2C5),
                      ),
                      SizedBox(width: 2 * s),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: _PixelBitmapText(
                            text:
                                '${(i + 1).toString().padLeft(2, '0')} // ${displayItems[i].title.toUpperCase()}',
                            pixelSize: 1.50 * s,
                            letterSpacingPixels: 1,
                            color: const Color(0xFF141D16),
                            shadowColor: const Color(0xFFC4D2C5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDynamicMonthGrid(double s) {
    return Container(
      color: const Color(0xFF9CAC9F),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cw = constraints.maxWidth / 7;
          final ch = constraints.maxHeight / 5;
          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _CalendarEtchedGridPainter(
                    cols: 7,
                    rows: 5,
                    selectedIndex: _selectedGridIndex,
                  ),
                ),
              ),
              for (int idx = 0; idx < 35; idx++)
                Positioned(
                  left: (idx % 7) * cw,
                  top: (idx ~/ 7) * ch,
                  width: cw,
                  height: ch,
                  child: Builder(
                    builder: (context) {
                      final d = _dateForGridIndex(idx);
                      if (d == null) return const SizedBox.shrink();
                      final items = widget.store.cartridgesFor(d);
                      final hasSword =
                          items.any((c) => c.type != CartridgeType.done);
                      final hasHeart =
                          items.any((c) => c.type == CartridgeType.done);
                      return Padding(
                        padding: EdgeInsets.all(3 * s),
                        child: Stack(
                          children: [
                            _PixelBitmapText(
                              text: '${d.day}',
                              pixelSize: 1.55 * s,
                              color: const Color(0xFF141C16),
                              shadowColor: const Color(0xFFC4D2C5),
                            ),
                            if (hasSword)
                              Positioned(
                                left: 0,
                                bottom: 0,
                                child: CustomPaint(
                                  size: Size(12 * s, 12 * s),
                                  painter: _PixelSpritePainter(
                                    CartridgeType.todo,
                                    useCrossedSwords: false,
                                  ),
                                ),
                              ),
                            if (hasHeart)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: CustomPaint(
                                  size: Size(12 * s, 12 * s),
                                  painter: _PixelSpritePainter(
                                    CartridgeType.done,
                                    useCrossedSwords: false,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ============================================================================
// PAGE 2: WONDER DAY SLOT PAGE (1080x2344 NATIVE 1:1 ZERO-DISTORTION)
// ============================================================================

class WonderDaySlotPage extends StatefulWidget {
  final WonderCalendarStore store;
  final DateTime date;
  final DayCartridge? initialCartridge;

  const WonderDaySlotPage({
    super.key,
    required this.store,
    required this.date,
    this.initialCartridge,
  });

  @override
  State<WonderDaySlotPage> createState() => _WonderDaySlotPageState();
}

class _WonderDaySlotPageState extends State<WonderDaySlotPage>
    with SingleTickerProviderStateMixin {
  static const double _kRefW = 702.0;
  static const double _kRefH = 1524.0;

  late AnimationController _choreoController;
  String? _activeCartridgeId;
  String _terminalText = 'WRITE API DOCS';
  bool _capsLock = true;
  bool _showCursorBlock = true;
  String? _pressedKey;
  Timer? _cursorTimer;

  @override
  void initState() {
    super.initState();
    _choreoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 860),
    );

    SystemChannels.textInput.invokeMethod('TextInput.hide');

    final list = widget.store.cartridgesFor(widget.date);
    if (widget.initialCartridge != null) {
      _activeCartridgeId = widget.initialCartridge!.id;
      _syncFromCartridge(widget.initialCartridge!);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _choreoController.forward();
      });
    } else if (list.isNotEmpty) {
      final defaultCart = list.length >= 3 ? list[2] : list.last;
      _activeCartridgeId = defaultCart.id;
      _syncFromCartridge(defaultCart);
    }

    _cursorTimer = Timer.periodic(const Duration(milliseconds: 520), (_) {
      if (mounted) setState(() => _showCursorBlock = !_showCursorBlock);
    });

    widget.store.addListener(_onStoreUpdated);
  }

  @override
  void dispose() {
    _cursorTimer?.cancel();
    widget.store.removeListener(_onStoreUpdated);
    _choreoController.dispose();
    super.dispose();
  }

  void _onStoreUpdated() {
    if (mounted) setState(() {});
  }

  void _syncFromCartridge(DayCartridge c) {
    _terminalText = c.body.isNotEmpty ? c.body : c.title;
  }

  DayCartridge? _findActiveCartridge(List<DayCartridge> list) {
    if (_activeCartridgeId == null) {
      return list.isNotEmpty ? list.last : null;
    }
    for (final c in list) {
      if (c.id == _activeCartridgeId) return c;
    }
    return list.isNotEmpty ? list.last : null;
  }

  void _onTapCartridge(DayCartridge cartridge) {
    HapticFeedback.mediumImpact();
    SystemChannels.textInput.invokeMethod('TextInput.hide');

    if (_activeCartridgeId == cartridge.id) {
      if (_choreoController.value > 0.5) {
        _choreoController.reverse();
      } else {
        _choreoController.forward();
      }
      return;
    }

    setState(() {
      _activeCartridgeId = cartridge.id;
      _syncFromCartridge(cartridge);
    });
    _choreoController.forward(from: 0.0);
  }

  void _onCreateCartridgeOfType(CartridgeType type) {
    HapticFeedback.heavyImpact();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    final defaultTitle = switch (type) {
      CartridgeType.todo => 'WRITE API DOCS',
      CartridgeType.done => 'MORNING RUN 5KM',
      CartridgeType.idea => 'NEW RETRO IDEA',
    };
    final created = widget.store.createCartridge(
      widget.date,
      title: defaultTitle,
      type: type,
      translucent: type != CartridgeType.todo ||
          widget.store.cartridgesFor(widget.date).length.isEven,
    );
    setState(() {
      _activeCartridgeId = created.id;
      _syncFromCartridge(created);
    });
    _choreoController.forward(from: 0.0);
  }

  void _cycleActiveCartridgeType() {
    final list = widget.store.cartridgesFor(widget.date);
    final active = _findActiveCartridge(list);
    if (active == null) return;

    HapticFeedback.selectionClick();
    final nextType = switch (active.type) {
      CartridgeType.todo => CartridgeType.done,
      CartridgeType.done => CartridgeType.idea,
      CartridgeType.idea => CartridgeType.todo,
    };
    widget.store.upsertCartridge(
      widget.date,
      active.copyWith(type: nextType),
    );
  }

  void _onHardwareKeyTap(String key) {
    HapticFeedback.lightImpact();
    SystemChannels.textInput.invokeMethod('TextInput.hide');

    final list = widget.store.cartridgesFor(widget.date);
    DayCartridge? active = _findActiveCartridge(list);
    if (active == null) {
      active = widget.store.createCartridge(widget.date);
      _activeCartridgeId = active.id;
    }

    if (_choreoController.value < 0.5) {
      _choreoController.forward();
    }

    String updated = _terminalText;
    if (key == 'BACKSPACE') {
      if (updated.isNotEmpty) {
        // 按字素簇删除，避免 emoji / 组合字符被截断成半个码点
        updated = updated.characters.skipLast(1).toString();
      }
    } else if (key == '123') {
      updated = '';
    } else if (key == 'SHIFT') {
      setState(() => _capsLock = !_capsLock);
      return;
    } else if (key == 'SPACE') {
      updated = '$updated ';
    } else if (key == 'ENTER') {
      HapticFeedback.mediumImpact();
      _choreoController.reverse();
      return;
    } else {
      final ch = _capsLock ? key.toUpperCase() : key.toLowerCase();
      updated = '$updated$ch';
    }

    setState(() {
      _terminalText = updated;
      _showCursorBlock = true;
    });

    final cleanTitle =
        updated.trim().isEmpty ? 'UNTITLED SLOT' : updated.trim().toUpperCase();
    widget.store.upsertCartridge(
      widget.date,
      active.copyWith(title: cleanTitle, body: updated),
    );
  }

  bool get _isOct14DefaultHeader {
    if (widget.date.year != 2026 ||
        widget.date.month != 10 ||
        widget.date.day != 14) {
      return false;
    }
    final list = widget.store.cartridgesFor(widget.date);
    final doneCount = list.where((c) => c.type == CartridgeType.done).length;
    final todoCount = list.where((c) => c.type != CartridgeType.done).length;
    return doneCount == 1 && todoCount == 2;
  }

  @override
  Widget build(BuildContext context) {
    final cartridges = widget.store.cartridgesFor(widget.date);
    final displayCartridges = cartridges.isNotEmpty
        ? cartridges
        : const [
            DayCartridge(
              id: '1014-1',
              title: 'MORNING RUN 5KM',
              type: CartridgeType.done,
              translucent: true,
              body: 'WRITE API DOCS',
            ),
            DayCartridge(
              id: '1014-2',
              title: 'FINISH UI DESIGN',
              type: CartridgeType.todo,
              translucent: false,
              body: 'WRITE API DOCS',
            ),
            DayCartridge(
              id: '1014-3',
              title: 'DEBUG WIDGET TAP',
              type: CartridgeType.todo,
              translucent: true,
              body: 'WRITE API DOCS',
            ),
          ];
    final activeCartridge = _findActiveCartridge(displayCartridges);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF0A2454),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF0A2454),
        resizeToAvoidBottomInset: false,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final W = constraints.maxWidth;
            final H = constraints.maxHeight;
            double sx(double x) => x * W / _kRefW;
            double sy(double y) => y * H / _kRefH;
            final s = W / 390.0;

            return AnimatedBuilder(
              animation: _choreoController,
              builder: (context, _) {
                final t = _choreoController.value;
                // Phase 1 (0.00 -> 0.36): CD-Slot Plunge
                final plungeProgress = Curves.easeOutBack
                    .transform((t / 0.36).clamp(0.0, 1.0));
                // Phase 2 (0.32 -> 1.00): Upward Rail Slide + Differential Stack
                final slideUpProgress = Curves.easeInOutCubic
                    .transform(((t - 0.32) / 0.68).clamp(0.0, 1.0));

                // Sliding White Carriage top Y in 702x1524 reference coordinates:
                // Initial State (Photo 2): y = 930.0 (spans 930..1490, covering keyboard!)
                // Input State (Photo 1):   y = 566.0 (spans 566..1122, sitting flush above keyboard!)
                final carrRefTopY =
                    ui.lerpDouble(930.0, 566.0, slideUpProgress)!;

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // ========================================================
                    // LAYER 1: 1080x2344 Super-Resolved Stationary Console Underlay
                    // ========================================================
                    Image.memory(
                      _WonderTextures.p2UnderlayBase,
                      width: W,
                      height: H,
                      fit: BoxFit.fill,
                      gaplessPlayback: true,
                      filterQuality: FilterQuality.high,
                    ),

                    if (!_isOct14DefaultHeader)
                      Positioned(
                        left: sx(398),
                        top: sy(58),
                        width: sx(218),
                        height: sy(104),
                        child: _buildDynamicDaySlotHeaderBadge(
                          displayCartridges,
                          s,
                        ),
                      ),

                    // ========================================================
                    // LAYER 2: Stationary Bottom Hardware QWERTY Keyboard
                    //          (y = 1048..1524 in 702x1524 space; 100% hidden when
                    //          slideUpProgress == 0.0 so 'enter' never peeks out!)
                    // ========================================================
                    if (slideUpProgress > 0.01)
                      Positioned(
                        left: 0,
                        right: 0,
                        top: sy(1048),
                        height: sy(476),
                        child: ClipRect(
                          clipper: _KeyboardRevealClipper(
                            revealTopPx: sy(
                              (carrRefTopY + 548.0 - 1048.0).clamp(0.0, 476.0),
                            ),
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.memory(
                                _WonderTextures.p2KeyboardBay,
                                fit: BoxFit.fill,
                                gaplessPlayback: true,
                                filterQuality: FilterQuality.high,
                              ),
                              // 3D Cast Shadow falling from the bottom of the sliding carriage onto the keyboard
                              Positioned(
                                left: 0,
                                right: 0,
                                top: sy((carrRefTopY + 548.0 - 1048.0)
                                    .clamp(0.0, 460.0)),
                                height: sy(34),
                                child: IgnorePointer(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.black.withValues(
                                              alpha: 0.58 * slideUpProgress),
                                          Colors.black.withValues(
                                              alpha: 0.20 * slideUpProgress),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Interactive QWERTY Key Hitboxes & 3D Keycap Depression Overlays
                    if (slideUpProgress > 0.15)
                      ..._buildQwertyInteractiveKeyOverlays(
                        sx: sx,
                        sy: sy,
                        s: s,
                      ),

                    // ========================================================
                    // LAYER 3: Top Category Tabs (+ TODO, + DONE, + IDEA)
                    // ========================================================
                    Positioned(
                      left: sx(152),
                      top: sy(192),
                      width: sx(133),
                      height: sy(56),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () =>
                            _onCreateCartridgeOfType(CartridgeType.todo),
                        child: const SizedBox.expand(),
                      ),
                    ),
                    Positioned(
                      left: sx(290),
                      top: sy(192),
                      width: sx(132),
                      height: sy(56),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () =>
                            _onCreateCartridgeOfType(CartridgeType.done),
                        child: const SizedBox.expand(),
                      ),
                    ),
                    Positioned(
                      left: sx(426),
                      top: sy(192),
                      width: sx(130),
                      height: sy(56),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () =>
                            _onCreateCartridgeOfType(CartridgeType.idea),
                        child: const SizedBox.expand(),
                      ),
                    ),

                    // ========================================================
                    // LAYER 4: Photorealistic Cartridge Stack with
                    //          CD-Slot Plunge & Differential-Speed Upward Slide
                    // ========================================================
                    ..._buildChoreographedCartridgeStack(
                      cartridges: displayCartridges,
                      activeCartridge: activeCartridge,
                      plungeProgress: plungeProgress,
                      slideUpProgress: slideUpProgress,
                      carrRefTopY: carrRefTopY,
                      sx: sx,
                      sy: sy,
                      s: s,
                    ),

                    // ========================================================
                    // LAYER 5: Photorealistic Sliding White Carriage (1:1 Unstretched!)
                    // ========================================================
                    Positioned(
                      left: 0,
                      width: W,
                      top: sy(carrRefTopY),
                      height: sy(560),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // 5A. 3D Upper Rim Shadow cast by the U-notch onto the plunged cartridge
                          Positioned(
                            left: sx(115),
                            right: sx(115),
                            top: sy(38),
                            height: sy(40),
                            child: IgnorePointer(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14 * s),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                          alpha: 0.44 + 0.18 * plungeProgress),
                                      blurRadius: 10 * s,
                                      offset: Offset(0, -3 * s),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // 5B. 1080p RGBA Sliding White Carriage Texture Slice
                          Image.memory(
                            _WonderTextures.p2SlidingCarriage,
                            width: W,
                            height: sy(560),
                            fit: BoxFit.fill,
                            gaplessPlayback: true,
                            filterQuality: FilterQuality.high,
                          ),

                          // 5C. Dynamic Glowing Dual LEDs (Green & Amber) on ACTIVE SLOT
                          if (plungeProgress > 0.1) ...[
                            Positioned(
                              left: sx(466),
                              top: sy(78),
                              width: sx(28),
                              height: sy(14),
                              child: IgnorePointer(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF38FF7A)
                                            .withValues(
                                                alpha: 0.68 *
                                                    plungeProgress.clamp(
                                                        0.0, 1.0)),
                                        blurRadius: 8 * s,
                                        spreadRadius: 2 * s,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: sx(504),
                              top: sy(78),
                              width: sx(28),
                              height: sy(14),
                              child: IgnorePointer(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFF9E2C)
                                            .withValues(
                                                alpha: 0.68 *
                                                    plungeProgress.clamp(
                                                        0.0, 1.0)),
                                        blurRadius: 8 * s,
                                        spreadRadius: 2 * s,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],

                          // 5D. Live Interactive Terminal Text inside CARTRIDGE TERMINAL LCD
                          //     (x_ref = 162..540, y_rel = 212..362 — fits on 1 line with zero overflow!)
                          Positioned(
                            left: sx(162),
                            top: sy(212),
                            width: sx(378),
                            height: sy(150),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                SystemChannels.textInput
                                    .invokeMethod('TextInput.hide');
                                if (_choreoController.value < 0.5) {
                                  _choreoController.forward();
                                }
                              },
                              child: _buildLiveTerminalLcdContent(
                                activeCartridge: activeCartridge,
                                s: s,
                              ),
                            ),
                          ),

                          // 5E. Interactive Hardware Controls on the Sliding Carriage
                          Positioned(
                            left: sx(240),
                            top: sy(72),
                            width: sx(220),
                            height: sy(52),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                if (_choreoController.value > 0.5) {
                                  _choreoController.reverse();
                                } else {
                                  _choreoController.forward();
                                }
                              },
                              child: const SizedBox.expand(),
                            ),
                          ),

                          // "\ SWITCH" 3D Mechanical Slider
                          Positioned(
                            left: sx(105),
                            top: sy(435),
                            width: sx(158),
                            height: sy(95),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: _cycleActiveCartridgeType,
                              child: Stack(
                                children: [
                                  if (activeCartridge != null &&
                                      activeCartridge.type !=
                                          CartridgeType.todo)
                                    Positioned(
                                      left: activeCartridge.type ==
                                              CartridgeType.done
                                          ? sx(62)
                                          : sx(34),
                                      top: sy(32),
                                      width: sx(52),
                                      height: sy(36),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10 * s),
                                          gradient: const LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Color(0xFFEFF1EE),
                                              Color(0xFFC2C6C4),
                                            ],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.35),
                                              blurRadius: 4 * s,
                                              offset: Offset(1 * s, 2 * s),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),

                          // "\ EJECT" White Pill Button
                          _build3DCarriageButton(
                            id: 'EJECT',
                            left: sx(298),
                            top: sy(448),
                            width: sx(106),
                            height: sy(66),
                            borderRadius: 24 * s,
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              _choreoController.reverse();
                            },
                          ),

                          // "+ RUN / SAVE" Angled Orange Capsule Button
                          _build3DCarriageButton(
                            id: 'RUN_SAVE',
                            left: sx(466),
                            top: sy(430),
                            width: sx(154),
                            height: sy(108),
                            borderRadius: 32 * s,
                            isOrange: true,
                            onTap: () {
                              HapticFeedback.heavyImpact();
                              if (_choreoController.value > 0.5) {
                                _choreoController.reverse();
                              } else {
                                _choreoController.forward();
                              }
                            },
                          ),
                        ],
                      ),
                    ),

                    // ========================================================
                    // LAYER 6: Top Circular Glass "<" Back Button ([< MAP])
                    // ========================================================
                    Positioned(
                      left: sx(22),
                      top: sy(32),
                      width: sx(106),
                      height: sy(124),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (_) =>
                            setState(() => _pressedKey = 'BACK_MAP'),
                        onTapUp: (_) {
                          setState(() => _pressedKey = null);
                          HapticFeedback.lightImpact();
                          Navigator.of(context).pop();
                        },
                        onTapCancel: () => setState(() => _pressedKey = null),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 90),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28 * s),
                            color: _pressedKey == 'BACK_MAP'
                                ? Colors.white.withValues(alpha: 0.18)
                                : Colors.transparent,
                          ),
                        ),
                      ),
                    ),

                    // ========================================================
                    // LAYER 7: Global 3D Directional Lighting & Specular Rim
                    // ========================================================
                    IgnorePointer(
                      child: CustomPaint(
                        size: Size(W, H),
                        painter: _Console3DLightingOverlayPainter(),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // CHOREOGRAPHED CARTRIDGE STACK (CD-SLOT PLUNGE + DIFFERENTIAL RAIL SLIDE)
  // --------------------------------------------------------------------------
  List<Widget> _buildChoreographedCartridgeStack({
    required List<DayCartridge> cartridges,
    required DayCartridge? activeCartridge,
    required double plungeProgress,
    required double slideUpProgress,
    required double carrRefTopY,
    required double Function(double) sx,
    required double Function(double) sy,
    required double s,
  }) {
    final backgroundCarts = <MapEntry<int, DayCartridge>>[];
    MapEntry<int, DayCartridge>? activeEntry;

    for (int i = 0; i < cartridges.length; i++) {
      final c = cartridges[i];
      if (activeCartridge != null && c.id == activeCartridge.id) {
        activeEntry = MapEntry(i, c);
      } else {
        backgroundCarts.add(MapEntry(i, c));
      }
    }
    if (activeEntry == null && cartridges.isNotEmpty) {
      activeEntry = MapEntry(cartridges.length - 1, cartridges.last);
    }

    final widgets = <Widget>[];

    // 1. Render unselected cartridges first (lower z-index, differential upward speed!)
    //    In 702x1524 space: Initial slots = 296.0, 512.0; Slid-up slots = 268.0, 346.0
    for (int bgIdx = 0; bgIdx < backgroundCarts.length; bgIdx++) {
      final entry = backgroundCarts[bgIdx];
      final origIndex = entry.key;
      final cart = entry.value;

      final initialSlotIdx = bgIdx.clamp(0, 2);
      final baseRefY = 296.0 + initialSlotIdx * 216.0;

      final speedMultiplier = bgIdx == 0 ? 1.28 : 1.12;
      final diffSlide = Curves.easeOutCubic
          .transform((slideUpProgress * speedMultiplier).clamp(0.0, 1.0));
      final targetRefY = 268.0 + bgIdx * 78.0;
      final currentRefY = ui.lerpDouble(baseRefY, targetRefY, diffSlide)!;
      final currentScale =
          ui.lerpDouble(1.0, 0.975 - bgIdx * 0.012, diffSlide)!;

      widgets.add(
        Positioned(
          left: sx(122),
          width: sx(458),
          top: sy(currentRefY),
          height: sy(cart.translucent ? 192 : 162),
          child: Transform.scale(
            scale: currentScale,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _onTapCartridge(cart),
              child: _buildPhotorealisticCartridgeSlice(
                cartridge: cart,
                displayNumber: origIndex + 1,
                isSelected: false,
                plungeProgress: 0.0,
                slideUpProgress: diffSlide,
                sx: sx,
                sy: sy,
                s: s,
              ),
            ),
          ),
        ),
      );
    }

    // 2. Render the clicked ACTIVE cartridge LAST (highest z-index, on top of all other cartridges!):
    //    - Phase 1 (plungeProgress 0->1): Plunges downward (+24px) into the CD-slot throat with RPG lock-in.
    //    - Phase 2 (slideUpProgress 0->1): Rides upward locked in the carriage throat from y=728+24 to y=430!
    if (activeEntry != null) {
      final origIndex = activeEntry.key;
      final cart = activeEntry.value;

      final plungeOffsetRefY = 24.0 * plungeProgress;
      final plungeBaseRefY = 728.0 + plungeOffsetRefY;
      // A 方案：下插锁定后，卡带与滑盖保持恒定偏移、同速上滑，
      // 最终停在滑盖顶部槽口（不再独立置顶到 lockedTopRefY=430）。
      final lockedRefY = carrRefTopY - 178.0;
      final currentRefY =
          ui.lerpDouble(plungeBaseRefY, lockedRefY, slideUpProgress)!;

      widgets.add(
        Positioned(
          left: sx(122),
          width: sx(458),
          top: sy(currentRefY),
          height: sy(192),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _onTapCartridge(cart),
            child: _buildPhotorealisticCartridgeSlice(
              cartridge: cart,
              displayNumber: origIndex + 1,
              isSelected: true,
              plungeProgress: plungeProgress,
              slideUpProgress: slideUpProgress,
              sx: sx,
              sy: sy,
              s: s,
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _buildPhotorealisticCartridgeSlice({
    required DayCartridge cartridge,
    required int displayNumber,
    required bool isSelected,
    required double plungeProgress,
    required double slideUpProgress,
    required double Function(double) sx,
    required double Function(double) sy,
    required double s,
  }) {
    final useBlueShell = isSelected || cartridge.translucent;
    final numStr = displayNumber.toString().padLeft(2, '0');

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18 * s),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isSelected ? 0.54 : 0.35),
            blurRadius: (isSelected ? 12 : 7) * s,
            offset: Offset(0, (isSelected ? 6 : 4) * s),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. 1080p Super-Resolved Cartridge Shell Slice
          Positioned.fill(
            child: Image.memory(
              useBlueShell
                  ? _WonderTextures.p2CartBlue
                  : _WonderTextures.p2CartWhite,
              fit: BoxFit.fill,
              gaplessPlayback: true,
              filterQuality: FilterQuality.high,
            ),
          ),

          // 2. Dynamic Specular Light Sweep across the Cartridge Shell during movement
          if (plungeProgress > 0.01 || slideUpProgress > 0.01)
            Positioned.fill(
              child: IgnorePointer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16 * s),
                  child: Transform.translate(
                    offset: Offset(
                      sx(-120 + 240 * slideUpProgress),
                      sy(-20 + 40 * plungeProgress),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.transparent,
                            Colors.white.withValues(alpha: 0.18),
                            Colors.transparent,
                          ],
                          stops: const [0.35, 0.50, 0.65],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // 3. Vector-Crisp Cartridge Label Content:
          //    Left box (x_rel = 74..136): Icon + 2-digit index ("03") inside the RPG golden frame
          //    Right box (x_rel = 158..386): "// DEBUG WIDGET TAP" cleanly to the right of the RPG frame!
          Positioned(
            left: sx(74),
            top: sy(63),
            width: sx(62),
            height: sy(46),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CustomPaint(
                  size: Size(sx(26), sx(26)),
                  painter: _PixelSpritePainter(
                    cartridge.type,
                    useCrossedSwords: false,
                  ),
                ),
                SizedBox(width: sx(5)),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: _PixelBitmapText(
                      text: numStr,
                      pixelSize: 1.95 * s,
                      letterSpacingPixels: 1,
                      color: const Color(0xFF12181C),
                      shadowColor: const Color(0xFFD6DCDE),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: sx(isSelected ? 158 : 144),
            top: sy(63),
            width: sx(isSelected ? 226 : 240),
            height: sy(46),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: _PixelBitmapText(
                  text: '// ${cartridge.title.toUpperCase()}',
                  pixelSize: 1.85 * s,
                  letterSpacingPixels: 1,
                  color: const Color(0xFF12181C),
                  shadowColor: const Color(0xFFD6DCDE),
                ),
              ),
            ),
          ),

          // 4. Super-Resolved Golden "RPG" Lock-In Badge on the Active Cartridge
          if (isSelected)
            Positioned(
              left: sx(36),
              top: sy(40),
              width: sx(124),
              height: sy(118),
              child: IgnorePointer(
                child: Transform.scale(
                  scale: 1.0 + 0.04 * math.sin(plungeProgress * math.pi),
                  child: Image.memory(
                    _WonderTextures.p2RpgBadge,
                    fit: BoxFit.fill,
                    gaplessPlayback: true,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // LIVE EDITABLE TERMINAL LCD CONTENT ("[⚔️] > WRITE API DOCS█")
  // Fits cleanly inside the LCD screen on 1 line (or wraps cleanly for long notes)
  // --------------------------------------------------------------------------
  Widget _buildLiveTerminalLcdContent({
    required DayCartridge? activeCartridge,
    required double s,
  }) {
    final type = activeCartridge?.type ?? CartridgeType.todo;
    final displayStr = _terminalText.toUpperCase();
    final isShortLine = displayStr.length <= 18 && !displayStr.contains('\n');

    Widget buildPromptAndText(double pxSize) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _PixelBitmapText(
            text: '[',
            pixelSize: pxSize,
            color: const Color(0xFF141D16),
            shadowColor: const Color(0xFFB8C8BA),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 2 * s),
            child: CustomPaint(
              size: Size(pxSize * 7.8, pxSize * 7.8),
              painter: _PixelSpritePainter(
                type,
                useCrossedSwords: type != CartridgeType.done,
              ),
            ),
          ),
          _PixelBitmapText(
            text: '] > ',
            pixelSize: pxSize,
            color: const Color(0xFF141D16),
            shadowColor: const Color(0xFFB8C8BA),
          ),
          _PixelBitmapText(
            text: displayStr,
            pixelSize: pxSize,
            letterSpacingPixels: 1,
            color: const Color(0xFF141D16),
            shadowColor: const Color(0xFFB8C8BA),
          ),
          SizedBox(width: 2 * s),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 120),
            opacity: _showCursorBlock ? 1.0 : 0.15,
            child: CustomPaint(
              size: Size(pxSize * 5.2, pxSize * 7.5),
              painter: _CheckeredBlockCursorPainter(),
            ),
          ),
        ],
      );
    }

    if (isShortLine) {
      return Padding(
        padding: EdgeInsets.fromLTRB(4 * s, 4 * s, 6 * s, 4 * s),
        child: Align(
          alignment: Alignment.topLeft,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: buildPromptAndText(1.55 * s),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(4 * s, 4 * s, 6 * s, 4 * s),
      child: SingleChildScrollView(
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 4 * s,
          children: [
            _PixelBitmapText(
              text: '[',
              pixelSize: 1.45 * s,
              color: const Color(0xFF141D16),
              shadowColor: const Color(0xFFB8C8BA),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 2 * s),
              child: CustomPaint(
                size: Size(12 * s, 12 * s),
                painter: _PixelSpritePainter(
                  type,
                  useCrossedSwords: type != CartridgeType.done,
                ),
              ),
            ),
            _PixelBitmapText(
              text: '] > $displayStr',
              pixelSize: 1.45 * s,
              letterSpacingPixels: 1,
              color: const Color(0xFF141D16),
              shadowColor: const Color(0xFFB8C8BA),
            ),
            SizedBox(width: 2 * s),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 120),
              opacity: _showCursorBlock ? 1.0 : 0.15,
              child: CustomPaint(
                size: Size(8 * s, 12 * s),
                painter: _CheckeredBlockCursorPainter(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _build3DCarriageButton({
    required String id,
    required double left,
    required double top,
    required double width,
    required double height,
    required double borderRadius,
    bool isOrange = false,
    required VoidCallback onTap,
  }) {
    final isPressed = _pressedKey == id;
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressedKey = id),
        onTapUp: (_) {
          setState(() => _pressedKey = null);
          onTap();
        },
        onTapCancel: () => setState(() => _pressedKey = null),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: isPressed
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.black.withValues(alpha: 0.25),
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.25),
                    ],
                  )
                : null,
            boxShadow: isPressed
                ? [
                    BoxShadow(
                      color: (isOrange
                              ? const Color(0xFFFF6D24)
                              : const Color(0xFF90C8FF))
                          .withValues(alpha: 0.38),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // INTERACTIVE HITBOXES FOR THE SLIDE-OUT QWERTY KEYBOARD (y_orig + 210 in 702x1524)
  // --------------------------------------------------------------------------
  List<Widget> _buildQwertyInteractiveKeyOverlays({
    required double Function(double) sx,
    required double Function(double) sy,
    required double s,
  }) {
    const row1 = ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'];
    const row2 = ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'];
    const row3 = ['Z', 'X', 'C', 'V', 'B', 'N', 'M'];

    final overlays = <Widget>[];

    void addKey({
      required String keyId,
      required double refL,
      required double refT,
      required double refW,
      required double refH,
    }) {
      final pressed = _pressedKey == 'KB_$keyId';
      overlays.add(
        Positioned(
          left: sx(refL),
          top: sy(refT),
          width: sx(refW),
          height: sy(refH),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => setState(() => _pressedKey = 'KB_$keyId'),
            onTapUp: (_) {
              setState(() => _pressedKey = null);
              _onHardwareKeyTap(keyId);
            },
            onTapCancel: () => setState(() => _pressedKey = null),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 70),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8 * s),
                color: pressed
                    ? const Color(0xFF88C0FF).withValues(alpha: 0.28)
                    : Colors.transparent,
                border: pressed
                    ? Border.all(
                        color: const Color(0xFFD6EEFF).withValues(alpha: 0.85),
                        width: 1.5,
                      )
                    : null,
                boxShadow: pressed
                    ? [
                        BoxShadow(
                          color: const Color(0xFF5CA8FF).withValues(alpha: 0.45),
                          blurRadius: 8 * s,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        ),
      );
    }

    // Row 1: Q..P (y = 934 + 210 = 1144)
    const r1Step = 61.0;
    for (int i = 0; i < row1.length; i++) {
      addKey(
        keyId: row1[i],
        refL: 46.0 + i * r1Step,
        refT: 1144.0,
        refW: 58.0,
        refH: 76.0,
      );
    }

    // Row 2: A..L (y = 1018 + 210 = 1228)
    for (int i = 0; i < row2.length; i++) {
      addKey(
        keyId: row2[i],
        refL: 76.0 + i * r1Step,
        refT: 1228.0,
        refW: 58.0,
        refH: 76.0,
      );
    }

    // Row 3: SHIFT, Z..M, BACKSPACE (y = 1102 + 210 = 1312)
    addKey(keyId: 'SHIFT', refL: 46.0, refT: 1312.0, refW: 78.0, refH: 76.0);
    for (int i = 0; i < row3.length; i++) {
      addKey(
        keyId: row3[i],
        refL: 128.0 + i * 62.8,
        refT: 1312.0,
        refW: 59.0,
        refH: 76.0,
      );
    }
    addKey(
        keyId: 'BACKSPACE', refL: 572.0, refT: 1312.0, refW: 84.0, refH: 76.0);

    // Row 4: 123, shift, spacebar, enter (y = 1186 + 210 = 1396)
    addKey(keyId: '123', refL: 46.0, refT: 1396.0, refW: 80.0, refH: 78.0);
    addKey(keyId: 'SHIFT', refL: 130.0, refT: 1396.0, refW: 70.0, refH: 78.0);
    addKey(keyId: 'SPACE', refL: 204.0, refT: 1396.0, refW: 304.0, refH: 78.0);
    addKey(keyId: 'ENTER', refL: 512.0, refT: 1396.0, refW: 144.0, refH: 78.0);

    return overlays;
  }

  Widget _buildDynamicDaySlotHeaderBadge(
      List<DayCartridge> cartridges, double s) {
    final doneCount =
        cartridges.where((c) => c.type == CartridgeType.done).length;
    final todoCount =
        cartridges.where((c) => c.type != CartridgeType.done).length;
    const weekdayNames = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    final wd = weekdayNames[widget.date.weekday - 1];
    final dateStr =
        '${widget.date.year}.${widget.date.month.toString().padLeft(2, '0')}.${widget.date.day.toString().padLeft(2, '0')}';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6 * s, vertical: 3 * s),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEC),
        borderRadius: BorderRadius.circular(8 * s),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: _PixelBitmapText(
              text: dateStr,
              pixelSize: 2.1 * s,
              color: const Color(0xFF142A72),
              shadowColor: const Color(0xFFC8D2E2),
            ),
          ),
          SizedBox(height: 4 * s),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6 * s, vertical: 3 * s),
            decoration: BoxDecoration(
              color: const Color(0xFF1C2E7A),
              borderRadius: BorderRadius.circular(5 * s),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PixelBitmapText(
                    text: '$wd // ',
                    pixelSize: 1.45 * s,
                    color: Colors.white,
                  ),
                  CustomPaint(
                    size: Size(11 * s, 11 * s),
                    painter: _PixelSpritePainter(CartridgeType.done),
                  ),
                  _PixelBitmapText(
                    text: '×$doneCount ',
                    pixelSize: 1.45 * s,
                    color: Colors.white,
                  ),
                  CustomPaint(
                    size: Size(11 * s, 11 * s),
                    painter: _PixelSpritePainter(
                      CartridgeType.todo,
                      useCrossedSwords: true,
                    ),
                  ),
                  _PixelBitmapText(
                    text: '×$todoCount',
                    pixelSize: 1.45 * s,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// CLIPPER & 3D DIRECTIONAL LIGHTING PAINTERS
// ============================================================================

class _KeyboardRevealClipper extends CustomClipper<Rect> {
  final double revealTopPx;

  const _KeyboardRevealClipper({required this.revealTopPx});

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(0, revealTopPx, size.width, size.height);
  }

  @override
  bool shouldReclip(covariant _KeyboardRevealClipper oldClipper) =>
      oldClipper.revealTopPx != revealTopPx;
}

class _Console3DLightingOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final W = size.width;
    final rect = Offset.zero & size;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.05),
            Colors.transparent,
            Colors.black.withValues(alpha: 0.08),
          ],
          stops: const [0.0, 0.52, 1.0],
        ).createShader(rect),
    );

    final outerRRect = RRect.fromRectAndRadius(
      rect.deflate(1.2),
      Radius.circular(W * 0.095),
    );
    canvas.drawRRect(
      outerRRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFD8EEFF).withValues(alpha: 0.55),
            const Color(0xFF6CA4E0).withValues(alpha: 0.22),
            const Color(0xFF061534).withValues(alpha: 0.60),
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CheckeredBlockCursorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dark = Paint()..color = const Color(0xFF141D16);
    final shadow = Paint()..color = const Color(0xFF56685A);
    const step = 2.0;
    for (double y = 0; y < size.height; y += step) {
      for (double x = 0; x < size.width; x += step) {
        final xi = (x / step).floor();
        final yi = (y / step).floor();
        canvas.drawRect(
          Rect.fromLTWH(x, y, step, step),
          (xi + yi).isEven ? dark : shadow,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// BUILT-IN 5x7 BITMAP PIXEL FONT ENGINE & SPRITE PAINTERS
// ============================================================================

class _PixelBitmapText extends StatelessWidget {
  final String text;
  final double pixelSize;
  final int letterSpacingPixels;
  final Color color;
  final Color? shadowColor;

  const _PixelBitmapText({
    required this.text,
    this.pixelSize = 2.0,
    this.letterSpacingPixels = 1,
    required this.color,
    this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    final upper = text.toUpperCase();
    int totalCols = 0;
    for (int i = 0; i < upper.length; i++) {
      final ch = upper[i];
      final glyph = _PixelGlyphs.map[ch] ?? _PixelGlyphs.map[' ']!;
      totalCols += glyph[0].length;
      if (i < upper.length - 1) {
        totalCols += letterSpacingPixels;
      }
    }
    return CustomPaint(
      size: Size(totalCols * pixelSize, 7 * pixelSize),
      painter: _PixelBitmapPainter(
        text: upper,
        pixelSize: pixelSize,
        letterSpacingPixels: letterSpacingPixels,
        color: color,
        shadowColor: shadowColor,
      ),
    );
  }
}

class _PixelBitmapPainter extends CustomPainter {
  final String text;
  final double pixelSize;
  final int letterSpacingPixels;
  final Color color;
  final Color? shadowColor;

  const _PixelBitmapPainter({
    required this.text,
    required this.pixelSize,
    required this.letterSpacingPixels,
    required this.color,
    this.shadowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fgPaint = Paint()..color = color;
    final shPaint = shadowColor != null ? (Paint()..color = shadowColor!) : null;

    int colOffset = 0;
    for (int i = 0; i < text.length; i++) {
      final ch = text[i];
      final glyph = _PixelGlyphs.map[ch] ?? _PixelGlyphs.map[' ']!;
      final cols = glyph[0].length;
      for (int r = 0; r < 7; r++) {
        final rowStr = glyph[r];
        for (int c = 0; c < cols; c++) {
          if (rowStr[c] == '#') {
            final x = (colOffset + c) * pixelSize;
            final y = r * pixelSize;
            if (shPaint != null) {
              canvas.drawRect(
                Rect.fromLTWH(
                  x + pixelSize * 0.55,
                  y + pixelSize * 0.55,
                  pixelSize * 1.04,
                  pixelSize * 1.04,
                ),
                shPaint,
              );
            }
            canvas.drawRect(
              Rect.fromLTWH(x, y, pixelSize * 1.04, pixelSize * 1.04),
              fgPaint,
            );
          }
        }
      }
      colOffset += cols + letterSpacingPixels;
    }
  }

  @override
  bool shouldRepaint(covariant _PixelBitmapPainter oldDelegate) =>
      oldDelegate.text != text ||
      oldDelegate.pixelSize != pixelSize ||
      oldDelegate.color != color;
}

class _PixelGlyphs {
  static const Map<String, List<String>> map = {
    'A': [' ### ', '#   #', '#   #', '#####', '#   #', '#   #', '#   #'],
    'B': ['#### ', '#   #', '#   #', '#### ', '#   #', '#   #', '#### '],
    'C': [' ####', '#    ', '#    ', '#    ', '#    ', '#    ', ' ####'],
    'D': ['#### ', '#   #', '#   #', '#   #', '#   #', '#   #', '#### '],
    'E': ['#####', '#    ', '#    ', '#### ', '#    ', '#    ', '#####'],
    'F': ['#####', '#    ', '#    ', '#### ', '#    ', '#    ', '#    '],
    'G': [' ####', '#    ', '#    ', '# ###', '#   #', '#   #', ' ####'],
    'H': ['#   #', '#   #', '#   #', '#####', '#   #', '#   #', '#   #'],
    'I': [' ### ', '  #  ', '  #  ', '  #  ', '  #  ', '  #  ', ' ### '],
    'J': ['  ###', '   # ', '   # ', '   # ', '#  # ', '#  # ', ' ##  '],
    'K': ['#   #', '#  # ', '# #  ', '##   ', '# #  ', '#  # ', '#   #'],
    'L': ['#    ', '#    ', '#    ', '#    ', '#    ', '#    ', '#####'],
    'M': ['#   #', '## ##', '# # #', '# # #', '#   #', '#   #', '#   #'],
    'N': ['#   #', '##  #', '# # #', '#  ##', '#   #', '#   #', '#   #'],
    'O': [' ### ', '#   #', '#   #', '#   #', '#   #', '#   #', ' ### '],
    'P': ['#### ', '#   #', '#   #', '#### ', '#    ', '#    ', '#    '],
    'Q': [' ### ', '#   #', '#   #', '#   #', '# # #', '#  # ', ' ## #'],
    'R': ['#### ', '#   #', '#   #', '#### ', '# #  ', '#  # ', '#   #'],
    'S': [' ####', '#    ', '#    ', ' ### ', '    #', '    #', '#### '],
    'T': ['#####', '  #  ', '  #  ', '  #  ', '  #  ', '  #  ', '  #  '],
    'U': ['#   #', '#   #', '#   #', '#   #', '#   #', '#   #', ' ### '],
    'V': ['#   #', '#   #', '#   #', '#   #', '#   #', ' # # ', '  #  '],
    'W': ['#   #', '#   #', '#   #', '# # #', '# # #', '## ##', '#   #'],
    'X': ['#   #', '#   #', ' # # ', '  #  ', ' # # ', '#   #', '#   #'],
    'Y': ['#   #', '#   #', ' # # ', '  #  ', '  #  ', '  #  ', '  #  '],
    'Z': ['#####', '    #', '   # ', '  #  ', ' #   ', '#    ', '#####'],
    '0': [' ### ', '#  ##', '# # #', '# # #', '##  #', '#   #', ' ### '],
    '1': ['  #  ', ' ##  ', '  #  ', '  #  ', '  #  ', '  #  ', ' ### '],
    '2': [' ### ', '#   #', '    #', '  ## ', ' #   ', '#    ', '#####'],
    '3': [' ### ', '#   #', '    #', '  ## ', '    #', '#   #', ' ### '],
    '4': ['   # ', '  ## ', ' # # ', '#  # ', '#####', '   # ', '   # '],
    '5': ['#####', '#    ', '#### ', '    #', '    #', '#   #', ' ### '],
    '6': [' ### ', '#    ', '#### ', '#   #', '#   #', '#   #', ' ### '],
    '7': ['#####', '    #', '   # ', '  #  ', ' #   ', ' #   ', ' #   '],
    '8': [' ### ', '#   #', '#   #', ' ### ', '#   #', '#   #', ' ### '],
    '9': [' ### ', '#   #', '#   #', ' ####', '    #', '#   #', ' ### '],
    '.': ['  ', '  ', '  ', '  ', '  ', '##', '##'],
    ':': ['  ', '##', '##', '  ', '##', '##', '  '],
    '/': ['    #', '   # ', '   # ', '  #  ', ' #   ', ' #   ', '#    '],
    '-': ['    ', '    ', '    ', '####', '    ', '    ', '    '],
    '>': ['#   ', ' #  ', '  # ', '   #', '  # ', ' #  ', '#   '],
    '<': ['   #', '  # ', ' #  ', '#   ', ' #  ', '  # ', '   #'],
    '[': [' ###', ' #  ', ' #  ', ' #  ', ' #  ', ' #  ', ' ###'],
    ']': ['### ', '  # ', '  # ', '  # ', '  # ', '  # ', '### '],
    '(': ['  # ', ' #  ', '#   ', '#   ', '#   ', ' #  ', '  # '],
    ')': [' #  ', '  # ', '   #', '   #', '   #', '  # ', ' #  '],
    '×': ['     ', '#   #', ' # # ', '  #  ', ' # # ', '#   #', '     '],
    '+': ['     ', '  #  ', '  #  ', '#####', '  #  ', '  #  ', '     '],
    ' ': ['   ', '   ', '   ', '   ', '   ', '   ', '   '],
  };
}

class _CalendarEtchedGridPainter extends CustomPainter {
  final int cols;
  final int rows;
  final int selectedIndex;

  const _CalendarEtchedGridPainter({
    required this.cols,
    required this.rows,
    required this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / cols;
    final cellH = size.height / rows;
    final darkLine = Paint()
      ..color = const Color(0xFF1E2620)
      ..strokeWidth = 1.2;
    final lightEtch = Paint()
      ..color = const Color(0xFFB9C9BA).withValues(alpha: 0.72)
      ..strokeWidth = 1.0;

    for (int c = 1; c < cols; c++) {
      final x = c * cellW;
      canvas.drawLine(
          Offset(x + 1.0, 0), Offset(x + 1.0, size.height), lightEtch);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), darkLine);
    }
    for (int r = 1; r < rows; r++) {
      final y = r * cellH;
      canvas.drawLine(
          Offset(0, y + 1.0), Offset(size.width, y + 1.0), lightEtch);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), darkLine);
    }
  }

  @override
  bool shouldRepaint(covariant _CalendarEtchedGridPainter oldDelegate) =>
      oldDelegate.selectedIndex != selectedIndex;
}

class _PixelSpritePainter extends CustomPainter {
  final CartridgeType type;
  final bool useCrossedSwords;

  const _PixelSpritePainter(
    this.type, {
    this.useCrossedSwords = false,
  });

  static const List<String> _heartGrid = [
    '..KKK...KKK..',
    '.KRRRK.KRRRK.',
    'KRWWWRKRRRRRK',
    'KRWWRRRRRRRRK',
    'KRRRRRRRRRRRK',
    'KRRRRRRRRRRRK',
    '.KRRRRRRRRRK.',
    '..KRRRRRRRK..',
    '...KRRRRRK...',
    '....KRRRK....',
    '.....KRK.....',
    '......K......',
  ];

  static const List<String> _swordGrid = [
    '..........KKK',
    '.........KWWK',
    '........KWWSK',
    '.......KWWSK.',
    '......KWWSK..',
    '..KK.KWWSK...',
    '..KGGWWSK....',
    '...KGGSK.....',
    '..KBBGGGKK...',
    '.KBBK.KKGKK..',
    'KGBK.........',
    'KKK..........',
  ];

  static const List<String> _crossedSwordsGrid = [
    'KKK.......KKK',
    'KWWK.....KWWK',
    '.KWWSK.KWWSK.',
    '..KWWSKWWSK..',
    '...KWWWWWk...',
    '....KWWWK....',
    '...KWWSWWSK..',
    '.KKGWSK.KSWGK',
    '.KGGK.....KGG',
    'KBBK.......KB',
    'KBK.........K',
    'KK...........',
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final grid = type == CartridgeType.done
        ? _heartGrid
        : (useCrossedSwords ? _crossedSwordsGrid : _swordGrid);

    final rows = grid.length;
    final cols = grid[0].length;
    final pw = size.width / cols;
    final ph = size.height / rows;

    for (int r = 0; r < rows; r++) {
      final rowStr = grid[r];
      for (int c = 0; c < rowStr.length; c++) {
        final ch = rowStr[c];
        if (ch == '.') continue;
        Color? color;
        switch (ch) {
          case 'K':
          case 'k':
            color = const Color(0xFF15191C);
            break;
          case 'R':
            color = const Color(0xFFD83327);
            break;
          case 'W':
            color = const Color(0xFFF6F8FA);
            break;
          case 'S':
            color = const Color(0xFF94A3AD);
            break;
          case 'G':
            color = const Color(0xFF9C8A68);
            break;
          case 'B':
            color = const Color(0xFF5C4228);
            break;
        }
        if (color != null) {
          canvas.drawRect(
            Rect.fromLTWH(c * pw, r * ph, pw * 1.04, ph * 1.04),
            Paint()..color = color,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PixelSpritePainter oldDelegate) =>
      oldDelegate.type != type ||
      oldDelegate.useCrossedSwords != useCrossedSwords;
}

// ============================================================================
// EXTERNAL 1080x2344 SUPER-RESOLVED ZERO-DISTORTION TEXTURE SLICES
// Loaded from assets/images/*.webp instead of inline base64.
// ============================================================================

class _WonderTextures {
  static bool _initialized = false;

  static late final Uint8List p1Base;
  static late final Uint8List p1Cursor;
  static late final Uint8List p1SubscreenClean;
  static late final Uint8List p2UnderlayBase;
  static late final Uint8List p2KeyboardBay;
  static late final Uint8List p2SlidingCarriage;
  static late final Uint8List p2CartBlue;
  static late final Uint8List p2CartWhite;
  static late final Uint8List p2RpgBadge;

  static Future<Uint8List> _load(String path) async {
    final data = await rootBundle.load(path);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    final r = await Future.wait(<Future<Uint8List>>[
      _load('assets/images/p1_base.webp'),
      _load('assets/images/p1_cursor.webp'),
      _load('assets/images/p1_subscreen_clean.webp'),
      _load('assets/images/p2_underlay.webp'),
      _load('assets/images/p2_keyboard.webp'),
      _load('assets/images/p2_carriage.webp'),
      _load('assets/images/p2_cart_blue.webp'),
      _load('assets/images/p2_cart_white.webp'),
      _load('assets/images/p2_rpg_badge.webp'),
    ]);
    p1Base = r[0];
    p1Cursor = r[1];
    p1SubscreenClean = r[2];
    p2UnderlayBase = r[3];
    p2KeyboardBay = r[4];
    p2SlidingCarriage = r[5];
    p2CartBlue = r[6];
    p2CartWhite = r[7];
    p2RpgBadge = r[8];
    _initialized = true;
  }
}

/// 预加载掌机贴图资源，供 main() 在 runApp 前 await。
Future<void> initWonderTextures() => _WonderTextures.ensureInitialized();
