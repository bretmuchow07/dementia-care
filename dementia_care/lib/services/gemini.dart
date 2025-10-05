import 'dart:typed_data';
import 'package:flutter_gemini/flutter_gemini.dart';

class GeminiService {
  final Gemini gemini = Gemini.instance;

  /// Generates a description for an image and identifies the mood of a person.
  ///
  /// Takes [imageBytes] and an optional [userCaption] to provide context.
  /// It asks the Gemini model to describe the image and classify the mood
  /// of any person present according to a predefined list.
  Future<String> describeImageAndGetMood({
    required Uint8List imageBytes,
    String? userCaption,
  }) async {
    // This is the core instruction for the Gemini model.
    // It's engineered to focus on describing the scene and identifying a mood
    // from the specific list you provided.
    String prompt = """
      Analyze the image provided. Your task is to do two things:
      1.  Provide a brief, engaging description of the image. This will be used as a caption.
      2.  If a person is in the image, identify their primary emotion from the following list ONLY:
          'happy', 'joyful', 'excited', 'calm', 'peaceful', 'relaxed', 'neutral', 'okay', 'sad',
          'down', 'upset', 'angry', 'frustrated', 'annoyed', 'confused', 'lost', 'anxious',
          'worried', 'tired', 'exhausted', 'energetic', 'active'.

      If the user has provided their own caption, use it as context to refine your description.
      User's caption: "${userCaption ?? 'None'}"

      Respond with the description. If a mood is identified, include it in the description.
      For example: "A person smiling brightly at a sunny park, appearing very happy."
      If no person is visible or the mood is unclear, just describe the image.
      For example: "A beautiful, calm sunset over the ocean."
    """;

    try {
      final response = await gemini.textAndImage(
        text: prompt,
        images: [imageBytes], // The image data
      );

      final lastPart = response?.content?.parts?.last;
      if (lastPart is TextPart) {
        // **NEW:** Clean the text before returning it.
        String generatedText = lastPart.text;

        // Remove the known GEMINI_WARNING string.
        String cleanedText = generatedText.replaceAll(
            RegExp(r'\[GEMINI_WARNING\].*'), ''
        ).trim();

        return cleanedText.isNotEmpty ? cleanedText : "Received an empty response.";
      }

      return "Sorry, I couldn't describe this image.";

    } catch (e) {
      // It's good practice to log the actual error for debugging.
      print("Gemini API Error: $e");
      throw Exception("Failed to generate description from Gemini: $e");
    }
  }
}
