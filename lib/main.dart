import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'navigation_screen.dart';

// Service Imports
import 'sos_model.dart';
import 'camera_service.dart';
import 'host_screen.dart';
import 'viewer_screen.dart';
import 'record_service.dart';
import 'video_record_service.dart';
import 'location_sms_service.dart';
import 'ai_screen.dart'; // NEW


class RemoteManager {
  static final RemoteManager _instance = RemoteManager._internal();
  factory RemoteManager() => _instance;
  RemoteManager._internal();
  IO.Socket? socket; String? myHostCode;
  String? savedGroupLink;

  Future<void> init() async {
    socket = IO.io('https://safely-871c.onrender.com', IO.OptionBuilder().setTransports(['websocket']).enableAutoConnect().build());
    SharedPreferences prefs = await SharedPreferences.getInstance();
    myHostCode = prefs.getString('h_code') ?? (1000 + Random().nextInt(9000)).toString();
    savedGroupLink = prefs.getString('wa_group_link') ?? "";
    await prefs.setString('h_code', myHostCode!);
  }

  Future<void> saveGroupLink(String link) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    savedGroupLink = link;
    await prefs.setString('wa_group_link', link);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(channelId: 'guard_final', channelName: 'GuardianX', channelImportance: NotificationChannelImportance.HIGH, priority: NotificationPriority.HIGH, iconData: const NotificationIconData(resType: ResourceType.mipmap, resPrefix: ResourcePrefix.ic, name: 'launcher')),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: const ForegroundTaskOptions(interval: 5000, allowWakeLock: true),
    );
  }
  await RemoteManager().init();
  runApp(const GuardianXApp());
}

class GuardianXApp extends StatelessWidget {
  const GuardianXApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(debugShowCheckedModeBanner: false, theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: const Color(0xFF0A0E21), primaryColor: Colors.redAccent), home: const SplashScreen());
}

// --- 1. SPLASH SCREEN (PULSING) ---
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override State<SplashScreen> createState() => _SplashState();
}
class _SplashState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  @override void initState() {
    super.initState();
    _anim = AnimationController(duration: const Duration(seconds: 1), vsync: this)..repeat(reverse: true);
    Timer(const Duration(seconds: 3), () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const AuthScreen())));
  }
  @override void dispose() { _anim.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Scaffold(body: Center(child: ScaleTransition(scale: Tween(begin: 0.9, end: 1.1).animate(_anim), child: const Icon(Icons.shield, size: 100, color: Colors.redAccent))));
}

// --- 2. LOGIN PAGE (PASSWORD ADDED) ---
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override State<AuthScreen> createState() => _AuthScreenState();
}
class _AuthScreenState extends State<AuthScreen> {
  final email = TextEditingController(); final pass = TextEditingController();
  @override Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(padding: const EdgeInsets.all(30.0), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text("GUARDIAN X", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
        const SizedBox(height: 40),
        TextField(controller: email, decoration: const InputDecoration(labelText: "Guardian Email", border: OutlineInputBorder())),
        const SizedBox(height: 15),
        TextField(controller: pass, obscureText: true, decoration: const InputDecoration(labelText: "Security Password", border: OutlineInputBorder())),
        const SizedBox(height: 30),
        SizedBox(width: double.infinity, height: 55, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent), onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const MainNavigation())), child: const Text("LOGIN"))),
      ])),
    );
  }
}

// --- 3. MAIN NAVIGATION (CONNECTED AI TAB) ---
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override State<MainNavigation> createState() => _MainNavigationState();
}
class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  List<EmergencyContact> myContacts = [EmergencyContact(id: "1", name: "Emergency Contact", number: "911")];
  late List<SOSLevel> myLevels = [
    SOSLevel(name: "Lvl 1", color: Colors.amber, customMessage: "Checking in.", activationGesture: "Single Tap"),
    SOSLevel(name: "Lvl 2", color: Colors.orange, customMessage: "Unsafe.", activationGesture: "Double Tap"),
    SOSLevel(name: "Lvl 3", color: Colors.red, recordVideo: true, recordAudio: true, liveStream: true, customMessage: "EMERGENCY!", activationGesture: "Long Press"),
  ];

  @override void initState() { super.initState(); if (!kIsWeb) [Permission.camera, Permission.microphone, Permission.storage, Permission.location, Permission.sms].request(); }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(levels: myLevels, contacts: myContacts),
      const NavigationScreen(),
      GuardianScreen(contacts: myContacts, onUpdate: (l) => setState(() => myContacts = l)),
      ConfigScreen(levels: myLevels, onUpdate: (l) => setState(() => myLevels = l)),
      const AIScreen(), // CONNECTED
      const VaultScreen(),
      ViewerEntryTab(socket: RemoteManager().socket!)
    ];
    return Scaffold(body: IndexedStack(index: _currentIndex, children: screens), bottomNavigationBar: BottomNavigationBar(currentIndex: _currentIndex, selectedItemColor: Colors.redAccent, unselectedItemColor: Colors.white24, type: BottomNavigationBarType.fixed, onTap: (i) => setState(() => _currentIndex = i), items: const [
      BottomNavigationBarItem(icon: Icon(Icons.shield), label: "SOS"),
      BottomNavigationBarItem(icon: Icon(Icons.map), label: "Map"),
      BottomNavigationBarItem(icon: Icon(Icons.people), label: "People"),
      BottomNavigationBarItem(icon: Icon(Icons.tune), label: "Config"),
      BottomNavigationBarItem(icon: Icon(Icons.psychology), label: "AI"),
      BottomNavigationBarItem(icon: Icon(Icons.folder), label: "Vault"),
      BottomNavigationBarItem(icon: Icon(Icons.visibility), label: "Watch"),
    ]));
  }
}

// --- 4. HOME (CENTERED SOS) ---
class HomeScreen extends StatefulWidget {
  final List<SOSLevel> levels; final List<EmergencyContact> contacts;
  const HomeScreen({super.key, required this.levels, required this.contacts});
  @override State<HomeScreen> createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> {
  int taps = 0; bool armed = false; bool isRunning = false;
  void trigger(SOSLevel lvl) async {
    if (!armed) return;
    setState(() => isRunning = true);
    if (!kIsWeb) await FlutterForegroundTask.startService(notificationTitle: "GuardianX ARMED", notificationText: "Protection Active");

    // MESSAGING LOGIC (INTEGRATED WHATSAPP GROUP)
    await LocationSmsService().triggerAlerts(
        contacts: widget.contacts,
        roomCode: RemoteManager().myHostCode!,
        customMsg: lvl.customMessage,
        useSMS: lvl.sendSMS,
        // isAuto: lvl.autoSms,
        useWA: lvl.sendWhatsApp,
        groupLink: RemoteManager().savedGroupLink
    );

    if (lvl.notifyPolice) await launchUrl(Uri.parse("tel:911"));
    if (lvl.notifyHospital) await launchUrl(Uri.parse("tel:102"));

    if (lvl.recordAudio) await RecordService().startLocalRecord();
    await CameraService().startStreaming(RemoteManager().socket!, RemoteManager().myHostCode!);
    if (lvl.recordVideo && CameraService().localStream != null) await VideoRecordService().startVideoRecording(CameraService().localStream!);
    if (lvl.liveStream) Navigator.push(context, MaterialPageRoute(builder: (c) => HostScreen(roomCode: RemoteManager().myHostCode!)));
  }
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Text(armed ? "READY: ${RemoteManager().myHostCode}" : "SYSTEM LOCKED", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
    const SizedBox(height: 50),
    GestureDetector(behavior: HitTestBehavior.opaque, onTap: () { if (!armed) { setState(() { taps++; if (taps >= 3) armed = true; }); } else { _showPicker(); } }, child: Container(height: 280, width: 280, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: armed ? Colors.green : Colors.redAccent, width: 4), boxShadow: [BoxShadow(color: armed ? Colors.green.withOpacity(0.1) : Colors.redAccent.withOpacity(0.1), blurRadius: 40)]), child: Icon(Icons.power_settings_new, size: 100, color: armed ? Colors.green : Colors.redAccent))),
    const SizedBox(height: 40),
    if (isRunning) ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () { RecordService().stopLocalRecord(); VideoRecordService().stopVideoRecording(); CameraService().stopEverything(); LocationSmsService().stop(); FlutterForegroundTask.stopService(); setState(() => isRunning = false); }, child: const Text("STOP ALL PROCESSES")),
  ]));
  void _showPicker() { showModalBottomSheet(context: context, builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, children: widget.levels.map((l) => ListTile(leading: Icon(Icons.warning, color: l.color), title: Text(l.name), onTap: () { Navigator.pop(ctx); trigger(l); })).toList())); }
}

// --- 5. CONFIG (ALL ORIGINAL FEATURES PRESERVED) ---
class ConfigScreen extends StatefulWidget {
  final List<SOSLevel> levels; final Function onUpdate;
  const ConfigScreen({super.key, required this.levels, required this.onUpdate});
  @override State<ConfigScreen> createState() => _ConfigState();
}
class _ConfigState extends State<ConfigScreen> with SingleTickerProviderStateMixin {
  late TabController _t; @override void initState() { super.initState(); _t = TabController(length: 3, vsync: this); }
  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("SOS Configuration"), bottom: TabBar(controller: _t, tabs: const [Tab(text: "L1"), Tab(text: "L2"), Tab(text: "L3")])),
      body: TabBarView(controller: _t, children: widget.levels.map((l) => ListView(padding: const EdgeInsets.all(20), children: [
        SwitchListTile(title: const Text("Send SMS Alert"), value: l.sendSMS, onChanged: (v) => setState(() => l.sendSMS = v)),
        SwitchListTile(title: const Text("Background Auto-SMS"), subtitle: const Text("Sends silently by itself"), value: l.autoSms, activeColor: Colors.green, onChanged: (v) => setState(() => l.autoSms = v)),
        SwitchListTile(title: const Text("Send WhatsApp"), value: l.sendWhatsApp, onChanged: (v) => setState(() => l.sendWhatsApp = v)),
        SwitchListTile(title: const Text("Physical Audio Record"), value: l.recordAudio, onChanged: (v) => setState(() => l.recordAudio = v)),
        SwitchListTile(title: const Text("Physical Video Record"), value: l.recordVideo, onChanged: (v) => setState(() => l.recordVideo = v)),
        SwitchListTile(title: const Text("Notify Police"), value: l.notifyPolice, onChanged: (v) => setState(() => l.notifyPolice = v)),
        SwitchListTile(title: const Text("Notify Hospital"), value: l.notifyHospital, onChanged: (v) => setState(() => l.notifyHospital = v)),
        SwitchListTile(title: const Text("Notice Safety Places"), value: l.noticeSafetyPlaces, onChanged: (v) => setState(() => l.noticeSafetyPlaces = v)),
        const Text("Message:"),
        TextField(maxLines: 2, controller: TextEditingController(text: l.customMessage), decoration: const InputDecoration(border: OutlineInputBorder()), onChanged: (v) => l.customMessage = v),
        ListTile(title: const Text("Gesture"), trailing: DropdownButton<String>(value: l.activationGesture, items: ["Single Tap", "Double Tap", "Long Press"].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) { setState(() => l.activationGesture = v!); widget.onUpdate(widget.levels); })),
      ])).toList()),
    );
  }
}

// --- 6. PEOPLE TAB (GROUP SETUP BRIDGE) ---
class GuardianScreen extends StatefulWidget {
  final List<EmergencyContact> contacts; final Function onUpdate;
  const GuardianScreen({super.key, required this.contacts, required this.onUpdate});
  @override State<GuardianScreen> createState() => _GuardianScreenState();
}
class _GuardianScreenState extends State<GuardianScreen> {
  final _linkCtrl = TextEditingController(text: RemoteManager().savedGroupLink);
  void _generateGroup() async {
    String allNumbers = widget.contacts.map((e) => e.number).join(", ");
    await Clipboard.setData(ClipboardData(text: allNumbers));
    showDialog(context: context, builder: (c) => AlertDialog(
      title: const Text("Ready to Create Group"),
      content: const Text("Numbers copied. Open WhatsApp, Create Group, and Paste."),
      actions: [ElevatedButton(onPressed: () => launchUrl(Uri.parse("https://wa.me/")), child: const Text("OPEN WHATSAPP"))],
    ));
  }
  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Guardian Hub"), actions: [IconButton(icon: const Icon(Icons.add), onPressed: () => _add(context))]),
      body: ListView(padding: const EdgeInsets.all(15), children: [
        Card(color: Colors.blue.withOpacity(0.1), child: Column(children: [
          const ListTile(title: Text("Setup WhatsApp Group"), subtitle: Text("One window for all alerts")),
          ElevatedButton(onPressed: _generateGroup, child: const Text("1. INITIALIZE GROUP")),
          TextField(controller: _linkCtrl, decoration: const InputDecoration(labelText: "2. Paste Group Link")),
          ElevatedButton(onPressed: () => RemoteManager().saveGroupLink(_linkCtrl.text), child: const Text("3. SAVE LINK")),
        ])),
        ...widget.contacts.map((c) => ListTile(title: Text(c.name), subtitle: Text(c.number))),
      ]),
    );
  }
  void _add(BuildContext context) {
    final n = TextEditingController(), p = TextEditingController();
    showDialog(context: context, builder: (c) => AlertDialog(title: const Text("Add"), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: n, decoration: const InputDecoration(labelText: "Name")), TextField(controller: p, decoration: const InputDecoration(labelText: "Phone"))]), actions: [ElevatedButton(onPressed: () { widget.contacts.add(EmergencyContact(id: "1", name: n.text, number: p.text)); widget.onUpdate(widget.contacts); Navigator.pop(c); }, child: const Text("Save"))]));
  }
}

// --- VAULT & WATCH (UNCHANGED) ---
class VaultScreen extends StatelessWidget { const VaultScreen({super.key}); Future<List<FileSystemEntity>> _getFiles() async { final dir = await getExternalStorageDirectory(); return dir?.listSync() ?? []; } @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("Vault")), body: FutureBuilder<List<FileSystemEntity>>(future: _getFiles(), builder: (context, snapshot) { if (!snapshot.hasData) return const CircularProgressIndicator(); final files = snapshot.data!.reversed.toList(); return ListView.builder(itemCount: files.length, itemBuilder: (context, i) { String name = files[i].path.split('/').last; return ListTile(leading: Icon(name.contains('.mp4') ? Icons.videocam : Icons.mic), title: Text(name)); }); })); }
class ViewerEntryTab extends StatelessWidget { final IO.Socket socket; const ViewerEntryTab({super.key, required this.socket}); @override Widget build(BuildContext context) { final c = TextEditingController(); return Padding(padding: const EdgeInsets.all(30), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.live_tv, size: 80, color: Colors.redAccent), TextField(controller: c, decoration: const InputDecoration(labelText: "Code")), ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (x) => ViewerScreen(socket: socket, roomCode: c.text))), child: const Text("WATCH"))])); } }