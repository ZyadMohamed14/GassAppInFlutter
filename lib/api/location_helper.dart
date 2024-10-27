import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../model/constans.dart';
import '../model/place_direction.dart';
class LocationHelper {
  static Future<Position> getCurrentLocation() async {
    bool isServicesEnabel = await Geolocator.isLocationServiceEnabled();

    if (!isServicesEnabel) {
      await Geolocator.requestPermission();
    }
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  static Future<bool> checkPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      // If permission is already granted, return true
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        return true;
      }

      // Request permission if it is denied
      permission = await Geolocator.requestPermission();

      // Return true if permission is granted, false otherwise
      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (e) {
      // Log the exception or handle it as needed
      print('Error checking or requesting location permission: $e');
      return false; // Return false if there's an error
    }
  }

  static Future<Either<String, Location>> getLatLngFromAddress(String address) async {
    // Make sure to handle permissions if needed
    if (await checkPermission()) {
      try {
        String fullAddress = "$address, Egypt";
        List<Location> locations = await locationFromAddress(fullAddress);

        if (locations.isNotEmpty) {
          Location location = locations.first;

          // Check if the latitude and longitude match the specified coordinates
          if (location.latitude == 26.820553 && location.longitude == 30.802498000000003) {
            return Left(' Cannot find the city'); // Return error if coordinates match
          }

          return Right(location); // Success if coordinates do not match
        } else {
          return Left('No locations found for the address'); // Error if no locations found
        }
      } catch (e) {
        return Left('Error getting location: $e'); // Error handling
      }
    } else {
      // Handle the case where the permission is denied and return a Left
      return Left('Please enable your location'); // Error when location is disabled
    }
  }

  static Future<Either<String, String>> getAddressFromLatLng(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks[0];
        String address = '${placemark.street}, ${placemark.locality}, ${placemark.country}';
        return Right(address); // Return address on success
      } else {
        return Left('Address not found');
      }
    } catch (e) {
      return Left('Error: $e');
    }
  }
  static Future<PlaceDirections> getDirections(LatLng origin, LatLng destination) async {
    Dio dio;
    BaseOptions options = BaseOptions(
      connectTimeout: Duration(seconds: 20),
      receiveTimeout: Duration(seconds: 20),
      receiveDataWhenStatusError: true,
    );
    dio = Dio(options);
    try {
      Response response = await dio.get(
        directionsBaseUrl,
        queryParameters: {
          'origin': '${origin.latitude},${origin.longitude}',
          'destination': '${destination.latitude},${destination.longitude}',
          'key': googleAPIKey,
        },
      );
      print("Response Data: ${response.data}");

      // Parse the response into a PlaceDirections object
      return PlaceDirections.fromJson(response.data);
    } catch (error) {
      return Future.error("Place location error: $error", StackTrace.current);
    }
  }


}
