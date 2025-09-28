import 'package:flutter/material.dart';
import 'db_helper.dart';

class AddTransactionScreen extends StatefulWidget {
  @override
  _AddTransactionScreenState createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final Color primaryColor = Color(0xFF7345EE);

  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _dateTimeCtrl = TextEditingController();
  final TextEditingController _paidToCtrl = TextEditingController();
  final TextEditingController _modeCtrl = TextEditingController();

  String? _selectedCategory;
  final List<String> _categories = [
    'Food',
    'Travel',
    'Shopping',
    'Bills',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Transaction'),
        backgroundColor: primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Title
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'ADD TRANSACTION',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: primaryColor,
                ),
              ),
            ),
            SizedBox(height: 16),

            // Main Input Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Add Amount',
                      hintStyle: TextStyle(fontSize: 20),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _dateTimeCtrl,
                    decoration: InputDecoration(
                      hintText: 'Date and Time',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _paidToCtrl,
                    decoration: InputDecoration(
                      hintText: 'Paid To',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _modeCtrl,
                    decoration: InputDecoration(
                      hintText: 'Mode (e.g. Cash)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Category Dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    'Category:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      hint: Text('Select Category'),
                      items: _categories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCategory = newValue;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 30),

            // Add Expense Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () async {
                  final expense = {
                    'amount': double.tryParse(_amountCtrl.text) ?? 0.0,
                    'date': _dateTimeCtrl.text,
                    'paidTo': _paidToCtrl.text,
                    'mode': _modeCtrl.text,
                    'category': _selectedCategory ?? 'Other',
                  };

                  await DBHelper.insertExpense(expense);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Expense added successfully!')),
                  );

                  _amountCtrl.clear();
                  _dateTimeCtrl.clear();
                  _paidToCtrl.clear();
                  _modeCtrl.clear();
                  setState(() {
                    _selectedCategory = null;
                  });
                },
                child: Text('Add Expense', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
