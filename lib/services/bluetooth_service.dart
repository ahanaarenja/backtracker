import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as blue;

/// Data model for spine alignment data from ESP32 strap
class SpineData {
  final double angle1;  // First spine sensor angle
  final double angle2;  // Second spine sensor angle
  final double angle3;  // Third spine sensor angle
  final DateTime timestamp;

  SpineData({
    required this.angle1,
    required this.angle2,
    required this.angle3,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory SpineData.fromJson(Map<String, dynamic> json) {
    return SpineData(
      angle1: (json['angle1'] ?? json['a1'] ?? 0.0).toDouble(),
      angle2: (json['angle2'] ?? json['a2'] ?? 0.0).toDouble(),
      angle3: (json['angle3'] ?? json['a3'] ?? 0.0).toDouble(),
    );
  }

  /// Parse custom format: "A1:30.5 A2:45.2 A3:12.8"
  factory SpineData.fromCustomFormat(String data) {
    double a1 = 0, a2 = 0, a3 = 0;
    
    try {
      List<String> parts = data.trim().split(' ');
      for (String part in parts) {
        if (part.contains(':')) {
          List<String> keyValue = part.split(':');
          if (keyValue.length == 2) {
            String key = keyValue[0].toLowerCase();
            String value = keyValue[1];
            
            switch (key) {
              case 'a1':
              case 'angle1':
                a1 = double.tryParse(value) ?? 0.0;
                break;
              case 'a2':
              case 'angle2':
                a2 = double.tryParse(value) ?? 0.0;
                break;
              case 'a3':
              case 'angle3':
                a3 = double.tryParse(value) ?? 0.0;
                break;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error parsing custom format: $e');
    }
    
    return SpineData(angle1: a1, angle2: a2, angle3: a3);
  }

  @override
  String toString() => 'SpineData(a1: $angle1, a2: $angle2, a3: $angle3)';
}

/// Singleton Bluetooth service for BackTracker ESP32 strap
class BluetoothService {
  static final BluetoothService _instance = BluetoothService._internal();
  factory BluetoothService() => _instance;
  BluetoothService._internal();

  // BLE UUIDs - Update these to match your ESP32 configuration
  static const String serviceUuid = "4fafc201-1fb5-459e-8dec-bc11c7f76b88";
  static const String writeCharacteristicUuid = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  static const String readCharacteristicUuid = "beb5483e-36e1-4688-b7f5-ea07361b26a7";

  blue.BluetoothDevice? _device;
  blue.BluetoothCharacteristic? _writeCharacteristic;
  blue.BluetoothCharacteristic? _readCharacteristic;
  StreamSubscription? _valueSubscription;
  StreamSubscription? _connectionSubscription;

  // Stream controller for spine data
  final StreamController<SpineData> _spineDataController = StreamController<SpineData>.broadcast();
  Stream<SpineData> get spineDataStream => _spineDataController.stream;

  // Connection status
  final StreamController<bool> _connectionStatusController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;

  bool _isReading = false;
  bool get isConnected => _device != null && _device!.isConnected;
  String? get connectedDeviceName => _device?.platformName;
  blue.BluetoothDevice? get connectedDevice => _device;

  /// Check if Bluetooth is available
  Future<bool> isBluetoothAvailable() async {
    try {
      return await blue.FlutterBluePlus.isSupported;
    } catch (e) {
      debugPrint('Bluetooth not available: $e');
      return false;
    }
  }

  /// Check if Bluetooth is enabled
  Future<bool> isBluetoothEnabled() async {
    try {
      blue.BluetoothAdapterState state = await blue.FlutterBluePlus.adapterState.first;
      return state == blue.BluetoothAdapterState.on;
    } catch (e) {
      debugPrint('Bluetooth not enabled: $e');
      return false;
    }
  }

  /// Scan for available devices
  Stream<List<blue.ScanResult>> scanForDevices() {
    // Stop any existing scan first
    blue.FlutterBluePlus.stopScan();
    
    // Start fresh scan with longer timeout
    blue.FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 15),
      androidUsesFineLocation: true,
    );
    return blue.FlutterBluePlus.scanResults;
  }

  /// Start scanning
  Future<void> startScan() async {
    try {
      // Stop any existing scan first
      await blue.FlutterBluePlus.stopScan();
      
      await blue.FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        androidUsesFineLocation: true,
      );
      debugPrint('Scan started successfully');
    } catch (e) {
      debugPrint('Error starting scan: $e');
    }
  }

  /// Stop scanning
  Future<void> stopScan() async {
    try {
      await blue.FlutterBluePlus.stopScan();
    } catch (e) {
      debugPrint('Error stopping scan: $e');
    }
  }

  /// Get devices from scan results
  List<blue.BluetoothDevice> getDevicesFromScanResults(List<blue.ScanResult> scanResults) {
    return scanResults.map((result) => result.device).toList();
  }

  /// Connect to a device
  Future<bool> connectToDevice(blue.BluetoothDevice device) async {
    _device = device;
    try {
      await _device!.connect(timeout: const Duration(seconds: 15));
      
      // Listen for disconnection
      _connectionSubscription?.cancel();
      _connectionSubscription = _device!.connectionState.listen((state) {
        if (state == blue.BluetoothConnectionState.disconnected) {
          _connectionStatusController.add(false);
          _cleanup();
        } else if (state == blue.BluetoothConnectionState.connected) {
          _connectionStatusController.add(true);
        }
      });

      // Discover services
      List<blue.BluetoothService> services = await _device!.discoverServices();
      
      for (blue.BluetoothService service in services) {
        if (service.uuid.toString().toLowerCase() == serviceUuid.toLowerCase()) {
          for (blue.BluetoothCharacteristic characteristic in service.characteristics) {
            if (characteristic.uuid.toString().toLowerCase() == writeCharacteristicUuid.toLowerCase()) {
              _writeCharacteristic = characteristic;
              debugPrint("Discovered Write Characteristic");
            }
            if (characteristic.uuid.toString().toLowerCase() == readCharacteristicUuid.toLowerCase()) {
              _readCharacteristic = characteristic;
              debugPrint("Discovered Read Characteristic");
              
              // Enable notifications
              await _readCharacteristic!.setNotifyValue(true);
            }
          }
        }
      }

      _connectionStatusController.add(true);
      return true;
    } catch (e) {
      debugPrint("Error connecting to device: $e");
      _connectionStatusController.add(false);
      return false;
    }
  }

  /// Start reading spine data from ESP32
  void startReading() {
    if (_readCharacteristic == null || _isReading) return;
    
    _isReading = true;
    _valueSubscription?.cancel();
    _valueSubscription = _readCharacteristic!.onValueReceived.listen((value) {
      try {
        String receivedData = utf8.decode(value);
        debugPrint("Received: $receivedData");
        
        SpineData spineData;
        try {
          // Try JSON first
          Map<String, dynamic> json = jsonDecode(receivedData);
          spineData = SpineData.fromJson(json);
        } catch (jsonError) {
          // Fall back to custom format
          spineData = SpineData.fromCustomFormat(receivedData);
        }
        
        _spineDataController.add(spineData);
      } catch (e) {
        debugPrint('Error parsing spine data: $e');
      }
    });
  }

  /// Stop reading spine data
  void stopReading() {
    _isReading = false;
    _valueSubscription?.cancel();
    _valueSubscription = null;
  }

  /// Send command to ESP32
  Future<void> sendCommand(String command) async {
    if (_writeCharacteristic == null || _device == null) {
      debugPrint("Write characteristic not found or not connected.");
      return;
    }
    
    try {
      List<int> dataBytes = utf8.encode(command);
      await _writeCharacteristic!.write(dataBytes, withoutResponse: false);
      debugPrint("Sent command: $command");
    } catch (e) {
      debugPrint("Error sending command: $e");
    }
  }

  /// Disconnect from device
  Future<void> disconnect() async {
    stopReading();
    _connectionSubscription?.cancel();
    try {
      await _device?.disconnect();
    } catch (e) {
      debugPrint('Error disconnecting: $e');
    }
    _cleanup();
    _connectionStatusController.add(false);
  }

  void _cleanup() {
    _device = null;
    _writeCharacteristic = null;
    _readCharacteristic = null;
  }

  /// Dispose resources
  void dispose() {
    stopReading();
    _connectionSubscription?.cancel();
    _spineDataController.close();
    _connectionStatusController.close();
  }
}
