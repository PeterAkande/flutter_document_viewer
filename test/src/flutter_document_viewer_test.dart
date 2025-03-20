// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_document_viewer/flutter_document_viewer.dart';
import 'package:flutter_document_viewer/src/flutter_document_viewer_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:webview_flutter/webview_flutter.dart';

// Import the mock WebViewPlatform helper
import '../helpers/webview_test_helpers.dart';
// Import generated mocks
import '../generate_mocks.mocks.dart';

void main() {
  // Set up WebViewPlatform for all tests
  setUp(() {
    setUpWebViewPlatform();
  });

  group('FlutterDocumentViewerController', () {
    late FlutterDocumentViewerController controller;
    late MockWebViewController mockWebController;

    setUp(() {
      mockWebController = MockWebViewController();
      controller = FlutterDocumentViewerController();

      // Setup mock behaviors
      when(mockWebController.setJavaScriptMode(any)).thenAnswer((_) async {});
      when(mockWebController.addJavaScriptChannel(any,
              onMessageReceived: anyNamed('onMessageReceived')))
          .thenAnswer((_) async {});
      when(mockWebController.setNavigationDelegate(any))
          .thenAnswer((_) async {});
      when(mockWebController.runJavaScript(any)).thenAnswer((_) async {});
    });

    test('initialization sets up web controller correctly', () {
      controller.initWebController(mockWebController);

      verify(mockWebController.setJavaScriptMode(JavaScriptMode.unrestricted))
          .called(1);
      verify(mockWebController.addJavaScriptChannel('PageChangeChannel',
              onMessageReceived: anyNamed('onMessageReceived')))
          .called(1);
      verify(mockWebController.setNavigationDelegate(any)).called(1);
    });

    test('default values are correct', () {
      expect(controller.currentPage, 1);
      expect(controller.totalPages, 0);
      expect(controller.isReady, false);
    });

    test('onPageChanged callback is triggered when page changes', () async {
      int callbackCurrentPage = 0;
      int callbackTotalPages = 0;

      controller = FlutterDocumentViewerController(
        onPageChanged: (currentPage, totalPages) {
          callbackCurrentPage = currentPage;
          callbackTotalPages = totalPages;
        },
      );

      when(mockWebController.runJavaScriptReturningResult(any))
          .thenAnswer((_) async => "2");

      controller.initWebController(mockWebController);
      await controller.gotoPage(2);

      expect(callbackCurrentPage, 2);
      expect(controller.currentPage, 2);
    });

    test('nextPage and previousPage functions work correctly', () async {
      when(mockWebController.runJavaScriptReturningResult(any))
          .thenAnswer((_) async => "2");

      controller.initWebController(mockWebController);
      controller = controller..initWebController(mockWebController);

      // First set current page to 2
      await controller.gotoPage(2);
      expect(controller.currentPage, 2);

      // Test nextPage
      when(mockWebController.runJavaScriptReturningResult(any))
          .thenAnswer((_) async => "3");
      await controller.nextPage();
      expect(controller.currentPage, 3);

      // Test previousPage
      when(mockWebController.runJavaScriptReturningResult(any))
          .thenAnswer((_) async => "2");
      await controller.previousPage();
      expect(controller.currentPage, 2);
    });
  });

  group('FlutterDocumentViewer Widget', () {
    testWidgets('renders correctly with controls', (WidgetTester tester) async {
      final controller = FlutterDocumentViewerController();

      // Replace direct WebViewWidget checks with more general widget structure verification
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlutterDocumentViewer(
              url: 'https://example.com/test.pdf',
              controller: controller,
              showControls: true,
            ),
          ),
        ),
      );

      // Initial pump to start loading
      await tester.pump();

      // We can't check for WebViewWidget directly since it's mocked
      // But we can check for the control elements
      expect(find.byType(BottomAppBar), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });

    testWidgets('hides controls when showControls is false',
        (WidgetTester tester) async {
      final controller = FlutterDocumentViewerController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlutterDocumentViewer(
              url: 'https://example.com/test.pdf',
              controller: controller,
              showControls: false,
            ),
          ),
        ),
      );

      await tester.pump();

      // Check for absence of controls
      expect(find.byType(BottomAppBar), findsNothing);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
      expect(find.byIcon(Icons.arrow_forward), findsNothing);
    });

    testWidgets('custom controls builder works', (WidgetTester tester) async {
      final controller = FlutterDocumentViewerController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlutterDocumentViewer(
              url: 'https://example.com/test.pdf',
              controller: controller,
              showControls: true,
              controlsBuilder: (context, ctrl) => Container(
                height: 50,
                color: Colors.amber,
                child: const Text('Custom Controls'),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify custom controls are rendered
      expect(find.text('Custom Controls'), findsOneWidget);
      expect(find.byType(BottomAppBar),
          findsNothing); // Default controls should not be present
    });
  });
}
