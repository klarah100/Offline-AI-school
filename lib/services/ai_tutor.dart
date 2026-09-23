abstract class AiTutor {
  Future<String> explain(String question);
}

class OfflineAiTutor implements AiTutor {
  const OfflineAiTutor();

  @override
  Future<String> explain(String question) async {
    final normalized = question.toLowerCase();

    if (normalized.contains('fraction')) {
      return 'A fraction shows parts of a whole. The denominator tells you how many equal parts there are, while the numerator tells you how many parts you have. When denominators are the same, add the numerators and keep the denominator.';
    }

    return 'I can explain this topic using the learning content available on your device. Try asking about a concept from your current lesson.';
  }
}

class CloudAiTutor implements AiTutor {
  final Future<String> Function(String prompt) request;

  const CloudAiTutor(this.request);

  @override
  Future<String> explain(String question) => request(question);
}
