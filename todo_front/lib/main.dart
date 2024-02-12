import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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
      home: const MainPage(),
    );
  }
}

Future<List<Map<String, dynamic>>> fetchData() async {
  final response = await http.get(Uri.parse('http://192.168.0.102:8000/api/'));
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

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  List<bool> checkboxes = [];
  late Future<List<Map<String, dynamic>>> futureData;

  @override
  void initState() {
    super.initState();
    futureData = fetchData();
    futureData.then((data) {
      checkboxes = data.map((item) => item['completed'] as bool).toList();
    });
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
    var url = Uri.parse('http://192.168.0.102:8000/api/$ItemIndex/');

    // Data to be sent
    var data = {
      "id": ItemIndex, // Assuming the itemIndex is the ID you want to send
      "completed": newValue!,
    };

    try {
      // Send the PUT request
      var response = await http.patch(
        url,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
                              var url = Uri.parse(
                                  'http://192.168.0.102:8000/api/'); // URL to your API endpoint
                              var data = {
                                "title": _textFieldController.text,
                                // Add other task properties if necessary
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
                            var url = Uri.parse(
                                'http://192.168.0.102:8000/api/${itemIndex}/');

                            try {
                              var response = await http.delete(url);

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
