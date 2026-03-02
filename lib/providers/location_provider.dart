import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/location_service.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final locationAccessProvider = FutureProvider<LocationAccessState>((ref) async {
  final svc = ref.watch(locationServiceProvider);
  return svc.ensurePermission();
});

