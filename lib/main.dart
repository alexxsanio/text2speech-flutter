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

  // Function to show error dialog
  void _showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text("OK"))
        ],
      ),
    );
  }

  Future<void> generateAudio() async {
    if (controller.text.isEmpty) {
      _showError("Please enter text to convert.");
      return;
    }

    setState(() => loading = true);

    try {
      final response = await http.post(
        Uri.parse("http://127.0.0.1:8000/tts"), // <-- update this
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"text": controller.text}),
      );

      // Check for HTTP errors
      if (response.statusCode != 200) {
        throw Exception(
            "Server returned status code ${response.statusCode}");
      }

      final data = jsonDecode(response.body);
      if (data['audio_file'] == null) {
        throw Exception("Invalid response from server.");
      }

      setState(() {
        audioUrl = "http://127.0.0.1:8000/audio/${data['audio_file']}";
        loading = false;
      });
    } on http.ClientException catch (e) {
      setState(() => loading = false);
      _showError("Network error: ${e.message}");
    } on Exception catch (e) {
      setState(() => loading = false);
      _showError("Error: ${e.toString()}");
    } catch (e) {
      setState(() => loading = false);
      _showError("Unexpected error: ${e.toString()}");
    }
  }

  Future<void> playAudio() async {
    if (audioUrl == null) {
      _showError("No audio to play.");
      return;
    }

    try {
      await player.play(UrlSource(audioUrl!));
    } catch (e) {
      _showError("Failed to play audio: ${e.toString()}");
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
                  ? const CircularProgressIndicator()
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
