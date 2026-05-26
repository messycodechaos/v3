import 'package:flutter/material.dart';
import 'ai_controller.dart';
import 'fake_call_screen.dart';

class AIScreen extends StatefulWidget {
  const AIScreen({super.key});
  @override
  State<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends State<AIScreen> {
  final ai = AIController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AI Guardian Settings"), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text("PROACTIVE PROTECTION", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 20),

          // 1. ACOUSTIC THREAT DETECTION
          _aiSwitch(
            "Safety Ear (Voice Monitor)",
            "Automatically triggers SOS if it hears screams or glass breaking.",
            ai.isVoiceMonitorActive,
                (v) => setState(() => ai.isVoiceMonitorActive = v),
          ),

          // 2. VISUAL GUARD
          _aiSwitch(
            "Safety Eye (Visual Guard)",
            "AI analyzes camera frames for weapons or suspicious followers.",
            ai.isVisualGuardActive,
                (v) => setState(() => ai.isVisualGuardActive = v),
          ),

          // 3. SMART RADAR
          _aiSwitch(
            "Smart Safety Radar",
            "Notifies you if you enter high-risk areas based on historical data.",
            ai.isSmartRadarActive,
                (v) => setState(() => ai.isSmartRadarActive = v),
          ),

          const SizedBox(height: 30),
          const Divider(color: Colors.white10),
          const SizedBox(height: 30),

          // 4. GUARDIAN PHONE CALL
          const Text("DETERRENT TOOLS", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 20),
          Card(
            color: Colors.blueAccent.withOpacity(0.1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ListTile(
              leading: const Icon(Icons.call, color: Colors.blueAccent),
              title: const Text("Trigger Fake Guardian Call"),
              subtitle: const Text("Starts a loud AI conversation to scare off attackers."),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const FakeCallScreen())),
            ),
          ),
        ],
      ),
    );
  }

  Widget _aiSwitch(String t, String s, bool val, Function(bool) onChanged) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      child: SwitchListTile(
        title: Text(t, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(s, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        value: val,
        onChanged: onChanged,
        activeColor: Colors.redAccent,
      ),
    );
  }
}