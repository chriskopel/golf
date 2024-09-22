import 'package:http/http.dart' as http;
import 'dart:convert';


// Function to fetch filtered golf courses from the backend
Future<List<String>> fetchGolfCourses(String query) async {
  final url = Uri.parse('http://127.0.0.1:5000/api/golf-courses?query=$query');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);
    return data.map((course) => course.toString()).toList();
  } else {
    throw Exception('Failed to load golf courses');
  }
}

// Function to send back the selected course to the backend
Future<void> sendSelectedCourse(String course) async {
  final url = Uri.parse('http://127.0.0.1:5000/api/filter-course');
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'course': course}),
  );

  if (response.statusCode != 200) {
    throw Exception('Failed to send selected course');
  }
}

// Function to fetch tee name and gender from the backend based on selected course
Future<List<String>> fetchTeeNameGender(String selectedCourse) async {
  final url = Uri.parse('http://127.0.0.1:5000/api/filter-course');
  
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: json.encode({'course': selectedCourse}),
  );

  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);
    return data.map((item) => item.toString()).toList();
  } else {
    throw Exception('Failed to load tee name and gender');
  }
}


// Function to send the submissions data to the backend
Future<void> sendSubmissionsData(List<Map<String, String>> submissions) async {
  final url = Uri.parse('http://127.0.0.1:5000/api/calculate-handicap');  // Replace with your backend URL and endpoint

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'submissions': submissions}),
    );

    if (response.statusCode == 200) {
      print('Data sent successfully: ${response.body}');
    } else {
      print('Failed to send data: ${response.statusCode}');
    }
  } catch (e) {
    print('Error sending data: $e');
  }
}

// Add a callback function to pass the handicap index back to the UI
Future<void> sendSubmissionsDataFront(List<Map<String, String>> submissions, Function(double) onHandicapCalculated) async {
  final url = Uri.parse('http://127.0.0.1:5000/api/calculate-handicap'); // Updated URL with /api

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'submissions': submissions}),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      if (responseData['status'] == 'success') {
        // Retrieve the handicap index from the response
        double handicapIndex = responseData['parsed_data']?.toDouble() ?? 0.0;
        print('Handicap Index calculated successfully: $handicapIndex');

        // Pass the value back to the UI
        onHandicapCalculated(handicapIndex);
      }
    } else {
      print('Failed to send data: ${response.statusCode}');
    }
  } catch (e) {
    print('Error sending data: $e');
  }
}