/*

import 'package:flutter/material.dart';
import 'package:gasapp/api/location_helper.dart';
import 'package:gasapp/screens/route_screen.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../model/city_route.dart';
import '../model/distance_time.dart';
import '../model/place_direction.dart';
import '../model/route_permutations.dart';
import 'package:fluttertoast/fluttertoast.dart';

class GasScreen extends StatefulWidget {
  @override
  State<GasScreen> createState() => _GasScreenState();
}

class _GasScreenState extends State<GasScreen> {
  final cityController = TextEditingController();
  RxList<String> citiesList = <String>[].obs;
  Map<String, LatLng> citiesLatLng = {}; // for default route
  Map<String, LatLng> directionsLatLng = {}; // for best route
 // List<LatLng>defaultDirectins=[];

  late LatLng cityLocation;
  int speed = 100;
  int engineCC = 1800;
  double fuelConsumptionPer100Km = 8.5;
  double currentFuelPrice = 13.0;
  late CitiesRoute? defaultRoute, bestRoute;
  List<CitiesRoute> allRoutes = [];
  List<CitiesRoute> disPlayedRoutes = [];
  List<String> defaultRouteList = [];

  List<List<String>> permutations = [];
  late LatLng currentLocation;
  RxBool isVaildCity = false.obs;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCurrentLocation();
  }

  void getCurrentLocation() async {
    await LocationHelper.getCurrentLocation();

    final currentPosition = await Geolocator.getLastKnownPosition();

    if (currentPosition == null) {
      // Handle null position case
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Unable to get current location.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
      return; // Exit early
    }

    final response = await LocationHelper.getAddressFromLatLng(
        currentPosition.latitude, currentPosition.longitude);

    response.fold(
      (errorMessage) {
        // Show error dialog when there is an error
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Error'),
              content: Text(errorMessage),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      },
      (address) {
        citiesList.add(address);
        final currentLocation = LatLng(currentPosition.latitude, currentPosition.longitude);
        citiesLatLng[address] =currentLocation;

      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Gas App')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: cityController,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return "Please Enter a City";
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: 'Where to go?',
                      border: const OutlineInputBorder(),
                      errorBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 1.3,
                        ),
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Colors.blue,
                          width: 1.3,
                        ),
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Colors.grey,
                          width: 1.3,
                        ),
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                    onPressed: () {
                      if (cityController.text.isNotEmpty) {
                        if (citiesList.contains(cityController.text)) {
                          showToast("This City Already exist");
                          return;
                        }
                        addCity();
                      } else {
                        showToast("Please Enter Vaild City");
                        return;
                      }
                    },
                    child: Text("Add"))
              ],
            ),
            SizedBox(height: 16),
            Obx(() {
              return Expanded(
                child: ListView.builder(
                  itemCount: citiesList.length,
                  itemBuilder: (context, index) {
                    return cityListItem(city: citiesList[index]);
                  },
                ),
              );
            }),
            ElevatedButton(
              onPressed: () {
                gasCalculation();
              },
              child: Text('Calculate'),
            ),
          ],
        ),
      ),
    );
  }

  Widget cityListItem({required String city}) {
    return Card(
      elevation: 4, // Adjust the elevation as needed
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        title: Text(city),
        leading: const Icon(Icons.location_city_sharp),
        trailing: IconButton(
          icon: const Icon(Icons.delete), // Change icon for clarity
          onPressed: () => {citiesList.remove(city)},
        ),
      ),
    );
  }

  void addCity() async {
    final response =
        await LocationHelper.getLatLngFromAddress(cityController.text);
    response.fold(
      (errorMessage) {
        // Show error dialog when there is an error
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Error'),
              content: Text(errorMessage),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      },
      (location) {

        cityLocation = LatLng(location.latitude, location.longitude);
        String city = cityController.text;
        citiesList.add(city);
        citiesLatLng[city] = cityLocation;

      },
    );
  }

  double calculateFuelCost(
      double distance, double fuelConsumptionPer100Km, double fuelPrice) {
    // Adjust the fuel consumption based on speed and engine CC
    double adjustedFuelConsumption = fuelConsumptionPer100Km *
        (1 + (speed / 100) * 0.1) *
        (1 + (engineCC / 1000) * 0.05);

    return distance * adjustedFuelConsumption * fuelPrice;
  }

  double calculateTime(double distance, int speed) {
    return (distance / speed);
  }

  Future<DistanceAndTime> calculateTotalDistance(
      List<String> route, Map<String, LatLng> locationCache) async {
    double totalDistance = 0.0;
    int totalTime = 0;

    for (int i = 0; i < route.length - 1; i++) {
      LatLng? cityLocation = locationCache[route[i]];
      LatLng? nextCityLocation = locationCache[route[i + 1]];
      try {
        // Call getDirections to get the distance and duration between cities
        PlaceDirections response = await LocationHelper.getDirections(cityLocation!, nextCityLocation!);

        // Extract distance and duration
        double distance = double.parse(response.totalDistance.replaceAll(' km', ''));
        int duration = _convertDurationToMinutes(response.totalDuration);

        totalDistance += distance; // Add distance to total
        totalTime += duration;     // Add time to total
      } catch (e) {
        print("Error fetching directions between $cityLocation and $cityLocation: $e");
      }
    }

    // Print the total distance and time
    print("Total Distance: $totalDistance km");
    print("Total Time: ${totalTime ~/ 60} hours and ${totalTime % 60} minutes");

    // Return both total distance and time
    return DistanceAndTime(totalDistance: totalDistance, totalTime: totalTime);
  }

  // Helper function to convert duration text (e.g., "12 mins") into minutes
  int _convertDurationToMinutes(String durationText) {
    if (durationText.contains('hour')) {
      final parts = durationText.split(' ');
      int hours = int.parse(parts[0]);
      int minutes = int.parse(parts[2]);
      return hours * 60 + minutes;
    } else {
      return int.parse(durationText.replaceAll(' mins', ''));
    }
  }

  void gasCalculation() async {
    // Step 1: Check if we have at least two cities
    if (citiesList.length <= 1) {
      showToast("Please Provide At least 2 Cities");
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissal by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Calculating..."),
            ],
          ),
        );
      },
    );
    try {
      // Step 2: Prepare default route
      defaultRouteList.clear(); // Ensure the default route list is empty before adding
      allRoutes.clear(); // Ensure the list is empty before adding new routes
      permutations.clear();
      disPlayedRoutes.clear();

      defaultRouteList.addAll(citiesList);
      final distanceAndTime =  await calculateTotalDistance(defaultRouteList, citiesLatLng);
      // Step 3: Calculate total distance for the default route (direct order of cities)
      final defaultRouteDistance = distanceAndTime.totalDistance;
      int defaultRouteTime = distanceAndTime.totalTime;
      // Step 4: Calculate fuel cost and time for the default route
      double defaultRouteFuelCost = calculateFuelCost(
          defaultRouteDistance, fuelConsumptionPer100Km, currentFuelPrice);


      // Step 5: Create the default route object
      defaultRoute = CitiesRoute(
        distance: defaultRouteDistance,
        cities: defaultRouteList,
        time: defaultRouteTime,
        fuelCost: defaultRouteFuelCost,
        directions: citiesLatLng.values.toList()
      );


      // Step 6: Handle when there are exactly two cities
      if (citiesList.length == 2) {
        // You can handle specific logic for two cities if needed
      } else {
        // Step 7: Handle when there are more than two cities
        // Add the default route to both lists
        allRoutes.add(defaultRoute!);
        disPlayedRoutes.add(defaultRoute!);

        // Step 8: Generate all permutations of routes
        citiesList.forEach((city) {
          permutations
              .addAll(RoutePermutations.generateRoutes(citiesList, city));
        });

        // Step 9: For each generated permutation, calculate the route distance

        for (var route in permutations) {
          var  routeDistanceAndTime = await calculateTotalDistance(route, citiesLatLng);
          List<LatLng> directions =[];
          for (var cityName in route) {
            if (citiesLatLng.containsKey(cityName)) {
              directions.add(citiesLatLng[cityName]!); // Use '!' to assert non-null
            }
          }
          allRoutes.add(
            CitiesRoute(
              distance: routeDistanceAndTime.totalDistance,
              cities: route,
              directions: directions,
              time: routeDistanceAndTime.totalTime

            ),
          );
        }

        print("bezn$allRoutes");

        // Step 10: Sort the routes by distance (ascending order)
        allRoutes.sort((d1, d2) => d1.distance.compareTo(d2.distance));

        // Step 11: Find the best route (the shortest route that starts from the first city)
        bestRoute = allRoutes.firstWhere(
              (route) => route.cities.first == citiesList.first,
        );

        // Step 12: Update the best route's fuel cost, time, and mark it as the best route
        if (bestRoute != null && bestRoute != defaultRoute) {
          // final bestRouteDistanceAndtime = await calculateTotalDistance(bestRoute!.cities,directionsLatLng);
          // double bestRouteFuelCost = calculateFuelCost(
          //   bestRoute!.distance,
          //   fuelConsumptionPer100Km,
          //   currentFuelPrice,
          // );
          // bestRoute!.time = bestRouteDistanceAndtime.totalTime;
          // bestRoute!.fuelCost = bestRouteFuelCost;
          bestRoute!.isBestRoute = true;
          // Add the best route to the displayed routes list
          disPlayedRoutes.add(bestRoute!);
        } else {
          // If the best route is the default route, mark it as the best route
          defaultRoute!.isBestRoute = true;
        }


      }
      if (disPlayedRoutes.isNotEmpty) {
       disPlayedRoutes.forEach((e){
         print('xvai ${e.cities}');
       });
        Navigator.of(context).pop();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RouteScreen(allRoutes: disPlayedRoutes),
          ),
        );
      }
    } catch (e) {
      // Handle errors as before
      Navigator.of(context).pop();
      showToast(e.toString());
    }
  }

  void showToast(String message) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        // Duration of the toast
        gravity: ToastGravity.BOTTOM,
        // Position of the toast
        backgroundColor: Colors.black,
        // Background color of the toast
        textColor: Colors.white,
        // Text color
        fontSize: 16.0 // Font size
        );
  }
}



 */