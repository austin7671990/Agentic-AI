import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/tools/device_tools.dart';

class DeviceInfoScreen extends StatelessWidget {
  const DeviceInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Device Info')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: deviceScan(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final info = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _InfoCard('Device Model', info['model'] ?? 'Unknown'),
              _InfoCard('Brand', info['brand'] ?? 'Unknown'),
              _InfoCard('Android Version', 'API ${info['androidApiLevel'] ?? 'Unknown'}'),
              _InfoCard('Total RAM', '${((info['totalRam'] ?? 0) / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB'),
              _InfoCard('Available RAM', '${((info['availableRam'] ?? 0) / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB'),
              _InfoCard('CPU Cores', '${info['cpuCores'] ?? 'Unknown'}'),
              _InfoCard('GPU', info['gpu'] ?? 'Unknown'),
              _InfoCard('Installed Apps', '${info['installedApps'] ?? 0}'),
              if ((info['appList'] as List?)?.isNotEmpty == true)
                _InfoCard('Sample Apps', (info['appList'] as List).take(10).join(', ')),
            ],
          );
        },
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;
  const _InfoCard(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        subtitle: Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
      ),
    );
  }
}