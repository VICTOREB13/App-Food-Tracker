import 'package:food_tracker/features/fasting_tracker/fasting_tracker.dart';

export 'package:food_tracker/features/fasting_tracker/fasting_tracker.dart';

/// Backward-compatible bridge for FastingWindowBentoCard routing to FastingTrackerView.
class FastingWindowBentoCard extends FastingTrackerView {
  const FastingWindowBentoCard({
    super.key,
    super.controller,
  });
}
