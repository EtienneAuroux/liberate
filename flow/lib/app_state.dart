import 'dart:async';
import 'dart:ffi';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:event/event.dart';
import 'package:flow/bindings.dart';
import 'package:flow/conversions.dart';

import 'dart:developer' as dev;

import 'package:flow/types.dart';

class AppState {
  static Painting painting = Painting();

  static Calculations conversions = Calculations();

  static Event onNewImage = Event();

  static LengthyProcess imageUpdateStatus = LengthyProcess.unknown;

  static void initialize() {
    ui.Size size = ui.PlatformDispatcher.instance.views.first.physicalSize;
    double pixelRatio = ui.PlatformDispatcher.instance.views.first.devicePixelRatio;

    int maxWidth = max((size.width / pixelRatio).ceil(), 3500);
    int maxHeight = max((size.height / pixelRatio).ceil(), 2000);

    cLayerBindings.initialize(Pointer.fromFunction<FuncPtrNewFrame>(_onNewFrame), maxWidth, maxHeight);
  }

  static void _onNewFrame(int width, int height, int dataSize, Pointer<Void> data) {
    FrameEvent frameEvent = FrameEvent(width, height, data, dataSize);
    _handleNewFrame(frameEvent);
  }

  static Future<void> _handleNewFrame(FrameEvent? frame) async {
    if (frame == null) {
      imageUpdateStatus = LengthyProcess.failed;
      return;
    }

    Uint8List dataAsList = frame.data.cast<Uint8>().asTypedList(frame.dataSize);

    Completer completer = Completer();
    ui.decodeImageFromPixels(dataAsList, frame.width, frame.height, ui.PixelFormat.rgba8888, (ui.Image result) {
      completer.complete(result);
    });

    painting.image = await completer.future;
    painting.height = frame.height.toDouble();
    painting.width = frame.width.toDouble();
    onNewImage.broadcast();

    imageUpdateStatus = LengthyProcess.done;
  }

  static Player player = Player();
  static List<Target> targets = List.filled(3, Target(Offset.zero, 0, 0));
  static Offset bounds = Offset.zero;

  static void initializeGameState(Offset pointerPosition, Offset bounds) {
    player.initializePosition(pointerPosition);

    for (int targetIndex = 0; targetIndex < targets.length; targetIndex++) {
      targets[targetIndex] = _createTarget(player.position);
    }
  }

  static void updateGameState() {
    for (int targetIndex = 0; targetIndex < targets.length; targetIndex++) {
      bool targetCollision = _checkForCollision(player, targets[targetIndex]);
      if (targetCollision) {
        player.points += targets[targetIndex].point;
        targets[targetIndex] = _createTarget(player.position);
      }
    }
  }

  static bool _checkForCollision(Player player, GameObject object) {
    return (player.position - object.position).distanceSquared <= pow(player.hitBoxRadius + object.hitBoxRadius, 2);
  }

  static Target _createTarget(Offset exclusionCenter) {
    int point = Random().nextInt(5) + 1;
    Offset position = exclusionCenter;
    while ((position - exclusionCenter).distanceSquared < 1000) {
      position = Offset(Random().nextDouble() * bounds.dx, Random().nextDouble() * bounds.dy);
    }
    double hitBoxRadius = 35 - point * 5;
    return Target(position, hitBoxRadius, point);
  }
}
