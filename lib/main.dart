import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(AgoraLink());
}

class AgoraLink extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgoraLink',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: Brightness.light,
        ),
      ),
      home: SplashScreen(),
    );
  }
}

// ---------------------------------------------------------------------------
// Splash Screen
// ---------------------------------------------------------------------------
class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => HomePage(),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.red[50]!, Colors.white],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
            ),

            const SizedBox(height: 24),

            Text(
              'AgoraLink',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Your community, connected.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.red[300],
                letterSpacing: 0.4,
              ),
            ),

            const SizedBox(height: 48),

            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.red[400]!),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class Event {
  final String title;
  final String info;
  final DateTime? dateandtime;
  Event({required this.title, required this.info, this.dateandtime});
}

// ---------------------------------------------------------------------------
// TickerPainter — draws scrolling text via CustomPainter
// ---------------------------------------------------------------------------
class _TickerPainter extends CustomPainter {
  final String text;
  final double offset;
  final TextStyle style;

  _TickerPainter({required this.text, required this.offset, required this.style});

  @override
  void paint(Canvas canvas, Size size) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: double.infinity);

    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));
    tp.paint(canvas, Offset(offset, (size.height - tp.height) / 2));
  }

  @override
  bool shouldRepaint(_TickerPainter old) =>
      old.text != text || old.offset != offset;
}

// ---------------------------------------------------------------------------
// NoticeTicker
// ---------------------------------------------------------------------------
class NoticeTicker extends StatefulWidget {
  final List<String> notices;
  const NoticeTicker({Key? key, required this.notices}) : super(key: key);

  @override
  _NoticeTickerState createState() => _NoticeTickerState();
}

class _NoticeTickerState extends State<NoticeTicker>
    with SingleTickerProviderStateMixin {

  static const double _pxPerSecond = 80.0;
  static const TextStyle _style = TextStyle(
    color: Colors.white,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  late Ticker _ticker;
  Duration? _prev;
  double _offset = 0;
  double _textWidth = 0;
  int _currentIndex = 0;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.notices.isNotEmpty) {
        _measureText(_currentIndex);
        _started = true;
        _ticker.start();
      }
    });
  }

  @override
  void didUpdateWidget(NoticeTicker old) {
    super.didUpdateWidget(old);
    if (widget.notices.isEmpty) return;
    if (old.notices != widget.notices) {
      _currentIndex = _currentIndex.clamp(0, widget.notices.length - 1);
      _measureText(_currentIndex);
    }
    if (!_started && widget.notices.isNotEmpty) {
      _started = true;
      _ticker.start();
    }
  }

  void _measureText(int index) {
    final tp = TextPainter(
      text: TextSpan(text: widget.notices[index], style: _style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: double.infinity);
    _textWidth = tp.size.width;
    _offset = double.infinity;
    _prev = null;
  }

  void _onTick(Duration elapsed) {
    if (!mounted || widget.notices.isEmpty) return;

    final w = context.size?.width ?? 400;

    if (_offset == double.infinity) {
      _offset = w;
      _prev = elapsed;
      setState(() {});
      return;
    }

    if (_prev != null) {
      final dt = (elapsed - _prev!).inMicroseconds / 1e6;
      _offset -= _pxPerSecond * dt;

      if (_offset < -_textWidth) {
        _currentIndex = (_currentIndex + 1) % widget.notices.length;
        _measureText(_currentIndex);
        _prev = elapsed;
        return;
      }
    }

    _prev = elapsed;
    setState(() {});
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.notices.isEmpty) return const SizedBox.shrink();
    final currentText = widget.notices[_currentIndex];

    return Container(
      width: double.infinity,
      color: Colors.red[700],
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            margin: const EdgeInsets.only(left: 12, right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'NOTICE',
              style: TextStyle(
                color: Colors.red[700],
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: SizedBox(
              height: 20,
              child: CustomPaint(
                painter: _TickerPainter(
                  text: currentText,
                  offset: _offset == double.infinity ? 400 : _offset,
                  style: _style,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// App state
// ---------------------------------------------------------------------------

class _HomePageState extends State<HomePage> {
  String weatherText = 'Loading weather...';
  String weatherCondition = '';
  List<String> activeNotices = [];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Event> events = [];

  @override
  void initState() {
    super.initState();
    loadWeather();
    loadEventsFromFirebase();
    loadActiveNotice();
  }

  Future<Position> determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Location services disabled');
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return await Geolocator.getCurrentPosition();
  }

  // TODO: API key protection needed ASAP!
  Future getWeather(double lat, double lon) async {
    final apiKey = dotenv.env['OPENWEATHER_API_KEY'] ?? '';
    if (apiKey.isEmpty) throw Exception('API key not configured');
    final url =
        'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric';
    final response = await http.get(Uri.parse(url));
    return jsonDecode(response.body);
  }

  IconData getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':        return Icons.wb_sunny_rounded;
      case 'clouds':       return Icons.cloud_rounded;
      case 'rain':
      case 'drizzle':      return Icons.umbrella_rounded;
      case 'thunderstorm': return Icons.thunderstorm_rounded;
      case 'snow':         return Icons.ac_unit_rounded;
      case 'mist':
      case 'smoke':
      case 'haze':
      case 'dust':
      case 'fog':
      case 'sand':
      case 'ash':
      case 'squall':       return Icons.foggy;
      case 'tornado':      return Icons.tornado_rounded;
      default:             return Icons.help_outline_rounded;
    }
  }

  void loadWeather() async {
    try {
      final pos = await determinePosition();
      final weather = await getWeather(pos.latitude, pos.longitude);
      final country   = weather['sys']['country'] as String;
      final city      = weather['name'] as String;
      double temp     = (weather['main']['temp'] as num).toDouble();
      final condition = weather['weather'][0]['main'] as String;
      String unit     = '°C';
      if (['US','BS','KY','LR','PW','FM','MH'].contains(country)) {
        temp = temp * 9 / 5 + 32;
        unit = '°F';
      }
      setState(() {
        weatherText      = '$city  ${temp.toStringAsFixed(1)}$unit  $condition';
        weatherCondition = condition;
      });
    } catch (_) {
      setState(() { weatherText = 'Could not load weather'; });
    }
  }

  void loadEventsFromFirebase() {
    _firestore.collection('events').snapshots().listen((snapshot) {
      final loaded = snapshot.docs.map((doc) {
        final data = doc.data();
        return Event(
          title: data['title'] as String? ?? 'Untitled Event',
          info:  data['info']  as String? ?? '',
          dateandtime: data['dateandtime'] != null
              ? (data['dateandtime'] as Timestamp).toDate()
              : null,
        );
      }).toList();
      setState(() { events = loaded; });
    });
  }

  void loadActiveNotice() {
    _firestore
        .collection('notices')
        .where('active', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        activeNotices = snapshot.docs
            .map((doc) => doc.data()['title'] as String? ?? '')
            .where((t) => t.isNotEmpty)
            .toList();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.red[50]!, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              if (activeNotices.isNotEmpty)
                NoticeTicker(notices: activeNotices),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                child: Text(
                  'Welcome to AgoraLink!',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.red[700]),
                  textAlign: TextAlign.center,
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.red[300]!, Colors.red[600]!],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6)),
                          ],
                        ),
                        child: Column(
                          children: [
                            Icon(getWeatherIcon(weatherCondition), color: Colors.white, size: 40),
                            const SizedBox(height: 12),
                            Text(
                              weatherText,
                              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      Center(
                        child: Text('Community Events',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red[800]),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Expanded(
                        child: ListView.builder(
                          itemCount: events.length,
                          itemBuilder: (context, i) {
                            final event = events[i];
                            final dt = event.dateandtime;
                            final dateLabel = dt != null
                                ? '${dt.month}/${dt.day}/${dt.year}  ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}'
                                : null;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.75),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
                              ),
                              child: ListTile(
                                leading: Icon(Icons.event, color: Colors.red[400]),
                                title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (dateLabel != null) ...[
                                      const SizedBox(height: 4),
                                      Text(dateLabel, style: TextStyle(color: Colors.red[400], fontSize: 12, fontWeight: FontWeight.w500)),
                                    ],
                                    if (event.info.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(event.info, style: const TextStyle(color: Colors.black87)),
                                    ],
                                  ],
                                ),
                                isThreeLine: event.info.isNotEmpty,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Add more widgets for each community's needs! This is completely customizable.
// The weather and events widgets are just examples — add anything you want!