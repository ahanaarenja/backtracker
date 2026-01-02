import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../models/pose_definition.dart';
import 'angle_calculator.dart';

/// Result of analyzing a single angle
class AngleAnalysisResult {
  final String name;
  final String displayName;
  final double? currentAngle;
  final double idealAngle;
  final double score;
  final FormQuality quality;
  final String feedback;
  final Color color;

  AngleAnalysisResult({
    required this.name,
    required this.displayName,
    this.currentAngle,
    required this.idealAngle,
    required this.score,
    required this.quality,
    required this.feedback,
    required this.color,
  });
}

/// Complete form analysis result
class FormAnalysisResult {
  final double overallScore;
  final List<AngleAnalysisResult> angleResults;
  final Map<String, Color> segmentColors;
  final String primaryFeedback;
  final FormQuality overallQuality;

  FormAnalysisResult({
    required this.overallScore,
    required this.angleResults,
    required this.segmentColors,
    required this.primaryFeedback,
    required this.overallQuality,
  });

  /// Get the worst performing areas for feedback
  List<AngleAnalysisResult> get worstAreas {
    final sorted = List<AngleAnalysisResult>.from(angleResults)
      ..sort((a, b) => a.score.compareTo(b.score));
    return sorted.take(2).where((r) => r.quality != FormQuality.good).toList();
  }
}

/// Analyzes pose form against a definition
class FormAnalyzer {
  static const Color goodColor = Color(0xFF4CAF50);    // Green
  static const Color warningColor = Color(0xFFFFEB3B); // Yellow
  static const Color badColor = Color(0xFFF44336);     // Red
  static const Color neutralColor = Color(0xFF9E9E9E); // Gray (no data)
  static const Color defaultColor = Color(0xFF00E5FF); // Cyan (not analyzed)

  /// Analyze a pose against a pose definition
  static FormAnalysisResult analyze(Pose pose, PoseDefinition definition) {
    // Calculate all angles from pose
    final currentAngles = AngleCalculator.calculateAllAngles(pose);
    
    // Analyze each angle check
    final angleResults = <AngleAnalysisResult>[];
    double totalWeightedScore = 0;
    double totalWeight = 0;

    for (final check in definition.angleChecks) {
      final currentAngle = currentAngles[check.name];
      
      double score;
      FormQuality quality;
      String feedback;
      Color color;

      if (currentAngle == null) {
        // No data for this angle
        score = 50; // Give neutral score instead of 0
        quality = FormQuality.warning;
        feedback = '${check.displayName} not visible';
        color = neutralColor;
      } else {
        score = check.calculateScore(currentAngle);
        quality = check.getQuality(currentAngle);
        feedback = check.getFeedback(currentAngle);
        color = _getColorForQuality(quality);
        
        totalWeightedScore += score * check.weight;
        totalWeight += check.weight;
      }

      angleResults.add(AngleAnalysisResult(
        name: check.name,
        displayName: check.displayName,
        currentAngle: currentAngle,
        idealAngle: check.idealAngle,
        score: score,
        quality: quality,
        feedback: feedback,
        color: color,
      ));
    }

    // Calculate overall score
    final overallScore = totalWeight > 0 ? totalWeightedScore / totalWeight : 50.0;
    
    // Determine overall quality
    FormQuality overallQuality;
    if (overallScore >= 80) {
      overallQuality = FormQuality.good;
    } else if (overallScore >= 50) {
      overallQuality = FormQuality.warning;
    } else {
      overallQuality = FormQuality.bad;
    }

    // Generate segment colors for painter
    final segmentColors = _generateSegmentColors(angleResults, overallQuality);

    // Generate primary feedback
    final primaryFeedback = _generatePrimaryFeedback(angleResults, overallScore);

    return FormAnalysisResult(
      overallScore: overallScore,
      angleResults: angleResults,
      segmentColors: segmentColors,
      primaryFeedback: primaryFeedback,
      overallQuality: overallQuality,
    );
  }

  static Color _getColorForQuality(FormQuality quality) {
    switch (quality) {
      case FormQuality.good:
        return goodColor;
      case FormQuality.warning:
        return warningColor;
      case FormQuality.bad:
        return badColor;
    }
  }

  /// Generate colors for each skeleton segment based on analysis
  static Map<String, Color> _generateSegmentColors(
    List<AngleAnalysisResult> results, 
    FormQuality overallQuality
  ) {
    // Get the overall color based on quality for segments not specifically analyzed
    final overallColor = _getColorForQuality(overallQuality);
    
    // Initialize all segments with overall color
    final colors = <String, Color>{
      'left_torso': overallColor,
      'right_torso': overallColor,
      'shoulders': overallColor,
      'hips': overallColor,
      'left_upper_arm': overallColor,
      'left_lower_arm': overallColor,
      'right_upper_arm': overallColor,
      'right_lower_arm': overallColor,
      'left_upper_leg': overallColor,
      'left_lower_leg': overallColor,
      'right_upper_leg': overallColor,
      'right_lower_leg': overallColor,
      'neck': overallColor,
      'face': overallColor,
    };
    
    // Override with specific colors based on angle results
    for (final result in results) {
      // Skip neutral color results (landmarks not visible)
      if (result.color == neutralColor) continue;
      
      final color = result.color;
      
      switch (result.name) {
        case 'spine_left':
          colors['left_torso'] = color;
          colors['right_torso'] = color;
          break;
        case 'spine_right':
          colors['right_torso'] = color;
          break;
        case 'neck':
          colors['neck'] = color;
          colors['face'] = color;
          break;
        case 'left_knee':
          colors['left_upper_leg'] = color;
          colors['left_lower_leg'] = color;
          break;
        case 'right_knee':
          colors['right_upper_leg'] = color;
          colors['right_lower_leg'] = color;
          break;
        case 'left_elbow':
          colors['left_upper_arm'] = color;
          colors['left_lower_arm'] = color;
          break;
        case 'right_elbow':
          colors['right_upper_arm'] = color;
          colors['right_lower_arm'] = color;
          break;
        case 'left_hip':
          colors['hips'] = color;
          colors['left_torso'] = color;
          break;
        case 'right_hip':
          colors['hips'] = color;
          colors['right_torso'] = color;
          break;
        case 'left_shoulder':
          colors['left_upper_arm'] = color;
          colors['shoulders'] = color;
          break;
        case 'right_shoulder':
          colors['right_upper_arm'] = color;
          colors['shoulders'] = color;
          break;
      }
    }
    
    return colors;
  }

  /// Generate feedback message
  static String _generatePrimaryFeedback(List<AngleAnalysisResult> results, double score) {
    if (score >= 90) {
      return 'Excellent form! 💪';
    } else if (score >= 80) {
      return 'Great form! Keep it up!';
    } else if (score >= 70) {
      // Find the worst area
      final validResults = results.where((r) => r.currentAngle != null).toList();
      if (validResults.isNotEmpty) {
        final worst = validResults.reduce((a, b) => a.score < b.score ? a : b);
        return worst.feedback;
      }
      return 'Good progress!';
    } else if (score >= 50) {
      final badAreas = results.where((r) => r.quality == FormQuality.bad && r.currentAngle != null).toList();
      if (badAreas.isNotEmpty) {
        return badAreas.first.feedback;
      }
      return 'Focus on your form';
    } else {
      return 'Adjust your position';
    }
  }
}


