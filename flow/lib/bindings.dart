import 'dart:ffi';
import 'dart:io';

import 'package:c_layer/c_layer_bindings_generated.dart';

class Bindings {
  final String _libName = 'c_layer';

  late final DynamicLibrary _dynamicLibrary;

  late CLayerBindings cLayerBindings;

  Bindings() {
    _dynamicLibrary = () {
      if (Platform.isMacOS || Platform.isIOS) {
        return DynamicLibrary.open('$_libName.framework/$_libName');
      }
      if (Platform.isAndroid || Platform.isLinux) {
        return DynamicLibrary.open('lib$_libName.so');
      }
      if (Platform.isWindows) {
        return DynamicLibrary.open('$_libName.dll');
      }
      throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
    }();

    cLayerBindings = CLayerBindings(_dynamicLibrary);
  }
}
