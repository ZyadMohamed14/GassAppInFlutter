import 'package:flutter/material.dart';

import 'package:gasapp/widget/route_item.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../api/RouteHelper.dart';
import '../model/city_route.dart';
import '../model/route_permutations.dart';
import '../widget/dialogs.dart';


class RouteScreen extends StatelessWidget {

  final CitiesRoute defaultRoute; // Accept the list via the constructor
  final Map<String, LatLng> citiesLatLng ;
  RxList<CitiesRoute> allRoutes = <CitiesRoute>[].obs;
  RxList<CitiesRoute> disPlayedRoutes = <CitiesRoute>[].obs;
  List<List<String>> permutations = [];
  List<LatLng> directions =[];
  RxBool isSuggestedRouteRequested  =false.obs;
  late CitiesRoute  bestRoute;
   RouteHelper routeHelper = RouteHelper();
  RouteScreen({Key? key, required this.defaultRoute, required this.citiesLatLng}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Convert the passed List to an observable List


    disPlayedRoutes.add(defaultRoute);
    allRoutes.forEach((e){
      print('RouteScreensssss${e.cities}');
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Routes')),
      body: Obx(() {
        if (disPlayedRoutes.isEmpty) {
          // Display a message when there are no routes
          return const Center(child: Text('No routes available'));
        } else {
          // Display the ListView with available routes
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: disPlayedRoutes.length,
                  itemBuilder: (context, index) {
                    return RouteItem(citiesRoute: disPlayedRoutes[index]);
                  },
                ),
              ),
              const SizedBox(height: 8,),
              if (!isSuggestedRouteRequested.value)
                // Show button
                ElevatedButton(
                  onPressed: () {
                    // Define your onPressed functionality here
                    suggestBestRoute(context);
                  },
                  child: const Text('Suggest Better Route'),
                ),

            ],

          );
        }
      }),
    );
  }
  void suggestBestRoute(BuildContext context) async {
    showLoadingDialog(context,"Calulating....");
    try{
      allRoutes.add(defaultRoute);

      permutations.addAll(RoutePermutations.generateRoutes(defaultRoute.cities, defaultRoute.cities.first));


      for (var route in permutations) {
        var routeDistanceAndTime = await routeHelper.calculateTotalDistance(route, citiesLatLng);
        directions = route.map((cityName) => citiesLatLng[cityName]!).toList();

        allRoutes.add(
          CitiesRoute(
            distance: routeDistanceAndTime.totalDistance,
            cities: route,
            directions: directions,
            time: routeDistanceAndTime.totalTime,
          ),
        );
      }

      allRoutes.sort((d1, d2) => d1.distance.compareTo(d2.distance));
      bestRoute = allRoutes.firstWhere(
            (route) => route.cities.first == defaultRoute.cities.first,
      );
      if ( bestRoute != defaultRoute) {
        disPlayedRoutes.add(bestRoute);
        bestRoute.isBestRoute = true;
      } else {
        defaultRoute.isBestRoute = true;
      }
      print("suggestBestRoute ${defaultRoute.directions.length}");
      print("suggestBestRoute ${bestRoute.directions.length}");
      // Trigger the update by setting `allRoutes.value`
      disPlayedRoutes.value = List.from(disPlayedRoutes);
      isSuggestedRouteRequested.value=true;
      Navigator.of(context).pop();
    }
    catch (e) {
      // Handle errors as before
      Navigator.of(context).pop();
      showToast(e.toString());
    }

  }

}
