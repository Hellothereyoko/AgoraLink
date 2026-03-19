import 'package:flutter/material.dart';
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

/*
 * AgoraLink is the main widget of the app, which sets up the MaterialApp and defines the theme and home page.
 */
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
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String weatherText = "Loading weather...";
  String weatherCondition = "";

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<String> events = [];

  @override
  void initState() {
    super.initState();
    loadWeather();
    loadEventsFromFirebase();
  }

  /*
   * Checks if location services are enabled and if the app has permission to
   * access the user's location.
   */
  Future<Position> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception("Location services disabled");
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return await Geolocator.getCurrentPosition();
  }

  /*
   * Fetches weather data from the OpenWeatherMap API based on the user's location.
   * API key is loaded from .env via flutter_dotenv.
   * TODO: API key protection needed ASAP!
   */
  Future getWeather(double lat, double lon) async {
    String apiKey = dotenv.env['OPENWEATHER_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      throw Exception("API key not configured");
    }
    final url =
        "https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric";
    final response = await http.get(Uri.parse(url));
    var data = jsonDecode(response.body);
    return data;
  }

  /*
   * Maps a main weather condition string to a Material Icon.
   */
  IconData getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny_rounded;
      case 'clouds':
        return Icons.cloud_rounded;
      case 'rain':
      case 'drizzle':
        return Icons.umbrella_rounded;
      case 'thunderstorm':
        return Icons.thunderstorm_rounded;
      case 'snow':
        return Icons.ac_unit_rounded;
      case 'mist':
      case 'smoke':
      case 'haze':
      case 'dust':
      case 'fog':
      case 'sand':
      case 'ash':
      case 'squall':
        return Icons.foggy;
      case 'tornado':
        return Icons.tornado_rounded;
      default:
        return Icons.cloud_queue_rounded;
    }
  }

  /*
   * Fetches the current weather for the user's location and updates the UI.
   * Converts to Fahrenheit for countries that use the Imperial system.
   */
  void loadWeather() async {
    try {
      Position pos = await determinePosition();
      var weather = await getWeather(pos.latitude, pos.longitude);

      String country = weather["sys"]["country"];
      String city = weather["name"];
      double temp = weather["main"]["temp"];
      String condition = weather["weather"][0]["main"];

      String unit = "°C";
      double displayTemp = temp;

      List<String> fahrenheitCountries = ["US", "BS", "KY", "LR", "PW", "FM", "MH"];
      if (fahrenheitCountries.contains(country)) {
        displayTemp = temp * 9 / 5 + 32;
        unit = "°F";
      }

      setState(() {
        weatherText = "$city  ${displayTemp.toStringAsFixed(1)}$unit  $condition";
        weatherCondition = condition;
      });
    } catch (e) {
      setState(() {
        weatherText = "Could not load weather";
      });
    }
  }

  /*
   * Loads community events from Firestore and listens for real-time updates.
   */
  void loadEventsFromFirebase() {
    _firestore.collection('events').snapshots().listen((snapshot) {
      List<String> loadedEvents = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['title'] != null) {
          loadedEvents.add(data['title'] as String);
        }
      }
      setState(() {
        events = loadedEvents;
      });
    }, onError: (error) {
      // ignore: avoid_print
      print('Error loading events: $error');
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
              // AppBar-style header
              Padding(
                padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                child: Text(
                  "Welcome to AgoraLink!",
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 8),

                      // Weather widget
                      Center(
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 28, horizontal: 24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Colors.red[300]!, Colors.red[600]!],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.3),
                                blurRadius: 16,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Icon(getWeatherIcon(weatherCondition), color: Colors.white, size: 40),
                              SizedBox(height: 12),
                              Text(
                                weatherText,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 40),

                      Center(
                        child: Text(
                          "Community Events",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[800],
                          ),
                        ),
                      ),

                      SizedBox(height: 12),

                      Expanded(
                        child: ListView.builder(
                          itemCount: events.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.75),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                leading: Icon(Icons.event, color: Colors.red[400]),
                                title: Text(
                                  events[index],
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {}, // TODO: Implement chat functionality
                            icon: Icon(Icons.chat_bubble_outline),
                            label: Text("Community Chat"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[600],
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
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