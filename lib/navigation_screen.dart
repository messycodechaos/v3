import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'map_service.dart';
import 'nav_models.dart';
import 'dart:async';

class NavHubScreen extends StatefulWidget {
  const NavHubScreen({super.key});
  @override State<NavHubScreen> createState() => _NavHubState();
}

class _NavHubState extends State<NavHubScreen> {
  final MapController _mapCtrl = MapController();
  final MapService _service = MapService();
  final TextEditingController _searchCtrl = TextEditingController();

  LatLng _userPos = const LatLng(28.6139, 77.2090);
  List<SafetyPlace> _nearbyMarkers = [];
  List<NavRoute> _routes = [];
  int _selectedRouteIdx = 0;
  bool _isNavigating = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _startLiveTracking();
  }

  void _startLiveTracking() {
    Geolocator.getPositionStream(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5)).listen((pos) {
      setState(() => _userPos = LatLng(pos.latitude, pos.longitude));
      if (_isNavigating) _mapCtrl.move(_userPos, 17.5);
    });
  }

  void _onDestSelected(LatLng dest) async {
    setState(() => _loading = true);
    var routes = await _service.getMultiRoutes(_userPos, dest);
    setState(() { _routes = routes; _selectedRouteIdx = 0; _isNavigating = false; _loading = false; });
    _mapCtrl.move(dest, 14.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapCtrl,
            options: MapOptions(initialCenter: _userPos, initialZoom: 15),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
              if (_routes.isNotEmpty) PolylineLayer(polylines: _routes.asMap().entries.map((e) {
                bool isSel = e.key == _selectedRouteIdx;
                return Polyline(points: e.value.points, color: isSel ? e.value.routeColor : e.value.routeColor.withOpacity(0.3), strokeWidth: isSel ? 8 : 4);
              }).toList()),
              MarkerLayer(markers: [
                Marker(point: _userPos, child: const Icon(Icons.navigation, color: Colors.blue, size: 40)),
                ..._nearbyMarkers.map((p) => Marker(point: p.location, child: GestureDetector(onTap: () => _onDestSelected(p.location), child: const Icon(Icons.location_on, color: Colors.red, size: 35)))),
              ]),
            ],
          ),

          if (!_isNavigating) Positioned(top: 50, left: 15, right: 15, child: Column(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)]),
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(hintText: "Where to?", border: InputBorder.none, suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: () async {
                  LatLng? target = await _service.searchPlace(_searchCtrl.text);
                  if (target != null) _onDestSelected(target);
                })),
              ),
            ),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              _chip("Police", Icons.local_police, Colors.blue, "police"),
              _chip("Hospital", Icons.local_hospital, Colors.red, "hospital"),
            ]),
          ])),

          if (_routes.isNotEmpty && !_isNavigating) Positioned(bottom: 0, left: 0, right: 0, child: Container(
            height: 250, decoration: const BoxDecoration(color: Color(0xFF1A1F3C), borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
            child: Column(children: [
              const SizedBox(height: 10),
              const Text("Select Route", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Expanded(child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: _routes.length, itemBuilder: (c, i) => _routeCard(i))),
              ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size(250, 50)), onPressed: () => setState(() => _isNavigating = true), child: const Text("START IN-APP NAV")),
              const SizedBox(height: 15),
            ]),
          )),

          if (_isNavigating) Positioned(top: 50, left: 15, right: 15, child: Container(
            padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(15)),
            child: Row(children: [
              const Icon(Icons.assistant_direction, color: Colors.white, size: 35),
              const SizedBox(width: 15),
              Expanded(child: Text(_routes[_selectedRouteIdx].instructions[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              IconButton(onPressed: () => setState(() => _isNavigating = false), icon: const Icon(Icons.close, color: Colors.white))
            ]),
          )),
          if (_loading) const Center(child: CircularProgressIndicator(color: Colors.redAccent)),
        ],
      ),
    );
  }

  Widget _routeCard(int i) {
    var r = _routes[i]; bool isSel = _selectedRouteIdx == i;
    return GestureDetector(
      onTap: () => setState(() => _selectedRouteIdx = i),
      child: Container(
        width: 160, margin: const EdgeInsets.all(10), padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: isSel ? r.routeColor.withOpacity(0.2) : Colors.white10, borderRadius: BorderRadius.circular(15), border: Border.all(color: isSel ? r.routeColor : Colors.transparent, width: 2)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(r.summary, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const Spacer(),
          Text("${r.distanceKm.toStringAsFixed(1)} km", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          Text("${r.durationMin.toStringAsFixed(0)} mins", style: const TextStyle(color: Colors.white70)),
        ]),
      ),
    );
  }

  Widget _chip(String label, IconData icon, Color color, String type) {
    return ActionChip(avatar: Icon(icon, color: Colors.white, size: 16), label: Text(label), backgroundColor: color, onPressed: () async {
      var p = await _service.findNearby(_userPos, type);
      setState(() => _nearbyMarkers = p);
    });
  }
}