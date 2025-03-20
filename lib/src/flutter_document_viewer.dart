import 'package:flutter/material.dart';
import 'package:flutter_document_viewer/src/flutter_document_viewer_controller.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Widget for displaying and interacting with PDF documents
class FlutterDocumentViewer extends StatefulWidget {
  const FlutterDocumentViewer({
    Key? key,
    required this.url,
    required this.controller,
    this.showControls = true,
    this.controlsBuilder,
    this.onPageChanged,
  }) : super(key: key);

  /// The URL of the PDF document to display
  final String url;

  /// Controller to manage the PDF viewer
  final FlutterDocumentViewerController controller;

  /// Show page navigation controls
  final bool showControls;

  /// Custom builder for navigation controls
  final Widget Function(BuildContext, FlutterDocumentViewerController)?
      controlsBuilder;

  /// Callback when page changes, provides current page and total pages
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
