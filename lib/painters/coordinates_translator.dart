import 'dart:io';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

/// Translates x coordinate from image space to canvas space
double translateX(
  double x,
  Size canvasSize,
  Size imageSize,
  InputImageRotation rotation,
  CameraLensDirection cameraLensDirection,
) {
  double translatedX;
  
  if (Platform.isAndroid) {
    // Android: image is rotated 90 or 270 degrees
    switch (rotation) {
      case InputImageRotation.rotation90deg:
        translatedX = x * canvasSize.width / imageSize.height;
        break;
      case InputImageRotation.rotation270deg:
        translatedX = canvasSize.width - (x * canvasSize.width / imageSize.height);
        break;
      default:
        translatedX = x * canvasSize.width / imageSize.width;
    }
    
    // DON'T mirror for front camera - CameraPreview already shows mirrored view
    // and pose detection coordinates match the mirrored view
  } else {
    // iOS
    switch (rotation) {
      case InputImageRotation.rotation90deg:
        translatedX = x * canvasSize.width / imageSize.width;
        break;
      case InputImageRotation.rotation270deg:
        translatedX = canvasSize.width - (x * canvasSize.width / imageSize.width);
        break;
      default:
        translatedX = x * canvasSize.width / imageSize.width;
    }
    
    // Mirror for front camera on iOS
    if (cameraLensDirection == CameraLensDirection.front) {
      translatedX = canvasSize.width - translatedX;
    }
  }
  
  return translatedX;
}

/// Translates y coordinate from image space to canvas space
double translateY(
  double y,
  Size canvasSize,
  Size imageSize,
  InputImageRotation rotation,
  CameraLensDirection cameraLensDirection,
) {
  if (Platform.isAndroid) {
    switch (rotation) {
      case InputImageRotation.rotation90deg:
      case InputImageRotation.rotation270deg:
        return y * canvasSize.height / imageSize.width;
      default:
        return y * canvasSize.height / imageSize.height;
    }
  } else {
    // iOS
    return y * canvasSize.height / imageSize.height;
  }
}
