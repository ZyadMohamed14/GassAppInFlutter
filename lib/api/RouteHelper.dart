import '../model/distance_time.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../model/place_direction.dart';
import 'location_helper.dart';
class RouteHelper{
  Map<String, DistanceAndTime> distanceCache = {};

   Future<DistanceAndTime> calculateTotalDistance(
      List<String> route, Map<String, LatLng> locationCache) async {
    double totalDistance = 0.0;
    int totalTime = 0;

    for (int i = 0; i < route.length - 1; i++) {
      String routeKey = '${route[i]}-${route[i + 1]}';
      if (distanceCache.containsKey(routeKey)) {
        // Use cached distance and time
        DistanceAndTime cachedData = distanceCache[routeKey]!;
        totalDistance += cachedData.totalDistance;
        totalTime += cachedData.totalTime;
      } else {
        // Fetch new data and cache it
        LatLng? cityLocation = locationCache[route[i]];
        LatLng? nextCityLocation = locationCache[route[i + 1]];
        PlaceDirections response = await LocationHelper.getDirections(cityLocation!, nextCityLocation!);

        double distance = double.parse(response.totalDistance.replaceAll(' km', ''));
        int duration = _convertDurationToMinutes(response.totalDuration);

        totalDistance += distance;
        totalTime += duration;

        distanceCache[routeKey] = DistanceAndTime(totalDistance: distance, totalTime: duration);
      }
    }
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

}