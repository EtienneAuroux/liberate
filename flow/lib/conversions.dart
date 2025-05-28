class Conversions {
  double dampenZoom(double scale, {int dampingFactor = 10}) {
    if (scale >= 1) {
      double increase = scale - 1;
      return 1 + increase / dampingFactor;
    } else if (scale > 0) {
      double decrease = 1 - scale;
      return 1 - decrease / dampingFactor;
    } else {
      return 1;
    }
  }
}
