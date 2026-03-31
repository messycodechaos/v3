import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class VaultScreen extends StatelessWidget {
  const VaultScreen({super.key});

  Future<List<FileSystemEntity>> _getFiles() async {
    // Logic: Look for files in the physical app storage
    final dir = await getExternalStorageDirectory();
    if (dir == null) return [];
    return dir.listSync();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Evidence Vault")),
      body: FutureBuilder<List<FileSystemEntity>>(
        future: _getFiles(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No recordings found."));
          }

          final files = snapshot.data!.reversed.toList();

          return ListView.builder(
            itemCount: files.length,
            itemBuilder: (context, i) {
              String name = files[i].path.split('/').last;
              bool isVideo = name.contains('.mp4');

              return ListTile(
                leading: Icon(isVideo ? Icons.videocam : Icons.mic, color: Colors.redAccent),
                title: Text(name),
                subtitle: const Text("Stored in Physical Memory"),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("File saved at: ${files[i].path}")),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}