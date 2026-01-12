import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';

void main() => runApp(const TTSApp());

class TTSApp extends StatelessWidget {
  const TTSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: TTSPage());
  }
}

class TTSPage extends StatefulWidget {
  const TTSPage({super.key});

  @override
  State<TTSPage> createState() => _TTSPageState();
}

class _TTSPageState extends State<TTSPage> {
  final TextEditingController controller = TextEditingController();
  final AudioPlayer player = AudioPlayer();

  String? audioUrl;
  bool loading = false;

  Future<void> generateAudio() async {
    if (controller.text.isEmpty) return;

    setState(() => loading = true);

    try {
      final response = await http.post(
        Uri.parse(
          "https://text2speech-flutter-production.up.railway.app/tts",
        ),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"text": controller.text}),
      );

      if (response.statusCode != 200) {
        debugPrint("TTS failed: ${response.statusCode}");
        return;
      }

      final data = jsonDecode(response.body);
      final audioFile = data['audio_file'];

      if (audioFile == null) {
        debugPrint("audio_file missing in response");
        return;
      }

      debugPrint("Received audio_file: $audioFile");

      setState(() {
        audioUrl =
            "https://text2speech-flutter-production.up.railway.app/audio/$audioFile";
      });
    } catch (e) {
      debugPrint("generateAudio error: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> playAudio() async {
    if (audioUrl == null) return;

    try {
      await player.play(UrlSource(audioUrl!));
    } catch (e) {
      debugPrint("playAudio error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Clipboard → Speech")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: controller,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: "Paste text here",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: loading ? null : generateAudio,
              child: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text("Generate Speech"),
            ),
            if (audioUrl != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: playAudio,
                child: const Text("Play Audio"),
              )
            ]
          ],
        ),
      ),
    );
  }
}
