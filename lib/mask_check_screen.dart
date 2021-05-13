import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:tflite/tflite.dart';

class MaskCheckScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  MaskCheckScreen({Key key, @required this.cameras}) : super(key: key);

  @override
  _MaskCheckScreenState createState() => _MaskCheckScreenState();
}

class _MaskCheckScreenState extends State<MaskCheckScreen> {
  CameraImage cameraImage;
  CameraController cameraController;
  String result = '';
  int selectedCameraIndex=1;

  initCamera() {
    cameraController = CameraController(
        widget.cameras[selectedCameraIndex], ResolutionPreset.ultraHigh);
    cameraController.initialize().then((value) {
      if (!mounted) return;
      setState(() {
        cameraController.startImageStream((imageStream) {
          cameraImage = imageStream;
          runModel();
        });
      });
    });
  }

  loadModel() async {
    await Tflite.loadModel(
        model: "assets/model_unquant.tflite", labels: "assets/labels.txt");
  }

  runModel() async {
    if (cameraImage != null) {
      var recognitions = await Tflite.runModelOnFrame(
          bytesList: cameraImage.planes.map((plane) {
            return plane.bytes;
          }).toList(),
          imageHeight: cameraImage.height,
          imageWidth: cameraImage.width,
          imageMean: 127.5,
          imageStd: 127.5,
          rotation: 90,
          numResults: 2,
          threshold: 0.1,
          asynch: true);
      recognitions.forEach((element) {
        setState(() {
          result = element["label"];
          print(result);
        });
      });
    }
  }

  @override
  void initState() {
    super.initState();
    initCamera();
    loadModel();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title: Text('Face Mask Detector'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              height: MediaQuery.of(context).size.height - 250,
              width: MediaQuery.of(context).size.width,
              child: !cameraController.value.isInitialized
                  ? Container()
                  : AspectRatio(
                      aspectRatio: cameraController.value.aspectRatio,
                      child: CameraPreview(cameraController),
                    ),
            ),
          ),
          Text(
            result,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
          ),
          SizedBox(
            height: 10.0,
          ),
          TextButton(
            onPressed: () {
              setState(() {
                selectedCameraIndex == 1
                    ? selectedCameraIndex = 0
                    : selectedCameraIndex = 1;
              });
            },
            child: Image.asset(
              'assets/images/camera.png',
              height: 50.0,
              width: 50.0,
            ),
          )
        ],
      ),
    ));
  }
}
