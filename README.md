# Flutter Document Viewer

[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![Powered by Mason](https://img.shields.io/endpoint?url=https%3A%2F%2Ftinyurl.com%2Fmason-badge)](https://github.com/felangel/mason)
[![License: MIT][license_badge]][license_link]

A powerful document viewer for Flutter that supports docx, PPTX, and PDF files.

## Installation 💻

**❗ In order to start using Flutter Document Viewer you must have the [Flutter SDK][flutter_install_link] installed on your machine.**

Install via `flutter pub add`:

```sh
dart pub add flutter_document_viewer
```
Or

```yaml
dependencies:
  flutter_document_viewer: ^0.1.0
```

### 🚀 Example Usage

```dart
import 'package:flutter/material.dart';
import 'package:flutter_document_viewer/flutter_document_viewer.dart';

class DocumentViewerExample extends StatefulWidget {
  const DocumentViewerExample({super.key, required this.title});

  final String title;

  @override
  State<DocumentViewerExample> createState() => _DocumentViewerExampleState();
}

class _DocumentViewerExampleState extends State<DocumentViewerExample> {
  // Sample PPTX file URL
  final String pptxUrl = 'https://www.unm.edu/~unmvclib/powerpoint/pptexamples.ppt';
  
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
          Expanded(
            child: FlutterDo cumentViewer(
              url: pptxUrl,
              controller: _controller,
              showControls: _showControls,
              onPageChanged: (currentPage, totalPages) {
                debugPrint('Page changed callback: $currentPage of $totalPages');
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
                  onPressed: () => _controller.gotoPage(_controller.totalPages),
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
```

Refer to the `main.dart` in the example directory for a complete implementation.

## Features

- 📄 Support for multiple document formats (PDF, PPTX, DOCX)
- 🔍 Page navigation controls
- 📱 Responsive design
- 🎮 Custom controller for programmatic navigation
- 👁️ Toggleable navigation UI
- 🔔 Event callbacks for viewer ready and page changes

## Screenshots

| Document View | Navigation Controls |
|---------------|-------------------|
| <img src="https://github.com/PeterAkande/flutter_document_viewer//raw/main/assets/screenshot.png" width="250"> | <img src="https://github.com/PeterAkande/flutter_document_viewer//raw/main/assets/screen.gif" width="250"> |

---

## 🐛 Bugs/Requests

Pull requests are welcome. If you have any feature requests or find bugs, please open an issue.

## Continuous Integration 🤖

Flutter Document Viewer comes with a built-in [GitHub Actions workflow][github_actions_link] powered by [Very Good Workflows][very_good_workflows_link] but you can also add your preferred CI/CD solution.

Out of the box, on each pull request and push, the CI `formats`, `lints`, and `tests` the code. This ensures the code remains consistent and behaves correctly as you add functionality or make changes. The project uses [Very Good Analysis][very_good_analysis_link] for a strict set of analysis options used by our team. Code coverage is enforced using the [Very Good Workflows][very_good_coverage_link].

---

[flutter_install_link]: https://docs.flutter.dev/get-started/install
[github_actions_link]: https://docs.github.com/en/actions/learn-github-actions
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
[very_good_cli_link]: https://pub.dev/packages/very_good_cli
[very_good_coverage_link]: https://github.com/marketplace/actions/very-good-coverage
[very_good_workflows_link]: https://github.com/VeryGoodOpenSource/very_good_workflows
