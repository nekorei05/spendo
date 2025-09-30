import 'package:flutter/material.dart';

enum ExportFormat { pdf, csv }

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  ExportFormat _selectedFormat = ExportFormat.pdf;
  bool _isDarkTheme = false;

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Export Statement"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Do you want to export your statement?"),
              ListTile(
                title: const Text("PDF"),
                leading: Radio<ExportFormat>(
                  value: ExportFormat.pdf,
                  groupValue: _selectedFormat,
                  onChanged: (ExportFormat? value) {
                    setState(() {
                      _selectedFormat = value!;
                    });
                    Navigator.pop(context);
                    _showExportDialog();
                  },
                ),
              ),
              ListTile(
                title: const Text("CSV"),
                leading: Radio<ExportFormat>(
                  value: ExportFormat.csv,
                  groupValue: _selectedFormat,
                  onChanged: (ExportFormat? value) {
                    setState(() {
                      _selectedFormat = value!;
                    });
                    Navigator.pop(context);
                    _showExportDialog();
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text("Export"),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Exported as ${_selectedFormat == ExportFormat.pdf ? 'PDF' : 'CSV'}",
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _toggleTheme(bool value) {
    setState(() {
      _isDarkTheme = value;
    });

    // Theme toggling logic here if using Provider or similar
    // For now this just updates local state
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF7345EE);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Navigate to edit screen or show bottom sheet
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: primaryColor,
                  child: const Icon(
                    Icons.person,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "9876543210",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text("Preferences"),
            onTap: () {
              // Navigate to preferences screen or show dialog
            },
          ),
          ListTile(
            leading: const Icon(Icons.file_download),
            title: const Text("Export Statement"),
            onTap: _showExportDialog,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.brightness_6),
            title: const Text("Dark Theme"),
            value: _isDarkTheme,
            onChanged: _toggleTheme,
          ),
        ],
      ),
    );
  }
}
