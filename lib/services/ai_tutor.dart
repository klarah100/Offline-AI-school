abstract class AiTutor {
  Future<String> explain(String question, {String? topicId});
}

class OfflineAiTutor implements AiTutor {
  const OfflineAiTutor();

  @override
  Future<String> explain(String question, {String? topicId}) async {
    final normalized = question.toLowerCase().trim();

    if (normalized.isEmpty) {
      return 'Ask a school-learning question and I will explain it step by step.';
    }

    if (topicId == 'fractions' || normalized.contains('fraction') || normalized.contains('numerator') || normalized.contains('denominator')) {
      return 'Fractions show equal parts of a whole. The denominator tells you how many equal parts make the whole, and the numerator tells you how many parts you have. For fractions with the same denominator, add the numerators and keep the denominator. Example: 2/5 + 1/5 = 3/5.';
    }

    if (topicId == 'decimals' || normalized.contains('decimal') || normalized.contains('place value')) {
      return 'Decimals use place value. The first digit after the decimal point is tenths, the second is hundredths, and so on. When adding decimals, line up the decimal points first. Example: 2.4 + 1.3 = 3.7.';
    }

    if (topicId == 'percentages' || normalized.contains('percent')) {
      return 'A percentage means a number out of 100. You can connect it to a fraction and decimal: 25% = 25/100 = 1/4 = 0.25. To find 10% of a number, divide the number by 10.';
    }

    if (topicId == 'matter' || normalized.contains('solid') || normalized.contains('liquid') || normalized.contains('gas') || normalized.contains('matter')) {
      return 'Matter is anything that has mass and takes up space. Solids keep their shape, liquids take the shape of their container, and gases spread to fill available space. Heating or cooling can cause matter to change state.';
    }

    if (topicId == 'density' || normalized.contains('density') || normalized.contains('mass') || normalized.contains('volume')) {
      return 'Density tells us how much mass is packed into a given volume. The formula is density = mass ÷ volume. For example, 200 g ÷ 100 cm³ = 2 g/cm³. If mass stays constant while volume increases, density decreases.';
    }

    final safePrompts = ['how', 'what', 'why', 'explain', 'calculate', 'solve', 'find', 'difference', 'define'];
    final isLearningQuestion = safePrompts.any(normalized.contains);
    if (!isLearningQuestion) {
      return 'I am an offline school tutor. Ask me to explain, compare, define, or solve something from your learning topics.';
    }

    return 'I can explain the Grade 6 topics stored on this device: fractions, decimals, percentages, matter, and density. Ask me about one of those concepts and I will guide you step by step.';
  }
}

class CloudAiTutor implements AiTutor {
  final Future<String> Function(String prompt) request;

  const CloudAiTutor(this.request);

  @override
  Future<String> explain(String question, {String? topicId}) => request(question);
}