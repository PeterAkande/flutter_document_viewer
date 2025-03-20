import 'package:flutter/material.dart';
import 'package:flutter_document_viewer/src/flutter_document_viewer_controller.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// A Flutter widget that displays document files like PDFs, DOCXs, PPTXs, etc.
/// in a WebView using Google Docs viewer.
///
/// This widget handles loading the document from a URL and provides navigation
/// controls for moving between pages in the document.
///
/// Example:
/// ```dart
/// FlutterDocumentViewer(
///   url: 'https://example.com/document.pdf',
///   controller: FlutterDocumentViewerController(),
///   showControls: true,
///   onPageChanged: (currentPage, totalPages) {
///     print('Page changed to $currentPage of $totalPages');
///   },
/// )
/// ```
class FlutterDocumentViewer extends StatefulWidget {
  /// Creates a document viewer widget.
  ///
  /// The [url] and [controller] parameters are required.
  ///
  /// [url] should be a valid URL pointing to the document to be displayed.
  ///
  /// [controller] is used to manage the viewer state and navigation.
  ///
  /// [showControls] determines whether to show the default navigation controls.
  ///
  /// [controlsBuilder] can be provided to customize the navigation controls.
  ///
  /// [onPageChanged] is called when the current page changes.
  const FlutterDocumentViewer({
    Key? key,
    required this.url,
    required this.controller,
    this.showControls = true,
    this.controlsBuilder,
    this.onPageChanged,
  }) : super(key: key);

  /// The URL of the document to display.
  ///
  /// This should be a publicly accessible URL pointing to the document file.
  /// Supported formats include PDF, DOCX, PPTX, and other formats supported
  /// by Google Docs viewer.
  final String url;

  /// Controller to manage the document viewer state and navigation.
  ///
  /// The controller provides methods for navigating between pages and
  /// properties for accessing the current state of the viewer.
  final FlutterDocumentViewerController controller;

  /// Whether to show the default navigation controls.
  ///
  /// If true, navigation controls for moving between pages will be displayed
  /// at the bottom of the viewer.
  ///
  /// Defaults to true.
  final bool showControls;

  /// Custom builder for navigation controls.
  ///
  /// If provided, this function will be used to build custom navigation
  /// controls instead of the default ones.
  ///
  /// The builder function is provided with the current [BuildContext] and
  /// the [FlutterDocumentViewerController] for the viewer.
  final Widget Function(BuildContext, FlutterDocumentViewerController)?
      controlsBuilder;

  /// Callback when the current page changes.
  ///
  /// This callback is called when the current page changes, providing
  /// the current page number and the total number of pages.
  final void Function(int currentPage, int totalPages)? onPageChanged;

  @override
  State<FlutterDocumentViewer> createState() => _FlutterDocumentViewerState();
}

class _FlutterDocumentViewerState extends State<FlutterDocumentViewer> {
  late final WebViewController _webController;
  late final FlutterDocumentViewerController _controller;

  @override
  void initState() {
    super.initState();
    _webController = WebViewController()
      ..loadRequest(Uri.parse(
          'https://docs.google.com/gview?embedded=true&url=${widget.url}'));

    // Handle onPageChanged callback priority
    if (widget.onPageChanged != null &&
        widget.controller.onPageChanged == null) {
      // Create a new controller that wraps the existing one but adds the callback
      _controller = FlutterDocumentViewerController(
        onReady: widget.controller.onReady,
        onPageChanged: widget.onPageChanged,
      );
      _controller.initWebController(_webController);
    } else {
      _controller = widget.controller;
      _controller.initWebController(_webController);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: WebViewWidget(controller: _webController),
        ),
        if (widget.showControls)
          widget.controlsBuilder?.call(context, _controller) ??
              _defaultControlsBuilder(context, _controller),
      ],
    );
  }

  /// Builds the default navigation controls.
  ///
  /// This method creates a bottom app bar with navigation buttons for
  /// moving between pages and a text display showing the current page number.
  Widget _defaultControlsBuilder(
      BuildContext context, FlutterDocumentViewerController controller) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return BottomAppBar(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed:
                    controller.currentPage > 1 ? controller.previousPage : null,
              ),
              Text(
                'Page ${controller.currentPage}${controller.totalPages > 0 ? ' of ${controller.totalPages}' : ''}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: (controller.totalPages == 0 ||
                        controller.currentPage < controller.totalPages)
                    ? controller.nextPage
                    : null,
              ),
            ],
          ),
        );
      },
    );
  }
}
