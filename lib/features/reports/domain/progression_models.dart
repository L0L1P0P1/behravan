enum ProgressionStatus { progress, maintain, regress, insufficientData }

class IntervalEvaluationResult {
  final int totalLogs;
  final int successfulLogs;
  final int accidentLogs;
  final int spontaneousLogs;
  final double successRate;
  final ProgressionStatus status;
  final int currentInterval;
  final int suggestedInterval;
  final String recommendationMessage;

  const IntervalEvaluationResult({
    required this.totalLogs,
    required this.successfulLogs,
    required this.accidentLogs,
    required this.spontaneousLogs,
    required this.successRate,
    required this.status,
    required this.currentInterval,
    required this.suggestedInterval,
    required this.recommendationMessage,
  });
}
