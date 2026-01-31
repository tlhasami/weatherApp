import 'dart:ui';
import 'package:flutter/material.dart';
import './secret_key.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class WeatherData {
  final String temperature;
  final String weather;
  final String humidity;
  final String windSpeed;
  final String pressure;
  final IconData icon; // determined automatically

  WeatherData({
    required this.temperature,
    required this.weather,
    required this.humidity,
    required this.windSpeed,
    required this.pressure,
  }) : icon = _getWeatherIcon(weather); // assign icon based on weather

  // private helper method to map weather string to an icon
  static IconData _getWeatherIcon(String weather) {
    switch (weather.toLowerCase()) {
      case 'clouds':
        return Icons.cloud;
      case 'rain':
        return Icons.beach_access; // or Icons.grain
      case 'sunny':
      case 'clear':
        return Icons.wb_sunny;
      case 'snow':
        return Icons.ac_unit;
      case 'storm':
      case 'thunderstorm':
        return Icons.flash_on;
      default:
        return Icons.cloud; // default icon
    }
  }
}

class HourlyWeather {
  final String time;
  final String temperature;
  final IconData icon;

  HourlyWeather({
    required this.time,
    required this.temperature,
    required this.icon,
  });

  factory HourlyWeather.fromJson(Map<String, dynamic> json) {
    final weatherMain = json['weather'][0]['main'];
    return HourlyWeather(
      time: json['dt_txt'].toString().substring(11, 16), // HH:MM
      temperature: json['main']['temp'].toStringAsFixed(1),
      icon: WeatherData._getWeatherIcon(weatherMain), // reuse your icon mapping
    );
  }
}



class _WeatherScreenState extends State<WeatherScreen> {

  late final List<String> cities ;

  // Currently selected city
  String selectedCity = "London";

  Future<List<HourlyWeather>> fetchHourlyForecast(String city) async {
    final response = await http.get(Uri.parse(
      "https://api.openweathermap.org/data/2.5/forecast?q=$city&appid=$openWeatherAPIKey&units=metric"
    ));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> list = data['list'];

      return list.map((item) => HourlyWeather.fromJson(item)).toList();
    } else {
      throw Exception("Failed to load hourly forecast");
    }
  }


  void loadCities() async {
    final data = await DefaultAssetBundle.of(context)
        .loadString("assets/cities.json");

    final List<dynamic> cityList = jsonDecode(data);

    setState(() {
      cities = cityList.map((c) => c['name'].toString()).toList();
    });

    if (cities.isEmpty){
      debugPrint("City list is empty!");
      return;
    } else {
      debugPrint("City list Loaded");
    }

    // for (var city in cities) {
    //   debugPrint(city);
    // }
  }


  // -------------------------------
  // 2. API FUNCTION (returns data)
  // -------------------------------
  Future<WeatherData> fetchCurrentWeather(String city) async {

    final response = await http.get(Uri.parse(
      "https://api.openweathermap.org/data/2.5/weather?q=$city&APPID=$openWeatherAPIKey&units=metric"
    ));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return WeatherData(
        temperature: data['main']['temp'].toStringAsFixed(1),
        weather: data['weather'][0]['main'],
        humidity: data['main']['humidity'].toString(),
        pressure: data['main']['pressure'].toString(),
        windSpeed: data['wind']['speed'].toStringAsFixed(1),
      );
    } else {
      throw Exception("Failed to load weather");
    }
  }

  // -------------------------------
  // 3. FUTURE HOLDER
  // -------------------------------
  late Future<WeatherData> weatherFuture;
  late Future<List<HourlyWeather>> hourlyForecastFuture;

  @override
  void initState() {
    super.initState();
    // Load default city weather
    weatherFuture = fetchCurrentWeather(selectedCity);
    hourlyForecastFuture = fetchHourlyForecast(selectedCity);
    loadCities();

  }
  late bool isWeb ;

  // Decide max width
  late double contentWidth;  

  Widget buildHourlyForecast(List<HourlyWeather> hourly) {
    if (isWeb) {
      // Web: Wrap + vertical scroll
      return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: hourly.map((hour) => WeatherForecastHourly(
            time: hour.time,
            temperature: hour.temperature,
            icon: hour.icon,
          )).toList(),
        ),
      );
    } else {
      // Mobile: Horizontal scroll
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: hourly.map((hour) => Padding(
            padding: const EdgeInsets.only(right: 12),
            child: WeatherForecastHourly(
              time: hour.time,
              temperature: "${hour.temperature}°C",
              icon: hour.icon,
            ),
          )).toList(),
        ),
      );
    }
  }

 

  @override
  Widget build(BuildContext context) {
    
    // Get screen width
    final double screenWidth = MediaQuery.of(context).size.width;
    isWeb = screenWidth >= 600;

    // Decide max width
    contentWidth = screenWidth < 600
        ? double.infinity   // Mobile
        : 750;               // Tablet / Web / Desktop

    return Scaffold(
      body: Center(
        child: SizedBox(
          width: contentWidth,
          child: Scaffold(
          
            // ---------
            // | APP BAR 
            // ---------
            appBar: AppBar(  
              elevation: 0,                  // no shadow
              foregroundColor: Colors.white, // text & icons
              scrolledUnderElevation: 0,    
              centerTitle: true,
              title: Padding(
                padding: const EdgeInsets.only(top: 15), // move down
                child: const Text(
                  "Weather App",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(top: 15),
                  child: IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      setState(() {
                        weatherFuture = fetchCurrentWeather(selectedCity);
                      });
                    },
                  ),
                ),
              ],
            ),
          
            // ----------------------------
            // | BODY WITH FUTURE BUILDER |
            // ----------------------------
            body: FutureBuilder<WeatherData>(
              future: weatherFuture,
              builder: (context, snapshot) {
          
                // LOADING STATE
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
          
                // ERROR STATE
                if (snapshot.hasError) {
                  return const Center(child: Text("Error loading weather"));
                }
          
                // SUCCESS STATE
                final data = snapshot.data!;
          
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
          
                      // -------------------------------
                      // 4. SEARCHABLE DROPDOWN (CITY)
                      // -------------------------------
                      Autocomplete<String>(
                        optionsBuilder: (TextEditingValue value) {
                          if (value.text.isEmpty) {
                            return const Iterable<String>.empty();
                          }
                          return cities.where(
                            (city) => city.toLowerCase().contains(
                              value.text.toLowerCase(),
                            ),
                          );
                        },
          
                        onSelected: (String city) {
                          // Update city and refetch weather
                          setState(() {
                            selectedCity = city;
                            weatherFuture = fetchCurrentWeather(city);
                            hourlyForecastFuture = fetchHourlyForecast(city);
                          });
                        },
          
                        fieldViewBuilder: (
                          context,
                          controller,
                          focusNode,
                          onSubmit,
                        ) {
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: const InputDecoration(
                              labelText: "Search City",
                              labelStyle: TextStyle(color: Colors.white),
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.search),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                              ),
                            ),
                          );
                        },
                      ),
          
                      const SizedBox(height: 20),
                      Center(
                        child: Text(
                          "Current Weather in $selectedCity",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ), 
          
                      const SizedBox(height: 20),
          
                      // -------------------------------
                      // MAIN WEATHER CARD
                      // -------------------------------
                      WeatherMainCard(
                        data: data,
                      ),
          
                      const SizedBox(height: 20),
          
                      const Text(
                        "Weather Forecast",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                      ),
          
                      const SizedBox(height: 10),
          
                 
                      FutureBuilder<List<HourlyWeather>>(
                        future: hourlyForecastFuture, // make sure this is fetched in initState
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (snapshot.hasError) {
                            return const Center(child: Text("Error loading hourly forecast"));
                          }

                          final hourly = snapshot.data!;

                          return buildHourlyForecast(hourly);
                        },
                      ),

          
                      const SizedBox(height: 20),
          
                      const Text(
                        "Additional Information",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                      ),
          
                      const SizedBox(height: 10),
          
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          AdditionalInformation(
                            value: "${data.humidity}%",   // humidity in %
                            icon: Icons.water_drop,
                            label: "Humidity",
                          ),
                          AdditionalInformation(
                            value: "${(double.parse(data.windSpeed) * 3.6).toStringAsFixed(1)} km/h", // convert m/s → km/h
                            icon: Icons.air,
                            label: "Wind Speed",
                          ),
                          AdditionalInformation(
                            value: "${data.pressure} hPa", // pressure in hPa
                            icon: Icons.speed,
                            label: "Pressure",
                          ),
                        ],
                      ),

                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class AdditionalInformation extends StatelessWidget {
  final String label, value;
  final IconData icon;

  const AdditionalInformation({
    super.key,
    required this.value,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 28,
            color: Colors.blueAccent,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class WeatherForecastHourly extends StatelessWidget {
  final String time , temperature;
  final IconData icon;

  const WeatherForecastHourly({
    super.key,
    required this.time,
    required this.temperature,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),

        child: Column(
          children: [
            Text(
              time,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold ,
              ),
            ),

            SizedBox(height: 5,),
            Icon(
              icon,
              size: 24,
            ),

            SizedBox(height: 5,),
            Text(
              temperature,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold ,
              ),
            ),

          ],
        ),
      ),
    );
  }
}

class WeatherMainCard extends StatelessWidget {
  final WeatherData data;

  const WeatherMainCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  SizedBox(height: 10),
                  Text(
                    "${data.temperature}°C",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Icon(
                    data.icon, // directly from WeatherData
                    size: 50,
                  ),
                  SizedBox(height: 10),
                  Text(
                    data.weather,
                    style: TextStyle(fontSize: 24),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
