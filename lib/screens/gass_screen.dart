import 'package:flutter/material.dart';
import 'package:gasapp/api/RouteHelper.dart';
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

import '../widget/dialogs.dart';

class GasScreen extends StatefulWidget {
  @override
  State<GasScreen> createState() => _GasScreenState();
}

class _GasScreenState extends State<GasScreen> {
  final cityController = TextEditingController();
  final  speedController = TextEditingController();
  final  engineCCController = TextEditingController();
  RxList<String> citiesList = <String>[].obs;
  Map<String, LatLng> citiesLatLng = {}; // for default route
  Map<String, LatLng> directionsLatLng = {}; // for best route
 // List<LatLng>defaultDirectins=[];


  late LatLng cityLocation;
  int defaultSpeed = 100;
  int defaultEngineCC = 1800;
  double fuelConsumptionPer100Km = 8.5;
  double currentFuelPrice = 13.0;
  late CitiesRoute defaultRoute;
  List<CitiesRoute> allRoutes = [];
  List<CitiesRoute> disPlayedRoutes = [];
  List<String> defaultRouteList = [];

  List<List<String>> permutations = [];
  late LatLng currentLocation;
  RxBool isVaildCity = false.obs;
  late RouteHelper routeHelper;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    routeHelper =RouteHelper();
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
      appBar: AppBar(
        title: Text('Gas App'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: cityController,
                    validator: (value) =>
                    value!.isEmpty ? "Please Enter a City" : null,
                    decoration: InputDecoration(
                      hintText: 'Where to go?',
                      border: OutlineInputBorder(),
                      errorBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red, width: 1.3),
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue, width: 1.3),
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey, width: 1.3),
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
                        showToast("This City Already exists");
                        return;
                      }
                      addCity();
                    } else {
                      showToast("Please Enter a Valid City");
                      return;
                    }
                  },
                  child: Text("Add"),
                ),
              ],
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: speedController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Enter Speed (km/h)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: engineCCController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Enter Engine CC',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            Obx(() {
              return Expanded(
                child: ReorderableListView(
                  onReorder: (oldIndex, newIndex) {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final item = citiesList.removeAt(oldIndex);
                    citiesList.insert(newIndex, item);
                  },
                  children: [
                    for (int index = 0; index < citiesList.length; index++)
                      ListTile(
                        key: ValueKey(citiesList[index]),
                        title: cityListItem(city: citiesList[index]),
                      ),
                  ],
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
          onPressed: (){
            citiesList.remove(city);
            citiesLatLng.remove(city);
          },
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
        showLoadingDialog(context,"Add City....");
        cityLocation = LatLng(location.latitude, location.longitude);
        String city = cityController.text;
        citiesList.add(city);
        if(!citiesLatLng.containsKey(city)){
          citiesLatLng[city] = cityLocation;
        }


        // Dismiss the loading dialog
        Navigator.of(context).pop();
        cityController.text="";
      },
    );
  }

  double calculateFuelCost(double distance) {
    num speed = double.tryParse(speedController.text) ?? defaultSpeed;  // Speed in km/h
    num engineCC = double.tryParse(engineCCController.text) ?? defaultEngineCC;  // Engine capacity in cc



    // Adjust fuel consumption based on speed and engine CC
    double adjustedFuelConsumption = fuelConsumptionPer100Km *
        (1 + (speed / 100) * 0.1) *  // Increase consumption by 10% for every 100 km/h speed increase
        (1 + (engineCC / 1000) * 0.05);  // Increase consumption by 5% for each 1000cc of engine displacement

    // Calculate the total fuel cost
    double totalCost = (distance / 100) * adjustedFuelConsumption * currentFuelPrice; // Distance in km

    return totalCost;
  }
  double calculateTime(double distance, int speed) {
    return (distance / speed);
  }




  void gasCalculation() async {
    // Step 1: Check if we have at least two cities
    if (citiesList.length <= 1) {
      showToast("Please Provide At least 2 Cities");
      return;
    }

    showLoadingDialog(context,"Calulating....");

    try {
      // Step 2: Prepare default route

      final distanceAndTime =  await routeHelper.calculateTotalDistance(citiesList, citiesLatLng);


      // Step 3: Calculate total distance for the default route (direct order of cities)
      final defaultRouteDistance = distanceAndTime.totalDistance;
      int defaultRouteTime = distanceAndTime.totalTime;
      // Step 4: Calculate fuel cost and time for the default route
      double defaultRouteFuelCost = calculateFuelCost(
          defaultRouteDistance);
      // Step 5: Create the default route object
      defaultRoute = CitiesRoute(
        distance: defaultRouteDistance,
        cities: citiesList,
        time: defaultRouteTime,
        fuelCost: defaultRouteFuelCost,
        directions: citiesLatLng.values.toList()
      );
        print('sddsdsdsdsdsssd${defaultRoute.cities.toString()}');
        Navigator.of(context).pop();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RouteScreen(defaultRoute: defaultRoute,citiesLatLng: citiesLatLng,),
          ),
        );
     // citiesLatLng.clear();
    } catch (e) {
      // Handle errors as before
      Navigator.of(context).pop();
      showToast(e.toString());
    }
  }


}


