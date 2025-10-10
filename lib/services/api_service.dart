import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = "https://api.apis.net.pe/v1/dni";
  static const String _apiKey =
      "f218e2052f77477c4131347ad1a17eea1c939c3bd9714d6075989d2d1bdf3fe3";

  static Future<Map<String, dynamic>> getDniInfo(String dni) async {
    final url = Uri.parse("$_baseUrl?numero=$dni");

    final response = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $_apiKey",
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 404) {
      throw Exception("No se encontró información para este DNI.");
    } else {
      throw Exception("Error ${response.statusCode}: ${response.body}");
    }
  }
}
