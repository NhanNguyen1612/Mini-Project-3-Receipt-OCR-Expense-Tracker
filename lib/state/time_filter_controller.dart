import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/time_filter.dart';

class TimeFilterNotifier extends StateNotifier<TimeFilterState> {
  TimeFilterNotifier() : super(TimeFilterState.initial());

  void setMode(TimeFilterMode mode) {
    state = state.copyWith(mode: mode);
  }

  void setDate(DateTime date) {
    state = state.copyWith(anchorDate: date);
  }

  void previous() {
    state = state.previous();
  }

  void next() {
    state = state.next();
  }

  void resetToToday() {
    state = state.copyWith(anchorDate: DateTime.now());
  }
}

final timeFilterProvider =
    StateNotifierProvider<TimeFilterNotifier, TimeFilterState>(
  (ref) => TimeFilterNotifier(),
);
