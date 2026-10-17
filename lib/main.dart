import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.bg,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const AzkarMuslimApp());
}

/// ───────────────────────── الألوان ─────────────────────────
class AppColors {
  static const bg = Color(0xFF08120F);
  static const panel = Color(0xFF10211C);
  static const panel2 = Color(0xFF173028);
  static const green = Color(0xFF2FB58A);
  static const deepGreen = Color(0xFF0E2B23);
  static const gold = Color(0xFFE7BD70);
  static const cream = Color(0xFFF6EFD9);
  static const white = Color(0xFFF4F6F2);
  static const muted = Color(0xFF9DB3AB);
}

class AzkarMuslimApp extends StatelessWidget {
  const AzkarMuslimApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'أذكار وتحصين مسلم',
        debugShowCheckedModeBanner: false,
        builder: (context, child) =>
            Directionality(textDirection: TextDirection.rtl, child: child!),
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppColors.bg,
          colorScheme: const ColorScheme.dark(
              primary: AppColors.green,
              secondary: AppColors.gold,
              surface: AppColors.panel),
          fontFamily: 'QuranFont',
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.bg,
            foregroundColor: AppColors.white,
            centerTitle: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            titleTextStyle: TextStyle(
                fontFamily: 'QuranFont',
                color: AppColors.gold,
                fontSize: 21,
                fontWeight: FontWeight.bold),
          ),
          snackBarTheme: SnackBarThemeData(
            backgroundColor: AppColors.panel2,
            contentTextStyle: const TextStyle(
                fontFamily: 'QuranFont', color: AppColors.white),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        home: const SplashPage(),
      );
}

/// ───────────────────────── رسومات مساعدة ─────────────────────────
Path starPath(Offset c, double r, double innerFactor, {int points = 8}) {
  final path = Path();
  final n = points * 2;
  for (int k = 0; k < n; k++) {
    final a = k * math.pi / points - math.pi / 2;
    final rad = k.isEven ? r : r * innerFactor;
    final pt = c + Offset(math.cos(a) * rad, math.sin(a) * rad);
    if (k == 0) {
      path.moveTo(pt.dx, pt.dy);
    } else {
      path.lineTo(pt.dx, pt.dy);
    }
  }
  path.close();
  return path;
}

class PatternPainter extends CustomPainter {
  final Color color;
  final double cell;
  const PatternPainter(this.color, {this.cell = 54});
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = .8;
    for (double y = 0; y < size.height + cell; y += cell) {
      for (double x = 0; x < size.width + cell; x += cell) {
        canvas.drawPath(starPath(Offset(x, y), cell * .36, .62), p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant PatternPainter old) =>
      old.color != color || old.cell != cell;
}

class RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  const RingPainter(this.progress, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 8;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final track = Paint()
      ..color = Colors.white.withOpacity(.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9;
    canvas.drawCircle(center, radius, track);
    if (progress > 0) {
      final arc = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 9;
      canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, arc);
    }
  }

  @override
  bool shouldRepaint(covariant RingPainter old) =>
      old.progress != progress || old.color != color;
}

class StarBadgePainter extends CustomPainter {
  final Color fill;
  final Color stroke;
  const StarBadgePainter(this.fill, this.stroke);
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final path = starPath(c, size.width / 2 - 1, .78);
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
        path,
        Paint()
          ..color = stroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);
  }

  @override
  bool shouldRepaint(covariant StarBadgePainter old) =>
      old.fill != fill || old.stroke != stroke;
}

String arDigits(int n) {
  const d = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  return n.toString().split('').map((c) => d[int.parse(c)]).join();
}

Color parseColor(dynamic v, Color fallback) {
  var s = (v ?? '').toString().replaceAll('#', '').trim();
  if (s.length == 6) s = 'FF$s';
  final n = int.tryParse(s, radix: 16);
  return n == null ? fallback : Color(n & 0xFFFFFFFF);
}

IconData sectionIcon(String? name) {
  switch (name) {
    case 'sun':
      return Icons.wb_sunny_rounded;
    case 'moon':
      return Icons.nightlight_round;
    case 'shield':
      return Icons.shield_rounded;
    case 'dome':
      return Icons.mosque_rounded;
    case 'star':
      return Icons.star_rounded;
    case 'heart':
      return Icons.favorite_rounded;
    default:
      return Icons.auto_awesome;
  }
}

class PatternCard extends StatelessWidget {
  final Widget child;
  final List<Color> colors;
  final EdgeInsets padding;
  final double radius;
  final Color? borderColor;
  const PatternCard({
    super.key,
    required this.child,
    this.colors = const [Color(0xFF1E5C48), AppColors.deepGreen],
    this.padding = const EdgeInsets.all(20),
    this.radius = 26,
    this.borderColor,
  });
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topRight,
                end: Alignment.bottomLeft),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
                color: borderColor ?? AppColors.gold.withOpacity(.28)),
          ),
          child: Stack(children: [
            Positioned.fill(
                child: CustomPaint(
                    painter: PatternPainter(AppColors.gold.withOpacity(.07)))),
            Padding(padding: padding, child: child),
          ]),
        ),
      );
}

/// ───────────────────────── السبلاش ─────────────────────────
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _logo;
  late final Animation<double> _text;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1900))
      ..forward();
    _logo = CurvedAnimation(
        parent: _c, curve: const Interval(0, .6, curve: Curves.easeOutBack));
    _text = CurvedAnimation(
        parent: _c, curve: const Interval(.45, 1, curve: Curves.easeOut));
    _timer = Timer(const Duration(milliseconds: 2500), _go);
  }

  void _go() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (_, __, ___) => const UpdateGate(child: HomePage()),
      transitionsBuilder: (_, a, __, child) =>
          FadeTransition(opacity: a, child: child),
    ));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        Positioned.fill(
            child: CustomPaint(
                painter: PatternPainter(AppColors.gold.withOpacity(.06),
                    cell: 62))),
        Center(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.scale(
                  scale: .6 + .4 * _logo.value.clamp(0.0, 1.2).toDouble(),
                  child: Opacity(
                    opacity: _logo.value.clamp(0.0, 1.0).toDouble(),
                    child: Container(
                      width: 148,
                      height: 148,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                            colors: [Color(0xFF1E5C48), AppColors.deepGreen]),
                        border: Border.all(
                            color: AppColors.gold.withOpacity(.6), width: 2),
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.gold.withOpacity(.25),
                              blurRadius: 40,
                              spreadRadius: 4),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/app_icon.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.mosque_rounded,
                              color: AppColors.gold,
                              size: 70),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Opacity(
                  opacity: _text.value,
                  child: Transform.translate(
                    offset: Offset(0, 14 * (1 - _text.value)),
                    child: Column(children: const [
                      Text('أذكار وتحصين مسلم',
                          style: TextStyle(
                              color: AppColors.gold,
                              fontSize: 30,
                              fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      Text('أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ',
                          style: TextStyle(
                              color: AppColors.muted, fontSize: 17, height: 1.8)),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

/// ───────────────────────── بوابة التحديث (Firebase) ─────────────────────────
/// Mandatory app-update gate backed by Firebase Realtime Database REST API.
/// Configure /app_update in the database (see update_config.example.json).
class UpdateGate extends StatefulWidget {
  final Widget child;
  const UpdateGate({super.key, required this.child});
  @override
  State<UpdateGate> createState() => _UpdateGateState();
}

class _UpdateGateState extends State<UpdateGate> {
  static const String _updateConfigUrl =
      'https://walied-f4f1b-default-rtdb.firebaseio.com/app_update.json';
  bool _checking = true;
  bool _mustUpdate = false;
  bool _checkFailed = false;
  bool _busy = false;
  String _currentVersion = '1.0.0';
  String _latestVersion = '';
  String _releaseNotes = 'يتوفر إصدار جديد من التطبيق. حدّث التطبيق للمتابعة.';
  String _apkUrl = '';
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
  }

  int _compareVersions(String a, String b) {
    List<int> parts(String value) => value
        .split('+')
        .first
        .split('-')
        .first
        .split('.')
        .map((part) => int.tryParse(part) ?? 0)
        .toList();
    final aa = parts(a);
    final bb = parts(b);
    final length = aa.length > bb.length ? aa.length : bb.length;
    for (var i = 0; i < length; i++) {
      final av = i < aa.length ? aa[i] : 0;
      final bv = i < bb.length ? bb[i] : 0;
      if (av < bv) return -1;
      if (av > bv) return 1;
    }
    return 0;
  }

  Future<void> _checkForUpdate() async {
    if (mounted) {
      setState(() {
        _checking = true;
        _checkFailed = false;
        _errorMessage = '';
      });
    }
    try {
      final package = await PackageInfo.fromPlatform();
      _currentVersion = package.version;
      final currentBuildCode = int.tryParse(package.buildNumber) ?? 0;
      final response = await http
          .get(Uri.parse(_updateConfigUrl))
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) {
        throw Exception('تعذر الوصول إلى إعدادات التحديث (${response.statusCode})');
      }
      final body = response.body.trim();
      if (body.isEmpty || body == 'null') {
        throw Exception('لم يتم إعداد بيانات التحديث في Firebase بعد.');
      }
      final config = jsonDecode(body) as Map<String, dynamic>;
      _latestVersion = (config['latestVersion'] ??
              config['latest_version_name'] ??
              config['latest_version_code'] ??
              '')
          .toString();
      final minVersion =
          (config['minVersion'] ?? config['min_version_name'] ?? '0.0.0')
              .toString();
      final latestCode =
          int.tryParse((config['latest_version_code'] ?? '').toString());
      final minCode =
          int.tryParse((config['min_version_code'] ?? '').toString());
      final updateUrl =
          (config['update_url'] ?? config['apkUrl'] ?? '').toString().trim();
      final forceUpdate =
          config['update_force'] == true || config['forceUpdate'] == true;
      _apkUrl = updateUrl;
      _releaseNotes = (config['releaseNotes'] ??
              config['update_message'] ??
              'يتوفر إصدار جديد من التطبيق. حدّث التطبيق للمتابعة.')
          .toString();
      final minVersionCode = minCode ?? 0;
      final latestVersionCode = latestCode ?? 0;
      final belowMinimum =
          (minVersionCode > 0 && currentBuildCode < minVersionCode) ||
              _compareVersions(_currentVersion, minVersion) < 0;
      final newerAvailable =
          (latestVersionCode > 0 && currentBuildCode < latestVersionCode) ||
              (_latestVersion.isNotEmpty &&
                  _compareVersions(_currentVersion, _latestVersion) < 0);
      if (mounted) {
        setState(() {
          _mustUpdate = belowMinimum || (forceUpdate && newerAvailable);
          _checking = false;
          _checkFailed = false;
        });
      }
    } catch (e) {
      // Fail closed: mandatory-update mode cannot be verified without the server.
      if (mounted) {
        setState(() {
          _checking = false;
          _checkFailed = true;
          _errorMessage = 'تعذر التحقق من التحديث. تأكد من الإنترنت ثم أعد المحاولة.';
        });
      }
    }
  }

  Future<void> _openDownload() async {
    if (_apkUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لم يتم إضافة رابط تنزيل APK في Firebase بعد.')),
      );
      return;
    }
    final uri = Uri.tryParse(_apkUrl);
    if (uri == null || uri.scheme != 'https' && uri.scheme != 'http') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رابط التحديث غير صحيح.')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح رابط التحديث.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _shell(Widget child) => Scaffold(
        body: Stack(children: [
          Positioned.fill(
              child: CustomPaint(
                  painter: PatternPainter(AppColors.gold.withOpacity(.05),
                      cell: 62))),
          SafeArea(child: Center(child: child)),
        ]),
      );

  Widget _badge(IconData icon) => Container(
        width: 104,
        height: 104,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
              colors: [Color(0xFF1E5C48), AppColors.deepGreen]),
          border: Border.all(color: AppColors.gold.withOpacity(.5), width: 1.5),
        ),
        child: Icon(icon, color: AppColors.gold, size: 50),
      );

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return _shell(Column(mainAxisSize: MainAxisSize.min, children: const [
        SizedBox(
            width: 38,
            height: 38,
            child: CircularProgressIndicator(
                strokeWidth: 3, color: AppColors.gold)),
        SizedBox(height: 20),
        Text('جارٍ التحقق من تحديث التطبيق...',
            style: TextStyle(color: AppColors.muted, fontSize: 16)),
      ]));
    }
    if (_checkFailed) {
      return _shell(Padding(
        padding: const EdgeInsets.all(26),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _badge(Icons.wifi_off_rounded),
          const SizedBox(height: 22),
          const Text('تعذر التحقق من التحديث',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 23,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(_errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, height: 1.8)),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _checkForUpdate,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.green,
                padding:
                    const EdgeInsets.symmetric(horizontal: 26, vertical: 14)),
          ),
        ]),
      ));
    }
    if (_mustUpdate) {
      return PopScope(
        canPop: false,
        child: _shell(SingleChildScrollView(
          padding: const EdgeInsets.all(26),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _badge(Icons.system_update_alt_rounded),
            const SizedBox(height: 24),
            const Text('تحديث إجباري',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 27,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('يجب تحديث التطبيق إلى أحدث إصدار قبل المتابعة.',
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: AppColors.muted, fontSize: 16, height: 1.8)),
            if (_latestVersion.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(.1),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(
                    'الإصدار الحالي: $_currentVersion  •  الجديد: $_latestVersion',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.gold)),
              ),
            ],
            if (_releaseNotes.isNotEmpty) ...[
              const SizedBox(height: 16),
              PatternCard(
                radius: 18,
                padding: const EdgeInsets.all(16),
                child: Text(_releaseNotes,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.cream, height: 1.8, fontSize: 16)),
              ),
            ],
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _busy ? null : _openDownload,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.download_rounded),
                label: const Text('تحديث الآن'),
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.bg,
                    textStyle: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                    padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
                onPressed: _checkForUpdate,
                child: const Text('تحقّق مرة أخرى')),
          ]),
        )),
      );
    }
    return widget.child;
  }
}

/// ───────────────────────── البيانات والتخزين ─────────────────────────
class DataStore {
  static List<Map<String, dynamic>> sections = [];
  static List<Map<String, dynamic>> ayahs = [];
  static final Map<int, List<Map<String, dynamic>>> bySurah = {};
  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    final a = jsonDecode(await rootBundle.loadString('assets/azkar.json'))
        as Map<String, dynamic>;
    sections = List<Map<String, dynamic>>.from(
        (a['sections'] as List).map((e) => Map<String, dynamic>.from(e)));
    final q = jsonDecode(await rootBundle.loadString('assets/quran.json'))
        as Map<String, dynamic>;
    ayahs = List<Map<String, dynamic>>.from(
        (q['ayahs'] as List).map((e) => Map<String, dynamic>.from(e)));
    bySurah.clear();
    for (final ay in ayahs) {
      final n = (ay['surah'] as num).toInt();
      bySurah.putIfAbsent(n, () => []).add(ay);
    }
    _loaded = true;
  }

  static Map<String, dynamic>? sectionById(String id) {
    for (final s in sections) {
      if (s['id'] == id) return s;
    }
    return null;
  }
}

class ProgressStore {
  static String today() {
    final n = DateTime.now();
    return '${n.year}${n.month.toString().padLeft(2, '0')}${n.day.toString().padLeft(2, '0')}';
  }

  static String key(String id) => 'c_${id}_${today()}';

  static Future<List<int>> counts(String id, int length) async {
    final p = await SharedPreferences.getInstance();
    final saved = p.getStringList(key(id)) ?? [];
    return List<int>.generate(
        length, (i) => i < saved.length ? (int.tryParse(saved[i]) ?? 0) : 0);
  }

  static Future<void> save(String id, List<int> counts) async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(key(id), counts.map((e) => e.toString()).toList());
  }

  static Future<double> fraction(Map<String, dynamic> section) async {
    final items = (section['items'] as List? ?? []);
    if (items.isEmpty) return 0;
    final c = await counts(section['id'].toString(), items.length);
    var total = 0, done = 0;
    for (var i = 0; i < items.length; i++) {
      final t = ((items[i] as Map)['count'] as num?)?.toInt() ?? 1;
      total += t;
      done += math.min(c[i], t);
    }
    return total == 0 ? 0 : done / total;
  }
}

/// ───────────────────────── الصفحة الرئيسية ─────────────────────────
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int tab = 0;
  late final Future<void> _load = DataStore.load();

  @override
  Widget build(BuildContext context) {
    const titles = ['أذكار وتحصين مسلم', 'الأذكار', 'القرآن الكريم'];
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[tab]),
        actions: [
          IconButton(
            tooltip: 'المفضلة',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const FavoritesPage())),
            icon: const Icon(Icons.favorite_border_rounded),
          ),
        ],
      ),
      body: FutureBuilder<void>(
        future: _load,
        builder: (context, s) {
          if (s.connectionState != ConnectionState.done) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.gold));
          }
          if (s.hasError) {
            return const Center(
                child: Text('تعذر تحميل البيانات',
                    style: TextStyle(color: AppColors.muted)));
          }
          return IndexedStack(index: tab, children: [
            HomeTab(onOpenTab: (i) => setState(() => tab = i)),
            const AzkarSectionsPage(),
            const QuranPage(),
          ]);
        },
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.panel,
          border: Border(
              top: BorderSide(color: AppColors.gold.withOpacity(.18))),
        ),
        child: NavigationBar(
          height: 68,
          backgroundColor: Colors.transparent,
          elevation: 0,
          indicatorColor: AppColors.gold.withOpacity(.18),
          selectedIndex: tab,
          onDestinationSelected: (v) => setState(() => tab = v),
          labelTextStyle: MaterialStateProperty.resolveWith((states) =>
              TextStyle(
                  fontFamily: 'QuranFont',
                  fontSize: 13,
                  color: states.contains(MaterialState.selected)
                      ? AppColors.gold
                      : AppColors.muted)),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.home_outlined, color: AppColors.muted),
                selectedIcon: Icon(Icons.home_rounded, color: AppColors.gold),
                label: 'الرئيسية'),
            NavigationDestination(
                icon: Icon(Icons.spa_outlined, color: AppColors.muted),
                selectedIcon: Icon(Icons.spa_rounded, color: AppColors.gold),
                label: 'الأذكار'),
            NavigationDestination(
                icon: Icon(Icons.menu_book_outlined, color: AppColors.muted),
                selectedIcon:
                    Icon(Icons.menu_book_rounded, color: AppColors.gold),
                label: 'القرآن'),
          ],
        ),
      ),
    );
  }
}

class HomeTab extends StatefulWidget {
  final void Function(int) onOpenTab;
  const HomeTab({super.key, required this.onOpenTab});
  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  String get greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'صباح الخير';
    if (h < 18) return 'مساء الخير';
    return 'مساء النور';
  }

  String get currentId {
    final h = DateTime.now().hour;
    if (h >= 4 && h < 12) return 'morning';
    if (h >= 12 && h < 21) return 'evening';
    return 'sleep';
  }

  Future<void> _open(Map<String, dynamic> s) async {
    await Navigator.push(context,
        MaterialPageRoute(builder: (_) => AzkarReaderPage(section: s)));
    if (mounted) setState(() {});
  }

  Future<Map<String, dynamic>?> _lastRead() async {
    final p = await SharedPreferences.getInstance();
    final n = p.getInt('last_surah');
    if (n == null) return null;
    return {'n': n, 'name': p.getString('last_surah_name') ?? ''};
  }

  @override
  Widget build(BuildContext context) {
    final current = DataStore.sectionById(currentId) ??
        (DataStore.sections.isNotEmpty ? DataStore.sections.first : null);
    final quick = DataStore.sections.take(4).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
      children: [
        PatternCard(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(.14),
                    shape: BoxShape.circle),
                child: const Icon(Icons.nights_stay_rounded,
                    color: AppColors.gold, size: 26),
              ),
              const SizedBox(width: 12),
              Text(greeting,
                  style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 19,
                      fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 18),
            const Text('طمئن قلبك بذكر الله',
                style: TextStyle(
                    color: AppColors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: Colors.black.withOpacity(.22),
                  borderRadius: BorderRadius.circular(16)),
              child: Column(children: const [
                Text('﴿ أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ ﴾',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.cream, fontSize: 21, height: 1.9)),
                SizedBox(height: 2),
                Text('سورة الرعد · ٢٨',
                    style: TextStyle(color: AppColors.muted, fontSize: 14)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 22),
        if (current != null) ...[
          _title('وردك الآن'),
          const SizedBox(height: 10),
          _featured(current),
          const SizedBox(height: 22),
        ],
        _title('أقسام الأذكار', action: 'عرض الكل', onAction: () => widget.onOpenTab(1)),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: quick
              .map((s) => SectionTile(section: s, onTap: () => _open(s)))
              .toList(),
        ),
        const SizedBox(height: 22),
        _title('القرآن الكريم'),
        const SizedBox(height: 10),
        FutureBuilder<Map<String, dynamic>?>(
          future: _lastRead(),
          builder: (context, snap) {
            final last = snap.data;
            return _quranCard(last);
          },
        ),
        const SizedBox(height: 26),
        const Center(
            child: Text('اللهم اجعل القرآن ربيع قلوبنا',
                style: TextStyle(color: AppColors.muted, fontSize: 16))),
      ],
    );
  }

  Widget _title(String t, {String? action, VoidCallback? onAction}) => Row(
        children: [
          Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(4))),
          const SizedBox(width: 10),
          Expanded(
              child: Text(t,
                  style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold))),
          if (action != null)
            TextButton(
                onPressed: onAction,
                child: Text(action,
                    style: const TextStyle(color: AppColors.gold))),
        ],
      );

  Widget _featured(Map<String, dynamic> s) {
    final color = parseColor(s['color'], AppColors.green);
    final count = (s['items'] as List? ?? []).length;
    return GestureDetector(
      onTap: () => _open(s),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.panel,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withOpacity(.45)),
        ),
        child: Row(children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
                color: color.withOpacity(.18),
                borderRadius: BorderRadius.circular(18)),
            child: Icon(sectionIcon(s['icon']?.toString()),
                color: color, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text((s['title'] ?? '').toString(),
                  style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('${arDigits(count)} ذكر · ${(s['description'] ?? '')}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 14)),
              const SizedBox(height: 10),
              FutureBuilder<double>(
                future: ProgressStore.fraction(s),
                builder: (context, snap) {
                  final f = snap.data ?? 0;
                  return Row(children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: f,
                          minHeight: 7,
                          backgroundColor: Colors.white.withOpacity(.08),
                          valueColor: AlwaysStoppedAnimation(color),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('${arDigits((f * 100).round())}٪',
                        style: TextStyle(color: color, fontSize: 13)),
                  ]);
                },
              ),
            ]),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_left_rounded, color: AppColors.gold, size: 30),
        ]),
      ),
    );
  }

  Widget _quranCard(Map<String, dynamic>? last) {
    final lastName = last == null ? '' : last['name'].toString();
    final hasLast = lastName.isNotEmpty;
    return GestureDetector(
      onTap: () {
        if (last != null && hasLast) {
          final lastN = last['n'] as int;
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => SurahPage(number: lastN, name: lastName)));
        } else {
          widget.onOpenTab(2);
        }
      },
      child: PatternCard(
        radius: 22,
        colors: const [Color(0xFF1B3A52), Color(0xFF0E1F2D)],
        child: Row(children: [
          const Icon(Icons.menu_book_rounded, color: AppColors.gold, size: 38),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(hasLast ? 'تابع القراءة' : 'اقرأ القرآن الكريم',
                  style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(hasLast ? 'سورة $lastName' : 'ابدأ من سورة الفاتحة',
                  style: const TextStyle(color: AppColors.muted, fontSize: 15)),
            ]),
          ),
          const Icon(Icons.chevron_left_rounded, color: AppColors.gold, size: 30),
        ]),
      ),
    );
  }
}

/// بطاقة قسم (للشبكة)
class SectionTile extends StatelessWidget {
  final Map<String, dynamic> section;
  final VoidCallback onTap;
  const SectionTile({super.key, required this.section, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = parseColor(section['color'], AppColors.green);
    final count = (section['items'] as List? ?? []).length;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [color.withOpacity(.30), AppColors.panel],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withOpacity(.38)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                  color: color.withOpacity(.22),
                  borderRadius: BorderRadius.circular(13)),
              child: Icon(sectionIcon(section['icon']?.toString()),
                  color: color, size: 24),
            ),
            const Spacer(),
            FutureBuilder<double>(
              future: ProgressStore.fraction(section),
              builder: (context, snap) {
                final f = snap.data ?? 0;
                if (f >= 1) {
                  return Icon(Icons.check_circle_rounded, color: color, size: 22);
                }
                return Text(f > 0 ? '${arDigits((f * 100).round())}٪' : '',
                    style: TextStyle(color: color, fontSize: 13));
              },
            ),
          ]),
          const Spacer(),
          Text((section['title'] ?? '').toString(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 3),
          Text('${arDigits(count)} ذكر',
              style: const TextStyle(color: AppColors.muted, fontSize: 13)),
        ]),
      ),
    );
  }
}

/// ───────────────────────── أقسام الأذكار ─────────────────────────
class AzkarSectionsPage extends StatefulWidget {
  const AzkarSectionsPage({super.key});
  @override
  State<AzkarSectionsPage> createState() => _AzkarSectionsPageState();
}

class _AzkarSectionsPageState extends State<AzkarSectionsPage> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final sections = DataStore.sections
        .where((s) =>
            (s['title'] ?? '').toString().contains(query) ||
            (s['description'] ?? '').toString().contains(query))
        .toList();
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: _SearchField(
            hint: 'ابحث عن قسم الأذكار',
            onChanged: (v) => setState(() => query = v)),
      ),
      Expanded(
        child: sections.isEmpty
            ? const Center(
                child: Text('لا توجد نتائج',
                    style: TextStyle(color: AppColors.muted)))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: sections.length,
                itemBuilder: (context, i) {
                  final s = sections[i];
                  return _sectionRow(s);
                }),
      ),
    ]);
  }

  Widget _sectionRow(Map<String, dynamic> s) {
    final color = parseColor(s['color'], AppColors.green);
    final count = (s['items'] as List? ?? []).length;
    return GestureDetector(
      onTap: () async {
        await Navigator.push(context,
            MaterialPageRoute(builder: (_) => AzkarReaderPage(section: s)));
        if (mounted) setState(() {});
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [color.withOpacity(.22), AppColors.panel],
              begin: Alignment.centerRight,
              end: Alignment.centerLeft),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(.32)),
        ),
        child: Row(children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
                color: color.withOpacity(.2),
                borderRadius: BorderRadius.circular(16)),
            child: Icon(sectionIcon(s['icon']?.toString()),
                color: color, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text((s['title'] ?? 'الأذكار').toString(),
                  style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 3),
              Text((s['description'] ?? '').toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 14)),
              const SizedBox(height: 8),
              FutureBuilder<double>(
                future: ProgressStore.fraction(s),
                builder: (context, snap) {
                  final f = snap.data ?? 0;
                  return Row(children: [
                    Text('${arDigits(count)} ذكر',
                        style: TextStyle(color: color, fontSize: 13)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: f,
                          minHeight: 5,
                          backgroundColor: Colors.white.withOpacity(.08),
                          valueColor: AlwaysStoppedAnimation(color),
                        ),
                      ),
                    ),
                  ]);
                },
              ),
            ]),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_left_rounded, color: AppColors.gold),
        ]),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  const _SearchField({required this.hint, required this.onChanged});
  @override
  Widget build(BuildContext context) => TextField(
        onChanged: onChanged,
        style: const TextStyle(color: AppColors.white),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.gold),
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.muted),
          filled: true,
          fillColor: AppColors.panel,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: Colors.white.withOpacity(.06))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: AppColors.gold.withOpacity(.6))),
        ),
      );
}

/// ───────────────────────── قارئ الأذكار + العدّاد ─────────────────────────
class AzkarReaderPage extends StatefulWidget {
  final Map<String, dynamic> section;
  const AzkarReaderPage({super.key, required this.section});
  @override
  State<AzkarReaderPage> createState() => _AzkarReaderPageState();
}

class _AzkarReaderPageState extends State<AzkarReaderPage> {
  late List items;
  List<int> counts = [];
  Set<String> favorites = {};
  final PageController _pc = PageController();
  int page = 0;
  double fontSize = 24;

  String get _id => widget.section['id'].toString();
  Color get _color => parseColor(widget.section['color'], AppColors.green);

  @override
  void initState() {
    super.initState();
    items = List.from(widget.section['items'] as List? ?? []);
    counts = List<int>.filled(items.length, 0);
    _init();
  }

  Future<void> _init() async {
    final c = await ProgressStore.counts(_id, items.length);
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      counts = c;
      favorites = (p.getStringList('favorites') ?? []).toSet();
      fontSize = p.getDouble('azkar_font') ?? 24;
    });
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  String _key(Map e) => '${e['title'] ?? ''}|${e['text'] ?? ''}';
  int _target(int i) => ((items[i] as Map)['count'] as num?)?.toInt() ?? 1;

  Future<void> _toggleFav(Map e) async {
    final p = await SharedPreferences.getInstance();
    final k = _key(e);
    setState(() {
      if (favorites.contains(k)) {
        favorites.remove(k);
      } else {
        favorites.add(k);
      }
    });
    await p.setStringList('favorites', favorites.toList());
  }

  Future<void> _setFont(double v) async {
    setState(() => fontSize = v.clamp(18.0, 40.0));
    final p = await SharedPreferences.getInstance();
    await p.setDouble('azkar_font', fontSize);
  }

  void _tap(int i) {
    final t = _target(i);
    if (counts[i] >= t) return;
    setState(() => counts[i]++);
    ProgressStore.save(_id, counts);
    if (counts[i] >= t) {
      HapticFeedback.mediumImpact();
      Future.delayed(const Duration(milliseconds: 450), () {
        if (mounted && page == i && i < items.length - 1) {
          _pc.nextPage(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic);
        }
      });
    } else {
      HapticFeedback.selectionClick();
    }
  }

  Future<void> _reset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppColors.panel2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Text('إعادة العدّاد',
              style: TextStyle(color: AppColors.gold)),
          content: const Text('هل تريد تصفير عدّاد هذا القسم بالكامل؟',
              style: TextStyle(color: AppColors.white)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('إلغاء')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.bg),
                child: const Text('تصفير')),
          ],
        ),
      ),
    );
    if (ok == true) {
      setState(() => counts = List<int>.filled(items.length, 0));
      await ProgressStore.save(_id, counts);
      if (_pc.hasClients) _pc.jumpToPage(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    var total = 0, done = 0;
    for (var i = 0; i < items.length; i++) {
      final t = _target(i);
      total += t;
      done += math.min(counts[i], t);
    }
    final frac = total == 0 ? 0.0 : done / total;
    final verse = widget.section['verse']?.toString();
    return Scaffold(
      appBar: AppBar(
        title: Text((widget.section['title'] ?? 'الأذكار').toString()),
        actions: [
          IconButton(
              tooltip: 'تصغير الخط',
              onPressed: () => _setFont(fontSize - 2),
              icon: const Icon(Icons.text_decrease_rounded)),
          IconButton(
              tooltip: 'تكبير الخط',
              onPressed: () => _setFont(fontSize + 2),
              icon: const Icon(Icons.text_increase_rounded)),
          IconButton(
              tooltip: 'إعادة العدّاد',
              onPressed: _reset,
              icon: const Icon(Icons.restart_alt_rounded)),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 2, 18, 8),
          child: Row(children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: frac,
                  minHeight: 8,
                  backgroundColor: Colors.white.withOpacity(.08),
                  valueColor: AlwaysStoppedAnimation(_color),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text('${arDigits((frac * 100).round())}٪',
                style: TextStyle(color: _color, fontWeight: FontWeight.bold)),
          ]),
        ),
        if (verse != null && verse.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
            child: Text(verse,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppColors.gold, fontSize: 16, height: 1.7)),
          ),
        Expanded(
          child: PageView.builder(
            controller: _pc,
            itemCount: items.length,
            onPageChanged: (v) => setState(() => page = v),
            itemBuilder: (context, i) => _card(i),
          ),
        ),
        _pager(),
      ]),
    );
  }

  Widget _pager() => Padding(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 14),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          IconButton.filledTonal(
            onPressed: page > 0
                ? () => _pc.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut)
                : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
          Text('ذكر ${arDigits(page + 1)} من ${arDigits(items.length)}',
              style: const TextStyle(color: AppColors.muted, fontSize: 15)),
          IconButton.filledTonal(
            onPressed: page < items.length - 1
                ? () => _pc.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut)
                : null,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
        ]),
      );

  Widget _card(int i) {
    final e = Map<String, dynamic>.from(items[i] as Map);
    final target = _target(i);
    final c = counts.length > i ? counts[i] : 0;
    final done = c >= target;
    final isFav = favorites.contains(_key(e));
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.panel,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
              color: done ? _color.withOpacity(.7) : AppColors.gold.withOpacity(.22),
              width: done ? 1.6 : 1),
        ),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 8, 0),
            child: Row(children: [
              Expanded(
                child: Text((e['title'] ?? 'ذكر').toString(),
                    style: const TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.bold,
                        fontSize: 18)),
              ),
              IconButton(
                onPressed: () => _toggleFav(e),
                icon: Icon(
                    isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: isFav ? Colors.pinkAccent : AppColors.muted),
              ),
              IconButton(
                onPressed: () async {
                  await Clipboard.setData(
                      ClipboardData(text: (e['text'] ?? '').toString()));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم نسخ الذكر')));
                  }
                },
                icon: const Icon(Icons.copy_rounded, color: AppColors.muted),
              ),
            ]),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Column(children: [
                Text((e['text'] ?? '').toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: fontSize,
                        height: 2.05,
                        color: AppColors.cream)),
                if (e['source'] != null &&
                    e['source'].toString().isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 14),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(.08),
                        borderRadius: BorderRadius.circular(14)),
                    child: Text(e['source'].toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 13.5, height: 1.7)),
                  ),
              ]),
            ),
          ),
          _counter(i, c, target, done),
        ]),
      ),
    );
  }

  Widget _counter(int i, int c, int target, bool done) {
    final color = done ? AppColors.gold : _color;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14, top: 4),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _tap(i),
        child: SizedBox(
          width: 132,
          height: 132,
          child: Stack(alignment: Alignment.center, children: [
            TweenAnimationBuilder<double>(
              tween: Tween<double>(end: target == 0 ? 0 : c / target),
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOut,
              builder: (context, v, _) => CustomPaint(
                  size: const Size(132, 132), painter: RingPainter(v, color)),
            ),
            Container(
              width: 98,
              height: 98,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(.14),
                border: Border.all(color: color.withOpacity(.4)),
              ),
              child: done
                  ? Icon(Icons.check_rounded, color: color, size: 52)
                  : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(arDigits(c),
                          style: TextStyle(
                              color: color,
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              height: 1.1)),
                      Text('من ${arDigits(target)}',
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 13)),
                    ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// ───────────────────────── القرآن الكريم ─────────────────────────
const List<String> kSurahNames = [
  'الفاتحة','البقرة','آل عمران','النساء','المائدة','الأنعام','الأعراف','الأنفال','التوبة','يونس','هود','يوسف','الرعد','إبراهيم','الحجر','النحل','الإسراء','الكهف','مريم','طه','الأنبياء','الحج','المؤمنون','النور','الفرقان','الشعراء','النمل','القصص','العنكبوت','الروم','لقمان','السجدة','الأحزاب','سبأ','فاطر','يس','الصافات','ص','الزمر','غافر','فصلت','الشورى','الزخرف','الدخان','الجاثية','الأحقاف','محمد','الفتح','الحجرات','ق','الذاريات','الطور','النجم','القمر','الرحمن','الواقعة','الحديد','المجادلة','الحشر','الممتحنة','الصف','الجمعة','المنافقون','التغابن','الطلاق','التحريم','الملك','القلم','الحاقة','المعارج','نوح','الجن','المزمل','المدثر','القيامة','الإنسان','المرسلات','النبأ','النازعات','عبس','التكوير','الانفطار','المطففين','الانشقاق','البروج','الطارق','الأعلى','الغاشية','الفجر','البلد','الشمس','الليل','الضحى','الشرح','التين','العلق','القدر','البينة','الزلزلة','العاديات','القارعة','التكاثر','العصر','الهمزة','الفيل','قريش','الماعون','الكوثر','الكافرون','النصر','المسد','الإخلاص','الفلق','الناس'
];

class QuranPage extends StatefulWidget {
  const QuranPage({super.key});
  @override
  State<QuranPage> createState() => _QuranPageState();
}

class _QuranPageState extends State<QuranPage> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final q = query.trim();
    final indexes = <int>[
      for (var i = 0; i < kSurahNames.length; i++)
        if (q.isEmpty ||
            kSurahNames[i].contains(q) ||
            arDigits(i + 1).contains(q) ||
            (i + 1).toString() == q)
          i
    ];
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: _SearchField(
            hint: 'ابحث عن سورة', onChanged: (v) => setState(() => query = v)),
      ),
      Expanded(
        child: indexes.isEmpty
            ? const Center(
                child: Text('لا توجد نتائج',
                    style: TextStyle(color: AppColors.muted)))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: indexes.length,
                itemBuilder: (context, k) {
                  final i = indexes[k];
                  final n = i + 1;
                  final name = kSurahNames[i];
                  final count = DataStore.bySurah[n]?.length ?? 0;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 9),
                    decoration: BoxDecoration(
                      color: AppColors.panel,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withOpacity(.05)),
                    ),
                    child: ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                      leading: SizedBox(
                        width: 46,
                        height: 46,
                        child: CustomPaint(
                          painter: StarBadgePainter(
                              AppColors.green.withOpacity(.14),
                              AppColors.gold.withOpacity(.55)),
                          child: Center(
                              child: Text(arDigits(n),
                                  style: const TextStyle(
                                      color: AppColors.gold,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold))),
                        ),
                      ),
                      title: Text('سورة $name',
                          style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      subtitle: Text('${arDigits(count)} آية',
                          style: const TextStyle(color: AppColors.muted)),
                      trailing: const Icon(Icons.chevron_left_rounded,
                          color: AppColors.gold),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  SurahPage(number: n, name: name))),
                    ),
                  );
                }),
      ),
    ]);
  }
}

class SurahPage extends StatefulWidget {
  final int number;
  final String name;
  const SurahPage({super.key, required this.number, required this.name});
  @override
  State<SurahPage> createState() => _SurahPageState();
}

class _SurahPageState extends State<SurahPage> {
  double fontSize = 27;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('last_surah', widget.number);
    await p.setString('last_surah_name', widget.name);
    if (mounted) setState(() => fontSize = p.getDouble('quran_font') ?? 27);
  }

  Future<void> _setFont(double v) async {
    setState(() => fontSize = v.clamp(20.0, 46.0));
    final p = await SharedPreferences.getInstance();
    await p.setDouble('quran_font', fontSize);
  }

  Widget _mark(int n) => Container(
        width: fontSize * .95,
        height: fontSize * .95,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.gold.withOpacity(.75), width: 1.2),
          color: AppColors.gold.withOpacity(.08),
        ),
        child: Text(arDigits(n),
            style: TextStyle(
                color: AppColors.gold,
                fontSize: fontSize * .42,
                fontWeight: FontWeight.bold,
                height: 1.0)),
      );

  @override
  Widget build(BuildContext context) {
    final ayahs = DataStore.bySurah[widget.number] ?? [];
    final spans = <InlineSpan>[];
    for (final a in ayahs) {
      spans.add(TextSpan(text: '${a['text']} '));
      spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: _mark((a['ayah'] as num).toInt())));
      spans.add(const TextSpan(text: '  '));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('سورة ${widget.name}'),
        actions: [
          IconButton(
              onPressed: () => _setFont(fontSize - 2),
              icon: const Icon(Icons.text_decrease_rounded)),
          IconButton(
              onPressed: () => _setFont(fontSize + 2),
              icon: const Icon(Icons.text_increase_rounded)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 30),
        children: [
          PatternCard(
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
            child: Column(children: [
              Text('سُورَةُ ${widget.name}',
                  style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 28,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('${arDigits(ayahs.length)} آية',
                  style: const TextStyle(color: AppColors.muted, fontSize: 15)),
              if (widget.number != 1 && widget.number != 9)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Text('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppColors.cream, fontSize: 24, height: 2)),
                ),
            ]),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
            decoration: BoxDecoration(
              color: AppColors.panel,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.gold.withOpacity(.18)),
            ),
            child: Text.rich(
              TextSpan(children: spans),
              textAlign: TextAlign.justify,
              style: TextStyle(
                  fontSize: fontSize, height: 2.2, color: AppColors.cream),
            ),
          ),
        ],
      ),
    );
  }
}

/// ───────────────────────── المفضلة ─────────────────────────
class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});
  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<String> favorites = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) setState(() => favorites = p.getStringList('favorites') ?? []);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('الأذكار المفضلة')),
        body: favorites.isEmpty
            ? Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: const [
                  Icon(Icons.favorite_border_rounded,
                      color: AppColors.gold, size: 58),
                  SizedBox(height: 14),
                  Text('لم تضف أذكارًا للمفضلة بعد',
                      style: TextStyle(color: AppColors.muted, fontSize: 17)),
                ]),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: favorites.length,
                itemBuilder: (context, i) {
                  final bits = favorites[i].split('|');
                  final text = bits.length > 1 ? bits.sublist(1).join('|') : '';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.fromLTRB(16, 8, 8, 14),
                    decoration: BoxDecoration(
                      color: AppColors.panel,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.gold.withOpacity(.2)),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(
                          child: Text(bits.first,
                              style: const TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded,
                              color: AppColors.muted),
                          onPressed: () async {
                            await Clipboard.setData(ClipboardData(text: text));
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('تم نسخ الذكر')));
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded,
                              color: Colors.redAccent),
                          onPressed: () async {
                            final p = await SharedPreferences.getInstance();
                            favorites.removeAt(i);
                            await p.setStringList('favorites', favorites);
                            if (mounted) setState(() {});
                          },
                        ),
                      ]),
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(text,
                            maxLines: 5,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppColors.cream, height: 1.9, fontSize: 18)),
                      ),
                    ]),
                  );
                }),
      );
}