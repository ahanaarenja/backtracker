import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../models/pose_definition.dart';
import 'angle_calculator.dart';

/// Exercise phases
enum ExercisePhase {
  standing,      // Top/Ready position - ANALYZE WITH STANDING POSE
  goingDown,     // Transitioning down
  bottom,        // Bottom position - ANALYZE WITH BOTTOM POSE
  goingUp,       // Transitioning up
  unknown,       // Can't determine
}

/// Phase detection result
class PhaseResult {
  final ExercisePhase phase;
  final String message;
  final bool shouldAnalyze;
  final PoseDefinition? poseToAnalyze; // Which pose definition to use
  final double? keyAngle; // The angle used for detection

  PhaseResult({
    required this.phase,
    required this.message,
    required this.shouldAnalyze,
    this.poseToAnalyze,
    this.keyAngle,
  });
}

/// Detects which phase of an exercise the user is in
class PhaseDetector {
  // Track previous angles for direction detection
  double? _previousKeyAngle;
  ExercisePhase _previousPhase = ExercisePhase.unknown;
  
  // Smoothing for phase transitions (avoid flickering)
  int _phaseHoldCounter = 0;
  static const int _phaseHoldThreshold = 3; // frames to hold before changing
  static const double angleChangeThreshold = 3; // Minimum change to detect movement

  /// Detect phase for any exercise
  PhaseResult detectPhase(Pose pose, ExerciseDefinition exercise) {
    // Get key angle based on exercise type
    double? keyAngle;
    
    final lowerName = exercise.name.toLowerCase();
    
    if (lowerName.contains('squat') || lowerName.contains('lunge')) {
      keyAngle = _getKneeAngle(pose);
    } else if (lowerName.contains('push') || lowerName.contains('plank')) {
      keyAngle = _getElbowAngle(pose);
    } else if (lowerName.contains('glute') || lowerName.contains('bridge')) {
      keyAngle = _getHipAngle(pose);
    } else if (lowerName.contains('bird dog')) {
      keyAngle = _getSpineAngle(pose);
    } else if (lowerName.contains('cat') || lowerName.contains('cow')) {
      keyAngle = _getSpineAngle(pose);
    } else {
      keyAngle = _getKneeAngle(pose);
    }

    if (keyAngle == null) {
      return PhaseResult(
        phase: ExercisePhase.unknown,
        message: 'Position yourself so body is visible',
        shouldAnalyze: false,
      );
    }

    // Determine direction of movement
    double angleChange = 0;
    if (_previousKeyAngle != null) {
      angleChange = keyAngle - _previousKeyAngle!;
    }

    // Determine phase based on angle and thresholds
    ExercisePhase detectedPhase;
    String message;
    bool shouldAnalyze;
    PoseDefinition? poseToAnalyze;

    if (keyAngle > exercise.standingThreshold) {
      // STANDING POSITION - Analyze with standing pose
      detectedPhase = ExercisePhase.standing;
      message = 'Standing Position';
      shouldAnalyze = true;
      poseToAnalyze = exercise.standingPose;
    } else if (keyAngle < exercise.bottomThreshold) {
      // BOTTOM POSITION - Analyze with bottom pose
      detectedPhase = ExercisePhase.bottom;
      message = '${exercise.name} Position';
      shouldAnalyze = true;
      poseToAnalyze = exercise.bottomPose;
    } else if (angleChange < -angleChangeThreshold) {
      // Angle decreasing = going down
      detectedPhase = ExercisePhase.goingDown;
      message = 'Going down...';
      shouldAnalyze = false;
    } else if (angleChange > angleChangeThreshold) {
      // Angle increasing = going up
      detectedPhase = ExercisePhase.goingUp;
      message = 'Coming up...';
      shouldAnalyze = false;
    } else {
      // In between, not moving much - analyze the closer position
      if (keyAngle < (exercise.standingThreshold + exercise.bottomThreshold) / 2) {
        // Closer to bottom
        detectedPhase = ExercisePhase.bottom;
        message = '${exercise.name} Position';
        shouldAnalyze = true;
        poseToAnalyze = exercise.bottomPose;
      } else {
        // Closer to top
        detectedPhase = ExercisePhase.standing;
        message = 'Standing Position';
        shouldAnalyze = true;
        poseToAnalyze = exercise.standingPose;
      }
    }

    // Apply phase hold to prevent flickering
    if (detectedPhase != _previousPhase) {
      _phaseHoldCounter++;
      if (_phaseHoldCounter < _phaseHoldThreshold) {
        // Keep previous phase but allow analysis if we were already analyzing
        if (_previousPhase == ExercisePhase.standing) {
          poseToAnalyze = exercise.standingPose;
          shouldAnalyze = true;
        } else if (_previousPhase == ExercisePhase.bottom) {
          poseToAnalyze = exercise.bottomPose;
          shouldAnalyze = true;
        }
        detectedPhase = _previousPhase;
      } else {
        // Commit to new phase
        _phaseHoldCounter = 0;
        _previousPhase = detectedPhase;
      }
    } else {
      _phaseHoldCounter = 0;
    }

    _previousKeyAngle = keyAngle;

    return PhaseResult(
      phase: detectedPhase,
      message: message,
      shouldAnalyze: shouldAnalyze,
      poseToAnalyze: poseToAnalyze,
      keyAngle: keyAngle,
    );
  }

  double? _getKneeAngle(Pose pose) {
    final leftKnee = AngleCalculator.getJointAngle(
      pose,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.leftKnee,
      PoseLandmarkType.leftAnkle,
    );
    
    final rightKnee = AngleCalculator.getJointAngle(
      pose,
      PoseLandmarkType.rightHip,
      PoseLandmarkType.rightKnee,
      PoseLandmarkType.rightAnkle,
    );

    if (leftKnee != null && rightKnee != null) {
      return (leftKnee + rightKnee) / 2;
    }
    return leftKnee ?? rightKnee;
  }

  double? _getElbowAngle(Pose pose) {
    final leftElbow = AngleCalculator.getJointAngle(
      pose,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.leftElbow,
      PoseLandmarkType.leftWrist,
    );
    
    final rightElbow = AngleCalculator.getJointAngle(
      pose,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.rightElbow,
      PoseLandmarkType.rightWrist,
    );

    if (leftElbow != null && rightElbow != null) {
      return (leftElbow + rightElbow) / 2;
    }
    return leftElbow ?? rightElbow;
  }

  double? _getSpineAngle(Pose pose) {
    return AngleCalculator.getJointAngle(
      pose,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.leftKnee,
    );
  }

  double? _getHipAngle(Pose pose) {
    // Hip angle: shoulder -> hip -> knee (same as spine but for glute bridge context)
    final leftHip = AngleCalculator.getJointAngle(
      pose,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.leftKnee,
    );
    
    final rightHip = AngleCalculator.getJointAngle(
      pose,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.rightHip,
      PoseLandmarkType.rightKnee,
    );

    if (leftHip != null && rightHip != null) {
      return (leftHip + rightHip) / 2;
    }
    return leftHip ?? rightHip;
  }

  void reset() {
    _previousKeyAngle = null;
    _previousPhase = ExercisePhase.unknown;
    _phaseHoldCounter = 0;
  }
}


