import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

void main() => runApp(WeatherClockApp());

class WeatherClockApp extends StatefulWidget {
  @override
  _WeatherClockAppState createState() => _WeatherClockAppState();
}

class _WeatherClockAppState extends State<WeatherClockApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void toggleTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather & Clock',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        primarySwatch: Colors.blueGrey,
      ),
      home: WeatherHomePage(onToggleTheme: toggleTheme),
    );
  }
}

class WeatherHomePage extends StatefulWidget {
  final Function(bool) onToggleTheme;

  WeatherHomePage({required this.onToggleTheme});

  @override
  _WeatherHomePageState createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  String city = "Delhi";
  String time = "";
  String date = "";
  String temp = "";
  String desc = "";
  String backgroundImage = "assets/bg.jpg";
  final TextEditingController cityController = TextEditingController();
  bool isDark = false;
  Timer? autoRefreshTimer;
  bool hasFetched = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    getCityFromGPS().then((value) {
      setState(() {
        city = value;
        cityController.text = value;
      });
    });
  }

  @override
  void dispose() {
    autoRefreshTimer?.cancel();
    super.dispose();
  }

  void startAutoRefresh() {
    autoRefreshTimer?.cancel();
    autoRefreshTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      fetchData();
    });
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
    });

    //final ip = "10.182.79.231"; // Replace with your FastAPI backend IP
    //final url = Uri.parse('http://$ip:8000/weather_time?city=$city');
    
    final url = Uri.parse('https://weather-and-clock-app.onrender.com/weather_time?city=$city',);



    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          time = data["local_time"];
          date = data["local_date"];
          temp = "${data["temperature"]} °C";
          desc = data["description"];
          backgroundImage = getBackground(desc, time);
        });
      } else {
        setState(() {
          time = "Error";
          date = "-";  
          temp = "N/A";
          desc = "City not found";
          backgroundImage = "assets/bg.jpg";
        });
      }
    } catch (e) {
      setState(() {
        time = "Error";
        date = "-";  
        temp = "N/A";
        desc = "Failed to connect";
        backgroundImage = "assets/bg.jpg";
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<String> getCityFromGPS() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return "Delhi";

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return "Delhi";
    }

    if (permission == LocationPermission.deniedForever) return "Delhi";

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (placemarks.isNotEmpty) {
      return placemarks.first.locality ?? "Delhi";
    } else {
      return "Delhi";
    }
  }

  String getBackground(String description, String timeStr) {
    String descLower = description.toLowerCase();
    int hour = int.tryParse(timeStr.split(":")[0]) ?? 12;
    bool isNight = hour < 6 || hour >= 18;
    bool isMorning = hour >= 6 && hour < 9;

    if (descLower.contains("clear") && !isNight) {
      return "assets/clean-day.jpg";
    } else if (descLower.contains("clear") && isNight) {
      return "assets/clear-night.jpg";
    } else if ((descLower.contains("cloud") || descLower.contains("overcast"))) {
      if (isNight) return "assets/cloudy-night.jpg";
      if (isMorning) return "assets/morning.jpg";
      return "assets/overcast-cloudy.jpg";
    } else if (descLower.contains("light rain") || descLower.contains("drizzle")) {
      return "assets/light-rain.jpg";
    } else if (descLower.contains("rain")) {
      return "assets/heavy-rain.jpg";
    } else {
      return "assets/bg.jpg";
    }
  }

  final textStyle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    shadows: [
      Shadow(blurRadius: 10, color: Colors.black87, offset: Offset(2, 2)),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Weather & Clock',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Switch(
            value: isDark,
            onChanged: (value) {
              setState(() => isDark = value);
              widget.onToggleTheme(value);
            },
            activeColor: Colors.white,
          ),
        ],
      ),
      body: Stack(
        children: [
          Image.asset(
            backgroundImage,
            fit: BoxFit.cover,
            height: double.infinity,
            width: double.infinity,
          ),
          Container(
            padding: const EdgeInsets.all(20.0),
            color: isDark
                ? Colors.black.withOpacity(0.6)
                : Colors.white.withOpacity(0.3),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: cityController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Enter City',
                        labelStyle: TextStyle(color: Colors.white),
                        filled: true,
                        fillColor: Colors.black54,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              setState(() {
                                city = cityController.text.trim();
                                hasFetched = true;
                              });
                              fetchData();
                              startAutoRefresh();
                            },
                      child: isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text("Get Time & Weather"),
                    ),
                    if (hasFetched) ...[
                      SizedBox(height: 30),
                      Text("City: $city", style: textStyle),
                      Text("Date: $date", style: textStyle),
                      Text("Time: $time", style: textStyle),
                      Text("Temperature: $temp", style: textStyle),
                      Text("Description: $desc", style: textStyle),
                    ],
                    SizedBox(height: 60),
                    // Footer
                    Column(
                      children: [
                        Text(
                          'Developed by',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.85),
                            fontWeight: FontWeight.w400,
                            shadows: [
                              Shadow(
                                blurRadius: 5,
                                color: Colors.black.withOpacity(0.6),
                                offset: Offset(1, 1),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Syed Afseh Ehsani',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.0,
                            shadows: [
                              Shadow(
                                blurRadius: 8,
                                color: Colors.black87,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}






/*import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

void main() => runApp(WeatherClockApp());

class WeatherClockApp extends StatefulWidget {
  @override
  _WeatherClockAppState createState() => _WeatherClockAppState();
}

class _WeatherClockAppState extends State<WeatherClockApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void toggleTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather & Clock',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        primarySwatch: Colors.blueGrey,
      ),
      home: WeatherHomePage(onToggleTheme: toggleTheme),
    );
  }
}

class WeatherHomePage extends StatefulWidget {
  final Function(bool) onToggleTheme;

  WeatherHomePage({required this.onToggleTheme});

  @override
  _WeatherHomePageState createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  String city = "Delhi";
  String time = "";
  String temp = "";
  String desc = "";
  String backgroundImage = "assets/bg.jpg";
  final TextEditingController cityController = TextEditingController();
  bool isDark = false;
  Timer? autoRefreshTimer;
  bool hasFetched = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    getCityFromGPS().then((value) {
      setState(() {
        city = value;
        cityController.text = value;
      });
    });
  }

  @override
  void dispose() {
    autoRefreshTimer?.cancel();
    super.dispose();
  }

  void startAutoRefresh() {
    autoRefreshTimer?.cancel();
    autoRefreshTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      fetchData();
    });
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
    });

    final ip = "10.182.79.231"; // Replace with your FastAPI backend IP
    final url = Uri.parse('http://$ip:8000/weather_time?city=$city');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          time = data["local_time"];
          temp = "${data["temperature"]} °C";
          desc = data["description"];
          backgroundImage = getBackground(desc, time);
        });
      } else {
        setState(() {
          time = "Error";
          temp = "N/A";
          desc = "City not found";
          backgroundImage = "assets/bg.jpg";
        });
      }
    } catch (e) {
      setState(() {
        time = "Error";
        temp = "N/A";
        desc = "Failed to connect";
        backgroundImage = "assets/bg.jpg";
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<String> getCityFromGPS() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return "Delhi";

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return "Delhi";
    }

    if (permission == LocationPermission.deniedForever) return "Delhi";

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (placemarks.isNotEmpty) {
      return placemarks.first.locality ?? "Delhi";
    } else {
      return "Delhi";
    }
  }

  String getBackground(String description, String timeStr) {
    String descLower = description.toLowerCase();
    int hour = int.tryParse(timeStr.split(":")[0]) ?? 12;
    bool isNight = hour < 6 || hour >= 18;
    bool isMorning = hour >= 6 && hour < 9;

    if (descLower.contains("clear") && !isNight) {
      return "assets/clean-day.jpg";
    } else if (descLower.contains("clear") && isNight) {
      return "assets/clear-night.jpg";
    } else if ((descLower.contains("cloud") || descLower.contains("overcast"))) {
      if (isNight) return "assets/cloudy-night.jpg";
      if (isMorning) return "assets/morning.jpg";
      return "assets/overcast-cloudy.jpg";
    } else if (descLower.contains("light rain") || descLower.contains("drizzle")) {
      return "assets/light-rain.jpg";
    } else if (descLower.contains("rain")) {
      return "assets/heavy-rain.jpg";
    } else {
      return "assets/bg.jpg";
    }
  }

  final textStyle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    shadows: [
      Shadow(blurRadius: 10, color: Colors.black87, offset: Offset(2, 2)),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Weather & Clock',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Switch(
            value: isDark,
            onChanged: (value) {
              setState(() => isDark = value);
              widget.onToggleTheme(value);
            },
            activeColor: Colors.white,
          ),
        ],
      ),
      body: Stack(
        children: [
          Image.asset(
            backgroundImage,
            fit: BoxFit.cover,
            height: double.infinity,
            width: double.infinity,
          ),
          Container(
            padding: const EdgeInsets.all(20.0),
            color: isDark
                ? Colors.black.withOpacity(0.6)
                : Colors.white.withOpacity(0.3),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: cityController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Enter City',
                        labelStyle: TextStyle(color: Colors.white),
                        filled: true,
                        fillColor: Colors.black54,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              setState(() {
                                city = cityController.text.trim();
                                hasFetched = true;
                              });
                              fetchData();
                              startAutoRefresh();
                            },
                      child: isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text("Get Time & Weather"),
                    ),
                    if (hasFetched) ...[
                      SizedBox(height: 30),
                      Text("City: $city", style: textStyle),
                      Text("Time: $time", style: textStyle),
                      Text("Temperature: $temp", style: textStyle),
                      Text("Description: $desc", style: textStyle),
                    ]
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}*/
