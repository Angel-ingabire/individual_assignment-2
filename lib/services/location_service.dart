import 'package:geolocator/geolocator.dart';

enum LocationAccessState {
  granted,
  denied,
  deniedForever,
  serviceDisabled,
}

class LocationService {
  Future<LocationAccessState> ensurePermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return LocationAccessState.serviceDisabled;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return LocationAccessState.denied;
    }

    if (permission == LocationPermission.deniedForever) {
      return LocationAccessState.deniedForever;
    }

    return LocationAccessState.granted;
  }
}

