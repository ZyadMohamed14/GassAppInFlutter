import 'package:google_maps_flutter/google_maps_flutter.dart';

class CitiesRoute {
  double distance;
  List<String> cities;
  List<LatLng> directions;
  int time;
  double fuelCost;
  bool isBestRoute;

  // Constructor with named parameters
  CitiesRoute({
    required this.distance, // Initialize directly
    required this.cities, // Initialize directly
    this.fuelCost = 0.0, // Optional with default value
    this.time = 0, // Optional with default value
    this.isBestRoute = false,
    required this.directions,
  });

  bool isTheBestRoute() {
    return isBestRoute;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CitiesRoute &&
        other.distance == distance &&
        _listEquals(other.cities, cities) &&
        _listEquals(other.directions, directions) &&
        other.time == time &&
        other.fuelCost == fuelCost &&
        other.isBestRoute == isBestRoute;
  }

  // Helper function to compare lists
  bool _listEquals(List a, List b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }


}
