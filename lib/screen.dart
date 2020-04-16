import 'package:camera/camera.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';

import 'ScannerUtils.dart';
import 'cameraView.dart';
import 'detectorPainter.dart';

class Screen extends StatefulWidget {
  final List<CameraDescription> cameras;

  Screen({this.cameras});

  @override
  _ScreenState createState() => _ScreenState();
}

class _ScreenState extends State<Screen> {
  VisionText _textScanResults;

  CameraController controller;
  bool isDetecting = false;

  final TextRecognizer _textRecognizer =
      FirebaseVision.instance.textRecognizer();

  @override
  void initState() {
    // TODO: implement initState

    super.initState();
    _initCamera();
  }

  @override
  void setState(fn) {
    // TODO: implement setState
    super.setState(fn);
  }

  setRecognitions(results) {
    setState(() {
      _textScanResults = results;
    });
    debugPrint("Detected   " + _textScanResults.text);
  }

  _initCamera() {
    if (widget.cameras == null || widget.cameras.length < 1) {
      debugPrint('No camera is found');
    } else {
      controller = new CameraController(
          widget.cameras[0], ResolutionPreset.medium,
          enableAudio: false);

      controller.initialize().then((_) {
        if (!mounted) {
          return;
        }
        setState(() {});

        controller.startImageStream((CameraImage img) {
          if (!isDetecting) {
            // detection firebase ML

            ScannerUtils.detect(
              image: img,
              detectInImage: _getDetectionMethod(),
              imageRotation: widget.cameras[0].sensorOrientation,
            ).then(
              (results) {
                setRecognitions(results);
              },
            ).whenComplete(() => isDetecting = false);
          }
        });
      });
    }
  }

  Future<VisionText> Function(FirebaseVisionImage image) _getDetectionMethod() {
    return _textRecognizer.processImage;
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller.value.isInitialized) {
      return Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(),
        ),
      );
    }
    var screenHeight = MediaQuery.of(context).size.height;
    var screenWidth = MediaQuery.of(context).size.width;
    Size screenSize = MediaQuery.of(context).size;

    return SafeArea(
      /*appBar: AppBar(
        title: Text('Translate'),
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.g_translate), onPressed: null) // select language
        ],
      ),
      body: */
      child: Stack(
        children: <Widget>[
          // camera view
          Container(
              height: screenSize.height,
              width: screenSize.width,
              child: OverflowBox(
                //aspectRatio: controller.value.aspectRatio,
                child: CameraPreview(controller),
              )),
          //CameraView(cameras: widget.cameras, setRecognitions: setRecognitions),
          // text container
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: EdgeInsets.only(bottom: 15),
              color: Colors.black26,
              height: screenHeight * 0.2,
              width: screenWidth * 0.7,
              child: Text(_textScanResults.text),
            ),
          )
          //_buildResults(_textScanResults)
        ],
      ),
    );
  }

  Widget _buildResults(VisionText visionText) {
    String text = visionText.text;
    for (TextBlock block in visionText.blocks) {
      final Rect boundingBox = block.boundingBox;
      final List<Offset> cornerPoints = block.cornerPoints;
      final String text = block.text;
      final List<RecognizedLanguage> languages = block.recognizedLanguages;

      for (TextLine line in block.lines) {
        // Same getters as TextBlock
        debugPrint(line.toString());
        for (TextElement element in line.elements) {
          // Same getters as TextBlock
          debugPrint(element.toString());
        }
      }
    }
    if (visionText.text != null)
      debugPrint(visionText.text.toString());
    else
      debugPrint('meh');
    return Container();
    /*CustomPainter painter;
  // print(scanResults);
  if (scanResults != null) {
    final Size imageSize = Size(
      _controller.value.previewSize.height - 100,
      _controller.value.previewSize.width,
    );
    painter = TextDetectorPainter(imageSize, scanResults);
    //getWords(scanResults);
    debugPrint(scanResults.blocks.toString());

    return CustomPaint(
      painter: painter,
    );
  } else {
    return Container();
  }*/
  }
  @override
  void dispose() {
    // TODO: implement dispose
    controller?.dispose();
    _textRecognizer?.close();
    super.dispose();
  }
}
