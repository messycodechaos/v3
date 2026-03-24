import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart'; // Added for persistent code
import 'dart:math'; // Added for code generation

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

class MapViewScreen extends StatelessWidget {
  const MapViewScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("Safe Routes")), body: const Center(child: Text("Map Integrated")));
}