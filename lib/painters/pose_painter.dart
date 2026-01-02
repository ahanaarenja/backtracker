import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import 'coordinates_translator.dart';

class _Connection {
  final PoseLandmarkType from;
  final PoseLandmarkType to;
  final String segment;

  const _Connection(this.from, this.to, this.segment);
}

class PosePainter extends CustomPainter {
  PosePainter(
    this.poses,
    this.imageSize,
    this.rotation,
    this.cameraLensDirection, {
    this.segmentColors,
  });

  final List<Pose> poses;
  final Size imageSize;
  final InputImageRotation rotation;
  final CameraLensDirection cameraLensDirection;
  final Map<String, Color>? segmentColors;

  // Default color when no segment colors provided
  static const Color defaultColor = Color(0xFF00E5FF);
  
  // All skeleton connections with their segment names
  static const List<_Connection> _connections = [
    // Torso
    _Connection(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip, 'left_torso'),
    _Connection(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip, 'right_torso'),
    _Connection(PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder, 'shoulders'),
    _Connection(PoseLandmarkType.leftHip, PoseLandmarkType.rightHip, 'hips'),
    
    // Left arm
    _Connection(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow, 'left_upper_arm'),
    _Connection(PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist, 'left_lower_arm'),
    
    // Right arm
    _Connection(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow, 'right_upper_arm'),
    _Connection(PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist, 'right_lower_arm'),
    
    // Left leg
    _Connection(PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee, 'left_upper_leg'),
    _Connection(PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle, 'left_lower_leg'),
    
    // Right leg
    _Connection(PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee, 'right_upper_leg'),
    _Connection(PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle, 'right_lower_leg'),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final pose in poses) {
      // Draw connections (skeleton lines)
      for (final connection in _connections) {
        final from = pose.landmarks[connection.from];
        final to = pose.landmarks[connection.to];

        if (from != null && to != null) {
          if (from.likelihood >= 0.5 && to.likelihood >= 0.5) {
            final color = _getSegmentColor(connection.segment);
            
            final paint = Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 5.0
              ..color = color
              ..strokeCap = StrokeCap.round;

            canvas.drawLine(
              Offset(
                translateX(from.x, size, imageSize, rotation, cameraLensDirection),
                translateY(from.y, size, imageSize, rotation, cameraLensDirection),
              ),
              Offset(
                translateX(to.x, size, imageSize, rotation, cameraLensDirection),
                translateY(to.y, size, imageSize, rotation, cameraLensDirection),
              ),
              paint,
            );
          }
        }
      }

      // Draw landmarks (joints)
      for (final landmark in pose.landmarks.values) {
        if (landmark.likelihood >= 0.5) {
          // Determine joint color based on surrounding segments
          final jointColor = _getJointColor(landmark.type);
          
          // Draw outer circle (white border)
          canvas.drawCircle(
            Offset(
              translateX(landmark.x, size, imageSize, rotation, cameraLensDirection),
              translateY(landmark.y, size, imageSize, rotation, cameraLensDirection),
            ),
            8,
            Paint()
              ..style = PaintingStyle.fill
              ..color = Colors.white,
          );
          
          // Draw inner circle (colored)
          canvas.drawCircle(
            Offset(
              translateX(landmark.x, size, imageSize, rotation, cameraLensDirection),
              translateY(landmark.y, size, imageSize, rotation, cameraLensDirection),
            ),
            6,
            Paint()
              ..style = PaintingStyle.fill
              ..color = jointColor,
          );
        }
      }
    }
  }

  Color _getSegmentColor(String segment) {
    if (segmentColors == null) {
      return defaultColor;
    }
    if (segmentColors!.isEmpty) {
      return defaultColor;
    }
    final color = segmentColors![segment];
    if (color == null) {
      return defaultColor;
    }
    return color;
  }

  Color _getJointColor(PoseLandmarkType type) {
    if (segmentColors == null || segmentColors!.isEmpty) {
      return defaultColor;
    }
    
    // Map landmarks to their relevant segments for coloring
    switch (type) {
      case PoseLandmarkType.leftShoulder:
        return segmentColors!['left_upper_arm'] ?? 
               segmentColors!['shoulders'] ?? 
               segmentColors!['left_torso'] ?? 
               defaultColor;
      case PoseLandmarkType.rightShoulder:
        return segmentColors!['right_upper_arm'] ?? 
               segmentColors!['shoulders'] ?? 
               segmentColors!['right_torso'] ?? 
               defaultColor;
      case PoseLandmarkType.leftElbow:
        return segmentColors!['left_upper_arm'] ?? 
               segmentColors!['left_lower_arm'] ?? 
               defaultColor;
      case PoseLandmarkType.rightElbow:
        return segmentColors!['right_upper_arm'] ?? 
               segmentColors!['right_lower_arm'] ?? 
               defaultColor;
      case PoseLandmarkType.leftWrist:
        return segmentColors!['left_lower_arm'] ?? defaultColor;
      case PoseLandmarkType.rightWrist:
        return segmentColors!['right_lower_arm'] ?? defaultColor;
      case PoseLandmarkType.leftHip:
        return segmentColors!['left_upper_leg'] ?? 
               segmentColors!['hips'] ?? 
               segmentColors!['left_torso'] ?? 
               defaultColor;
      case PoseLandmarkType.rightHip:
        return segmentColors!['right_upper_leg'] ?? 
               segmentColors!['hips'] ?? 
               segmentColors!['right_torso'] ?? 
               defaultColor;
      case PoseLandmarkType.leftKnee:
        return segmentColors!['left_upper_leg'] ?? 
               segmentColors!['left_lower_leg'] ?? 
               defaultColor;
      case PoseLandmarkType.rightKnee:
        return segmentColors!['right_upper_leg'] ?? 
               segmentColors!['right_lower_leg'] ?? 
               defaultColor;
      case PoseLandmarkType.leftAnkle:
        return segmentColors!['left_lower_leg'] ?? defaultColor;
      case PoseLandmarkType.rightAnkle:
        return segmentColors!['right_lower_leg'] ?? defaultColor;
      default:
        return defaultColor;
    }
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) {
    return oldDelegate.poses != poses || 
           oldDelegate.segmentColors != segmentColors ||
           oldDelegate.imageSize != imageSize;
  }
}


