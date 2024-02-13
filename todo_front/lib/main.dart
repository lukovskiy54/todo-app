import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:todo_front/auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:todo_front/login.dart';
import 'package:todo_front/splash.dart';
import 'package:todo_front/login.dart';
import 'dart:math' as math;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        checkboxTheme: CheckboxThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(2),
            // Optional: if you want rounded corners
          ),
          side: BorderSide(
              color: Colors.grey.shade400,
              width: 2), // Set your border color here
        ),

        brightness: Brightness.light,
        primaryColor: Colors.black,

        // Define the default font family.

        // Define the default TextTheme.

        // Define the default ColorScheme.
        colorScheme: ColorScheme(
          primary:
              Colors.black, // Primary color (used for AppBar background, etc.)
          onPrimary: Colors.white, // Text color on top of primary color
          secondary: Colors
              .white, // Secondary color (used for floating action buttons, etc.)
          onSecondary: Colors.black, // Text color on top of secondary color
          surface: Colors.white, // Color for cards, sheets, menus
          onSurface: Colors.black, // Text color on top of surface color
          background: Colors.white, // Color for backgrounds
          onBackground: Colors.white, // Text color on top of background color
          error: Colors.red, // Color for error messages and icons
          onError: Colors.white, // Text color on top of error color
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      routes: {
        '/': (_) => LoginScreen(),
        '/main': (_) => MainPage(),
        '/login': (_) => LoginScreen(),
      },
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  List<bool> checkboxes = [];
  final storage = new FlutterSecureStorage();
  late Future<List<Map<String, dynamic>>> futureData;
  final GoogleSignIn googleSignIn = GoogleSignIn(
      scopes: <String>[
        'email',
      ],
      clientId:
          "48608572513-19oeb7v99nj1sjbksiqq41npdh4sv768.apps.googleusercontent.com");

  @override
  void initState() {
    checkSignIn();

    super.initState();
    futureData = fetchData();
    futureData.then((data) {
      checkboxes = data.map((item) => item['completed'] as bool).toList();
    });
  }

  Future<List<Map<String, dynamic>>> fetchData() async {
    final String? userEmail = await getEmailFromStorage();
    final response = await http.get(Uri.parse('http://127.0.0.1:8000/api/')
        .replace(queryParameters: {'email': userEmail}));
    print('response');
    print(response.headers);
    print('response $response.body');
    if (response.statusCode == 200) {
      var decodedBody = utf8.decode(response.bodyBytes);
      print(decodedBody);
      List<dynamic> data = json.decode(decodedBody);
      print('data');
      print('data $data');

      return data.map((item) => item as Map<String, dynamic>).toList();
    } else {
      throw Exception('Failed to load data');
    }
  }

  void sendTokenToBackend(String accessToken) async {
    // Your Django REST API endpoint
    final String backendUrl = 'http://localhost:8000/google-login/';

    // Send a POST request with the token
    final response = await http.post(
      Uri.parse(backendUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: json.encode({'access_token': accessToken}),
    );
    print('info sent');
    if (response.statusCode == 200) {
      // Handle the response from the server
      final responseData = json.decode(response.body);
      print(responseData);
      // Use the response data as needed
    } else {
      // Handle errors
      print('Failed to send token: ${response.body}');
    }
  }

  Future<String?> getTokenFromStorage() async {
    final storage = FlutterSecureStorage();
    String? accessToken = await storage.read(key: 'google_access_token');
    print(accessToken);
    return accessToken;
  }

  Future<String?> getEmailFromStorage() async {
    final storage = FlutterSecureStorage();
    String? email = await storage.read(key: 'email');
    print(email);
    return email;
  }

  void checkSignIn() async {
    bool isSignedIn = await googleSignIn.isSignedIn();
    if (isSignedIn) {
      String? accessToken = await getTokenFromStorage();
      print('Signed in successful');
      sendTokenToBackend(accessToken!);
    } else {
      print('Signed in not successful');
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> _refreshData() async {
    var newData = await fetchData();
    setState(() {
      futureData = Future.value(newData);
      checkboxes = newData.map((item) => item['completed'] as bool).toList();
    });
  }

  void _handleCheckboxChange(bool? newValue, int index, int ItemIndex) async {
    setState(() {
      checkboxes[index] = newValue!;
    });

    var url = Uri.parse('http://127.0.0.1:8000/api/$ItemIndex/');
    final String? userEmail = await getEmailFromStorage();
    print('${userEmail}');
    // Data to be sent
    var data = {
      "id": ItemIndex, // Assuming the itemIndex is the ID you want to send
      "completed": newValue!,
      "email": userEmail,
    };

    try {
      // Send the PUT request
      var response = await http.patch(
        Uri.parse('http://127.0.0.1:8000/api/$ItemIndex/')
            .replace(queryParameters: {'email': userEmail}),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        // Handle successful response
        print('Item updated successfully');
      } else {
        // Handle error response
        print('Failed to update item. Status code: ${response.statusCode}');
      }
    } catch (e) {
      // Handle network error or other exceptions
      print('Error occurred: $e');
    }
  }

  void clearElementFromStorage(String key) async {
    try {
      await storage.delete(key: key);
      print('Element with key $key cleared from storage.');
    } catch (e) {
      print('Error clearing element from storage: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: Transform(
              alignment: Alignment.center,
              transform: Matrix4.rotationY(
                  math.pi), // This flips the icon horizontally
              child: Icon(Icons.exit_to_app_sharp),
            ),
            onPressed: () {
              setState(() {
                clearElementFromStorage('google_access_token');
                clearElementFromStorage('email');
                googleSignIn.signOut();
              });
              Navigator.pushReplacementNamed(context, '/login');
            }),
        scrolledUnderElevation: 0,
        title: const Text(
          'Simple To-Do',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          backgroundColor: Colors.blue[700],
          onPressed: () {
            TextEditingController _textFieldController =
                TextEditingController();
            showDialog<String>(
              context: context,
              builder: (BuildContext context) => SimpleDialog(
                contentPadding: const EdgeInsets.symmetric(vertical: 0.0),
                title: const Padding(
                  padding: EdgeInsets.only(bottom: 13),
                  child: Center(child: Text('Add task')),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: TextField(
                      controller: _textFieldController,
                      cursorColor: Colors.black,
                      decoration: const InputDecoration(
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.black,
                            width: 1.0,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.black,
                            width: 2.0,
                          ),
                        ),
                        fillColor: Colors.black,
                        focusColor: Colors.black,
                        hoverColor: Colors.black,
                        border: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black)),

                        isDense: true, // Reduces the overall size

                        contentPadding: EdgeInsets.symmetric(
                            vertical: 10.0, horizontal: 10.0),
                        // Adjust padding here
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      CupertinoButton(
                          onPressed: () async {
                            var data = {
                              "title": _textFieldController
                                  .text, // Assuming the itemIndex is the ID you want to send
                              "completed": false,
                            };
                            if (_textFieldController.text.isNotEmpty) {
                              var userEmail = await getEmailFromStorage();
                              var url = Uri.parse('http://127.0.0.1:8000/api/');
                              print(userEmail); // URL to your API endpoint
                              var data = {
                                "title": _textFieldController.text,
                                "user_email": userEmail,
                              };

                              try {
                                var response = await http.post(
                                  url,
                                  headers: {
                                    'Content-Type':
                                        'application/json; charset=UTF-8',
                                  },
                                  body: json.encode(data),
                                );
                                print(response);
                                if (response.statusCode == 201) {
                                  // Assuming 201 is the status code for successful creation
                                  print('Task created successfully');
                                  print(_textFieldController.text);

                                  Map<String, dynamic> newTask =
                                      json.decode(response.body);
                                  List<Map<String, dynamic>> currentTasks =
                                      await futureData;
                                  setState(() {
                                    currentTasks.insert(0, newTask);
                                    futureData = Future.value(currentTasks);
                                    checkboxes.insert(0,
                                        false); // Assuming new tasks are not completed
                                  });
                                } else {
                                  // Handle error response
                                  print(
                                      'Failed to create task. Status code: ${response.statusCode}');
                                }
                              } catch (e) {
                                // Handle network error or other exceptions
                                print('Error occurred: $e');
                              }

                              // Close the dialog
                            }
                            Navigator.of(context).pop();
                            _textFieldController.clear();
                          },
                          child: Text('OK')),
                      CupertinoButton(
                          onPressed: () {
                            _textFieldController.dispose();
                            Navigator.of(context).pop();
                          },
                          child: Text('Cancel')),
                    ],
                  )
                ],
              ),
            );
          }),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: futureData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else if (snapshot.hasData) {
            return RefreshIndicator(
              color: Colors.black,
              onRefresh: _refreshData,
              child: ListView.builder(
                itemCount:
                    snapshot.data!.length, // Increase the number of items
                itemBuilder: (context, index) {
                  // Use modulo to alternate between list items and dividers
                  final itemIndex = snapshot.data![index]["id"];
                  return Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.95,
                      child: ListTile(
                        leading: Checkbox(
                          checkColor: Colors.white,
                          activeColor: Colors.black,
                          value: checkboxes[index],
                          onChanged: (bool? val) {
                            _handleCheckboxChange(
                              val,
                              index,
                              itemIndex,
                            );
                          },
                        ),
                        title: Text(
                          snapshot.data![index]["title"],
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              decoration: checkboxes[index]
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () async {
                            final String? userEmail = await getEmailFromStorage();
                            try {
                              var response = await http.delete(Uri.parse(
                                      'http://127.0.0.1:8000/api/${itemIndex}/')
                                  .replace(
                                      queryParameters: {'email': userEmail}));

                              if (response.statusCode == 200 ||
                                  response.statusCode == 204) {
                                // Handle successful response
                                print('Item deleted successfully');
                                setState(() {
                                  var dataIndex = snapshot.data!.indexWhere(
                                      (item) => item['id'] == itemIndex);
                                  if (dataIndex != -1) {
                                    snapshot.data!.removeAt(dataIndex);
                                    checkboxes.removeAt(dataIndex);
                                  }
                                });
                              } else {
                                // Handle error response
                                print(
                                    'Failed to delete item. Status code: ${response.statusCode}');
                              }
                            } catch (e) {
                              // Handle network error or other exceptions
                              print('Error occurred: $e');
                            }
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          } else {
            return const Text('No data available');
          }
        },
      ),
    );
  }
}
