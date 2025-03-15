class UserInteraction {
  final String userId;
  final String action;
  final DateTime timestamp;
  final Map<String, dynamic>? additionalData;

  UserInteraction({
    required this.userId,
    required this.action,
    required this.timestamp,
    this.additionalData,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'action': action,
      'timestamp': timestamp.toIso8601String(),
      'additionalData': additionalData,
    };
  }
}
