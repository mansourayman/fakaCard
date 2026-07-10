import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  const ConnectivityService();

  Future<bool> isUsingMobileData() async {
    final result = await Connectivity().checkConnectivity();
    return result.contains(ConnectivityResult.mobile);
  }
}
