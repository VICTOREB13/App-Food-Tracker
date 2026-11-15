/// Helper utility for repairing truncated or malformed JSON payloads from LLMs.
class JsonRepairHelper {
  /// Repairs truncated JSON by closing dangling strings, stripping trailing operators/keys,
  /// and matching unclosed braces/brackets using a balanced stack.
  static String repair(String raw) {
    var s = raw.trim();
    final firstBrace = s.indexOf('{');
    if (firstBrace != -1) {
      s = s.substring(firstBrace);
    }

    bool inString = false;
    bool escape = false;
    final stack = <String>[];
    final buffer = StringBuffer();

    for (int i = 0; i < s.length; i++) {
      final c = s[i];
      if (escape) {
        escape = false;
        buffer.write(c);
        continue;
      }
      if (c == '\\') {
        escape = true;
        buffer.write(c);
        continue;
      }
      if (c == '"') {
        inString = !inString;
        buffer.write(c);
        continue;
      }
      if (inString) {
        buffer.write(c);
        continue;
      }

      if (c == '{') {
        stack.add('}');
        buffer.write(c);
      } else if (c == '[') {
        stack.add(']');
        buffer.write(c);
      } else if (c == '}' || c == ']') {
        if (stack.isNotEmpty && stack.last == c) {
          stack.removeLast();
        }
        buffer.write(c);
      } else {
        buffer.write(c);
      }
    }

    var repaired = buffer.toString();
    // Drop trailing dangling backslash if string ended mid-escape
    if (escape && repaired.endsWith('\\')) {
      repaired = repaired.substring(0, repaired.length - 1);
    }
    repaired = repaired.trim();
    if (inString) {
      repaired += '"';
    }

    while (true) {
      repaired = repaired.trim();
      if (repaired.endsWith(',')) {
        repaired = repaired.substring(0, repaired.length - 1);
      } else if (repaired.endsWith(':')) {
        repaired = repaired.substring(0, repaired.length - 1).trim();
        if (repaired.endsWith('"')) {
          final lastQuote = repaired.lastIndexOf('"', repaired.length - 2);
          if (lastQuote != -1) {
            repaired = repaired.substring(0, lastQuote).trim();
          }
        }
      } else if (stack.isNotEmpty && stack.last == '}' && repaired.endsWith('"')) {
        // Drop bare dangling keys without value inside an object
        final lastQuote = repaired.lastIndexOf('"', repaired.length - 2);
        if (lastQuote != -1) {
          final prefix = repaired.substring(0, lastQuote).trim();
          if (prefix.endsWith('{') || prefix.endsWith(',')) {
            repaired = prefix;
            continue;
          }
        }
        break;
      } else {
        break;
      }
    }

    for (int i = stack.length - 1; i >= 0; i--) {
      repaired = repaired.trim();
      if (repaired.endsWith(',')) {
        repaired = repaired.substring(0, repaired.length - 1);
      }
      repaired += stack[i];
    }

    return repaired;
  }
}
