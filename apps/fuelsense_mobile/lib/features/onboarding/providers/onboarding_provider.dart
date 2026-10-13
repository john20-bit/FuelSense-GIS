import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingPageNotifier extends Notifier<int> {
  @override
  int build() {
    return 0;
  }

  void changePage(int index) {
    state = index;
  }
}

final onboardingPageProvider = NotifierProvider<OnboardingPageNotifier, int>(
  OnboardingPageNotifier.new,
);
