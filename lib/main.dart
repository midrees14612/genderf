import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

late List<CameraDescription> _cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    _cameras = await availableCameras();
  } catch (e) {
    _cameras = [];
  }
  runApp(const GenderApp());
}

class GenderApp extends StatelessWidget {
  const GenderApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const CameraScreen(),
    );
  }
}

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});
  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? controller;
  bool isInitialized = false;
  bool isProcessing = false;
  String resultText = "System Booting... 🗿";

  // Face Detector ko late initialize karenge taake crash na ho
  late FaceDetector faceDetector;

  @override
  void initState() {
    super.initState();
    faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableLandmarks: true,
        enableClassification: true,
        performanceMode: FaceDetectorMode.accurate,
      ),
    );
    initCamera();
  }

  void initCamera() async {
    if (_cameras.isEmpty) {
      setState(() => resultText = "No Camera! ❌");
      return;
    }

    // Safety: Index 0 hamesha available hota hai agar list khali na ho
    controller = CameraController(_cameras[0], ResolutionPreset.high, enableAudio: false);

    try {
      await controller!.initialize();
      if (!mounted) return;
      setState(() {
        isInitialized = true;
        resultText = "Vibe Sensor Ready ✅";
      });
    } catch (e) {
      setState(() => resultText = "Cam Error: $e");
    }
  }

  Future<void> detectRealVibe() async {
    if (controller == null || !controller!.value.isInitialized || isProcessing) return;

    setState(() {
      isProcessing = true;
      resultText = "AI SCANNING... ⚡";
    });

    try {
      final XFile image = await controller!.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);

      // Yahan error aa sakta hai agar plugin register na hua ho
      final List<Face> faces = await faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        setState(() {
          resultText = "NO FACE FOUND! 🚫";
          isProcessing = false;
        });
        return;
      }

      Face face = faces.first;
      double? smile = face.smilingProbability;

      setState(() {
        isProcessing = false;
        // Strict Sigma Logic for your heavy beard
        if (smile != null && smile < 0.10) {
          resultText = "100% SIGMA MALE 🗿\nPure GigaChad Energy!";
        } else if (smile != null && smile > 0.40) {
          resultText = "SLAY QUEEN 💅\nMain Character Vibes!";
        } else {
          resultText = "VIBE CHECK: SUS 💀\nKussra Mode Activated 😂";
        }
      });

    } catch (e) {
      setState(() {
        isProcessing = false;
        resultText = "Plugin Fail! ❌\nRestart Phone & Re-run";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isInitialized) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 70),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 30),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.cyanAccent, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: CameraPreview(controller!),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              children: [
                Text(resultText, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isProcessing ? null : detectRealVibe,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text("SCAN MY AURA 🚀", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    faceDetector.close();
    super.dispose();
  }
}