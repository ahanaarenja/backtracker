import 'dart:async';
import 'package:backtracker/edit_profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'bluetooth_device_list_screen.dart';
import 'colours.dart';
import 'services/bluetooth_service.dart';

class ProfileScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return ProfileScreenState();
  }
}

class ProfileScreenState extends State<ProfileScreen> {
  final BluetoothService _bluetoothService = BluetoothService();
  bool _isConnected = false;
  String? _connectedDeviceName;
  StreamSubscription? _connectionSubscription;

  @override
  void initState() {
    super.initState();
    _updateConnectionStatus();
    _connectionSubscription = _bluetoothService.connectionStatusStream.listen((connected) {
      if (mounted) {
        setState(() {
          _isConnected = connected;
          _connectedDeviceName = connected ? _bluetoothService.connectedDeviceName : null;
        });
      }
    });
  }

  void _updateConnectionStatus() {
    setState(() {
      _isConnected = _bluetoothService.isConnected;
      _connectedDeviceName = _bluetoothService.connectedDeviceName;
    });
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: light,
      appBar: AppBar(
        backgroundColor: light,
        centerTitle: true,
        automaticallyImplyLeading: false,
        // leading: IconButton(
        //   icon: Icon(Icons.arrow_back_ios, color: dark),
        //   onPressed: () {
        //     Navigator.pop(context);
        //   },
        // ),
        title: Text(
          "Profile",
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: dark),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10),
            // Edit Profile
            _buildMenuItem(
              icon: FontAwesomeIcons.userPen,
              title: "Edit profile",
              onTap: () {
                Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(builder: (context) => EditProfile()),
                );
              },
            ),
            SizedBox(height: 20),
            // General Settings Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "General Settings",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: mid,
                ),
              ),
            ),
            SizedBox(height: 10),
            // Connect Device
            _buildBluetoothMenuItem(),
            // About
            _buildMenuItem(
              icon: FontAwesomeIcons.question,
              title: "About",
              onTap: () {
                // Navigate to about
              },
            ),
            // Terms & Conditions
            _buildMenuItem(
              icon: FontAwesomeIcons.circleInfo,
              title: "Terms & Conditions",
              onTap: () {
                // Navigate to terms
              },
            ),
            // Privacy Policy
            _buildMenuItem(
              icon: FontAwesomeIcons.lock,
              title: "Privacy Policy",
              onTap: () {
                // Navigate to privacy policy
              },
            ),
            // Logout
            _buildMenuItem(
              icon: FontAwesomeIcons.rightFromBracket,
              title: "Logout",
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                // Navigate to login screen
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBluetoothMenuItem() {
    return GestureDetector(
      onTap: () async {
        if (_isConnected) {
          // Show disconnect dialog
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('Disconnect Device?', style: TextStyle(color: dark, fontWeight: FontWeight.bold)),
              content: Text('Do you want to disconnect from ${_connectedDeviceName ?? "BackTracker Strap"}?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: mid)),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _bluetoothService.disconnect();
                    _updateConnectionStatus();
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.red.shade400,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: const Text('Disconnect', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          );
        } else {
          // Navigate to device list
          final result = await Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(builder: (context) => const BluetoothDeviceListScreen()),
          );
          if (result == true) {
            _updateConnectionStatus();
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _isConnected ? Colors.green.shade50 : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: _isConnected ? Border.all(color: Colors.green, width: 1.5) : null,
              ),
              child: Icon(
                FontAwesomeIcons.bluetoothB,
                color: _isConnected ? Colors.green : dark,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isConnected ? "Connected" : "Connect your device",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: _isConnected ? Colors.green : Colors.black87,
                    ),
                  ),
                  if (_isConnected && _connectedDeviceName != null)
                    Text(
                      _connectedDeviceName!,
                      style: TextStyle(fontSize: 12, color: mid),
                    ),
                ],
              ),
            ),
            if (_isConnected)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Active',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            else
              Icon(Icons.arrow_forward_ios, color: dark, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool highlighted = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: highlighted
            ? BoxDecoration(
                // color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: dark, width: 1.5),
              )
            : null,
        child: Row(
          children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20)
            ),
            child: Icon(
              icon,
              color: dark,
              size: 22,
            ),
          ),
          SizedBox(width: 10,),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          if(title != "Logout")
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Icon(
                Icons.arrow_forward_ios,
                color: dark,
                size: 18,
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }
}

