import 'package:flutter/material.dart';
import 'package:gsoc_pre2/global_connection.dart';
import 'connection_manager_page.dart';
import 'dart:io';
import 'dart:convert';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future main() async {
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late stt.SpeechToText _speechToText;
  bool _isListening = false;
  String _text = '';
  final double _confidence = 1.0;
  TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _speechToText = stt.SpeechToText();
    _initSpeech();
  }

  void _initSpeech() async {
    _isListening = await _speechToText.initialize();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final ButtonStyle buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: Colors.lightBlue,
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 25),
      textStyle: const TextStyle(fontSize: 20, color: Colors.white),
      minimumSize: const Size(260, 70),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple Flutter App'),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: const Icon(Icons.settings, size: 50),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => const ConnectionManagerPage()),
                );
              },
            ),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.asset('assets/logo.png', width: 800),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => voiceToVoice(),
                style: buttonStyle,
                child: const Text('Voice Display',
                    style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 20),
              Container(
                width: 200,
                child: TextField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Enter Text',
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => textToVoice(),
                style: buttonStyle,
                child: const Text('Submit Text',
                    style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await cleanKML();
                  await setRefresh();
                },
                style: buttonStyle,
                child: const Text('Clear KML',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> callGroqApi(String content) async {
    var url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
    String groqApiKey = dotenv.env['GROQ_API_KEY']!;

    var response = await http.post(
      url,
      headers: <String, String>{
        'Authorization': 'Bearer $groqApiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'messages': [
          {'role': 'user', 'content': content}
        ],
        'model': 'gemma-7b-it'
      }),
    );

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      String message = jsonResponse['choices'][0]['message']['content'];
      return message;
    } else {
      return null;
    }
  }

  Future<void> textToVoice() async {
    String? responseText = await callGroqApi(_textController.text);
    if (responseText != null) {
      await createVoice(responseText);
      await displayTextOnLG(responseText);
    }
  }

  Future<void> voiceToVoice() async {
    if (!_isListening) {
      bool available = await _speechToText.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speechToText.listen(onResult: _handleSpeechResultForVoice);
      }
    } else {
      setState(() => _isListening = false);
      _speechToText.stop();
    }
  }

  Future<void> _handleSpeechResultForVoice(
      SpeechRecognitionResult result) async {
    if (result.finalResult && result.recognizedWords.isNotEmpty) {
      _speechToText.stop();
      setState(() {
        _isListening = false;
        _text = result.recognizedWords;
      });

      String? responseText = await callGroqApi(_text);
      if (responseText != null) {
        await createVoice(responseText);
        await displayTextOnLG(responseText);
      }
    }
  }

  Future<void> createVoice(String content) async {
    final url =
        Uri.parse('https://api.deepgram.com/v1/speak?model=aura-asteria-en');
    String deepgramApiKey = dotenv.env['DEEPGRAM_API_KEY']!;
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Token $deepgramApiKey"
      },
      body: jsonEncode({"text": content}),
    );

    if (response.statusCode == 200) {
      final bytes = response.bodyBytes;
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/textToSpeech.wav');
      await file.writeAsBytes(bytes);
      final player = AudioPlayer();
      await player.play(DeviceFileSource(file.path));
    }
  }

  Future<void> displayTextOnLG(String content) async {
    String kmlContent = '''
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2" xmlns:kml="http://www.opengis.net/kml/2.2" xmlns:atom="http://www.w3.org/2005/Atom">
  <Document>
    <name>Groq-API</name>
    <open>1</open>
    <Folder>
      <Style id="balloon">
        <BalloonStyle>
          <bgColor>ffffffff</bgColor>
          <text><![CDATA[
            <b><font size="+2">Response: <font color="#5D5D5D"></font></font></b>
            <br/><br/>
            <b>$content</b>
          ]]></text>
        </BalloonStyle>
        <LabelStyle>
          <scale>0</scale>
        </LabelStyle>
        <IconStyle>
          <scale>0</scale>
        </IconStyle>
      </Style>
      <Placemark>
        <name>Groq API Response</name>
        <styleUrl>#balloon</styleUrl>
        <Point>
          <gx:drawOrder>1</gx:drawOrder>
          <gx:altitudeMode>relativeToGround</gx:altitudeMode>
          <coordinates>-123.1207,49.2827,0</coordinates>
        </Point>
        <gx:balloonVisibility>1</gx:balloonVisibility>
      </Placemark>
    </Folder>
  </Document>
</kml>
''';

    if (GlobalConnection.isConnected && GlobalConnection.sshClient != null) {
      int rightScreen = (GlobalConnection.numberOfScreens / 2).floor() + 1;
      await GlobalConnection.sshClient!.execute(
          "echo '$kmlContent' > /var/www/html/kml/slave_$rightScreen.kml");
    }
  }

  Future<void> cleanKML() async {
    if (GlobalConnection.isConnected && GlobalConnection.sshClient != null) {
      String kmlContent = '''
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2" xmlns:kml="http://www.opengis.net/kml/2.2" xmlns:atom="http://www.w3.org/2005/Atom">
  <Document>
  </Document>
</kml>''';
      int rightScreen = (GlobalConnection.numberOfScreens / 2).floor() + 1;
      await GlobalConnection.sshClient!.execute(
          "echo '$kmlContent' > /var/www/html/kml/slave_$rightScreen.kml");
    }
  }

  setRefresh() async {
    String password = GlobalConnection.clientPassword;
    for (var i = 2; i <= GlobalConnection.numberOfScreens; i++) {
      String kmlFileLocation =
          '<href>##LG_PHPIFACE##kml\\/slave_$i.kml<\\/href>';
      String changeRefresh =
          '<href>##LG_PHPIFACE##kml\\/slave_$i.kml<\\/href><refreshMode>onInterval<\\/refreshMode><refreshInterval>2<\\/refreshInterval>';

      await GlobalConnection.sshClient!.execute(
          'sshpass -p $password ssh -t lg$i \'echo $password | sudo -S sed -i "s/$changeRefresh/$kmlFileLocation/" ~/earth/kml/slave/myplaces.kml\'');
      await GlobalConnection.sshClient!.execute(
          'sshpass -p $password ssh -t lg$i \'echo $password | sudo -S sed -i "s/$kmlFileLocation/$changeRefresh/" ~/earth/kml/slave/myplaces.kml\'');
    }
  }
}
