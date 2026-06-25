class MessageChunk {
  final String text;
  final bool isComplete;
  final String? type; // e.g., 'text' or 'action'
  final Map<String, dynamic>? metadata;

  MessageChunk({
    required this.text,
    required this.isComplete,
    this.type,
    this.metadata,
  });

  factory MessageChunk.completion(String fullText, {String? type, Map<String, dynamic>? metadata}) {
    return MessageChunk(
      text: fullText,
      isComplete: true,
      type: type,
      metadata: metadata,
    );
  }

  factory MessageChunk.partial(String extraText) {
    return MessageChunk(
      text: extraText,
      isComplete: false,
    );
  }
}
