import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';

class CameraPage extends StatefulWidget {
  final List<CameraDescription> cameras;
  const CameraPage({super.key, required this.cameras});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _controller;
  List<String> capturedImagePaths = [];
  List<String> returnedImages = [];
  bool isCapturing = false;
  String? title;
  @override
  void initState() {
    super.initState();
    initCamera();
  }

  Future<void> initCamera() async {
    _controller = CameraController(
      widget.cameras[0],
      ResolutionPreset.veryHigh,
    );

    try {
      await _controller!.initialize();
      setState(() {});
    } catch (e) {
      print('Error al inicializar la cámara: $e');
    }
  }

  Future<void> sendImageToBackend(String imagePath) async {
    var uri = Uri.parse("https://v9k5scrk-5000.brs.devtunnels.ms/upload");
    var request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('image', imagePath));

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final raza = data['raza'];
        print("Raza recibida desde el servidor: $raza");
        setState(() {
          title = raza;
        });
        // Aquí puedes hacer lo que quieras con `raza`, como mostrarla o guardarla
        // Por ejemplo, agregarla a una lista en el estado:
        // setState(() {
        //   razasDetectadas.add(raza);
        // });
      } else if (response.statusCode == 204) {
        setState(() {
          title = "No se detectó ganado en la imagen.";
        });
        print("No se detectó ganado en la imagen.");
      } else {
        print(
          "Error al enviar imagen: ${response.statusCode} ${response.body}",
        );
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> captureFrames() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        isCapturing) {
      return;
    }

    setState(() {
      capturedImagePaths.clear();
      isCapturing = true;
    });

    while (isCapturing) {
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final imagePath = join(directory.path, 'frame_$timestamp.jpg');

      try {
        final XFile file = await _controller!.takePicture();
        await file.saveTo(imagePath);
        await sendImageToBackend(imagePath);
        setState(() {
          capturedImagePaths.add(imagePath);
        });
      } catch (e) {
        print('Error al capturar imagen: $e');
      }
      await Future.delayed(Duration(seconds: 5));
    }
  }

  void stopCapturing() {
    setState(() {
      isCapturing = false;
      title = null; // Reset title when stopping capture
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Cargando cámaras'),
          centerTitle: true,
          backgroundColor: Colors.blueGrey,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Capturar Frames',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueGrey,
      ),
      body: Center(
        child: Column(
          children: [
            Container(
              height: 360,
              width: 270,
              margin: EdgeInsets.all(10),
              child: CameraPreview(_controller!),
            ),
            SizedBox(height: 10),

            Text(
              title ?? 'Esperando detección...',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: !isCapturing ? captureFrames : stopCapturing,
        child: Icon(isCapturing ? Icons.cancel_outlined : Icons.camera),
      ),
    );
  }


}
