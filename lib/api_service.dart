import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

class ApiService {
  final String baseGeneralUrl = 'https://api-my3.soliq.uz';
  final String baseTasnifUrl = 'https://api-tasnif.soliq.uz/cls-api';
  final String baseUrl = 'https://your-base-url.soliq.uz'; // Update if needed
  final http.Client client = http.Client();

  // Example baseHeader (modify based on your auth requirements)
  Map<String, String> get baseHeader => {
    'Content-Type': 'application/json',
    // Add Authorization token if required
  };

  Future<Map<String, String>> baseGeneralHeader() async {
    return {
      'Content-Type': 'application/json',
      // Add Authorization token if required
    };
  }

  // Response handler (example implementation, modify as per your _response logic)
  dynamic _response(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw FetchDataException('Error: ${response.statusCode} - ${response.body}');
    }
  }

  // Response handler with token (example, modify as needed)
  dynamic _responseWithToken(http.Response response, context) {
    return _response(response); // Add token handling if required
  }

  // Search product by type
  Future<dynamic> searchProductByType(String text, String type, int page) async {
    var responseJson;
    String url =
        "$baseTasnifUrl/mxik/search/by-params?$type=$text&size=20&page=$page";
    if (type == 'dvCertNumber') {
      url =
      "$baseTasnifUrl/mxik/search/dv-cert-number?dvCertNumber=$text&size=20&page=$page";
    }
    try {
      final response = await client.get(Uri.parse(url), headers: baseHeader);
      var res = _response(response);
      responseJson = ClassificationResponse.fromJson(res);
    } on FetchDataException {
      throw FetchDataException("No Internet connection");
    }
    return responseJson;
  }

  // Search MXIK by text
  Future<dynamic> searchMxikByText(String text) async {
    var responseJson;
    String url = "$baseTasnifUrl/mxik/search/by-params?text=$text";
    try {
      final response = await client.get(Uri.parse(url), headers: baseHeader);
      developer.log('Request headers: ${response.request!.headers}');
      developer.log('Response body: ${response.body}');
      var res = _response(response);
      responseJson = ClassificationResponse.fromJson(res);
    } on FetchDataException {
      throw FetchDataException("No Internet connection");
    }
    return responseJson;
  }

  // Search product by GTIN
  Future<dynamic> search2ProductByText(String tin) async {
    var responseJson;
    String url = "$baseTasnifUrl/mxik/search/by-params?gtin=$tin";
    try {
      final response = await client.get(Uri.parse(url), headers: baseHeader);
      developer.log('Request headers: ${response.request!.headers}');
      developer.log('Response body: ${response.body}');
      var res = _response(response);
      responseJson = ClassificationResponse.fromJson(res);
    } on FetchDataException {
      throw FetchDataException("No Internet connection");
    }
    return responseJson;
  }

// Add more API methods as needed (e.g., getUnits, sendFeedbackFromUser, etc.)
}

// Custom exception
class FetchDataException implements Exception {
  final String message;
  FetchDataException(this.message);
  @override
  String toString() => message;
}

// Placeholder models (replace with your actual model definitions)
class ClassificationResponse {
  // Define properties and fromJson method
  ClassificationResponse.fromJson(Map<String, dynamic> json) {
    // Implement parsing logic
  }
}