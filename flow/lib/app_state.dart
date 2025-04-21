import 'dart:async';
import 'dart:ffi';
import 'dart:typed_data';
import 'dart:ui';

import 'package:event/event.dart';
import 'package:flow/bindings.dart';

class AppState {
  /// Gives access to the C layer.
  static Bindings bindings = Bindings();

  Image? image;
  int imageHeight = 1;
  int imageWidth = 1;

  Event onNewImage = Event();

  void _onNewFrame(int viewId, int width, int height, Pointer<Void> data, int dataSize) {
    // libipr.ipr_profile_view_metrics metrics
    FrameEvent frameEvent = FrameEvent(viewId, width, height, data, dataSize, Metrics());
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
  final int id;
  final int width;
  final int height;
  final int dataSize;
  final Pointer<Void> data;
  final Metrics metrics;

  FrameEvent(this.id, this.width, this.height, this.data, this.dataSize, this.metrics);
}

class Metrics {}
