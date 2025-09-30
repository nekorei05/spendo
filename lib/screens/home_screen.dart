import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'add_transaction.dart';
import 'db_helper.dart';
import 'insights_screen.dart'; // Import the insights screen
import 'package:intl/intl.dart';
import '../services/sms_service.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Color primaryColor = Color(0xFF7345EE);
  double _totalExpenses = 0.0;
  List<Map<String, dynamic>> _recentExpenses = [];

  @override
  void initState() {
    super.initState();
    final smsService = SmsService();

    smsService.initSmsListener(() {
      _loadDashboardData();
    });

    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final total = await DBHelper.getMonthlyTotalExpenses(); // only this month
    final recent = await DBHelper.getRecentExpenses();
    setState(() {
      _totalExpenses = total;
      _recentExpenses = recent;
    });
  }

  String formatDate(String rawDate) {
    final date = DateTime.tryParse(rawDate);
    return date != null ? DateFormat('MMM d').format(date) : rawDate;
  }

  String getCurrentMonthYear() {
    return DateFormat('MMMM yyyy').format(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser();
    final nameOrEmail = user?.displayName?.isNotEmpty == true
        ? user!.displayName
        : user?.email ?? user?.phoneNumber ?? 'User';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProfileScreen()),
                );
              },
              child: CircleAvatar(
                backgroundImage: NetworkImage(
                  user?.photoURL ?? 'https://via.placeholder.com/150',
                ),
                radius: 20,
              ),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nameOrEmail ?? '',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Welcome back',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(icon: Icon(Icons.notifications), onPressed: () {}),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await AuthService.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Summary Cards
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: primaryColor.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            'Month',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            getCurrentMonthYear(),
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Card(
                    color: primaryColor.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            'Total Expenses',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '₹${_totalExpenses.toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                final smsService = SmsService();
                await smsService.importExistingSms(() {
                  _loadDashboardData();
                });
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('SMS import complete')));
              },
              icon: Icon(Icons.sms),
              label: Text('Import Existing SMS'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: _recentExpenses.isEmpty
                  ? Center(child: Text('No transactions yet'))
                  : ListView(
                      children: _recentExpenses.map((expense) {
                        return ListTile(
                          leading: Icon(
                            expense['type'] == 'income'
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            color: expense['type'] == 'income'
                                ? Colors.green
                                : primaryColor,
                          ),
                          title: Text(
                            expense['paidTo'] ?? 'Unknown',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${expense['category']} • ₹${(expense['amount'] as double).toStringAsFixed(2)}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(formatDate(expense['date'])),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  await DBHelper.deleteExpense(expense['id']);
                                  await _loadDashboardData();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Transaction deleted'),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        child: Icon(Icons.add),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddTransactionScreen()),
          );
          _loadDashboardData(); // Refresh after adding
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 8,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.home, color: primaryColor),
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(Icons.insights, color: primaryColor),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => InsightsScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
