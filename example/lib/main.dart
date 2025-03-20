import 'package:flutter/material.dart';
import 'package:flutter_document_viewer/flutter_document_viewer.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Document Viewer Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const DocumentViewerExample(title: 'Document Viewer Example'),
    );
  }
}

class DocumentViewerExample extends StatefulWidget {
  const DocumentViewerExample({super.key, required this.title});

  final String title;

  @override
  State<DocumentViewerExample> createState() => _DocumentViewerExampleState();
}

class _DocumentViewerExampleState extends State<DocumentViewerExample> {
  // Sample PPTX file URL
  final String pptxUrl =
      'https://www.unm.edu/~unmvclib/powerpoint/pptexamples.ppt';

  // Controller for the document viewer
  late final FlutterDocumentViewerController _controller;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _controller = FlutterDocumentViewerController(
      onReady: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document viewer is ready')),
        );
      },
      onPageChanged: (currentPage, totalPages) {
        debugPrint('Page changed to $currentPage of $totalPages');
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(_showControls ? Icons.visibility_off : Icons.visibility),
            onPressed: () {
              setState(() {
                _showControls = !_showControls;
              });
            },
            tooltip: 'Toggle controls visibility',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Viewing: PowerPoint Example',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Expanded(
            child: FlutterDocumentViewer(
              url: pptxUrl,
              controller: _controller,
              showControls: _showControls,
              onPageChanged: (currentPage, totalPages) {
                debugPrint(
                    'Page changed callback: $currentPage of $totalPages');
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _controller.gotoPage(1),
                  child: const Text('First Page'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final middlePage = (_controller.totalPages / 2).ceil();
                    _controller.gotoPage(middlePage);
                  },
                  child: const Text('Middle Page'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_controller.totalPages > 0) {
                      _controller.gotoPage(_controller.totalPages);
                    }
                  },
                  child: const Text('Last Page'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
