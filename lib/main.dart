import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_audio_recorder2/flutter_audio_recorder2.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:io';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audio Recorder App',
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
  bool isRecording = false;
  bool isUltrasoundDetected = false;
  String filePath = "";
  List<int> audioData = [];

  StreamSubscription<Uint8List>? microphoneStream;
  late FlutterAudioRecorder2 _recorder;

  void startStopRecording() async {
    if (!isRecording) {
      Directory appDocDirectory = await getApplicationDocumentsDirectory();
      String recordingPath = appDocDirectory.path + '/recording.wav';

      _recorder = FlutterAudioRecorder2(recordingPath, audioFormat: AudioFormat.WAV);

      await _recorder.initialized;

      var status;
      if (_recorder.status == RecordingStatus.Initialized) {
        await _recorder.start();

        var audioStream;
        microphoneStream = _recorder.audioStream.listen((samples) {
          setState(() {
            audioData.addAll(samples);
          });

          bool detected = detectUltrasoundSignal(samples);
          if (detected) {
            setState(() {
              isUltrasoundDetected = true;
            });
          }
        });

        setState(() {
          isRecording = true;
          filePath = recordingPath;
        });
      }
    } else {
      microphoneStream?.cancel();
      Recording? recording = await _recorder.stop();

      if (audioData.isNotEmpty) {
        File audioFile = File(filePath);
        await audioFile.writeAsBytes(audioData);
      }

      setState(() {
        isRecording = false;
        isUltrasoundDetected = false;
        audioData.clear();
      });
    }
  }

  bool detectUltrasoundSignal(List<int> samples) {
    final int threshold = 20000;

    double sum = 0;
    for (int sample in samples) {
      sum += sample.abs();
    }
    double averageMagnitude = sum / samples.length;

    return averageMagnitude > threshold;
  }

  @override
  void dispose() {
    microphoneStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Audio Recorder App'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: startStopRecording,
              style: ElevatedButton.styleFrom(
                primary: isRecording ? Colors.red : Colors.green,
              ),
              child: Text(
                isRecording ? 'Stop Recording' : 'Start Recording',
                style: TextStyle(color: Colors.white),
              ),
            ),
            SizedBox(height: 20),
            Text(
              filePath,
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            SizedBox(height: 20),
            isUltrasoundDetected
                ? Text(
                    'Ultrasound Detected',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : SizedBox(),
          ],
        ),
      ),
    );
  }
}
