
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _loading = true;
  File? _image;
  List? _outputs;
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    loadModel().then((value) {
      setState(() {
        _loading = false;
      });
    });
  }

  Future<void> loadModel() async {
    try {
      tfl.Interpreter interpreter = await tfl.Interpreter.fromAsset('assets/model_unquant.tflite');
      setState(() {
        _loading = false;
      });
    } catch (e) {
      print("Failed to load model: $e");
    }
  }

  Future<void> pickImage() async {
    try {
      final image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image == null) return null;
      setState(() {
        _loading = true;
        _image = File(image.path);
      });
      await classifyImage(_image!);
    } catch (e) {
      print("Failed to pick image: $e");
    }
  }

  Future<void> classifyImage(File image) async {
    try {
      var interpreter = await tfl.Interpreter.fromAsset('assets/model_unquant.tflite'); // Modeli yükle
      var input = image.readAsBytesSync(); // Giriş verisini dosyadan oku

      interpreter.allocateTensors(); // Tensorları ayır

      var inputBuffer = input.buffer.asUint8List(); // Giriş verisini hazırla

      var outputBuffer = List<double>.filled(
          interpreter.getOutputTensor(0).shape.reduce((a, b) => a * b), 0); // Çıkış tamponunu oluştur

      interpreter.run(inputBuffer, outputBuffer); // Modeli çalıştır

      setState(() {
        _loading = false;
        _outputs = outputBuffer; // Çıkışları ata
      });
    } catch (e) {
      print("Failed to classify image: $e");
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Kıyaslamaca"),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          SizedBox(height: 20),
          _image == null ? Text("Fotoğraf Seçilmedi") : Image.file(_image!),
          SizedBox(height: 20),
          _outputs != null
              ? Text("Tahmin Sonucu: ${_outputs![0]['label']}")
              : Container(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          pickImage();
        },
        child: Icon(Icons.image),
      ),
    );
  }
}