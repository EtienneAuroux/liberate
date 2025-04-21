import 'dart:async';
import 'dart:ffi';
import 'dart:typed_data';
import 'dart:ui';

import 'package:event/event.dart';
import 'package:flow/bindings.dart';

import 'dart:developer' as dev;

class AppState {
  Image? image;
  int imageHeight = 1;
  int imageWidth = 1;

  Event onNewImage = Event();

  void initialize() {
    cLayerBindings.initialize(Pointer.fromFunction<FuncPtrNewFrame>(_onNewFrame));
  }

  void _onNewFrame(int width, int height, int dataSize, Pointer<Void> data) {
    dev.log('received new frame from c layer: $width, $height, $dataSize');
    FrameEvent frameEvent = FrameEvent(width, height, data, dataSize);
    handleNewFrame(frameEvent);
  }

  Future<void> handleNewFrame(FrameEvent? frame) async {
    if (frame == null) {
      return;
    }

    Uint8List dataAsList = frame.data.cast<Uint8>().asTypedList(frame.dataSize);
    Completer completer = Completer();
    decodeImageFromPixels(dataAsList, frame.width, frame.height, PixelFormat.rgba8888, (Image result) {
      completer.complete(result);
    });

    image = await completer.future;
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
