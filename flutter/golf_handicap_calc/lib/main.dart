import 'package:flutter/material.dart';
import 'package:golf_handicap_calc/api_service.dart'; // Make sure to adjust the import path

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
  final String title;

  const MyHomePage({super.key, required this.title});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Controller for the search input
  final TextEditingController searchController = TextEditingController();
  final TextEditingController scoreController = TextEditingController();
  List<String> filteredCourses = [];
  List<Map<String, String>> submissions = []; // List to store submissions
  String? selectedCourse;
  List<String> teeNameGenderList = [];
  String? selectedTeeGender;
  double _handicapIndex = 0.0; // State variable to store the calculated handicap index

  // Method to fetch and update the filtered course list
  void updateInput() {
    String query = searchController.text;
    fetchGolfCourses(query).then((courses) {
      setState(() {
        filteredCourses = courses;
      });
    }).catchError((e) {
      print('Error fetching golf courses: $e');
    });
  }

  // Method to fetch Tee Name and Gender based on the selected course
  void fetchTeeNameGenderList(String course) {
    fetchTeeNameGender(course).then((teeList) {
      setState(() {
        teeNameGenderList = teeList;
      });
    }).catchError((e) {
      print('Error fetching tee name and gender: $e');
    });
  }

  // Method to handle submission
  void handleSubmit() {
    if (selectedCourse != null && selectedTeeGender != null && scoreController.text.isNotEmpty) {
      setState(() {
        // Add new submission to the list
        submissions.add({
          'course': selectedCourse!,
          'teeGender': selectedTeeGender!,
          'score': scoreController.text
        });

        // Reset input fields
        searchController.clear();
        scoreController.clear();
        selectedCourse = null;
        selectedTeeGender = null;
        filteredCourses = [];
        teeNameGenderList = [];
      });
    }
  }

  // Method to send data to the backend when "Calculate Handicap" is pressed
  void handleCalculateHandicap() {
    sendSubmissionsDataFront(submissions, _updateHandicapIndex).then((_) {
      print('Submissions Data: $submissions'); // Print the submissions data to the console
    });
  }

  // Method to update the state with the calculated handicap index
  void _updateHandicapIndex(double handicapIndex) {
    setState(() {
      _handicapIndex = handicapIndex;
    });
  }

  // Method to remove a specific submission
  void clearSubmission(int index) {
    setState(() {
      submissions.removeAt(index);
    });
  }

  // Method to reset all fields and clear the submissions list
  void handleReset() {
    setState(() {
      searchController.clear();
      scoreController.clear();
      filteredCourses = [];
      selectedCourse = null;
      selectedTeeGender = null;
      teeNameGenderList = [];
      submissions.clear();
      _handicapIndex = 0.0; // Reset the handicap index as well
    });
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
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 20),

            // Display the calculated handicap index at the top center of the screen
            Text(
              'Handicap Index: ${_handicapIndex.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            const Text('Enter your search:'),

            // TextField for entering the search input
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  labelText: 'Search',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (value) => updateInput(),
              ),
            ),

            // Tee and Gender Dropdown and Score Input Row
            if (teeNameGenderList.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: [
                    // Tee Name and Gender Dropdown
                    Expanded(
                      child: DropdownButton<String>(
                        value: selectedTeeGender,
                        hint: const Text('Select Tee and Gender'),
                        items: teeNameGenderList.map((tee) {
                          return DropdownMenuItem<String>(
                            value: tee,
                            child: Text(tee),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            selectedTeeGender = newValue;
                          });
                        },
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Score Input
                    Expanded(
                      child: TextField(
                        controller: scoreController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Score',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Submit Button
                    ElevatedButton(
                      onPressed: handleSubmit,
                      child: const Text('Submit'),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Display the list of filtered courses
            if (filteredCourses.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: filteredCourses.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(filteredCourses[index]),
                      onTap: () {
                        setState(() {
                          selectedCourse = filteredCourses[index];
                          searchController.text = selectedCourse!;
                          filteredCourses = [];
                          fetchTeeNameGenderList(selectedCourse!);
                        });
                      },
                    );
                  },
                ),
              ),

            const SizedBox(height: 20),

            // Display all submissions in the center of the screen with Clear button
            Expanded(
              child: ListView.builder(
                itemCount: submissions.length,
                itemBuilder: (context, index) {
                  final submission = submissions[index];
                  return ListTile(
                    title: Text(
                      'Course: ${submission['course']} \nTee & Gender: ${submission['teeGender']} \nScore: ${submission['score']}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => clearSubmission(index), // Clear individual submission
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // Tooltip for Calculate Handicap button
            Tooltip(
              message: submissions.length < 3
                  ? 'Please Enter 3 Scores at Minimum to Calculate Handicap'
                  : '',
              child: ElevatedButton(
                onPressed: submissions.length >= 3 ? handleCalculateHandicap : null,
                child: const Text('Calculate Handicap'),
              ),
            ),

            const SizedBox(height: 20),

            // Reset Button at the bottom center
            ElevatedButton(
              onPressed: handleReset,
              child: const Text('Clear All Scores'),
            ),
          ],
        ),
      ),
    );
  }
}
