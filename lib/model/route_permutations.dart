import 'package:dartx/dartx.dart';

class RoutePermutations {
  static List<List<String>> generateRoutes(List<String> locations, String startLocation) {
    List<List<String>> result = [];
    List<String> tempList = List<String>.from(locations);
    tempList.remove(startLocation);  // Start location will be fixed at the beginning
    _generatePermutations(tempList, 0, result, startLocation);
    return result;
  }

  static void _generatePermutations(List<String> list, int index, List<List<String>> result, String startLocation) {
    if (index == list.length) {
      List<String> route = [startLocation];
      route.addAll(list);
      result.add(route);
    } else {
      for (int i = index; i < list.length; i++) {
        _swap(list, index, i);
        _generatePermutations(list, index + 1, result, startLocation);
        _swap(list, index, i);  // backtrack
      }
    }
  }

  static void _swap(List<String> list, int i, int j) {
    String temp = list[i];
    list[i] = list[j];
    list[j] = temp;
  }
}
