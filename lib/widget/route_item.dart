import 'package:flutter/material.dart';
import 'package:gasapp/model/city_route.dart';
import 'package:gasapp/screens/map_screen.dart';
import 'package:get/get.dart';

class RouteItem extends StatelessWidget {
  final CitiesRoute citiesRoute;

  RouteItem({required this.citiesRoute});

  @override
  Widget build(BuildContext context) {
    int size = citiesRoute.cities.length;
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Card(
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Cities: ",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Container(
                  width: double.infinity, // Set width to take available space
                  child: ListView.builder(
                    shrinkWrap: true, // Allows ListView to take the size of its children
                    physics: NeverScrollableScrollPhysics(), // Prevent scrolling in ListView
                    itemCount: size,
                    itemBuilder: (context, index) {
                      return cityItem(
                        citiesRoute.cities[index],
                        index,
                        size,

                      );
                    },
                  ),
                ),
                 SizedBox(height: 10,),
                Row(
                  children: [
                    Text(
                      "Distance: ",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    Expanded(
                      child: Text(
                        "${citiesRoute.distance.toStringAsFixed(2)} km",
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      "Fuel Cost: ",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    Expanded(
                      child: Text(
                        "${citiesRoute.fuelCost.toStringAsFixed(2)} EGP",
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      "Time: ",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    Expanded(
                      child: Text(
                        formatTime(citiesRoute.time),
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
                if (citiesRoute.isBestRoute)
                  Center(
                    child: Text(
                      "Best Route",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ),
                Center(child: ElevatedButton(onPressed: (){
                  openMap(context, citiesRoute);
                }, child: Text('Show Details on Map')))
              ],
            ),
          ),
        ),
    );

  }

  Widget cityItem(String cityName, int index, int listSize) {
    return
        // Circular Icon with city icon inside
        Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18, // Set the size of the circle
                  backgroundColor: Colors.green, // Green background
                  child: Icon(
                    Icons.location_city, // City icon
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 10,),
                // Route Name Text
                Text(
                    cityName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),

                ),
              ],
            ),
            // Vertical divider if it's not the last item
            if (index != listSize-1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 17),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    height: 40, // Set the height of the divider
                    width: 2, // Divider thickness
                    color: Colors.grey, // Divider color
                  ),
                ),
              ),



          ],


    );
  }
  void openMap(BuildContext context,CitiesRoute city){
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapScreen(citiesRoute:city ,),
      ),
    );
  }
}

String formatTime(int timeInMinutes) {
  // Get the whole number of hours
  int hours = timeInMinutes ~/ 60;

  // Get the remaining minutes
  int minutes = timeInMinutes % 60;

  // Handle different scenarios based on time
  if (hours > 0 && minutes > 0) {
    // If both hours and minutes are present
    return "$hours hour${hours == 1 ? '' : 's'} and $minutes minute${minutes == 1 ? '' : 's'}";
  } else if (hours > 0) {
    // If only hours are present
    return "$hours hour${hours == 1 ? '' : 's'}";
  } else {
    // If only minutes are present
    return "$minutes minute${minutes == 1 ? '' : 's'}";
  }
}


