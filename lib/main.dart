import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'sos_model.dart';
import 'dart:async';

void main() => runApp(const GuardianXApp());

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

// --- 1. SPLASH SCREEN ---
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
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.redAccent, width: 2),
              ),
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

// --- 2. AUTH SCREEN ---
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

  // GLOBAL STATE DATA
  List<EmergencyContact> myContacts = [
    EmergencyContact(id: "1", name: "Mom", number: "911", relation: "Family"),
  ];

  List<SOSLevel> myLevels = [
    SOSLevel(name: "Lvl 1: Caution", color: Colors.amber, customMessage: "Just checking in, please keep an eye on my location.", activationGesture: "Single Tap"),
    SOSLevel(name: "Lvl 2: Warning", color: Colors.orange, recordAudio: true, customMessage: "I feel unsafe. Please check on me now.", activationGesture: "Double Tap"),
    SOSLevel(name: "Lvl 3: Critical", color: Colors.red, recordVideo: true, notifyPolice: true, customMessage: "EMERGENCY! I am in danger. Send help to my location!", activationGesture: "Long Press"),
  ];

  List<EvidenceRecord> vault = [
    EvidenceRecord(date: "2023-11-15", type: "Video", duration: "0:45", level: "Lvl 3"),
    EvidenceRecord(date: "2023-11-10", type: "Audio", duration: "1:20", level: "Lvl 2"),
  ];

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(levels: myLevels),
      const MapViewScreen(),
      GuardianScreen(contacts: myContacts, onUpdate: (list) => setState(() => myContacts = list)),
      ConfigScreen(levels: myLevels, onUpdate: (list) => setState(() => myLevels = list)),
      AIScreen(),
      VaultScreen(records: vault),
    ];

    return Scaffold(
      body: screens[_currentIndex],
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
        ],
      ),
    );
  }
}

// --- 4. HOME: THE SOS HUB ---
class HomeScreen extends StatelessWidget {
  final List<SOSLevel> levels;
  const HomeScreen({super.key, required this.levels});

  void trigger(BuildContext context, SOSLevel lvl) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: lvl.color,
      content: Text("ACTIVATED: ${lvl.name}\nAction: Recording & SMS Sent!"),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("SECURITY STATUS: ACTIVE", style: TextStyle(color: Colors.green, letterSpacing: 2)),
        const SizedBox(height: 60),
        Center(
          child: GestureDetector(
            onTap: () => trigger(context, levels[0]),
            onDoubleTap: () => trigger(context, levels[1]),
            onLongPress: () => trigger(context, levels[2]),
            child: Container(
              height: 280, width: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withOpacity(0.05),
                border: Border.all(color: Colors.redAccent.withOpacity(0.5), width: 2),
                boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.2), blurRadius: 40)],
              ),
              child: Center(
                child: Container(
                  height: 200, width: 200,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.redAccent),
                  child: const Icon(Icons.power_settings_new, size: 80, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
        Text(levels[2].activationGesture + " for Critical Alert", style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}

// --- 5. CONFIG: 3-LEVEL SOS DETAILING ---
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
            _buildSwitch("Notify Authorities", lvl.notifyPolice, (v) => setState(() => lvl.notifyPolice = v)),
            const SizedBox(height: 20),
            TextField(
              maxLines: 3,
              decoration: InputDecoration(labelText: "Emergency Message", border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
              onChanged: (v) => lvl.customMessage = v,
              controller: TextEditingController(text: lvl.customMessage),
            ),
            const SizedBox(height: 20),
            ListTile(
              title: const Text("Trigger Gesture"),
              trailing: DropdownButton<String>(
                value: lvl.activationGesture,
                items: ["Single Tap", "Double Tap", "Long Press", "Triple Tap"].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setState(() => lvl.activationGesture = v!),
              ),
            ),
          ],
        )).toList(),
      ),
    );
  }

  Widget _buildSwitch(String t, bool v, Function(bool) c) => SwitchListTile(activeColor: Colors.redAccent, title: Text(t), value: v, onChanged: c);
}

// --- 6. GUARDIAN: CONTACT MANAGEMENT ---
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
      actions: [
        ElevatedButton(onPressed: () {
          contacts.add(EmergencyContact(id: DateTime.now().toString(), name: n.text, number: p.text));
          onUpdate(contacts);
          Navigator.pop(ctx);
        }, child: const Text("Save"))
      ],
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
            trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.grey), onPressed: () {
              contacts.removeAt(i);
              onUpdate(contacts);
            }),
          ),
        ),
      ),
    );
  }
}

// --- 7. AI FEATURES SCREEN ---
class AIScreen extends StatefulWidget {
  @override
  State<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends State<AIScreen> {
  bool vDistress = false;
  bool mDetection = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AI Guardian Settings")),
      body: ListView(
        children: [
          SwitchListTile(title: const Text("Voice Distress Detection"), subtitle: const Text("Uses MFCC/CNN to detect screams"), value: vDistress, onChanged: (v) => setState(() => vDistress = v)),
          SwitchListTile(title: const Text("Suspicious Movement"), subtitle: const Text("Alerts if path deviates significantly"), value: mDetection, onChanged: (v) => setState(() => mDetection = v)),
          const ListTile(title: Text("Crime Heatmap"), subtitle: Text("Predicting unsafe zones using K-Means"), trailing: Icon(Icons.auto_graph, color: Colors.blue)),
        ],
      ),
    );
  }
}

// --- 8. VAULT & MAP PLACEHOLDERS ---
class VaultScreen extends StatelessWidget {
  final List<EvidenceRecord> records;
  const VaultScreen({super.key, required this.records});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Evidence Vault")),
      body: ListView.builder(
        itemCount: records.length,
        itemBuilder: (ctx, i) => ListTile(
          leading: Icon(records[i].type == "Video" ? Icons.videocam : Icons.mic, color: Colors.redAccent),
          title: Text("${records[i].type} - ${records[i].level}"),
          subtitle: Text(records[i].date),
          trailing: const Icon(Icons.lock_outline),
        ),
      ),
    );
  }
}

class MapViewScreen extends StatelessWidget {
  const MapViewScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Safe Routes")),
      body: const Center(child: Text("Google Maps & Crime Heatmap Integrated")),
    );
  }
}