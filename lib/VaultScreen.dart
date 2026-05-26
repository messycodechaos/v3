import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {

  // Logic: Get both Audio and Video files from our specific folders
  Future<List<FileSystemEntity>> _getAllRecords() async {
    Directory? baseDir = await getExternalStorageDirectory();
    List<FileSystemEntity> allFiles = [];

    // Check Audio Folder
    Directory audioDir = Directory("${baseDir!.path}/GuardianX/Audio");
    if (audioDir.existsSync()) allFiles.addAll(audioDir.listSync());

    // Check Video Folder
    Directory videoDir = Directory("${baseDir.path}/GuardianX/Video");
    if (videoDir.existsSync()) allFiles.addAll(videoDir.listSync());

    // Sort by date (Newest first)
    allFiles.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    return allFiles;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Evidence Vault"),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: () => setState(() {}))],
      ),
      body: FutureBuilder<List<FileSystemEntity>>(
        future: _getAllRecords(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Vault is empty."));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              FileSystemEntity file = snapshot.data![index];
              String name = file.path.split('/').last;
              bool isVideo = name.contains('VID_');

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: Icon(
                    isVideo ? Icons.videocam : Icons.mic,
                    color: isVideo ? Colors.blue : Colors.orange,
                  ),
                  title: Text(name),
                  subtitle: Text("Size: ${(file.statSync().size / 1024).toStringAsFixed(1)} KB"),
                  trailing: const Icon(Icons.play_circle_fill, color: Colors.redAccent),
                  onTap: () {
                    // Logic: Provide path for opening the file
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("File Location: ${file.path}")),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}