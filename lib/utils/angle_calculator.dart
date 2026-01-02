import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Utility class for calculating angles between body landmarks
class AngleCalculator {
  /// Calculate the angle at point B formed by points A, B, and C
  /// Returns angle in degrees (0-180)
  static double calculateAngle(
    PoseLandmark pointA,
    PoseLandmark pointB,
    PoseLandmark pointC,
  ) {
    final radians = atan2(pointC.y - pointB.y, pointC.x - pointB.x) -
        atan2(pointA.y - pointB.y, pointA.x - pointB.x);
    
    var angle = (radians * 180 / pi).abs();
    
    if (angle > 180) {
      angle = 360 - angle;
    }
    
    return angle;
  }

  /// Calculate angle from coordinates directly
  static double calculateAngleFromCoords(
    double ax, double ay,
    double bx, double by,
    double cx, double cy,
  ) {
    final radians = atan2(cy - by, cx - bx) - atan2(ay - by, ax - bx);
    var angle = (radians * 180 / pi).abs();
    
    if (angle > 180) {
      angle = 360 - angle;
    }
    
    return angle;
  }

  /// Get angle for a specific joint from pose
  /// Returns null if required landmarks are not available
  static double? getJointAngle(
    Pose pose,
    PoseLandmarkType pointAType,
    PoseLandmarkType pointBType,
    PoseLandmarkType pointCType, {
    double minConfidence = 0.5,
  }) {
    final pointA = pose.landmarks[pointAType];
    final pointB = pose.landmarks[pointBType];
    final pointC = pose.landmarks[pointCType];

    if (pointA == null || pointB == null || pointC == null) {
      return null;
    }

    if (pointA.likelihood < minConfidence ||
        pointB.likelihood < minConfidence ||
        pointC.likelihood < minConfidence) {
      return null;
    }

    return calculateAngle(pointA, pointB, pointC);
  }

  /// Calculate all common body angles from a pose
  static Map<String, double?> calculateAllAngles(Pose pose) {
    return {
      // Spine angles
      'neck': getJointAngle(
        pose,
        PoseLandmarkType.leftEar,
        PoseLandmarkType.leftShoulder,
        PoseLandmarkType.leftHip,
      ),
      'spine_left': getJointAngle(
        pose,
        PoseLandmarkType.leftShoulder,
        PoseLandmarkType.leftHip,
        PoseLandmarkType.leftKnee,
      ),
      'spine_right': getJointAngle(
        pose,
        PoseLandmarkType.rightShoulder,
        PoseLandmarkType.rightHip,
        PoseLandmarkType.rightKnee,
      ),
      
      // Arm angles
      'left_elbow': getJointAngle(
        pose,
        PoseLandmarkType.leftShoulder,
        PoseLandmarkType.leftElbow,
        PoseLandmarkType.leftWrist,
      ),
      'right_elbow': getJointAngle(
        pose,
        PoseLandmarkType.rightShoulder,
        PoseLandmarkType.rightElbow,
        PoseLandmarkType.rightWrist,
      ),
      'left_shoulder': getJointAngle(
        pose,
        PoseLandmarkType.leftElbow,
        PoseLandmarkType.leftShoulder,
        PoseLandmarkType.leftHip,
      ),
      'right_shoulder': getJointAngle(
        pose,
        PoseLandmarkType.rightElbow,
        PoseLandmarkType.rightShoulder,
        PoseLandmarkType.rightHip,
      ),
      
      // Leg angles
      'left_knee': getJointAngle(
        pose,
        PoseLandmarkType.leftHip,
        PoseLandmarkType.leftKnee,
        PoseLandmarkType.leftAnkle,
      ),
      'right_knee': getJointAngle(
        pose,
        PoseLandmarkType.rightHip,
        PoseLandmarkType.rightKnee,
        PoseLandmarkType.rightAnkle,
      ),
      'left_hip': getJointAngle(
        pose,
        PoseLandmarkType.leftShoulder,
        PoseLandmarkType.leftHip,
        PoseLandmarkType.leftKnee,
      ),
      'right_hip': getJointAngle(
        pose,
        PoseLandmarkType.rightShoulder,
        PoseLandmarkType.rightHip,
        PoseLandmarkType.rightKnee,
      ),
      'left_ankle': getJointAngle(
        pose,
        PoseLandmarkType.leftKnee,
        PoseLandmarkType.leftAnkle,
        PoseLandmarkType.leftFootIndex,
      ),
      'right_ankle': getJointAngle(
        pose,
        PoseLandmarkType.rightKnee,
        PoseLandmarkType.rightAnkle,
        PoseLandmarkType.rightFootIndex,
      ),
    };
  }
}


