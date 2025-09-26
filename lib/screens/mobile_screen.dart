import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'otp_screen.dart';

class MobileScreen extends StatefulWidget {
  @override
  State<MobileScreen> createState() => _MobileScreenState();
}

class _MobileScreenState extends State<MobileScreen> {
  final _phoneCtrl = TextEditingController();
  final AuthService _auth = AuthService();
  bool _isLoading = false;
  String? _error;

  // Country code dropdown
  String _selectedCode = '+91';
  final List<String> _countryCodes = ['+91', '+1', '+44'];

  void _sendOtp() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    String phone = '$_selectedCode${_phoneCtrl.text.trim()}';

    try {
      await _auth.sendPhoneVerification(
        phoneNumber: phone,
        verificationFailed: (e) {
          setState(() {
            _error = e.message;
            _isLoading = false;
          });
        },
        codeSent: (String verificationId, int? resendToken) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OtpScreen(verificationId: verificationId),
            ),
          );
        },
        codeAutoRetrievalTimeout: (verId) {},
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Verify Phone')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter your phone number', style: TextStyle(fontSize: 16)),
            SizedBox(height: 12),
            Row(
              children: [
                DropdownButton<String>(
                  value: _selectedCode,
                  items: _countryCodes
                      .map((code) => DropdownMenuItem(
                            value: code,
                            child: Text(code),
                          ))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedCode = val!;
                    });
                  },
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      hintText: 'e.g. 9876543210',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              SizedBox(height: 10),
              Text(_error!, style: TextStyle(color: Colors.red)),
            ],
            SizedBox(height: 20),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    child: Text('Send OTP'),
                    onPressed: _sendOtp,
                  ),
          ],
        ),
      ),
    );
  }
}
