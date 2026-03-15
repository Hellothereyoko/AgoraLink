
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

//Intantiates the homepage of the app, which will display weather and events
class HomePage extends StatefulWidget {
  @override
  // ignore: library_private_types_in_public_api
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  String weatherText = "Loading weather...";


//THIS IS A PLACEHOLDER: In a real app, this would be fetched from a backend or database, but for this demo we'll just hardcode some events
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

//Determine the location of the user, which will be used to fetch weather data for that location
  Future<Position> determinePosition() async {

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();

//ERROR HANDLING: If location services are disabled, throw an error
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

    String apiKey = "7a8cfe0a1bcfec82dea7a8c9d4c25422"; //Please be nice to the API key, it's free to use but has a limit on requests per minute. If you want to test the app more, you can get your own API key for free at https://openweathermap.org/api

    final url =
        "https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric";

    final response = await http.get(Uri.parse(url));

    var data = jsonDecode(response.body);

    return data;
  }


  void loadWeather() async {

    Position pos = await determinePosition();

    var weather = await getWeather(pos.latitude, pos.longitude);

    setState(() {
      weatherText =
          "${weather["name"]}  ${weather["main"]["temp"]}°C  ${weather["weather"][0]["main"]}";
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Align(
          alignment: Alignment.center,
          child: 
            Text( "Welcome to AgoraLink!",
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            )
        ),  
      ),

      body: Padding(
        padding: EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Align(
              alignment: Alignment.center,
              child:
            Text(
              "Local Weather",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            ),

            SizedBox(height: 10),

            Align(
              alignment: Alignment.center,
              child:
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(weatherText),
                ),
                ),

            SizedBox(height: 25),

            Align(
              alignment: Alignment.center,
              child: Text(
                "Community Events",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),

            SizedBox(height: 10),

            Expanded(
              child: ListView.builder(
                itemCount: events.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: ListTile(
                      title: Text(events[index]),
                    ),
                  );
                },
              ),
            ),

            ElevatedButton(
              onPressed: () {}, //TODO: Implement chat functionality
              child: Text("Community Chat"),
            )
          ],
        ),
      ),
    );
  }
}
