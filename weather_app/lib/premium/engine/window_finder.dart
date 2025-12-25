class WindowFinder {
  /// Returns index of best consecutive window by average score.
  static int bestWindowStart(List<int> scores, int windowSize) {
    if (scores.length < windowSize) return 0;
    int bestIdx = 0;
    double bestAvg = -1;

    int sum = 0;
    for (int i = 0; i < windowSize; i++) sum += scores[i];
    bestAvg = sum / windowSize;

    for (int i = windowSize; i < scores.length; i++) {
      sum += scores[i] - scores[i - windowSize];
      final avg = sum / windowSize;
      if (avg > bestAvg) {
        bestAvg = avg;
        bestIdx = i - windowSize + 1;
      }
    }
    return bestIdx;
  }
}
