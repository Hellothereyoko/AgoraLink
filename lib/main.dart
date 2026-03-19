import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load();
  runApp(AgoraLink());
}

/*
 * AgoraLink is the main widget of the app, which sets up the MaterialApp and defines the theme and home page. It serves as the entry point for the application and provides a consistent look and feel across all screens. The HomePage widget is set as the home of the app, which will be displayed when the app is launched.
 */
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

/*
 * @return Position - The current position of the user
 * This function checks if location services are enabled and if the app has permission to access the user's
 * location.
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
   * @param condition - The main weather condition (e.g., "Clear", "Clouds", "Rain")
   * This function maps the main weather condition to a corresponding Material Icon. It uses a switch statement to return the appropriate icon based on the condition. If the condition is not recognized, it defaults to a generic cloud icon. This allows the app to visually represent the current weather in a simple and intuitive way.
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
  * @param lat - Latitude of the user's location
  * @param lon - Longitude of the user's location
  * This function fetches the current weather data for the user's location using the OpenWeatherMap API. It then extracts the relevant information (city, temperature, and weather condition) and updates the UI accordingly. The temperature is displayed in Celsius by default, but if the user's country is in the list of Fahrenheit-using countries, it converts it to Fahrenheit before displaying.
  */
  void loadWeather() async {
    Position pos = await determinePosition();
    var weather = await getWeather(pos.latitude, pos.longitude);

    String country = weather["sys"]["country"];
    String city = weather["name"];
    double temp = weather["main"]["temp"];
    String condition = weather["weather"][0]["main"];

    String unit = "°C";
    double displayTemp = temp;


    //This list stores the countries still using The Imperial System 
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
  /*
  * @param context - The BuildContext of the widget
  * @return Widget - The widget tree for the HomePage
  * This is the main build method for the HomePage widget. It constructs the UI of the app, which includes a gradient background, a custom AppBar with a welcome message, a weather widget that displays the current weather conditions, and a list of community events. The weather widget uses the getWeatherIcon function to display an appropriate icon based on the current weather condition. The community events are displayed in a ListView, and there is also a button for accessing the community chat (functionality to be implemented). The overall design is intended to be visually appealing and user-friendly, with a focus on providing relevant information to the user in an accessible way.
  */
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