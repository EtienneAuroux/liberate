import 'dart:ffi';
import 'dart:io';

import 'package:c_layer/c_layer_bindings_generated.dart';

// class Bindings {

//   late final DynamicLibrary _dynamicLibrary;

//   late CLayerBindings cLayerBindings;

//   Bindings() {

// }

const String _libName = 'c_layer';

final DynamicLibrary _dynamicLibrary = () {
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

final CLayerBindings cLayerBindings = CLayerBindings(_dynamicLibrary);

typedef FuncPtrNewFrame = Void Function(Uint64, Uint64, Uint64, Pointer<Void>);
