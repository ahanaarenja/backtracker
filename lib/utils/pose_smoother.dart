import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Smooths pose landmarks using exponential moving average
/// to reduce jitter and flickering in real-time detection
class PoseSmoother {
  // Smoothing factor: 0.0 = no smoothing (use new value), 1.0 = full smoothing (keep old value)
  // Higher values = more stable but slower to respond
  final double smoothingFactor;
  
  // Minimum confidence to consider a landmark valid
  final double minConfidence;
  
  // Store previous landmark positions
  Map<PoseLandmarkType, _SmoothedLandmark> _previousLandmarks = {};
  
  PoseSmoother({
    this.smoothingFactor = 0.5,
    this.minConfidence = 0.5,
  });

  /// Smooth a list of poses and return smoothed versions
  List<Pose> smooth(List<Pose> poses) {
    if (poses.isEmpty) return poses;
    
    // For simplicity, only smooth the first detected pose
    final pose = poses.first;
    final smoothedLandmarks = <PoseLandmarkType, PoseLandmark>{};
    
    pose.landmarks.forEach((type, landmark) {
      // Skip low confidence landmarks
      if (landmark.likelihood < minConfidence) {
        // Still include it but don't smooth
        smoothedLandmarks[type] = landmark;
        return;
      }
      
      final previous = _previousLandmarks[type];
      
      if (previous == null) {
        // First time seeing this landmark, use as-is
        _previousLandmarks[type] = _SmoothedLandmark(
          x: landmark.x,
          y: landmark.y,
          z: landmark.z,
        );
        smoothedLandmarks[type] = landmark;
      } else {
        // Apply exponential smoothing
        final smoothedX = _exponentialSmooth(previous.x, landmark.x);
        final smoothedY = _exponentialSmooth(previous.y, landmark.y);
        final smoothedZ = _exponentialSmooth(previous.z, landmark.z);
        
        // Update stored values
        _previousLandmarks[type] = _SmoothedLandmark(
          x: smoothedX,
          y: smoothedY,
          z: smoothedZ,
        );
        
        // Create smoothed landmark
        smoothedLandmarks[type] = PoseLandmark(
          type: type,
          x: smoothedX,
          y: smoothedY,
          z: smoothedZ,
          likelihood: landmark.likelihood,
        );
      }
    });
    
    // Return list with smoothed pose
    return [_SmoothedPose(landmarks: smoothedLandmarks)];
  }
  
  double _exponentialSmooth(double previous, double current) {
    return previous * smoothingFactor + current * (1 - smoothingFactor);
  }
  
  /// Reset the smoother (e.g., when switching cameras or restarting)
  void reset() {
    _previousLandmarks.clear();
  }
}

class _SmoothedLandmark {
  final double x;
  final double y;
  final double z;
  
  _SmoothedLandmark({
    required this.x,
    required this.y,
    required this.z,
  });
}

/// A pose implementation that holds smoothed landmarks
class _SmoothedPose implements Pose {
  @override
  final Map<PoseLandmarkType, PoseLandmark> landmarks;
  
  _SmoothedPose({required this.landmarks});
}


