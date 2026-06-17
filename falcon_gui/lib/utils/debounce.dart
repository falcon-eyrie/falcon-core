import 'dart:async';

class Debounce {
  Debounce({required this.delay});
  final Duration delay;
  Timer? timer;

  void call(void Function() action) {
    timer?.cancel();
    timer = Timer(delay, action);
  }

  void dispose() {
    timer?.cancel();
  }
}
