import 'package:flutter_gemini/flutter_gemini.dart';

class GeminiService {
  final gemini = Gemini.instance;

  Future<String> getDiversificationAdvice(String userData) async {
    try {
      // Create the prompt for the model
      String prompt = "Analyze this user's portfolio: $userData. Suggest how to diversify investments across Nifty 50, Gold, and Mutual Funds.";

      // Use the gemini instance to get a response
      final response = await gemini.text(prompt);

      // The response?.output contains the generated text.
      // We use the null-aware operator '??' to provide a default message if the output is null.
      return response?.output ?? "Could not get a response.";
    } catch (e) {
      // Handle any errors that might occur during the API call
      throw Exception("Gemini API Error: $e");
    }
  }
}
