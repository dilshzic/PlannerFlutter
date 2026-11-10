import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flt_alx_core_ai/flt_alx_core_ai.dart';

/// A brain implementation that calls the Google Gemini REST API directly.
/// Works on all platforms including Linux (no Firebase dependency).
class GeminiBrain implements AiBrain {
  const GeminiBrain();

  @override
  Future<BrainResponse> ask(
    String prompt, {
    StoredBrainConfig? config,
  }) async {
    final effectiveConfig = config ?? const StoredBrainConfig();
    final apiKey = effectiveConfig.apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Gemini API key is not configured.');
    }

    final model = effectiveConfig.model.isNotEmpty
        ? effectiveConfig.model
        : 'gemini-2.0-flash';

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
    );

    final systemInstruction = effectiveConfig.systemInstruction;

    final List<dynamic> contents = [];
    final history = effectiveConfig.metadata['history'];
    if (history is List) {
      for (final turn in history) {
        if (turn is Map) {
          contents.add({
            'role': turn['role'] == 'user' ? 'user' : 'model',
            'parts': [
              {'text': turn['text'] ?? ''}
            ],
          });
        }
      }
    }

    // Append current prompt
    contents.add({
      'role': 'user',
      'parts': [
        {'text': prompt}
      ],
    });

    final body = <String, dynamic>{
      'contents': contents,
      'generationConfig': {
        'temperature': effectiveConfig.temperature,
        'maxOutputTokens': effectiveConfig.maxTokens,
      },
    };

    if (systemInstruction != null && systemInstruction.isNotEmpty) {
      body['systemInstruction'] = {
        'parts': [
          {'text': systemInstruction}
        ],
      };
    }

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Gemini API error (${response.statusCode}): ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = json['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('Gemini returned no candidates.');
    }

    final parts = candidates[0]['content']?['parts'] as List<dynamic>?;
    final text = parts?.map((p) => p['text'] ?? '').join('') ?? '';

    return BrainResponse(
      text: text,
      provider: BrainProvider.gemini,
      model: model,
      generatedAt: DateTime.now().toUtc(),
    );
  }

  @override
  Stream<BrainResponse> stream(
    String prompt, {
    StoredBrainConfig? config,
  }) async* {
    // Fallback: just yield the full response
    final response = await ask(prompt, config: config);
    yield response;
  }
}
