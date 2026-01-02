import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide BluetoothService;
import 'package:permission_handler/permission_handler.dart';
import 'services/bluetooth_service.dart';
import 'colours.dart';

class BluetoothDeviceListScreen extends StatefulWidget {
  const BluetoothDeviceListScreen({super.key});

  @override
  State<BluetoothDeviceListScreen> createState() => _BluetoothDeviceListScreenState();
}

class _BluetoothDeviceListScreenState extends State<BluetoothDeviceListScreen> {
  final BluetoothService _bluetoothService = BluetoothService();
  List<BluetoothDevice> _devices = [];
  bool _isScanning = false;
  bool _isConnecting = false;
  String? _connectingDeviceId;

  @override
  void initState() {
    super.initState();
    _checkBluetoothStatus();
  }

  Future<void> _checkBluetoothStatus() async {
    try {
      // Request Bluetooth permissions first
      bool permissionsGranted = await _requestBluetoothPermissions();
      if (!permissionsGranted) {
        _showErrorDialog('Bluetooth permissions are required to scan for devices. Please grant permissions in Settings.');
        return;
      }

      final isAvailable = await _bluetoothService.isBluetoothAvailable();
      final isEnabled = await _bluetoothService.isBluetoothEnabled();

      if (!isAvailable) {
        _showErrorDialog('Bluetooth Low Energy (BLE) is not supported on this device. This is required for the BackTracker strap.');
        return;
      }

      if (!isEnabled) {
        // Try to turn on Bluetooth
        if (Platform.isAndroid) {
          try {
            await FlutterBluePlus.turnOn();
            await Future.delayed(const Duration(seconds: 1));
          } catch (e) {
            debugPrint('Could not turn on Bluetooth: $e');
          }
        }
        
        // Check again
        final stillDisabled = !(await _bluetoothService.isBluetoothEnabled());
        if (stillDisabled) {
          _showErrorDialog('Please enable Bluetooth in your device settings to connect to the BackTracker strap.');
          return;
        }
      }

      _startScanning();
    } catch (e) {
      _showErrorDialog('Error checking Bluetooth status: $e');
    }
  }

  Future<bool> _requestBluetoothPermissions() async {
    if (Platform.isAndroid) {
      // Android 12+ requires these permissions
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ].request();

      // Check if all permissions are granted
      bool allGranted = statuses.values.every(
        (status) => status == PermissionStatus.granted || status == PermissionStatus.limited
      );

      if (!allGranted) {
        debugPrint('Bluetooth permissions not granted: $statuses');
      }

      return allGranted;
    } else if (Platform.isIOS) {
      // iOS handles Bluetooth permissions differently
      PermissionStatus status = await Permission.bluetooth.request();
      return status == PermissionStatus.granted;
    }
    return true;
  }

  void _startScanning() {
    setState(() {
      _isScanning = true;
      _devices = [];
    });

    debugPrint('Starting Bluetooth scan...');

    // Listen to scan results
    _bluetoothService.scanForDevices().listen((scanResults) {
      debugPrint('Scan results received: ${scanResults.length} devices');
      if (mounted) {
        setState(() {
          // Filter out devices without names if you only want named devices
          // Or keep all devices to see everything
          _devices = scanResults
              .map((result) => result.device)
              .toList();
        });
        
        // Debug: Print device names
        for (var result in scanResults) {
          debugPrint('Found: ${result.device.platformName} - ${result.device.remoteId}');
        }
      }
    }, onError: (error) {
      debugPrint('Scan error: $error');
    });

    // Stop scanning after timeout
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted && _isScanning) {
        debugPrint('Scan timeout - stopping scan');
        setState(() => _isScanning = false);
        _bluetoothService.stopScan();
      }
    });
  }

  void _stopScanning() {
    setState(() => _isScanning = false);
    _bluetoothService.stopScan();
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() {
      _isConnecting = true;
      _connectingDeviceId = device.remoteId.toString();
    });

    _stopScanning();

    try {
      final success = await _bluetoothService.connectToDevice(device);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Connected to ${device.platformName.isNotEmpty ? device.platformName : "BackTracker Strap"}'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Return true to indicate successful connection
        } else {
          _showErrorDialog('Failed to connect to ${device.platformName.isNotEmpty ? device.platformName : "device"}. Please try again.');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error connecting to device: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _connectingDeviceId = null;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Bluetooth Error', style: TextStyle(color: dark, fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              backgroundColor: dark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('OK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: light,
      appBar: AppBar(
        backgroundColor: light,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: dark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Connect Device",
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: dark),
        ),
        actions: [
          if (_isScanning)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: dark),
              ),
            )
          else
            IconButton(
              icon: Icon(Icons.refresh, color: dark),
              onPressed: _startScanning,
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header info
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: mid.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: light,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.bluetooth_searching, color: dark, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BackTracker Strap',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: dark),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isScanning 
                            ? 'Searching for devices...' 
                            : 'Tap a device below to connect',
                        style: TextStyle(color: mid, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Section header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Available Devices',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: mid),
            ),
          ),
          const SizedBox(height: 10),
          
          // Device list
          Expanded(
            child: _devices.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _devices.length,
                    itemBuilder: (context, index) {
                      final device = _devices[index];
                      final isConnecting = _connectingDeviceId == device.remoteId.toString();
                      return _buildDeviceItem(device, isConnecting);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isScanning ? Icons.bluetooth_searching : Icons.bluetooth_disabled,
            size: 80,
            color: mid.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          Text(
            _isScanning ? 'Searching for devices...' : 'No devices found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: mid,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isScanning 
                ? 'Make sure your BackTracker strap is powered on' 
                : 'Ensure your strap is on and try again',
            style: TextStyle(fontSize: 14, color: mid.withOpacity(0.7)),
            textAlign: TextAlign.center,
          ),
          if (!_isScanning) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _startScanning,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Scan Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: dark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeviceItem(BluetoothDevice device, bool isConnecting) {
    final deviceName = device.platformName.isNotEmpty ? device.platformName : 'Unknown Device';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isConnecting || _isConnecting ? null : () => _connectToDevice(device),
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: light,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.bluetooth, color: dark, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deviceName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: dark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        device.remoteId.toString(),
                        style: TextStyle(fontSize: 12, color: mid),
                      ),
                    ],
                  ),
                ),
                if (isConnecting)
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: dark),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: dark,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Connect',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _bluetoothService.stopScan();
    super.dispose();
  }
}

