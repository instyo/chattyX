import 'package:rxdart/rxdart.dart';

abstract class RxController<T> {
  RxController() {
    init();
  }

  T initState();

  final BehaviorSubject<T> source = BehaviorSubject<T>();

  T get state => source.value;

  Stream<T> get stream => source.stream;

  void setState(T Function(T state) fn) {
    source.add(fn(state));
  }

  void init() {
    source.add(initState());
  }

  void dispose() {
    source.close();
  }
}
