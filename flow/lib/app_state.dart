import 'dart:async';
import 'dart:ffi';
import 'dart:typed_data';
import 'dart:ui';

import 'package:event/event.dart';
import 'package:flow/bindings.dart';

import 'dart:developer' as dev;

class AppState {
  static Image? image;
  static double imageHeight = 1;
  static double imageWidth = 1;

  static Event onNewImage = Event();

  static void initialize() {
    cLayerBindings.initialize(Pointer.fromFunction<FuncPtrNewFrame>(_onNewFrame));
  }

  static void _onNewFrame(int width, int height, int dataSize, Pointer<Void> data) {
    dev.log('received new frame from c layer: $width, $height, $dataSize');
    FrameEvent frameEvent = FrameEvent(width, height, data, dataSize);
    _handleNewFrame(frameEvent);
  }

  static Future<void> _handleNewFrame(FrameEvent? frame) async {
    if (frame == null) {
      return;
    }

    Uint8List dataAsList = frame.data.cast<Uint8>().asTypedList(frame.dataSize);

    Completer completer = Completer();
    decodeImageFromPixels(dataAsList, frame.width, frame.height, PixelFormat.rgba8888, (Image result) {
      completer.complete(result);
    });

    image = await completer.future;
    imageHeight = frame.height.toDouble();
    imageWidth = frame.width.toDouble();
    onNewImage.broadcast();
  }
}

class FrameEvent extends EventArgs {
  final int width;
  final int height;
  final int dataSize;
  final Pointer<Void> data;

  FrameEvent(this.width, this.height, this.data, this.dataSize);
}

class Metrics {}
