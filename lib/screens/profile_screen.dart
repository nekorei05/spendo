import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:csv/csv.dart';
import '../services/theme_provider.dart';
import 'db_helper.dart';

enum ExportFormat { pdf, csv }

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  ExportFormat _selectedFormat = ExportFormat.pdf;

  Future<void> _exportStatement() async {
    final data = await DBHelper.getAllTransactionsForExport();

    if (data.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("No transactions to export.")));
      return;
    }

    if (_selectedFormat == ExportFormat.pdf) {
      await _exportPDF(data);
    } else {
      await _exportCSV(data);
    }
  }

  Future<void> _exportPDF(List<Map<String, dynamic>> data) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            children: [
              pw.Text(
                'Transaction Statement',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ['Date', 'Category', 'Amount', 'Type', 'Merchant'],
                data: data.map((tx) {
                  return [
                    tx['date'],
                    tx['category'],
                    '₹${tx['amount'].toStringAsFixed(2)}',
                    tx['type'],
                    tx['paidTo'] ?? '',
                  ];
                }).toList(),
              ),
            ],
          );
        },
      ),
    );

    // Use printing package to save or share the PDF
    await Printing.sharePdf(bytes: await pdf.save(), filename: 'statement.pdf');

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('PDF exported successfully')));
  }

  Future<void> _exportCSV(List<Map<String, dynamic>> data) async {
    List<List<dynamic>> rows = [];

    rows.add(['Date', 'Category', 'Amount', 'Type', 'Merchant']);

    for (var tx in data) {
      rows.add([
        tx['date'],
        tx['category'],
        tx['amount'].toString(),
        tx['type'],
        tx['paidTo'] ?? '',
      ]);
    }

    String csvData = const ListToCsvConverter().convert(rows);

    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/statement.csv';
    final file = File(path);

    await file.writeAsString(csvData);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('CSV exported to $path')));
  }

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
                _exportStatement();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF7345EE);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: primaryColor,
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
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.file_download),
            title: const Text("Export Statement"),
            onTap: _showExportDialog,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.brightness_6),
            title: const Text("Dark Theme"),
            value: themeProvider.isDarkMode,
            onChanged: (value) {
              themeProvider.toggleTheme(value);
            },
          ),
        ],
      ),
    );
  }
}
