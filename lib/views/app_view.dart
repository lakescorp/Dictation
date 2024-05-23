import 'dart:io' show File, Platform;
import 'package:intl/intl.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart' show Share;
import 'package:speech_to_text/speech_recognition_result.dart'
    show SpeechRecognitionResult;
import 'package:speech_to_text/speech_to_text.dart' show SpeechToText;

class AppWidget extends StatefulWidget {
  const AppWidget({super.key});

  @override
  State<AppWidget> createState() => _AppWidgetState();
}

class _AppWidgetState extends State<AppWidget> {
  final SpeechToText _speechToText = SpeechToText();
  String _lastWords = '';
  String _wordsBeforeSpeech = '';
  final TextEditingController _inputController = TextEditingController();
  bool _isListening = false;

  // Speech related methods

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  void _initSpeech() async {
    await _speechToText.initialize(
      onStatus: _statusListener,
    );
    setState(() {});
  }

  void _statusListener(String status) {
    // Restart listening if it was interrupted
    if (status == 'done' || status == 'notListening') {
      if (_isListening) {
        _startListening();
      }
    }
  }

  void _startListening() async {
    _wordsBeforeSpeech = _inputController.text;
    await _speechToText
        .listen(onResult: _onSpeechResult)
        .then((value) => setState(() {}));
  }

  void _stopListening() async {
    _speechToText.stop().then((value) => setState(() {
          _isListening = false;
        }));
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _lastWords = result.recognizedWords;
      _inputController.text = "$_wordsBeforeSpeech $_lastWords";
    });
  }

  // Button actions

  void onMicrophone() {
    if (!_isListening && _speechToText.isNotListening) {
      _startListening();
      _isListening = true;
    } else if (_isListening && _speechToText.isListening) {
      _stopListening();
      _isListening = false;
    }
    setState(() {});
  }

  void onSaveNote() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }
    FilePicker.platform.getDirectoryPath().then(
      (pickedDirectory) async {
        String fileName = await obtainFileName();
        fileName = fileName.isNotEmpty
            ? fileName
            : DateFormat('yyyy-MM-dd–kk-mm').format(DateTime.now());
        final file =
            File('$pickedDirectory${Platform.pathSeparator}note_$fileName.txt');
        if (!file.existsSync()) {
          await file.create();
        }
        await file.writeAsString(_inputController.text);
      },
    );
  }

  void onShare() async {
    if (_inputController.text.isEmpty) return;
    Share.share(_inputController.text);
  }

  void onLoad() {
    FilePicker.platform.pickFiles().then((result) {
      if (result != null) {
        File file = File(result.files.single.path!);
        file.readAsString().then((String contents) {
          setState(() {
            _inputController.text = contents;
          });
        });
      }
    });
  }

  // Other methods
  Future<dynamic> obtainFileName() {
    return showDialog(
      context: context,
      builder: (context) {
        TextEditingController _fileNameController = TextEditingController();
        return AlertDialog(
          title: const Text('Enter file name'),
          content: TextField(
            controller: _fileNameController,
            decoration: const InputDecoration(hintText: "Enter file name here"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(_fileNameController.text);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: Stack(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: _inputController.clear,
                              icon: const Icon(Icons.clear),
                            ),
                            IconButton(
                              onPressed: onShare,
                              icon: const Icon(Icons.share),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: onLoad,
                              icon: const Icon(Icons.file_upload),
                            ),
                            IconButton(
                              onPressed: onSaveNote,
                              icon: const Icon(Icons.save),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Center(
                      child: IconButton.filled(
                        onPressed: onMicrophone,
                        icon: Icon(_isListening ? Icons.mic_off : Icons.mic),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    border: Border.all(),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: TextField(
                    maxLines: null,
                    controller: _inputController,
                    decoration: const InputDecoration(
                      hintText: 'Enter your text here',
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
