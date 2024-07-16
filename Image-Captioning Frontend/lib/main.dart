import 'dart:convert';
import 'dart:io'; // Import the File class
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as dotenv;

Future main() async {
  await dotenv.dotenv.load();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Captioning App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String caption = ''; // Ensure caption is declared as a String
  final picker = ImagePicker();
  File? _image; // File to store the selected image

  @override
  void initState() {
    super.initState();
  }

  Future<void> getImageAndCaption() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path); // Update _image with the selected image
      });

      var request = http.MultipartRequest(
          'POST', Uri.parse("${dotenv.dotenv.env['URL']}/caption"));
      request.files.add(await http.MultipartFile.fromPath(
          'image', pickedFile.path,
          contentType: MediaType('image', 'jpeg')));

      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        setState(() {
          caption = jsonDecode(
              responseData)['caption']; // Update caption from response
        });
      } else {
        print('Failed to load caption');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Captioning'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _image != null
                ? Image.file(_image!) // Display the selected image if available
                : Text('No image selected.'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: getImageAndCaption,
              child: Text('Pick Image'),
            ),
            SizedBox(height: 20),
            Text(
              'Generated Caption:',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 10),
            Text(
              caption.replaceAll("start", "").replaceAll("end", ""),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
