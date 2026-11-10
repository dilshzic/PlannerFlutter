class TimeBlockRecord {
  final String date; // Format: YYYY-MM-DD
  final List<String> blocks; // 120 blocks, "" means not done, "generic" means manually done, other string is projectId

  TimeBlockRecord({
    required this.date,
    required this.blocks,
  });

  factory TimeBlockRecord.fromMap(Map<String, dynamic> map, String dateId) {
    List<String> blocks = [];
    if (map['blocks'] != null) {
      blocks = (map['blocks'] as List).map((e) {
        if (e is bool) return e ? "generic" : "";
        if (e is String) return e;
        return "";
      }).toList();
    }
    // Ensure we have exactly 120 blocks
    if (blocks.length != 120) {
      blocks = List.generate(120, (_) => "");
    }
    return TimeBlockRecord(
      date: dateId,
      blocks: blocks,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'blocks': blocks,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };
  }
}
