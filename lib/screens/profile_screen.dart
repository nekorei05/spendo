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
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  // ✅ For PDF export

  Future<void> _exportPDF(List<Map<String, dynamic>> data) async {
    final pdf = pw.Document();

    // Get current Firebase user
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? "User";
    final contact = user?.phoneNumber ?? user?.email ?? "Not Provided";

    // Calculate total expenses
    final totalAmount = data.fold<double>(
      0.0,
      (sum, tx) => sum + (tx['amount'] ?? 0.0),
    );

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          // Title
          pw.Center(
            child: pw.Text(
              'Expense Report',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 10),

          // User Info Section
          pw.Text("Name: $name"),
          pw.Text("Contact: $contact"),
          pw.Text("Total Spent: ${totalAmount.toStringAsFixed(2)}"),
          pw.SizedBox(height: 20),

          // Transaction Table
          pw.Table.fromTextArray(
            headers: ['Date', 'Category', 'Amount', 'Type', 'Merchant'],
            data: data.map((tx) {
              String dateStr = tx['date'].toString();
              String formattedDate;

              try {
                final parsed = DateTime.tryParse(dateStr);
                if (parsed != null) {
                  formattedDate =
                      "${parsed.day}-${parsed.month}-${parsed.year}";
                } else {
                  formattedDate = dateStr;
                }
              } catch (_) {
                formattedDate = dateStr;
              }

              return [
                formattedDate,
                tx['category'] ?? 'Other',
                tx['amount'].toStringAsFixed(2),
                tx['type'] ?? '',
                tx['paidTo'] ?? '',
              ];
            }).toList(),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: pw.BoxDecoration(color: PdfColors.deepPurple),
            cellAlignment: pw.Alignment.centerLeft,
            border: pw.TableBorder.all(color: PdfColors.grey),
            cellStyle: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );

    // Save/share PDF
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Spendo_Report.pdf',
    );

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('PDF exported successfully')));
  }

  // ✅ For csv export
  Future<void> _exportCSV(List<Map<String, dynamic>> data) async {
    // Get user info
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? "User";
    final contact = user?.phoneNumber ?? user?.email ?? "Not Provided";

    // Calculate total expenses
    final totalAmount = data.fold<double>(
      0.0,
      (sum, tx) => sum + (tx['amount'] ?? 0.0),
    );

    List<List<dynamic>> rows = [];

    // Header section
    rows.add(["Expense Report"]);
    rows.add(["Name", name]);
    rows.add(["Contact", contact]);
    rows.add(["Total Spent", totalAmount.toStringAsFixed(2)]);
    rows.add([]); // empty line
    rows.add(['Date', 'Category', 'Amount', 'Type', 'Merchant']);

    // Add transactions
    for (var tx in data) {
      rows.add([
        tx['date'],
        tx['category'],
        tx['amount'].toStringAsFixed(2),
        tx['type'],
        tx['paidTo'] ?? '',
      ]);
    }

    String csvData = const ListToCsvConverter().convert(rows);

    // Save to Downloads folder for easier access
    Directory? downloadsDir;
    if (Platform.isAndroid) {
      downloadsDir = Directory('/storage/emulated/0/Download');
    } else {
      downloadsDir = await getDownloadsDirectory();
    }

    final path = '${downloadsDir!.path}/Spendo_Report.csv';
    final file = File(path);
    await file.writeAsString(csvData);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('CSV exported to $path')));
  }

  // Export options
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
