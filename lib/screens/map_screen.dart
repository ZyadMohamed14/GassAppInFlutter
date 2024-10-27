import 'package:flutter/material.dart';
import 'package:gasapp/api/location_helper.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../model/city_route.dart';
import '../model/place_direction.dart';

class MapScreen extends StatefulWidget {
  final CitiesRoute citiesRoute;

  MapScreen({required this.citiesRoute});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
   List<LatLng>directions=[] ;
   List<String>cities=[];

  @override
  void initState() {

    super.initState();

    directions.clear();
    cities.clear();
    cities.addAll(widget.citiesRoute.cities);
    directions.addAll(widget.citiesRoute.directions);
    _createMarkers();

    _createPolylines();

  }

  void _createMarkers() {
    print("ziziziiiz${cities.length}");
    print("ziziziiiz${directions.length}");
    for (int i = 0; i < directions.length; i++) {
      final LatLng position = directions[i];
      BitmapDescriptor markerColor;

      // Choose marker color based on the position in the route
      if (i == 0) {
        // Starting point marker
        markerColor = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      } else if (i == directions.length - 1) {
        // Ending point marker
        markerColor = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      } else {
        // Intermediate points
        markerColor = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      }

      _markers.add(
        Marker(
          markerId: MarkerId('marker_$i'),
          position: position,
          icon: markerColor,
          infoWindow: InfoWindow(
            title: cities[i],
            snippet: '${position.latitude}, ${position.longitude}',
          ),
        ),
      );
    }
  }


// Fetch and create polyline using PlaceDirections
  Future<void> _createPolylines() async {
    // Clear previous polylines
    _polylines.clear();

    for (int i = 0; i < directions.length - 1; i++) {
      final LatLng origin = directions[i];
      final LatLng destination = directions[i + 1];

      try {
        // Call the method to get directions
        PlaceDirections response = await LocationHelper.getDirections(origin, destination);

        // Set polyline color based on the segment index
        Color polylineColor;
        switch (i) {
          case 0:
            polylineColor = Colors.blue; // Color for the first segment
            break;
          case 1:
            polylineColor = Colors.red; // Color for the second segment
            break;
          case 2:
            polylineColor = Colors.green; // Color for the third segment
            break;
          default:
            polylineColor = Colors.orange; // Default color for subsequent segments
            break;
        }

        // Create polyline using polylinePoints from PlaceDirections
        _polylines.add(
          Polyline(
            polylineId: PolylineId('polyline_$i'),
            points: response.polylinePoints.map((point) {
              return LatLng(point.latitude, point.longitude);
            }).toList(),
            color: polylineColor, // Use the selected color
            width: 3,
          ),
        );
      } catch (e) {
        print("Error fetching directions between $origin and $destination: $e");
      }
    }

    // Refresh the UI
    setState(() {});
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        onMapCreated: (GoogleMapController controller) {
          mapController = controller;
        },
        initialCameraPosition: CameraPosition(
          target: directions.isNotEmpty
              ? directions[0] // Center the map on the first marker
              : LatLng(0, 0),
          zoom: 10,
        ),
        markers: _markers,
        polylines: _polylines,
      ),
    );
  }
}
/*
  void showDistanceAndTime() async {
    double totalDistance = 0.0;
    int totalTime = 0;

    for (int i = 0; i < directions.length - 1; i++) {
      final LatLng origin = directions[i];
      final LatLng destination = directions[i + 1];

      try {
        // Call getDirections to get the distance and duration between cities
        PlaceDirections response = await  LocationHelper.getDirections(origin, destination);

        // Extract distance and duration
        double distance = double.parse(response.totalDistance.replaceAll(' km', ''));
        int duration = _convertDurationToMinutes(response.totalDuration);

        totalDistance += distance; // Add distance to total
        totalTime += duration;     // Add time to total
      } catch (e) {
        print("Error fetching directions between $origin and $destination: $e");
      }
    }

    // Display the total distance and time
    print("Total Distance: ${totalDistance.toStringAsFixed(2)} km");
    print("Total Time: ${totalTime ~/ 60} hours and ${totalTime % 60} minutes");
  }

 */