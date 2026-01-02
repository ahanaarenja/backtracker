import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'models/pose_definition.dart';
import 'painters/pose_painter.dart';
import 'services/analytics_service.dart';
import 'services/bluetooth_service.dart';
import 'utils/form_analyzer.dart';
import 'utils/phase_detector.dart';
import 'utils/pose_smoother.dart';
import 'colours.dart';

class FormCheckScreen extends StatefulWidget {
  final Map<String, dynamic> exerciseData;
  final bool useStrap;

  const FormCheckScreen({
    super.key, 
    required this.exerciseData,
    this.useStrap = false,
  });

  @override
  State<FormCheckScreen> createState() => _FormCheckScreenState();
}

class _FormCheckScreenState extends State<FormCheckScreen>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  int _cameraIndex = -1;
  bool _isInitialized = false;
  bool _isDetecting = false;
  bool _isDisposed = false;
  
  // Frame skipping for performance
  int _frameCount = 0;
  static const int _processEveryNFrames = 1; // Process every frame (change to 2 or 3 if still laggy)
  
  late PoseDetector _poseDetector;
  late PoseSmoother _poseSmoother;
  late PhaseDetector _phaseDetector;
  late ExerciseDefinition _exerciseDefinition;
  List<Pose> _poses = [];
  
  // Phase detection
  PhaseResult? _phaseResult;
  ExercisePhase _currentPhase = ExercisePhase.unknown;
  String _currentPoseName = '';
  
  // Form analysis
  FormAnalysisResult? _analysisResult;
  Map<String, Color>? _segmentColors;
  
  // For coordinate translation
  Size? _imageSize;
  InputImageRotation? _rotation;
  CameraLensDirection _cameraLensDirection = CameraLensDirection.front;
  
  late AnimationController _pulseController;
  double _displayedScore = 0;
  
  // Analytics tracking
  late DateTime _startTime;
  double _maxAccuracy = 0;
  final AnalyticsService _analyticsService = AnalyticsService();

  // Bluetooth strap tracking
  final BluetoothService _bluetoothService = BluetoothService();
  StreamSubscription<SpineData>? _spineDataSubscription;
  SpineData? _latestSpineData;

  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now(); // Track when exercise started
    _exerciseDefinition = BackTrackerExercises.getByName(widget.exerciseData["name"] ?? "");
    _initializePoseDetector();
    _initializeAnimations();
    _initializeCamera();
    _initializeBluetooth();
  }

  void _initializeBluetooth() {
    // Only start reading if strap is enabled and Bluetooth is connected
    if (widget.useStrap && _bluetoothService.isConnected) {
      _bluetoothService.startReading();
      _spineDataSubscription = _bluetoothService.spineDataStream.listen((data) {
        if (mounted && !_isDisposed) {
          setState(() {
            _latestSpineData = data;
          });
          debugPrint('Spine data: ${data.angle1}, ${data.angle2}, ${data.angle3}');
        }
      });
    }
  }

  void _initializePoseDetector() {
    _poseDetector = PoseDetector(
      options: PoseDetectorOptions(
        mode: PoseDetectionMode.stream,
        model: PoseDetectionModel.base, // Faster detection (base is ~2x faster than accurate)
      ),
    );
    // Very low smoothing = instant response (0.05 means 95% new value, 5% old value)
    _poseSmoother = PoseSmoother(smoothingFactor: 0.05, minConfidence: 0.3);
    _phaseDetector = PhaseDetector();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  Future<void> _initializeCamera() async {
    if (_isDisposed) return;
    
    final status = await Permission.camera.request();
    if (status != PermissionStatus.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission is required')),
        );
      }
      return;
    }

    _cameras = await availableCameras();
    if (_cameras == null || _cameras!.isEmpty) return;

    for (var i = 0; i < _cameras!.length; i++) {
      if (_cameras![i].lensDirection == CameraLensDirection.front) {
        _cameraIndex = i;
        break;
      }
    }
    if (_cameraIndex == -1) _cameraIndex = 0;

    await _startLiveFeed();
  }

  Future<void> _startLiveFeed() async {
    if (_isDisposed || _cameras == null) return;
    
    final camera = _cameras![_cameraIndex];
    _cameraLensDirection = camera.lensDirection;
    
    _cameraController = CameraController(
      camera,
      ResolutionPreset.medium, // Medium gives good balance of speed and quality
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    try {
      await _cameraController!.initialize();
      
      if (_isDisposed) {
        await _cameraController?.dispose();
        return;
      }
      
      await _cameraController!.startImageStream(_processCameraImage);
      
      if (mounted && !_isDisposed) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  Future<void> _stopLiveFeed() async {
    _isInitialized = false;
    
    try {
      if (_cameraController != null) {
        if (_cameraController!.value.isStreamingImages) {
          await _cameraController!.stopImageStream();
        }
        await _cameraController!.dispose();
      }
    } catch (e) {
      debugPrint('Error stopping camera: $e');
    }
    
    _cameraController = null;
  }

  void _processCameraImage(CameraImage image) {
    // Skip if already processing or disposed
    if (_isDetecting || _isDisposed) return;
    
    // Frame skipping - only process every N frames
    _frameCount++;
    if (_frameCount % _processEveryNFrames != 0) return;
    
    _isDetecting = true;
    
    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) {
      _isDetecting = false;
      return;
    }
    
    _processImage(inputImage);
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_cameraController == null || _isDisposed) return null;

    final camera = _cameras![_cameraIndex];
    final sensorOrientation = camera.sensorOrientation;
    
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation =
          _orientations[_cameraController!.value.deviceOrientation];
      if (rotationCompensation == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    if (rotation == null) return null;

    _rotation = rotation;
    _imageSize = Size(image.width.toDouble(), image.height.toDouble());

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) {
      return null;
    }

    if (image.planes.length != 1) return null;
    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  Future<void> _processImage(InputImage inputImage) async {
    if (_isDisposed) {
      _isDetecting = false;
      return;
    }
    
    try {
      final poses = await _poseDetector.processImage(inputImage);
      
      if (_isDisposed || !mounted) {
        _isDetecting = false;
        return;
      }
      
      if (poses.isNotEmpty) {
        final pose = poses.first;
        
        // Quick phase detection (lightweight)
        final phaseResult = _phaseDetector.detectPhase(pose, _exerciseDefinition);
        
        // Only do heavy analysis every few frames to reduce load
        FormAnalysisResult? analysis;
        if (phaseResult.shouldAnalyze && phaseResult.poseToAnalyze != null) {
          analysis = FormAnalyzer.analyze(pose, phaseResult.poseToAnalyze!);
        }

        // Track max accuracy
        if (analysis != null && analysis.overallScore > _maxAccuracy) {
          _maxAccuracy = analysis.overallScore;
        }

        // Single setState call with all updates
        setState(() {
          _poses = poses;
          _phaseResult = phaseResult;
          _currentPhase = phaseResult.phase;
          if (analysis != null) {
            _currentPoseName = phaseResult.poseToAnalyze!.name;
            _analysisResult = analysis;
            _segmentColors = analysis.segmentColors;
            _displayedScore = analysis.overallScore;
          } else {
            _currentPoseName = '';
            _segmentColors = null;
          }
        });
      } else {
        setState(() {
          _poses = [];
          _phaseResult = null;
          _currentPhase = ExercisePhase.unknown;
          _currentPoseName = '';
        });
      }
    } catch (e) {
      debugPrint('Error processing image: $e');
    }

    _isDetecting = false;
  }

  void _toggleCamera() async {
    if (_cameras == null || _cameras!.length < 2 || _isDisposed) return;

    setState(() => _isInitialized = false);
    
    _cameraIndex = (_cameraIndex + 1) % _cameras!.length;
    _poseSmoother.reset();
    _phaseDetector.reset();

    await _stopLiveFeed();
    await _startLiveFeed();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _stopLiveFeed();
    _poseDetector.close();
    _pulseController.dispose();
    // Stop Bluetooth reading but keep connection
    _spineDataSubscription?.cancel();
    if (widget.useStrap) {
      _bluetoothService.stopReading();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      body: SafeArea(
        child: Stack(
          children: [
            _buildCameraPreview(),
            _buildOverlayGradient(),
            _buildTopBar(),
            _buildScoreDisplay(),
            _buildFeedbackPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    // Check if camera is properly initialized and not disposed
    if (!_isInitialized || 
        _cameraController == null || 
        !_cameraController!.value.isInitialized ||
        _isDisposed) {
      return Container(
        color: const Color(0xFF0A0E21),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: dark),
              const SizedBox(height: 16),
              const Text('Initializing Camera...', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      );
    }

    final previewSize = _cameraController!.value.previewSize;
    if (previewSize == null) {
      return Center(child: CircularProgressIndicator(color: dark));
    }

    // For portrait mode, swap width and height
    final screenSize = MediaQuery.of(context).size;
    final previewWidth = previewSize.height;
    final previewHeight = previewSize.width;
    
    // Calculate scale to fill screen
    final scaleX = screenSize.width / previewWidth;
    final scaleY = screenSize.height / previewHeight;
    final scale = scaleX > scaleY ? scaleX : scaleY;
    
    final scaledWidth = previewWidth * scale;
    final scaledHeight = previewHeight * scale;

    return ClipRect(
      child: OverflowBox(
        maxWidth: scaledWidth,
        maxHeight: scaledHeight,
        child: SizedBox(
          width: scaledWidth,
          height: scaledHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Camera preview
              CameraPreview(_cameraController!),
              // Pose overlay - use same size as camera preview
              if (_poses.isNotEmpty && _imageSize != null && _rotation != null)
                CustomPaint(
                  size: Size(scaledWidth, scaledHeight),
                  painter: PosePainter(
                    _poses,
                    _imageSize!,
                    _rotation!,
                    _cameraLensDirection,
                    segmentColors: _segmentColors,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverlayGradient() {
    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.6),
                Colors.transparent,
                Colors.transparent,
                Colors.black.withOpacity(0.85),
              ],
              stops: const [0.0, 0.15, 0.6, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.fitness_center, color: dark, size: 20),
                const SizedBox(width: 8),
                Text(
                  widget.exerciseData["name"] ?? "Exercise",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _toggleCamera,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.cameraswitch, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreDisplay() {
    final isAnalyzing = _phaseResult?.shouldAnalyze ?? false;
    final score = isAnalyzing ? _displayedScore : 0.0;
    final quality = _analysisResult?.overallQuality ?? FormQuality.bad;
    
    Color scoreColor;
    
    if (!isAnalyzing) {
      scoreColor = dark;
    } else {
      switch (quality) {
        case FormQuality.good:
          scoreColor = const Color(0xFF4CAF50);
          break;
        case FormQuality.warning:
          scoreColor = const Color(0xFFFFEB3B);
          break;
        case FormQuality.bad:
          scoreColor = const Color(0xFFF44336);
          break;
      }
    }

    String message;
    if (_phaseResult != null) {
      if (isAnalyzing && _analysisResult != null) {
        message = _analysisResult!.primaryFeedback;
      } else {
        message = _phaseResult!.message;
      }
    } else {
      message = 'Position yourself in frame';
    }

    return Positioned(
      top: 80,
      left: 0,
      right: 0,
      child: Column(
        children: [
          // Circular score indicator
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withOpacity(0.5),
              border: Border.all(
                color: scoreColor.withOpacity(0.5),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: scoreColor.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: isAnalyzing ? score / 100 : 0,
                    strokeWidth: 8,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isAnalyzing)
                      Text(
                        '${score.toInt()}',
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: scoreColor,
                        ),
                      )
                    else
                      Icon(
                        _getPhaseIcon(_currentPhase),
                        size: 40,
                        color: scoreColor,
                      ),
                    Text(
                      isAnalyzing ? 'SCORE' : _getPhaseLabel(_currentPhase).toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.7),
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Primary feedback
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: scoreColor.withOpacity(0.3)),
            ),
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getPhaseColor(ExercisePhase phase) {
    switch (phase) {
      case ExercisePhase.standing:
        return const Color(0xFF4ECDC4);
      case ExercisePhase.goingDown:
        return dark;
      case ExercisePhase.bottom:
        return const Color(0xFFFF6B6B);
      case ExercisePhase.goingUp:
        return dark;
      case ExercisePhase.unknown:
        return Colors.grey;
    }
  }

  IconData _getPhaseIcon(ExercisePhase phase) {
    switch (phase) {
      case ExercisePhase.standing:
        return Icons.accessibility_new;
      case ExercisePhase.goingDown:
        return Icons.arrow_downward;
      case ExercisePhase.bottom:
        return Icons.fitness_center;
      case ExercisePhase.goingUp:
        return Icons.arrow_upward;
      case ExercisePhase.unknown:
        return Icons.help_outline;
    }
  }

  String _getPhaseLabel(ExercisePhase phase) {
    switch (phase) {
      case ExercisePhase.standing:
        return 'Standing';
      case ExercisePhase.goingDown:
        return 'Going Down';
      case ExercisePhase.bottom:
        return 'Bottom';
      case ExercisePhase.goingUp:
        return 'Coming Up';
      case ExercisePhase.unknown:
        return 'Get Ready';
    }
  }

  Widget _buildFeedbackPanel() {
    final isAnalyzing = _phaseResult?.shouldAnalyze ?? false;
    
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Spine data indicator (when strap is enabled)
              if (widget.useStrap) ...[
                _buildSpineDataIndicator(),
                const SizedBox(height: 8),
              ],
              // Legend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem('Good', const Color(0xFF4CAF50)),
                  const SizedBox(width: 16),
                  _buildLegendItem('Adjust', const Color(0xFFFFEB3B)),
                  const SizedBox(width: 16),
                  _buildLegendItem('Wrong', const Color(0xFFF44336)),
                ],
              ),
              const SizedBox(height: 12),
              if (isAnalyzing && _analysisResult != null) ...[
                ..._analysisResult!.angleResults.take(2).map((result) => 
                  _buildCompactAngleRow(result)
                ),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    _phaseResult?.message ?? 'Position yourself in frame',
                    style: TextStyle(
                      color: dark,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              // Done button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    // Calculate duration in minutes
                    final durationMinutes = DateTime.now().difference(_startTime).inMinutes;
                    
                    // Save to Firebase (just time and accuracy)
                    await _analyticsService.saveExerciseSession(
                      durationMinutes: durationMinutes > 0 ? durationMinutes : 1,
                      accuracy: _maxAccuracy,
                    );
                    
                    if (mounted) {
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dark,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactAngleRow(AngleAnalysisResult result) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: result.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              result.displayName,
              style: TextStyle(color: dark.withOpacity(0.7), fontSize: 13),
            ),
          ),
          if (result.currentAngle != null)
            Text(
              '${result.currentAngle!.toInt()}°',
              style: TextStyle(
                color: result.color,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          const SizedBox(width: 6),
          Text(
            '→${result.idealAngle.toInt()}°',
            style: TextStyle(
              color: dark.withOpacity(0.4),
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 50,
            height: 5,
            child: LinearProgressIndicator(
              value: result.score / 100,
              backgroundColor: dark.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(result.color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: dark.withOpacity(0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSpineDataIndicator() {
    final isConnected = _bluetoothService.isConnected;
    final hasData = _latestSpineData != null;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isConnected ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isConnected ? Colors.green.shade200 : Colors.orange.shade200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
            size: 16,
            color: isConnected ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 8),
          if (isConnected && hasData) ...[
            Text(
              'Spine: ',
              style: TextStyle(
                fontSize: 11,
                color: dark.withOpacity(0.7),
              ),
            ),
            Text(
              '${_latestSpineData!.angle1.toStringAsFixed(1)}°',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            Text(' | ', style: TextStyle(color: dark.withOpacity(0.3))),
            Text(
              '${_latestSpineData!.angle2.toStringAsFixed(1)}°',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            Text(' | ', style: TextStyle(color: dark.withOpacity(0.3))),
            Text(
              '${_latestSpineData!.angle3.toStringAsFixed(1)}°',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ] else if (isConnected) ...[
            Text(
              'Strap connected - awaiting data',
              style: TextStyle(fontSize: 11, color: Colors.green.shade700),
            ),
          ] else ...[
            Text(
              'Strap not connected',
              style: TextStyle(fontSize: 11, color: Colors.orange.shade700),
            ),
          ],
        ],
      ),
    );
  }
}
