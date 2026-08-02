import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({
    super.key,
    this.initialValue,
    this.enableLiveLocation = true,
  });

  final String? initialValue;
  final bool enableLiveLocation;

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  static const _fallbackCenter = LatLng(55.9421, -3.1913);
  static const _fallbackPlaces = <_NearbyPlace>[
    _NearbyPlace(
      name: 'Papa John’s',
      address: '114 Dundees Street, Edinburgh',
      distance: 86,
      point: LatLng(55.9423, -3.1907),
    ),
    _NearbyPlace(
      name: 'SCOTMID',
      address: '114 Dundee Street, Edinburgh',
      distance: 95,
      point: LatLng(55.9418, -3.1902),
    ),
    _NearbyPlace(
      name: 'Yugo Arran House',
      address: '5 Drysdale Road, Edinburgh',
      distance: 100,
      point: LatLng(55.9414, -3.1921),
    ),
    _NearbyPlace(
      name: 'Co-op Food',
      address: 'Earl Grey Street, Edinburgh',
      distance: 180,
      point: LatLng(55.9435, -3.1910),
    ),
    _NearbyPlace(
      name: 'Lochrin Basin',
      address: 'Lochrin, Edinburgh',
      distance: 230,
      point: LatLng(55.9419, -3.1950),
    ),
  ];

  final _mapController = MapController();
  final _searchController = TextEditingController();
  LatLng _center = _fallbackCenter;
  List<_NearbyPlace> _places = _fallbackPlaces;
  _NearbyPlace? _selected;
  bool _locating = false;
  bool _showFallbackMap = true;
  String? _locationNotice;

  @override
  void initState() {
    super.initState();
    _selected = _places.cast<_NearbyPlace?>().firstWhere(
      (place) => place?.name == widget.initialValue,
      orElse: () => _places.first,
    );
    if (widget.enableLiveLocation) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadNearby());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNearby() async {
    setState(() {
      _locating = true;
      _locationNotice = null;
    });
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw const _LocationFallback('Location permission was not granted');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      final center = LatLng(position.latitude, position.longitude);
      final nearby = await _fetchNearby(center);
      if (!mounted) return;
      setState(() {
        _center = center;
        _showFallbackMap = false;
        if (nearby.isNotEmpty) {
          _places = nearby;
          _selected = nearby.first;
        }
      });
      _mapController.move(center, 15.5);
    } on _LocationFallback catch (error) {
      if (mounted) setState(() => _locationNotice = error.message);
    } catch (_) {
      if (mounted) {
        setState(() {
          _locationNotice =
              'Using the sample area because live location is unavailable.';
        });
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<List<_NearbyPlace>> _fetchNearby(LatLng center) async {
    final query =
        '''
[out:json][timeout:12];
(
  node(around:900,${center.latitude},${center.longitude})["name"]["amenity"];
  node(around:900,${center.latitude},${center.longitude})["name"]["shop"];
  node(around:900,${center.latitude},${center.longitude})["name"]["tourism"];
  way(around:900,${center.latitude},${center.longitude})["name"]["amenity"];
  way(around:900,${center.latitude},${center.longitude})["name"]["shop"];
);
out center 30;
''';
    final response = await http
        .post(
          Uri.parse('https://overpass-api.de/api/interpreter'),
          body: {'data': query},
        )
        .timeout(const Duration(seconds: 14));
    if (response.statusCode != 200) return const [];

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final elements = (body['elements'] as List<dynamic>? ?? const []);
    final found = <_NearbyPlace>[];
    final names = <String>{};
    for (final raw in elements) {
      final item = raw as Map<String, dynamic>;
      final tags = item['tags'] as Map<String, dynamic>? ?? const {};
      final name = (tags['name'] as String?)?.trim();
      if (name == null || name.isEmpty || !names.add(name)) continue;
      final pointData = item['center'] as Map<String, dynamic>?;
      final lat =
          (item['lat'] as num?)?.toDouble() ??
          (pointData?['lat'] as num?)?.toDouble();
      final lon =
          (item['lon'] as num?)?.toDouble() ??
          (pointData?['lon'] as num?)?.toDouble();
      if (lat == null || lon == null) continue;
      final street = tags['addr:street'] as String?;
      final number = tags['addr:housenumber'] as String?;
      final city = tags['addr:city'] as String?;
      final addressParts = <String>[?number, ?street, ?city];
      final distance = Geolocator.distanceBetween(
        center.latitude,
        center.longitude,
        lat,
        lon,
      ).round();
      found.add(
        _NearbyPlace(
          name: name,
          address: addressParts.isEmpty
              ? 'Nearby place'
              : addressParts.join(', '),
          distance: distance,
          point: LatLng(lat, lon),
        ),
      );
    }
    found.sort((a, b) => a.distance.compareTo(b.distance));
    return found.take(12).toList();
  }

  List<_NearbyPlace> get _filteredPlaces {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _places;
    return _places
        .where(
          (place) =>
              place.name.toLowerCase().contains(query) ||
              place.address.toLowerCase().contains(query),
        )
        .toList();
  }

  void _choose(_NearbyPlace place) {
    setState(() => _selected = place);
    if (!_showFallbackMap) {
      _mapController.move(place.point, 16);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visiblePlaces = _filteredPlaces;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 54,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Text(
                    'My Location',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  Positioned(
                    left: 8,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.chevron_left, size: 28),
                    ),
                  ),
                  Positioned(
                    right: 25,
                    child: GestureDetector(
                      key: const Key('location-done'),
                      onTap: _selected == null
                          ? null
                          : () => Navigator.of(context).pop(_selected!.name),
                      child: Container(
                        width: 60,
                        height: 33,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE229),
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: const Text(
                          'Done',
                          style: TextStyle(
                            color: Color(0xFFC640A3),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 0, 25, 10),
              child: TextField(
                key: const Key('location-search'),
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Search',
                  prefixIcon: const Icon(Icons.search, size: 24),
                  filled: true,
                  fillColor: const Color(0xFFE7E7E7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 236,
              child: Stack(
                children: [
                  if (_showFallbackMap)
                    Positioned.fill(
                      child: Image.asset(
                        'assets/location/map.png',
                        fit: BoxFit.cover,
                        alignment: const Alignment(0, 0.12),
                      ),
                    )
                  else
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _center,
                        initialZoom: 15.5,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.mood_quiz',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _center,
                              width: 46,
                              height: 46,
                              child: const _CurrentLocationMarker(),
                            ),
                            if (_selected != null)
                              Marker(
                                point: _selected!.point,
                                width: 36,
                                height: 36,
                                child: const Icon(
                                  Icons.location_on,
                                  color: Color(0xFFFFC107),
                                  size: 34,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  if (_showFallbackMap)
                    const Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: IgnorePointer(
                        child: Center(child: _CurrentLocationMarker()),
                      ),
                    ),
                  if (_locating)
                    const Positioned(
                      right: 12,
                      top: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  if (_locationNotice != null)
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 8,
                      child: Material(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(7),
                          child: Text(
                            _locationNotice!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: visiblePlaces.isEmpty
                  ? const Center(child: Text('No nearby places found'))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 17),
                      itemCount: visiblePlaces.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, color: Color(0xFFD0D0D0)),
                      itemBuilder: (_, index) {
                        final place = visiblePlaces[index];
                        final selected = place == _selected;
                        return InkWell(
                          key: Key('location-place-$index'),
                          onTap: () => _choose(place),
                          child: SizedBox(
                            height: 55,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        place.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF333333),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${place.distance <= 100 ? '≤100m' : '${place.distance}m'} | ${place.address}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0x80333333),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (selected)
                                  const Icon(
                                    Icons.check,
                                    color: Color(0xFF59C31A),
                                    size: 25,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentLocationMarker extends StatelessWidget {
  const _CurrentLocationMarker();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: const Color(0xFF2979FF),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 5)],
        ),
      ),
    );
  }
}

class _NearbyPlace {
  const _NearbyPlace({
    required this.name,
    required this.address,
    required this.distance,
    required this.point,
  });

  final String name;
  final String address;
  final int distance;
  final LatLng point;
}

class _LocationFallback implements Exception {
  const _LocationFallback(this.message);
  final String message;
}
