import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(AgoraLink());
}

class AgoraLink extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgoraLink',
      theme: ThemeData(primarySwatch: Colors.red),
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

  // THIS IS A PLACEHOLDER: In a real app, this would be fetched from a backend or database
  final List<String> events = [
    "Farmers Market - Saturday 9AM",
    "Community Cleanup - Sunday",
    "City Council Meeting - Tuesday"
  ];

  @override
  void initState() {
    super.initState();
    loadWeather();
  }

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

  Future getWeather(double lat, double lon) async {
    String apiKey = "7a8cfe0a1bcfec82dea7a8c9d4c25422";
    final url =
        "https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric";
    final response = await http.get(Uri.parse(url));
    var data = jsonDecode(response.body);
    return data;
  }

  // Maps OpenWeatherMap condition strings to Material icons
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

  void loadWeather() async {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Gradient background replacing plain white
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFF3F3), // very light warm red/pink
              Color(0xFFFDE8D8), // soft warm peach
              Color(0xFFF5F0FF), // barely-there lavender at the bottom
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom AppBar area
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Center(
                  child: Text(
                    "Welcome to AgoraLink!",
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
                ),
              ),

              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 8),

                      // Larger, richer weather widget
                      Center(
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 28, horizontal: 24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.red[300]!,
                                Colors.red[600]!,
                              ],
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

                      // Extra spacing before the events section
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