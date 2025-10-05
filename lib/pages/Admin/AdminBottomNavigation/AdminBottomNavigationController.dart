import 'package:get/get.dart';

class AdminBottomNavigationController extends GetxController {
  // Observable for selected index
  var selectedIndex = 0.obs;

  // Change index method
  void onItemTapped(int index) {
    selectedIndex.value = index;
  }
}
