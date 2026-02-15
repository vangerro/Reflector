import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';

void main() {
  test('permission status values exist', () {
    expect(PermissionStatus.granted, isNotNull);
    expect(PermissionStatus.denied, isNotNull);
    expect(PermissionStatus.restricted, isNotNull);
    expect(PermissionStatus.limited, isNotNull);
    expect(PermissionStatus.permanentlyDenied, isNotNull);
  });

  test('checks granted status', () {
    expect(PermissionStatus.granted == PermissionStatus.granted, isTrue);
    expect(PermissionStatus.denied == PermissionStatus.granted, isFalse);
  });

  test('both permissions granted check', () {
    bool arePermissionsGranted(
      PermissionStatus cameraStatus,
      PermissionStatus microphoneStatus,
    ) {
      return cameraStatus == PermissionStatus.granted &&
          microphoneStatus == PermissionStatus.granted;
    }

      expect(
        arePermissionsGranted(
          PermissionStatus.granted,
          PermissionStatus.granted,
        ),
        isTrue,
      );

      expect(
        arePermissionsGranted(
          PermissionStatus.granted,
          PermissionStatus.denied,
        ),
        isFalse,
      );

      expect(
        arePermissionsGranted(
          PermissionStatus.denied,
          PermissionStatus.granted,
        ),
        isFalse,
      );

      expect(
        arePermissionsGranted(
          PermissionStatus.denied,
          PermissionStatus.denied,
        ),
        isFalse,
      );
  });

  test('should request permissions when not granted', () {
    bool shouldRequestPermissions(
      PermissionStatus cameraStatus,
      PermissionStatus microphoneStatus,
    ) {
      return cameraStatus != PermissionStatus.granted ||
          microphoneStatus != PermissionStatus.granted;
    }

      expect(
        shouldRequestPermissions(
          PermissionStatus.granted,
          PermissionStatus.granted,
        ),
        isFalse,
      );

      expect(
        shouldRequestPermissions(
          PermissionStatus.denied,
          PermissionStatus.granted,
        ),
        isTrue,
      );

      expect(
        shouldRequestPermissions(
          PermissionStatus.granted,
          PermissionStatus.denied,
        ),
        isTrue,
      );

      expect(
        shouldRequestPermissions(
          PermissionStatus.permanentlyDenied,
          PermissionStatus.granted,
        ),
        isTrue,
      );
  });

  test('permission combinations', () {
    final combinations = [
        (PermissionStatus.granted, PermissionStatus.granted),
        (PermissionStatus.granted, PermissionStatus.denied),
        (PermissionStatus.denied, PermissionStatus.granted),
        (PermissionStatus.denied, PermissionStatus.denied),
        (PermissionStatus.permanentlyDenied, PermissionStatus.granted),
        (PermissionStatus.granted, PermissionStatus.permanentlyDenied),
      ];

      for (final (camera, microphone) in combinations) {
        final bothGranted = camera == PermissionStatus.granted &&
            microphone == PermissionStatus.granted;
        
        if (bothGranted) {
          expect(camera, PermissionStatus.granted);
          expect(microphone, PermissionStatus.granted);
        } else {
          expect(
            camera != PermissionStatus.granted ||
                microphone != PermissionStatus.granted,
            isTrue,
          );
        }
      }
  });

  test('prefers front camera', () {
    final cameras = [
        _MockCameraDescription(CameraLensDirection.back, 'back'),
        _MockCameraDescription(CameraLensDirection.front, 'front'),
      ];

    String? findPreferredCamera(List<_MockCameraDescription> cameras) {
        try {
          return cameras
              .firstWhere(
                (camera) => camera.lensDirection == CameraLensDirection.front,
              )
              .name;
        } catch (e) {
          try {
            return cameras
                .firstWhere(
                  (camera) => camera.lensDirection == CameraLensDirection.back,
                )
                .name;
          } catch (e) {
            return cameras.isNotEmpty ? cameras.first.name : null;
          }
        }
      }

    expect(findPreferredCamera(cameras), 'front');
  });

  test('falls back to back camera', () {
      final cameras = [
        _MockCameraDescription(CameraLensDirection.back, 'back'),
      ];

      String? findPreferredCamera(List<_MockCameraDescription> cameras) {
        try {
          return cameras
              .firstWhere(
                (camera) => camera.lensDirection == CameraLensDirection.front,
              )
              .name;
        } catch (e) {
          try {
            return cameras
                .firstWhere(
                  (camera) => camera.lensDirection == CameraLensDirection.back,
                )
                .name;
          } catch (e) {
            return cameras.isNotEmpty ? cameras.first.name : null;
          }
        }
      }

    expect(findPreferredCamera(cameras), 'back');
  });

  test('handles empty camera list', () {
      final cameras = <_MockCameraDescription>[];

      String? findPreferredCamera(List<_MockCameraDescription> cameras) {
        try {
          return cameras
              .firstWhere(
                (camera) => camera.lensDirection == CameraLensDirection.front,
              )
              .name;
        } catch (e) {
          try {
            return cameras
                .firstWhere(
                  (camera) => camera.lensDirection == CameraLensDirection.back,
                )
                .name;
          } catch (e) {
            return cameras.isNotEmpty ? cameras.first.name : null;
          }
        }
      }

    expect(findPreferredCamera(cameras), isNull);
  });
}

class _MockCameraDescription {
  final CameraLensDirection lensDirection;
  final String name;

  _MockCameraDescription(this.lensDirection, this.name);
}
