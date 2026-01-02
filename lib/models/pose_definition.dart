import 'package:flutter/material.dart';

/// Quality level for form assessment
enum FormQuality {
  good,    // Green - within tolerance
  warning, // Yellow - slightly off
  bad,     // Red - significantly off
}

/// Definition of an ideal angle for a body part
class IdealAngle {
  final String name;           // e.g., "left_knee", "spine"
  final String displayName;    // e.g., "Left Knee", "Back"
  final double idealAngle;     // Target angle in degrees
  final double greenTolerance; // Deviation for green (good)
  final double yellowTolerance;// Deviation for yellow (warning)
  final double weight;         // How much this affects total score (0-1)
  final String goodFeedback;
  final String warningFeedback;
  final String badFeedback;

  const IdealAngle({
    required this.name,
    required this.displayName,
    required this.idealAngle,
    this.greenTolerance = 10,
    this.yellowTolerance = 25,
    this.weight = 0.25,
    this.goodFeedback = 'Good!',
    this.warningFeedback = 'Adjust slightly',
    this.badFeedback = 'Needs correction',
  });

  /// Calculate score (0-100) based on current angle
  double calculateScore(double currentAngle) {
    final deviation = (currentAngle - idealAngle).abs();
    
    if (deviation <= greenTolerance) {
      // 80-100 score for green zone
      return 100 - (deviation / greenTolerance) * 20;
    } else if (deviation <= yellowTolerance) {
      // 50-80 score for yellow zone
      final yellowDeviation = deviation - greenTolerance;
      final yellowRange = yellowTolerance - greenTolerance;
      return 80 - (yellowDeviation / yellowRange) * 30;
    } else {
      // 0-50 score for red zone
      final redDeviation = deviation - yellowTolerance;
      return (50 - redDeviation).clamp(0, 50);
    }
  }

  /// Get quality level based on current angle
  FormQuality getQuality(double currentAngle) {
    final deviation = (currentAngle - idealAngle).abs();
    
    if (deviation <= greenTolerance) {
      return FormQuality.good;
    } else if (deviation <= yellowTolerance) {
      return FormQuality.warning;
    } else {
      return FormQuality.bad;
    }
  }

  /// Get feedback based on current angle
  String getFeedback(double currentAngle) {
    switch (getQuality(currentAngle)) {
      case FormQuality.good:
        return goodFeedback;
      case FormQuality.warning:
        return warningFeedback;
      case FormQuality.bad:
        return badFeedback;
    }
  }
}

/// Complete pose definition for an exercise position
class PoseDefinition {
  final String name;
  final String description;
  final List<IdealAngle> angleChecks;
  final IconData icon;
  final Color color;

  const PoseDefinition({
    required this.name,
    required this.description,
    required this.angleChecks,
    required this.icon,
    required this.color,
  });

  /// Get total weight (should sum to ~1.0)
  double get totalWeight => angleChecks.fold(0, (sum, a) => sum + a.weight);
}

/// Exercise with multiple positions (e.g., standing + squat)
class ExerciseDefinition {
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final PoseDefinition standingPose;
  final PoseDefinition bottomPose;
  final double standingThreshold;  // Angle above this = standing
  final double bottomThreshold;    // Angle below this = bottom

  const ExerciseDefinition({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.standingPose,
    required this.bottomPose,
    this.standingThreshold = 160,
    this.bottomThreshold = 100,
  });
}

/// Predefined exercise definitions for BackTracker exercises
class BackTrackerExercises {
  
  // ==================== GLUTE BRIDGES ====================
  static const gluteBridges = ExerciseDefinition(
    name: 'Glute Bridges',
    description: 'Strengthens glutes to reduce stress on the lower back',
    icon: Icons.airline_seat_flat,
    color: Color(0xFF1552af),
    standingThreshold: 160,
    bottomThreshold: 100,
    
    standingPose: PoseDefinition(
      name: 'Lying Flat',
      description: 'Starting position',
      icon: Icons.airline_seat_flat,
      color: Color(0xFF4ECDC4),
      angleChecks: [
        IdealAngle(
          name: 'left_hip',
          displayName: 'Hip Position',
          idealAngle: 180,
          greenTolerance: 15,
          yellowTolerance: 30,
          weight: 0.50,
          goodFeedback: 'Hips in start position!',
          warningFeedback: 'Relax hips down',
          badFeedback: 'Lower your hips',
        ),
        IdealAngle(
          name: 'left_knee',
          displayName: 'Knees',
          idealAngle: 90,
          greenTolerance: 15,
          yellowTolerance: 30,
          weight: 0.50,
          goodFeedback: 'Knee position good!',
          warningFeedback: 'Adjust knee bend',
          badFeedback: 'Bend knees more',
        ),
      ],
    ),
    
    bottomPose: PoseDefinition(
      name: 'Bridge Up',
      description: 'Hips raised',
      icon: Icons.airline_seat_flat,
      color: Color(0xFF1552af),
      angleChecks: [
        IdealAngle(
          name: 'left_hip',
          displayName: 'Hip Extension',
          idealAngle: 180,
          greenTolerance: 15,
          yellowTolerance: 30,
          weight: 0.60,
          goodFeedback: 'Great hip extension!',
          warningFeedback: 'Push hips higher',
          badFeedback: 'Lift hips more!',
        ),
        IdealAngle(
          name: 'left_knee',
          displayName: 'Knees',
          idealAngle: 90,
          greenTolerance: 15,
          yellowTolerance: 30,
          weight: 0.40,
          goodFeedback: 'Knee angle good!',
          warningFeedback: 'Keep knees bent',
          badFeedback: 'Check knee position',
        ),
      ],
    ),
  );

  // ==================== SQUATS ====================
  static const squats = ExerciseDefinition(
    name: 'Squats',
    description: 'Strengthens legs and supports proper movement patterns',
    icon: Icons.accessibility_new,
    color: Color(0xFF1552af),
    standingThreshold: 160,
    bottomThreshold: 100,
    
    standingPose: PoseDefinition(
      name: 'Standing',
      description: 'Stand tall',
      icon: Icons.accessibility_new,
      color: Color(0xFF4ECDC4),
      angleChecks: [
        IdealAngle(
          name: 'left_knee',
          displayName: 'Knees',
          idealAngle: 175,
          greenTolerance: 10,
          yellowTolerance: 25,
          weight: 0.50,
          goodFeedback: 'Legs straight!',
          warningFeedback: 'Straighten legs',
          badFeedback: 'Stand up fully',
        ),
        IdealAngle(
          name: 'spine_left',
          displayName: 'Back',
          idealAngle: 175,
          greenTolerance: 10,
          yellowTolerance: 25,
          weight: 0.50,
          goodFeedback: 'Back is straight!',
          warningFeedback: 'Stand taller',
          badFeedback: 'Straighten back',
        ),
      ],
    ),
    
    bottomPose: PoseDefinition(
      name: 'Squat',
      description: 'Sit back and down',
      icon: Icons.accessibility_new,
      color: Color(0xFF1552af),
      angleChecks: [
        IdealAngle(
          name: 'left_knee',
          displayName: 'Knees',
          idealAngle: 90,
          greenTolerance: 15,
          yellowTolerance: 30,
          weight: 0.50,
          goodFeedback: 'Good depth!',
          warningFeedback: 'Go a bit lower',
          badFeedback: 'Squat deeper',
        ),
        IdealAngle(
          name: 'spine_left',
          displayName: 'Back',
          idealAngle: 150,
          greenTolerance: 15,
          yellowTolerance: 30,
          weight: 0.50,
          goodFeedback: 'Back angle good!',
          warningFeedback: 'Keep chest up',
          badFeedback: 'Don\'t lean too far',
        ),
      ],
    ),
  );

  // ==================== SIDE PLANK HOLDS ====================
  static const sidePlankHolds = ExerciseDefinition(
    name: 'Side Plank Holds',
    description: 'Builds lateral core strength for spinal stability',
    icon: Icons.straighten,
    color: Color(0xFF1552af),
    standingThreshold: 160,
    bottomThreshold: 140,
    
    standingPose: PoseDefinition(
      name: 'Setup',
      description: 'Get ready',
      icon: Icons.straighten,
      color: Color(0xFF4ECDC4),
      angleChecks: [
        IdealAngle(
          name: 'spine_left',
          displayName: 'Body',
          idealAngle: 180,
          greenTolerance: 15,
          yellowTolerance: 30,
          weight: 1.0,
          goodFeedback: 'Ready position!',
          warningFeedback: 'Get into position',
          badFeedback: 'Prepare for plank',
        ),
      ],
    ),
    
    bottomPose: PoseDefinition(
      name: 'Side Plank',
      description: 'Hold body straight',
      icon: Icons.straighten,
      color: Color(0xFF1552af),
      angleChecks: [
        IdealAngle(
          name: 'spine_left',
          displayName: 'Body Line',
          idealAngle: 180,
          greenTolerance: 10,
          yellowTolerance: 25,
          weight: 0.70,
          goodFeedback: 'Perfect line!',
          warningFeedback: 'Keep body straight',
          badFeedback: 'Hips dropping',
        ),
        IdealAngle(
          name: 'left_elbow',
          displayName: 'Support Arm',
          idealAngle: 90,
          greenTolerance: 15,
          yellowTolerance: 30,
          weight: 0.30,
          goodFeedback: 'Arm position good!',
          warningFeedback: 'Adjust elbow',
          badFeedback: 'Check arm position',
        ),
      ],
    ),
  );

  // ==================== BIRD DOG ====================
  static const birdDog = ExerciseDefinition(
    name: 'Bird Dog',
    description: 'Improves core control and spinal stability',
    icon: Icons.pets,
    color: Color(0xFF1552af),
    standingThreshold: 160,
    bottomThreshold: 100,
    
    standingPose: PoseDefinition(
      name: 'All Fours',
      description: 'Hands and knees',
      icon: Icons.pets,
      color: Color(0xFF4ECDC4),
      angleChecks: [
        IdealAngle(
          name: 'spine_left',
          displayName: 'Back',
          idealAngle: 180,
          greenTolerance: 10,
          yellowTolerance: 25,
          weight: 0.60,
          goodFeedback: 'Back is flat!',
          warningFeedback: 'Flatten back',
          badFeedback: 'Keep back neutral',
        ),
        IdealAngle(
          name: 'left_hip',
          displayName: 'Hips',
          idealAngle: 90,
          greenTolerance: 15,
          yellowTolerance: 30,
          weight: 0.40,
          goodFeedback: 'Hips positioned!',
          warningFeedback: 'Adjust hips',
          badFeedback: 'Hips over knees',
        ),
      ],
    ),
    
    bottomPose: PoseDefinition(
      name: 'Extended',
      description: 'Arm and leg out',
      icon: Icons.pets,
      color: Color(0xFF1552af),
      angleChecks: [
        IdealAngle(
          name: 'spine_left',
          displayName: 'Back',
          idealAngle: 180,
          greenTolerance: 10,
          yellowTolerance: 25,
          weight: 0.50,
          goodFeedback: 'Back stable!',
          warningFeedback: 'Keep back flat',
          badFeedback: 'Don\'t arch',
        ),
        IdealAngle(
          name: 'left_elbow',
          displayName: 'Arm',
          idealAngle: 180,
          greenTolerance: 15,
          yellowTolerance: 30,
          weight: 0.25,
          goodFeedback: 'Arm extended!',
          warningFeedback: 'Extend arm more',
          badFeedback: 'Reach forward',
        ),
        IdealAngle(
          name: 'left_knee',
          displayName: 'Leg',
          idealAngle: 180,
          greenTolerance: 15,
          yellowTolerance: 30,
          weight: 0.25,
          goodFeedback: 'Leg extended!',
          warningFeedback: 'Extend leg more',
          badFeedback: 'Reach back',
        ),
      ],
    ),
  );

  // ==================== CAT-COW POSE ====================
  static const catCowPose = ExerciseDefinition(
    name: 'Cat-Cow Pose',
    description: 'Improves spinal flexibility and reduces stiffness',
    icon: Icons.self_improvement,
    color: Color(0xFF1552af),
    standingThreshold: 160,
    bottomThreshold: 100,
    
    standingPose: PoseDefinition(
      name: 'Cow Pose',
      description: 'Arch back, look up',
      icon: Icons.self_improvement,
      color: Color(0xFF4ECDC4),
      angleChecks: [
        IdealAngle(
          name: 'spine_left',
          displayName: 'Back Arch',
          idealAngle: 160,
          greenTolerance: 15,
          yellowTolerance: 30,
          weight: 0.70,
          goodFeedback: 'Nice arch!',
          warningFeedback: 'Arch more',
          badFeedback: 'Drop belly down',
        ),
        IdealAngle(
          name: 'neck',
          displayName: 'Head',
          idealAngle: 150,
          greenTolerance: 20,
          yellowTolerance: 35,
          weight: 0.30,
          goodFeedback: 'Head up!',
          warningFeedback: 'Lift head',
          badFeedback: 'Look up',
        ),
      ],
    ),
    
    bottomPose: PoseDefinition(
      name: 'Cat Pose',
      description: 'Round spine, tuck chin',
      icon: Icons.self_improvement,
      color: Color(0xFF1552af),
      angleChecks: [
        IdealAngle(
          name: 'spine_left',
          displayName: 'Back Round',
          idealAngle: 120,
          greenTolerance: 15,
          yellowTolerance: 30,
          weight: 0.70,
          goodFeedback: 'Good rounding!',
          warningFeedback: 'Round more',
          badFeedback: 'Push back up',
        ),
        IdealAngle(
          name: 'neck',
          displayName: 'Head',
          idealAngle: 160,
          greenTolerance: 15,
          yellowTolerance: 30,
          weight: 0.30,
          goodFeedback: 'Chin tucked!',
          warningFeedback: 'Tuck chin',
          badFeedback: 'Drop head down',
        ),
      ],
    ),
  );

  // ==================== DEAD BUG ====================
  static const deadBug = ExerciseDefinition(
    name: 'Dead Bug',
    description: 'Builds deep core stability without stressing the spine',
    icon: Icons.bug_report,
    color: Color(0xFF1552af),
    standingThreshold: 150,
    bottomThreshold: 90,
    
    standingPose: PoseDefinition(
      name: 'Start Position',
      description: 'Arms and legs up',
      icon: Icons.bug_report,
      color: Color(0xFF4ECDC4),
      angleChecks: [
        IdealAngle(
          name: 'left_hip',
          displayName: 'Hips',
          idealAngle: 90,
          greenTolerance: 15,
          yellowTolerance: 30,
          weight: 0.50,
          goodFeedback: 'Legs up!',
          warningFeedback: 'Raise legs',
          badFeedback: 'Legs to 90°',
        ),
        IdealAngle(
          name: 'left_shoulder',
          displayName: 'Arms',
          idealAngle: 90,
          greenTolerance: 15,
          yellowTolerance: 30,
          weight: 0.50,
          goodFeedback: 'Arms up!',
          warningFeedback: 'Raise arms',
          badFeedback: 'Arms to ceiling',
        ),
      ],
    ),
    
    bottomPose: PoseDefinition(
      name: 'Extended',
      description: 'Opposite arm and leg out',
      icon: Icons.bug_report,
      color: Color(0xFF1552af),
      angleChecks: [
        IdealAngle(
          name: 'left_elbow',
          displayName: 'Arm',
          idealAngle: 180,
          greenTolerance: 15,
          yellowTolerance: 30,
          weight: 0.35,
          goodFeedback: 'Arm extended!',
          warningFeedback: 'Extend arm',
          badFeedback: 'Reach back',
        ),
        IdealAngle(
          name: 'left_knee',
          displayName: 'Leg',
          idealAngle: 180,
          greenTolerance: 15,
          yellowTolerance: 30,
          weight: 0.35,
          goodFeedback: 'Leg extended!',
          warningFeedback: 'Extend leg',
          badFeedback: 'Straighten leg',
        ),
        IdealAngle(
          name: 'spine_left',
          displayName: 'Core',
          idealAngle: 180,
          greenTolerance: 10,
          yellowTolerance: 25,
          weight: 0.30,
          goodFeedback: 'Core engaged!',
          warningFeedback: 'Keep back flat',
          badFeedback: 'Press back down',
        ),
      ],
    ),
  );

  // ==================== DEFAULT (GENERIC) ====================
  static const generic = ExerciseDefinition(
    name: 'Exercise',
    description: 'General exercise form check',
    icon: Icons.fitness_center,
    color: Color(0xFF1552af),
    standingThreshold: 160,
    bottomThreshold: 100,
    
    standingPose: PoseDefinition(
      name: 'Ready',
      description: 'Starting position',
      icon: Icons.accessibility_new,
      color: Color(0xFF4ECDC4),
      angleChecks: [
        IdealAngle(
          name: 'spine_left',
          displayName: 'Posture',
          idealAngle: 175,
          greenTolerance: 15,
          yellowTolerance: 30,
          weight: 0.50,
          goodFeedback: 'Good posture!',
          warningFeedback: 'Stand taller',
          badFeedback: 'Straighten up',
        ),
        IdealAngle(
          name: 'left_knee',
          displayName: 'Legs',
          idealAngle: 175,
          greenTolerance: 15,
          yellowTolerance: 30,
          weight: 0.50,
          goodFeedback: 'Legs ready!',
          warningFeedback: 'Check legs',
          badFeedback: 'Adjust stance',
        ),
      ],
    ),
    
    bottomPose: PoseDefinition(
      name: 'Active',
      description: 'Exercise position',
      icon: Icons.fitness_center,
      color: Color(0xFF1552af),
      angleChecks: [
        IdealAngle(
          name: 'spine_left',
          displayName: 'Form',
          idealAngle: 160,
          greenTolerance: 20,
          yellowTolerance: 35,
          weight: 0.50,
          goodFeedback: 'Good form!',
          warningFeedback: 'Adjust form',
          badFeedback: 'Check position',
        ),
        IdealAngle(
          name: 'left_knee',
          displayName: 'Legs',
          idealAngle: 90,
          greenTolerance: 20,
          yellowTolerance: 35,
          weight: 0.50,
          goodFeedback: 'Good position!',
          warningFeedback: 'Adjust depth',
          badFeedback: 'Check legs',
        ),
      ],
    ),
  );

  /// Get exercise definition by name
  static ExerciseDefinition getByName(String exerciseName) {
    final lowerName = exerciseName.toLowerCase();
    
    if (lowerName.contains('glute') && lowerName.contains('bridge')) {
      return gluteBridges;
    } else if (lowerName.contains('squat')) {
      return squats;
    } else if (lowerName.contains('side plank')) {
      return sidePlankHolds;
    } else if (lowerName.contains('bird dog')) {
      return birdDog;
    } else if (lowerName.contains('cat') || lowerName.contains('cow')) {
      return catCowPose;
    } else if (lowerName.contains('dead bug')) {
      return deadBug;
    } else {
      // Return generic definition for other exercises
      return generic;
    }
  }
}
