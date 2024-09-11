import 'package:flutter/material.dart';
import 'package:golf_handicap_calc/api_service.dart';  // Adjust the import path if needed

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Golf Handicap Calculator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Golf Handicap Calculator'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;  // Declare the title field here

  const MyHomePage({super.key, required this.title});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // List of golf courses
  List<String> golfCourses = [];
  String? selectedCourse;

  // List to store selected courses and corresponding scores
  List<Map<String, dynamic>> selectedCourses = [];

  // Controller for entering the score
  final TextEditingController scoreController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchGolfCourses().then((courses) {
      setState(() {
        golfCourses = courses;
      });
    }).catchError((e) {
      print('Error fetching golf courses: $e');
    });
  }

  // Method to add a selected course and score to the list
  void addCourseAndScore() {
    if (selectedCourse != null && scoreController.text.isNotEmpty) {
      setState(() {
        selectedCourses.add({
          'course': selectedCourse,
          'score': double.parse(scoreController.text),
        });
      });
      // Reset the selection and text field
      selectedCourse = null;
      scoreController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Select a golf course and enter your score:'),
            
            // Dropdown for selecting a golf course
            DropdownButton<String>(
              value: selectedCourse,
              hint: const Text('Select a course'),
              items: golfCourses.map<DropdownMenuItem<String>>((String course) {
                return DropdownMenuItem<String>(
                  value: course,
                  child: Text(course),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedCourse = newValue;
                });
              },
            ),

            // TextField for entering the score
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: scoreController,
                decoration: const InputDecoration(
                  labelText: 'Enter score',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),

            // Button to add the course and score
            ElevatedButton(
              onPressed: addCourseAndScore,
              child: const Text('Add Course and Score'),
            ),

            const SizedBox(height: 20),

            // Display list of selected courses and scores
            Expanded(
              child: ListView.builder(
                itemCount: selectedCourses.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text('${selectedCourses[index]['course']}'),
                    subtitle: Text('Score: ${selectedCourses[index]['score']}'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
