import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:exam_planner/calendar_widget';
import 'package:exam_planner/exam_widget.dart';
import 'package:intl/intl.dart';
import 'package:exam_planner/map_widget.dart';
import 'exam.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_controller.dart';
import 'notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await AwesomeNotifications().initialize(null, [
    NotificationChannel(
      channelGroupKey: "basic_channel_group",
      channelKey: "basic_channel",
      channelName: "basic_notif",
      channelDescription: "basic notification channel",
    )
  ], channelGroups: [
    NotificationChannelGroup(
        channelGroupKey: "basic_channel_group", channelGroupName: "basic_group")
  ]);

  if (!(await AwesomeNotifications().isNotificationAllowed())) {
    AwesomeNotifications().requestPermissionToSendNotifications();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      routes: {
        '/': (context) => const MainListScreen(),
        '/login': (context) => const AuthScreen(isLogin: true),
        '/register': (context) => const AuthScreen(isLogin: false),
      },
    );
  }
}

class MainListScreen extends StatefulWidget {
  const MainListScreen({super.key});

  @override
  MainListScreenState createState() => MainListScreenState();
}

class MainListScreenState extends State<MainListScreen> {
  final List<Exam> exams = [
    Exam(course: 'BMS', timestamp: DateTime.now()),
    Exam(course: 'MMF', timestamp: DateTime(2024, 02, 15, 14, 30)),
    Exam(course: 'BNP', timestamp: DateTime(2024, 02, 08, 9, 45)),
    Exam(course: 'DS', timestamp: DateTime(2024, 02, 09, 18, 15)),
  ];

  bool _isLocationBasedNotificationsEnabled = false;

  @override
  void initState() {
    super.initState();

    AwesomeNotifications().setListeners(
        onActionReceivedMethod: NotificationController.onActionReceiveMethod,
        onDismissActionReceivedMethod:
            NotificationController.onDismissActionReceiveMethod,
        onNotificationCreatedMethod:
            NotificationController.onNotificationCreateMethod,
        onNotificationDisplayedMethod:
            NotificationController.onNotificationDisplayed);

    NotificationService().scheduleNotificationsForExistingExams(exams);
  }

  @override
  Widget build(BuildContext context) {
    exams.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ispiti'),
        actions: [
          IconButton(
            onPressed: _openMap,
            icon: const Icon(
              Icons.map_outlined,
              size: 28,
            ),
          ),
          IconButton(
            onPressed: _openCalendar,
            icon: const Icon(
              Icons.calendar_today_outlined,
              size: 28,
            ),
          ),
          IconButton(
            onPressed: _toggleLocationNotifications,
            icon: Icon(
              _isLocationBasedNotificationsEnabled
                  ? Icons.alarm_on_outlined
                  : Icons.alarm_add_outlined,
              size: 28,
              color: _isLocationBasedNotificationsEnabled
                  ? Colors.red
                  : Colors.green,
            ),
          ),
          IconButton(
            onPressed: () => FirebaseAuth.instance.currentUser != null
                ? _addExamFunction(context)
                : _navigateToSignInPage(context),
            icon: const Icon(
              Icons.add_circle_outline,
              size: 28,
            ),
          ),
          IconButton(
            onPressed: _signOut,
            icon: const Icon(
              Icons.logout,
              size: 28,
            ),
          ),
        ],
      ),
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
        ),
        itemCount: exams.length,
        itemBuilder: (context, index) {
          final course = exams[index].course;
          final timestamp = exams[index].timestamp;

          return Container(
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 228, 221, 171),
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    course,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    formattedDateTime(timestamp),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String formattedDateTime(DateTime timestamp) {
    return DateFormat.yMMMd().add_Hm().format(timestamp);
  }

  void _toggleLocationNotifications() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Lokaciski bazirani notifikacii"),
          content: _isLocationBasedNotificationsEnabled
              ? const Text("Gi isklucivte lokacisko baziranite notifikacii")
              : const Text("Gi vklucivte lokacisko baziranite notifikacii"),
          actions: [
            TextButton(
              onPressed: () {
                NotificationService().toggleLocationNotification();
                setState(() {
                  _isLocationBasedNotificationsEnabled =
                      !_isLocationBasedNotificationsEnabled;
                });
                Navigator.pop(context);
              },
              child: const Text("OK"),
            )
          ],
        );
      },
    );
  }

  void _openCalendar() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CalendarWidget(exams: exams),
      ),
    );
  }

  void _openMap() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => const MapWidget()));
  }

  Future<void> _addExamFunction(BuildContext context) async {
    return showModalBottomSheet(
        context: context,
        builder: (_) {
          return GestureDetector(
            onTap: () {},
            behavior: HitTestBehavior.opaque,
            child: ExamWidget(
              addExam: _addExam,
            ),
          );
        });
  }

  void _addExam(Exam exam) {
    setState(() {
      exams.add(exam);
      NotificationService().scheduleNotification(exam);
    });
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  void _navigateToSignInPage(BuildContext context) {
    Future.delayed(Duration.zero, () {
      Navigator.pushReplacementNamed(context, '/login');
    });
  }
}

class AuthScreenState extends State<AuthScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _authAction() async {
    try {
      if (widget.isLogin) {
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
        _showSuccessSnackBar("Login Successful");
        _navigateToHome();
      } else {
        await _auth.createUserWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
        _showSuccessSnackBar("Registration Successful");
        _navigateToLogin();
      }
    } catch (e) {
      _showErrorDialog(
          "Authentication Error", "Error during authentication: $e");
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _navigateToHome() {
    Future.delayed(Duration.zero, () {
      Navigator.pushReplacementNamed(context, '/');
    });
  }

  void _navigateToLogin() {
    Future.delayed(Duration.zero, () {
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  void _navigateToRegister() {
    Future.delayed(Duration.zero, () {
      Navigator.pushReplacementNamed(context, '/register');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: widget.isLogin ? const Text("Login") : const Text("Register"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
                fillColor: Colors.white,
                filled: true,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
                fillColor: Colors.white,
                filled: true,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _authAction,
              style: ElevatedButton.styleFrom(
                primary: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
              ),
              child: Text(
                widget.isLogin ? "Sign In" : "Register",
                style: TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: _navigateToHome,
              child: const Text('Back to Main Screen',
                  style: TextStyle(fontSize: 16)),
            ),
            if (!widget.isLogin)
              TextButton(
                onPressed: _navigateToLogin,
                child: const Text('Already have an account? Login',
                    style: TextStyle(fontSize: 16)),
              ),
            if (widget.isLogin)
              TextButton(
                onPressed: _navigateToRegister,
                child: const Text('Create an account',
                    style: TextStyle(fontSize: 16)),
              ),
          ],
        ),
      ),
    );
  }
}

class AuthScreen extends StatefulWidget {
  final bool isLogin;

  const AuthScreen({super.key, required this.isLogin});

  @override
  AuthScreenState createState() => AuthScreenState();
}
