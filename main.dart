import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const TriviaQuizApp());
}

class TriviaQuizApp extends StatelessWidget {
  const TriviaQuizApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // This line removes the debug tag
      title: 'Trivia Quiz',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const QuizScreen(),
    );
  }
}

class QuizScreen extends StatefulWidget {
  const QuizScreen({Key? key}) : super(key: key);

  @override
  QuizScreenState createState() => QuizScreenState();
}

class QuizScreenState extends State<QuizScreen> {
  List<Map<String, Object>> _questions = [];
  int _score = 0;
  int _questionIndex = 0;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    loadScore();
    fetchQuestions();
  }

  Future<void> loadScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _score = prefs.getInt('score') ?? 0;
    });
  }

  Future<void> saveScore() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('score', _score);
  }

  Future<void> fetchQuestions() async {
    try {
      final response = await http.get(
          Uri.parse('https://opentdb.com/api.php?amount=10&type=multiple'));
      if (response.statusCode == 200) {
        final extractedData =
        json.decode(response.body) as Map<String, dynamic>;
        final List<Map<String, Object>> loadedQuestions = [];
        extractedData['results'].forEach((questionData) {
          final List<String> answers = (questionData['incorrect_answers']
          as List<dynamic>)
              .map((answer) => answer as String)
              .toList()
            ..add(questionData['correct_answer'] as String);
          loadedQuestions.add({
            'questionText': questionData['question'],
            'answers': answers,
            'correctAnswer': questionData['correct_answer'],
          });
        });
        setState(() {
          _score = 0; // Reset the score when new questions are fetched
          _questions = loadedQuestions;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load questions.';
          _isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        _errorMessage = 'An error occurred while fetching questions.';
        _isLoading = false;
      });
    }
  }

  void _answerQuestion(String answer) {
    if (_questions[_questionIndex]['correctAnswer'] == answer) {
      _score++;
    }
    setState(() {
      _questionIndex++;
    });
    if (_questionIndex >= _questions.length) {
      saveScore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Trivia Quiz',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Colors.blue, Colors.red],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage.isNotEmpty
            ? Center(child: Text(_errorMessage))
            : _questionIndex < _questions.length
            ? Column(
          children: [
            Text(
              _questions[_questionIndex]['questionText']
              as String,
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold),
            ),
            ...(_questions[_questionIndex]['answers']
            as List<String>)
                .map((answer) {
              return ElevatedButton(
                onPressed: () => _answerQuestion(answer),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // background color
                  foregroundColor: Colors.white, // text color
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
                child: Text(answer),
              );
            }).toList(),
          ],
        )
            : Center(
          child: Text('You scored $_score/${_questions.length}!',
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
