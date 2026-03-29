import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart'; // Added for persistent code
import 'dart:math'; // Added for code generation
import 'package:flutter_map/flutter_map.dart'; // Free map
import 'package:latlong2/latlong.dart';       // Coordinates
import 'package:geolocator/geolocator.dart';  // Location
import 'package:http/http.dart' as http;      // To get the route
import 'dart:convert';
import 'dart:async';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'dart:ui';
// To read the route data
// Importing your specific files
import 'sos_model.dart';
import 'camera_service.dart';
import 'host_screen.dart';
import 'viewer_screen.dart';

// --- NEW: REMOTE MANAGER CLASS (Handles persistent code & history) ---
class RemoteManager {
  static final RemoteManager _instance = RemoteManager._internal();
  factory RemoteManager() => _instance;
  RemoteManager._internal();

  IO.Socket? socket;
  String? myHostCode;
  List<String> roomHistory = [];

  Future<void> init() async {
    // Initialize Socket
    socket = IO.io('https://safely-871c.onrender.com', IO.OptionBuilder().setTransports(['websocket']).build());

    // Load Saved Data
    SharedPreferences prefs = await SharedPreferences.getInstance();
    myHostCode = prefs.getString('my_host_code');
    roomHistory = prefs.getStringList('view_history') ?? [];

    // Generate permanent code if it doesn't exist
    if (myHostCode == null) {
      myHostCode = (1000 + Random().nextInt(9000)).toString();
      await prefs.setString('my_host_code', myHostCode!);
    }
  }

  Future<void> saveToHistory(String code) async {
    if (roomHistory.contains(code) || code.isEmpty) return;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    roomHistory.insert(0, code);
    if (roomHistory.length > 5) roomHistory.removeLast();
    await prefs.setStringList('view_history', roomHistory);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RemoteManager().init(); // Initialize code & socket before app starts
  runApp(const GuardianXApp());
}

class GuardianXApp extends StatelessWidget {
  const GuardianXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GuardianX',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0E21),
        primaryColor: Colors.redAccent,
        cardTheme: const CardThemeData(
          color: Color(0xFF1D1E33),
          elevation: 10,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// --- 1. SPLASH SCREEN (UNCHANGED) ---
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AuthScreen()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.redAccent, width: 2)),
              child: const Icon(Icons.shield, size: 80, color: Colors.redAccent),
            ),
            const SizedBox(height: 24),
            const Text("GUARDIAN X", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 4)),
            const Text("AI SAFETY REDEFINED", style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// --- 2. AUTH SCREEN (UNCHANGED) ---
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(isLogin ? "Welcome Back" : "Join GuardianX", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            TextField(decoration: InputDecoration(labelText: "Email", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 20),
            TextField(obscureText: true, decoration: InputDecoration(labelText: "Password", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainNavigation())),
                child: Text(isLogin ? "LOGIN" : "SIGN UP"),
              ),
            ),
            TextButton(onPressed: () => setState(() => isLogin = !isLogin), child: Text(isLogin ? "Create an account" : "Have an account? Login"))
          ],
        ),
      ),
    );
  }
}

// --- 3. MAIN NAVIGATION ---
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  List<EmergencyContact> myContacts = [
    EmergencyContact(id: "1", name: "Mom", number: "911", relation: "Family"),
  ];

  late List<SOSLevel> myLevels = [
    SOSLevel(name: "Lvl 1: Caution", color: Colors.amber, customMessage: "Just checking in...", activationGesture: "Single Tap", liveStream: false),
    SOSLevel(name: "Lvl 2: Warning", color: Colors.orange, recordAudio: true, customMessage: "I feel unsafe...", activationGesture: "Double Tap", liveStream: false),
    SOSLevel(name: "Lvl 3: Critical", color: Colors.red, recordVideo: true, notifyPolice: true, customMessage: "EMERGENCY!", activationGesture: "Long Press", liveStream: true),
  ];

  List<EvidenceRecord> vault = [
    EvidenceRecord(date: "2023-11-15", type: "Video", duration: "0:45", level: "Lvl 3"),
    EvidenceRecord(date: "2023-11-10", type: "Audio", duration: "1:20", level: "Lvl 2"),
  ];

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const HomeScreen(levels: []), // Passed levels inside the widget itself now
      const MapViewScreen(),
      GuardianScreen(contacts: myContacts, onUpdate: (list) => setState(() => myContacts = list)),
      ConfigScreen(levels: myLevels, onUpdate: (list) => setState(() => myLevels = list)),
      AIScreen(),
      VaultScreen(records: vault),
      const ViewerEntryScreen(),
    ];

    return Scaffold(
      body: _currentIndex == 0 ? HomeScreen(levels: myLevels) : screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.redAccent,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.shield), label: "SOS"),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: "Map"),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Contacts"),
          BottomNavigationBarItem(icon: Icon(Icons.tune), label: "Config"),
          BottomNavigationBarItem(icon: Icon(Icons.psychology), label: "AI"),
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: "Vault"),
          BottomNavigationBarItem(icon: Icon(Icons.visibility), label: "Viewer"),
        ],
      ),
    );
  }
}

// --- 4. HOME: THE SOS HUB (UPDATED WITH TAP SYSTEM) ---
class HomeScreen extends StatefulWidget {
  final List<SOSLevel> levels;
  const HomeScreen({super.key, required this.levels});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tapCount = 0;
  bool _isGenerated = false;

  void trigger(BuildContext context, SOSLevel lvl) async {
    if (!_isGenerated) return; // Prevent SOS until code is generated

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: lvl.color,
      content: Text("ACTIVATED: ${lvl.name}"),
    ));

    if (lvl.liveStream) {
      String code = RemoteManager().myHostCode!;
      bool success = await CameraService().startStreaming(RemoteManager().socket!, code);
      if (success && context.mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => HostScreen(roomCode: code)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isGenerated ? "YOUR PERSONAL HOST CODE" : "TAP SYSTEM LOCKED",
          style: const TextStyle(color: Colors.grey, letterSpacing: 2),
        ),
        Text(
          _isGenerated ? RemoteManager().myHostCode! : "Tap Shield 3x to Generate",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: _isGenerated ? Colors.blueAccent : Colors.grey.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 40),
        Center(
          child: GestureDetector(
            onTap: () {
              if (!_isGenerated) {
                _tapCount++;
                if (_tapCount >= 3) {
                  setState(() => _isGenerated = true);
                }
              } else {
                trigger(context, widget.levels[0]);
              }
            },
            onDoubleTap: () => trigger(context, widget.levels[1]),
            onLongPress: () => trigger(context, widget.levels[2]),
            child: Container(
              height: 280, width: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isGenerated ? Colors.blue.withOpacity(0.05) : Colors.red.withOpacity(0.05),
                border: Border.all(
                  color: _isGenerated ? Colors.blueAccent : Colors.redAccent.withOpacity(0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _isGenerated ? Colors.blueAccent.withOpacity(0.2) : Colors.redAccent.withOpacity(0.2),
                    blurRadius: 40,
                  )
                ],
              ),
              child: Center(
                child: Container(
                  height: 200, width: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isGenerated ? Colors.blueAccent : Colors.redAccent,
                  ),
                  child: Icon(
                    _isGenerated ? Icons.check_circle : Icons.power_settings_new,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
        Text(
          _isGenerated ? "System Active: Long Press for Critical" : "Tap system to unlock host functions",
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}

// --- VIEWER ENTRY SCREEN ---
class ViewerEntryScreen extends StatefulWidget {
  const ViewerEntryScreen({super.key});
  @override
  State<ViewerEntryScreen> createState() => _ViewerEntryScreenState();
}

class _ViewerEntryScreenState extends State<ViewerEntryScreen> {
  final TextEditingController _viewCtrl = TextEditingController();
  @override
  Widget build(BuildContext context) {
    var mgr = RemoteManager();
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 60),
          const Text("ENTER GUARDIAN CODE", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          TextField(
            controller: _viewCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: "Room Code",
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.play_arrow),
                onPressed: () async {
                  await mgr.saveToHistory(_viewCtrl.text);
                  if (mounted) {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ViewerScreen(socket: mgr.socket!, roomCode: _viewCtrl.text)));
                    setState(() {});
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 30),
          const Align(alignment: Alignment.centerLeft, child: Text("RECENT ROOMS:")),
          Expanded(
            child: ListView.builder(
              itemCount: mgr.roomHistory.length,
              itemBuilder: (context, index) => ListTile(
                leading: const Icon(Icons.history),
                title: Text("Room ${mgr.roomHistory[index]}"),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ViewerScreen(socket: mgr.socket!, roomCode: mgr.roomHistory[index])));
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}

// --- 5. CONFIG SCREEN (UNCHANGED) ---
class ConfigScreen extends StatefulWidget {
  final List<SOSLevel> levels;
  final Function(List<SOSLevel>) onUpdate;
  const ConfigScreen({super.key, required this.levels, required this.onUpdate});
  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SOS Customization"),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.redAccent,
          tabs: const [Tab(text: "Lvl 1"), Tab(text: "Lvl 2"), Tab(text: "Lvl 3")],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: widget.levels.map((lvl) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text("Action Profile: ${lvl.name}", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: lvl.color)),
            const Divider(height: 30),
            _buildSwitch("Send Location SMS", lvl.sendSMS, (v) => setState(() => lvl.sendSMS = v)),
            _buildSwitch("Auto Audio Recording", lvl.recordAudio, (v) => setState(() => lvl.recordAudio = v)),
            _buildSwitch("Auto Video Recording", lvl.recordVideo, (v) => setState(() => lvl.recordVideo = v)),
            _buildSwitch("Enable Auto Live Stream", lvl.liveStream, (v) => setState(() => lvl.liveStream = v)),
            _buildSwitch("Notify Authorities", lvl.notifyPolice, (v) => setState(() => lvl.notifyPolice = v)),
            const SizedBox(height: 20),
            TextField(
              maxLines: 3,
              decoration: InputDecoration(labelText: "Emergency Message", border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
              onChanged: (v) => lvl.customMessage = v,
              controller: TextEditingController(text: lvl.customMessage),
            ),
          ],
        )).toList(),
      ),
    );
  }
  Widget _buildSwitch(String t, bool v, Function(bool) c) => SwitchListTile(activeColor: Colors.redAccent, title: Text(t), value: v, onChanged: c);
}

// --- 6. GUARDIAN (UNCHANGED) ---
class GuardianScreen extends StatelessWidget {
  final List<EmergencyContact> contacts;
  final Function(List<EmergencyContact>) onUpdate;
  const GuardianScreen({super.key, required this.contacts, required this.onUpdate});

  void _add(BuildContext context) {
    final n = TextEditingController();
    final p = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("New Guardian"),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: n, decoration: const InputDecoration(labelText: "Name")),
        TextField(controller: p, decoration: const InputDecoration(labelText: "Phone")),
      ]),
      actions: [ElevatedButton(onPressed: () { contacts.add(EmergencyContact(id: DateTime.now().toString(), name: n.text, number: p.text)); onUpdate(contacts); Navigator.pop(ctx); }, child: const Text("Save"))],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Trusted Guardians")),
      floatingActionButton: FloatingActionButton(backgroundColor: Colors.redAccent, onPressed: () => _add(context), child: const Icon(Icons.person_add)),
      body: ListView.builder(
        itemCount: contacts.length,
        itemBuilder: (ctx, i) => Card(
          margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.redAccent, child: Icon(Icons.person, color: Colors.white)),
            title: Text(contacts[i].name),
            subtitle: Text(contacts[i].number),
            trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.grey), onPressed: () { contacts.removeAt(i); onUpdate(contacts); }),
          ),
        ),
      ),
    );
  }
}

// --- 7. AI FEATURES (UNCHANGED) ---
class AIScreen extends StatefulWidget {
  @override
  State<AIScreen> createState() => _AIScreenState();
}
class _AIScreenState extends State<AIScreen> {
  bool vDistress = false; bool mDetection = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AI Guardian Settings")),
      body: ListView(
        children: [
          SwitchListTile(title: const Text("Voice Distress Detection"), value: vDistress, onChanged: (v) => setState(() => vDistress = v)),
          SwitchListTile(title: const Text("Suspicious Movement"), value: mDetection, onChanged: (v) => setState(() => mDetection = v)),
        ],
      ),
    );
  }
}

// --- 8. VAULT & MAP (UNCHANGED) ---
class VaultScreen extends StatelessWidget {
  final List<EvidenceRecord> records;
  const VaultScreen({super.key, required this.records});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("Evidence Vault")), body: ListView.builder(itemCount: records.length, itemBuilder: (ctx, i) => ListTile(leading: Icon(records[i].type == "Video" ? Icons.videocam : Icons.mic, color: Colors.redAccent), title: Text("${records[i].type} - ${records[i].level}"), subtitle: Text(records[i].date))));
}



class MapViewScreen extends StatefulWidget {
  const MapViewScreen({super.key});
  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> with TickerProviderStateMixin {
  late final _mapController = AnimatedMapController(vsync: this);
  final TextEditingController _startCtrl = TextEditingController();
  final TextEditingController _destCtrl = TextEditingController();

  List<Map<String, dynamic>> _allRoutes = [];
  List<Marker> _poiMarkers = [];
  List<Map<String, dynamic>> _safetyPlacesList = [];

  int _selectedIndex = 0;
  bool _isLoading = false;
  bool _isNavigating = false;
  LatLng _userPos = const LatLng(28.6139, 77.2090);

  @override
  void initState() {
    super.initState();
    _initUserPos();
  }

  Future<void> _initUserPos() async {
    Position pos = await Geolocator.getCurrentPosition();
    setState(() => _userPos = LatLng(pos.latitude, pos.longitude));
    _mapController.animateTo(dest: _userPos, zoom: 15);
  }

  Future<void> _useCurrentLocation() async {
    Position pos = await Geolocator.getCurrentPosition();
    setState(() {
      _userPos = LatLng(pos.latitude, pos.longitude);
      _startCtrl.text = "My Current Location";
    });
    _mapController.animateTo(dest: _userPos, zoom: 15);
  }

  // --- FIXED POI SCANNER ---
// --- ENHANCED POI SCANNER ---
  Future<void> _fetchSafetyPOIs(LatLng center) async {
    setState(() => _safetyPlacesList = []); // Clear old list

    // Expanded query to include police, hospital, worship, food, and shops
    final query = """
    [out:json][timeout:25];
    (
      node["amenity"~"police|hospital|clinic|doctors|place_of_worship|restaurant|cafe|fast_food|food_court"](around:3000, ${center.latitude}, ${center.longitude});
      node["shop"~"supermarket|marketplace|convenience"](around:3000, ${center.latitude}, ${center.longitude});
    );
    out body;
    """;

    final url = 'https://overpass-api.de/api/interpreter?data=${Uri.encodeComponent(query)}';

    try {
      final res = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'GuardianX_Safety_App/1.0'},
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        List<Marker> markers = [];
        List<Map<String, dynamic>> places = [];

        for (var e in data['elements']) {
          // Identify the type
          String amenity = e['tags']['amenity'] ?? "";
          String shop = e['tags']['shop'] ?? "";
          String name = e['tags']['name'] ?? "Public Place";

          IconData icon = Icons.location_on;
          Color color = Colors.grey;
          String displayType = "Place";

          // Police
          if (amenity == 'police') {
            icon = Icons.local_police;
            color = Colors.blue.shade800;
            displayType = "Police Station";
          }
          // Hospitals / Medical
          else if (amenity == 'hospital' || amenity == 'clinic' || amenity == 'doctors') {
            icon = Icons.local_hospital;
            color = Colors.red;
            displayType = "Medical";
          }
          // Religious / Temples / Gurudwaras
          else if (amenity == 'place_of_worship') {
            icon = Icons.account_balance; // Generic landmark icon
            color = Colors.orange.shade700;
            displayType = "Religious/Temple";
          }
          // Food & Cafes
          else if (amenity == 'restaurant' || amenity == 'cafe' || amenity == 'fast_food' || amenity == 'food_court') {
            icon = (amenity == 'cafe') ? Icons.local_cafe : Icons.restaurant;
            color = Colors.brown;
            displayType = "Food/Cafe";
          }
          // Stores / Markets
          else if (shop != "") {
            icon = Icons.shopping_cart;
            color = Colors.green;
            displayType = "Market/Store";
          }

          markers.add(Marker(
            point: LatLng(e['lat'], e['lon']),
            width: 35,
            height: 35,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 4)],
              ),
              child: Icon(icon, color: color, size: 20),
            ),
          ));

          places.add({
            'name': name,
            'type': displayType,
            'icon': icon,
            'color': color
          });
        }

        setState(() {
          _poiMarkers = markers;
          _safetyPlacesList = places;
        });
      }
    } catch (e) {
      debugPrint("POI Fetch Failed: $e");
    }
  }
  Future<void> _findRoutes() async {
    if (_destCtrl.text.isEmpty) return;
    setState(() { _isLoading = true; _allRoutes = []; });

    LatLng start = (_startCtrl.text == "My Current Location" || _startCtrl.text.isEmpty)
        ? _userPos
        : await _geocode(_startCtrl.text) ?? _userPos;

    LatLng? end = await _geocode(_destCtrl.text);
    if (end == null) { setState(() => _isLoading = false); return; }

    final url = 'https://router.project-osrm.org/route/v1/driving/'
        '${start.longitude},${start.latitude};${end.longitude},${end.latitude}'
        '?overview=full&geometries=geojson&alternatives=true';

    try {
      final res = await http.get(Uri.parse(url));
      final data = json.decode(res.body);

      if (data['routes'] != null) {
        List<Map<String, dynamic>> routes = [];
        for (var r in data['routes']) {
          routes.add({
            'points': (r['geometry']['coordinates'] as List).map((e) => LatLng(e[1], e[0])).toList(),
            'distance': (r['distance'] / 1000).toStringAsFixed(1),
            'duration': (r['duration'] / 60).toStringAsFixed(0),
          });
        }
        setState(() { _allRoutes = routes; _selectedIndex = 0; });
        _mapController.animatedFitCamera(
          cameraFit: CameraFit.bounds(bounds: LatLngBounds.fromPoints(routes[0]['points']), padding: const EdgeInsets.all(80)),
        );
        _fetchSafetyPOIs(end);
      }
    } catch (e) {
      debugPrint("Route Error: $e");
    }
    setState(() => _isLoading = false);
  }

  Future<LatLng?> _geocode(String address) async {
    final url = 'https://nominatim.openstreetmap.org/search?q=$address&format=json&limit=1';
    final res = await http.get(Uri.parse(url), headers: {'User-Agent': 'GuardianX'});
    final data = json.decode(res.body);
    if (data.isNotEmpty) return LatLng(double.parse(data[0]['lat']), double.parse(data[0]['lon']));
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController.mapController,
            options: MapOptions(initialCenter: _userPos, initialZoom: 15, maxZoom: 19),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
              ),
              if (_allRoutes.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    for (int i = 0; i < _allRoutes.length; i++)
                      if (i != _selectedIndex)
                        Polyline(
                          points: _allRoutes[i]['points'],
                          color: i == 1 ? Colors.purple.withOpacity(0.4) : Colors.teal.withOpacity(0.4),
                          strokeWidth: 5,
                        ),
                    Polyline(
                      points: _allRoutes[_selectedIndex]['points'],
                      color: Colors.blue,
                      strokeWidth: 8,
                    ),
                  ],
                ),
              MarkerLayer(markers: _poiMarkers),
              MarkerLayer(markers: [
                Marker(point: _userPos, child: const Icon(Icons.navigation, color: Colors.blue, size: 35)),
              ]),
            ],
          ),

          // Search Inputs
          if (!_isNavigating)
            Positioned(
              top: 50, left: 15, right: 15,
              child: _buildGlassBox(
                child: Column(
                  children: [
                    _buildInputField(_startCtrl, "Start Point", Icons.circle, Colors.green, isStart: true),
                    const Divider(height: 1, color: Colors.black12),
                    _buildInputField(_destCtrl, "Destination", Icons.location_on, Colors.red),
                    if (_isLoading) const LinearProgressIndicator(color: Colors.blue, minHeight: 2),
                  ],
                ),
              ),
            ),

          // Bottom Sheet
          if (_allRoutes.isNotEmpty && !_isNavigating)
            DraggableScrollableSheet(
              initialChildSize: 0.35,
              minChildSize: 0.2,
              maxChildSize: 0.9,
              builder: (context, scrollController) {
                return _buildGlassBox(
                  radius: const BorderRadius.vertical(top: Radius.circular(30)),
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(25),
                    children: [
                      Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10)))),
                      const SizedBox(height: 15),
                      const Text("Select Route", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
                      const SizedBox(height: 15),
                      ..._allRoutes.asMap().entries.map((e) {
                        bool sel = _selectedIndex == e.key;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedIndex = e.key),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: sel ? Colors.blue.withOpacity(0.1) : Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: sel ? Colors.blue : Colors.black12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.directions_car, color: sel ? Colors.blue : Colors.grey),
                                const SizedBox(width: 15),
                                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text("Option ${e.key + 1}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                                  Text("${e.value['duration']} mins • ${e.value['distance']} km", style: const TextStyle(color: Colors.black54)),
                                ]),
                                const Spacer(),
                                if (sel) const Icon(Icons.check_circle, color: Colors.blue),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                      const Divider(height: 40, color: Colors.black12),
                      const Text("Safety Points Nearby", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                      const SizedBox(height: 10),
                      if (_safetyPlacesList.isEmpty)
                        const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Searching for Police, Hospitals...", style: TextStyle(color: Colors.grey)))),
                      ..._safetyPlacesList.map((p) => ListTile(
                        leading: Icon(p['icon'], color: p['color']),
                        title: Text(p['name'], style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500)),
                        subtitle: Text(p['type'].toUpperCase(), style: const TextStyle(color: Colors.black45, fontSize: 11)),
                        dense: true,
                      )),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: () => setState(() => _isNavigating = true),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.all(18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                        child: const Text("START NAVIGATION", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildGlassBox({required Widget child, BorderRadius? radius}) {
    return ClipRRect(
      borderRadius: radius ?? BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95), // Solider background for text visibility
            borderRadius: radius ?? BorderRadius.circular(20),
            border: Border.all(color: Colors.black12),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildInputField(TextEditingController ctrl, String hint, IconData icon, Color color, {bool isStart = false}) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.black),
      onSubmitted: (_) => _findRoutes(),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: color, size: 18),
        suffixIcon: isStart
            ? IconButton(icon: const Icon(Icons.my_location, color: Colors.blue, size: 20), onPressed: _useCurrentLocation)
            : IconButton(icon: const Icon(Icons.search), onPressed: _findRoutes),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      ),
    );
  }
}