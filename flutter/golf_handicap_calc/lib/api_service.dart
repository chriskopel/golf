import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> getHandicap(List<double> scores, List<Map<String, String>> courseInfo) async {
  final url = Uri.parse('http://127.0.0.1:5000/calculate-handicap');
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'scores': scores,
      'course_info': courseInfo,
    }),
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    print('Handicap Index: ${data['handicap_index']}');
  } else {
    print('Error: ${response.reasonPhrase}');
  }
}


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