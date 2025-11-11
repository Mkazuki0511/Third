class MatchWithUser {
  final String requestId;
  final String opponentId;
  final String opponentNickname;
  final String? opponentImageUrl;

  MatchWithUser({
    required this.requestId,
    required this.opponentId,
    required this.opponentNickname,
    this.opponentImageUrl,
  });
}