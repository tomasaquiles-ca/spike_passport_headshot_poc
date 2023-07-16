import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:spike_pictures_poc/document_information_extraction/document_information_extraction.dart';
import 'package:spike_pictures_poc/face_position_recognition/face_position_recognition.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spike Pictures POC',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(title: 'Spike Pictures POC'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    final featureList = <Feature>[
      const Feature(
        title: 'Face Position Recognition',
        child: FacePositionRecognition.new,
      ),
      const Feature(
        title: 'Document Information Extraction',
        child: DocumentInformationExtraction.new,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: ListView.builder(
          itemCount: featureList.length,
          itemBuilder: (context, index) {
            final feature = featureList[index];
            return ListTile(
              title: Text(feature.title),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => feature.child(),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class Feature {
  const Feature({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget Function() child;
}
