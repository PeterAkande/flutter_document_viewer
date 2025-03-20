import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Controller for managing the state and navigation of a document viewer.
///
/// This controller handles the interaction with the WebView that displays
/// the document, providing methods for navigating between pages and
/// properties for accessing the current state of the viewer.
///
/// It uses JavaScript to communicate with the Google Docs viewer within
/// the WebView to control navigation and retrieve page information.
///
/// Example:
/// ```dart
/// final controller = FlutterDocumentViewerController(
///   onReady: () {
///     print('Document viewer is ready');
///   },
///   onPageChanged: (currentPage, totalPages) {
///     print('Page changed to $currentPage of $totalPages');
///   },
/// );
/// ```
class FlutterDocumentViewerController extends ChangeNotifier {
  /// Creates a controller for managing document viewer state and navigation.
  ///
  /// [onReady] is called when the document viewer is ready.
  ///
  /// [onPageChanged] is called when the current page changes, providing
  /// the current page number and the total number of pages.
  FlutterDocumentViewerController({
    this.onReady,
    this.onPageChanged,
  });

  WebViewController? _webController;
  int _currentPage = 1;
  int _totalPages = 0;
  bool _isReady = false;

  /// The current page number in the document.
  ///
  /// This starts at 1 for the first page and is updated as the user
  /// navigates through the document.
  int get currentPage => _currentPage;

  /// The total number of pages in the document.
  ///
  /// This may be 0 if the total number of pages has not been determined yet.
  int get totalPages => _totalPages;

  /// Whether the document viewer is ready.
  ///
  /// This is set to true after the document has been loaded and the
  /// viewer is ready for interaction.
  bool get isReady => _isReady;

  /// Callback that is called when the document viewer is ready.
  final VoidCallback? onReady;

  /// Callback that is called when the current page changes.
  ///
  /// This callback provides the current page number and the total number
  /// of pages. It is called whenever the current page changes, either
  /// through user interaction or programmatic navigation.
  final void Function(int currentPage, int totalPages)? onPageChanged;

  /// Initializes the controller with a WebViewController.
  ///
  /// This method should be called before using the controller to manage
  /// the document viewer. It sets up the necessary JavaScript bindings
  /// and event handlers for communication with the WebView.
  ///
  /// [controller] is the WebViewController to use for controlling the WebView.
  void initWebController(WebViewController controller) {
    if (_webController != null) {
      return;
    }
    _webController = controller;
    _setupController();
  }

  /// Sets up the WebViewController with the necessary JavaScript bindings
  /// and event handlers.
  void _setupController() {
    _webController!
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'PageChangeChannel',
        onMessageReceived: (JavaScriptMessage message) {
          // Handle page change notifications from JavaScript
          final newPage = int.tryParse(message.message) ?? -1;
          if (newPage > 0 && newPage != _currentPage) {
            _currentPage = newPage;
            onPageChanged?.call(_currentPage, _totalPages);
            notifyListeners();
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            _injectNavigationHelpers();
            _getTotalPages();
            _hidePageNavigation();
            _hideOpenInDriveButton();
            _setupPageChangeObserver(); // Add page change observer
            _isReady = true;

            onReady?.call();
            notifyListeners();
          },
        ),
      );
  }

  /// Sets up an observer to detect page changes from the Google Docs interface.
  ///
  /// This injects JavaScript code that monitors the page number input field
  /// and navigation buttons in the Google Docs viewer, sending notifications
  /// through the JavaScript channel when the page changes.
  void _setupPageChangeObserver() {
    _webController!.runJavaScript('''
    (function() {
      // Store the current page value
      let lastPageValue = getCurrentPage();
      
      // Check for page changes every 300ms
      setInterval(function() {
        const currentPage = getCurrentPage();
        if (currentPage > 0 && currentPage !== lastPageValue) {
          // Page has changed, update stored value
          lastPageValue = currentPage;
          
          // Send message to Flutter using JavaScript channel
          window.PageChangeChannel.postMessage(currentPage.toString());
        }
      }, 300);
      
      // Additionally, intercept clicks on navigation buttons
      const observeClicks = function() {
        const nextButton = document.querySelector('.ndfHFb-c4YZDc-vyDMJf-aZ2wEe');
        const prevButton = document.querySelector('.ndfHFb-c4YZDc-vyDMJf-Pd8PKe');
        
        if (nextButton) {
          nextButton.addEventListener('click', function() {
            // Give time for page to change
            setTimeout(function() {
              const current = getCurrentPage();
              window.PageChangeChannel.postMessage(current.toString());
            }, 100);
          });
        }
        
        if (prevButton) {
          prevButton.addEventListener('click', function() {
            // Give time for page to change
            setTimeout(function() {
              const current = getCurrentPage();
              window.PageChangeChannel.postMessage(current.toString());
            }, 100);
          });
        }
      };
      
      // Try immediately and also after a delay (for elements that load later)
      observeClicks();
      setTimeout(observeClicks, 1000);
    })();
  ''');
  }

  /// Injects JavaScript helpers for document navigation.
  ///
  /// This injects JavaScript functions into the WebView that provide
  /// methods for navigating between pages and retrieving the current
  /// page number from the Google Docs viewer.
  void _injectNavigationHelpers() {
    _webController!.runJavaScript('''
      function goToPage(pageNum) {
        const input = document.querySelector('.ndfHFb-c4YZDc-DARUcf-NGme3c-YPqjbf');
        if (input) {
          // Update the input field value
          input.value = pageNum;
          input.dispatchEvent(new Event('input', { bubbles: true }));
          input.dispatchEvent(new Event('change', { bubbles: true }));
          
          // Focus the input to ensure events are captured
          input.focus();
          
          // Simulate Enter key press
          setTimeout(() => {
            const enterKeyDown = new KeyboardEvent('keydown', {
              key: 'Enter',
              code: 'Enter',
              keyCode: 13,
              which: 13,
              bubbles: true
            });
            input.dispatchEvent(enterKeyDown);
            
            const enterKeyPress = new KeyboardEvent('keypress', {
              key: 'Enter',
              code: 'Enter',
              keyCode: 13,
              which: 13,
              bubbles: true
            });
            input.dispatchEvent(enterKeyPress);
            
            const enterKeyUp = new KeyboardEvent('keyup', {
              key: 'Enter',
              code: 'Enter',
              keyCode: 13,
              which: 13,
              bubbles: true
            });
            input.dispatchEvent(enterKeyUp);
            
            // Alternative: Try to find and click the navigation buttons directly
            const nextButton = document.querySelector('.ndfHFb-c4YZDc-vyDMJf-aZ2wEe');
            if (nextButton && pageNum > getCurrentPage()) {
              nextButton.click();
            }
            
            const prevButton = document.querySelector('.ndfHFb-c4YZDc-vyDMJf-Pd8PKe');
            if (prevButton && pageNum < getCurrentPage()) {
              prevButton.click();
            }
          }, 100);

          return getCurrentPage();
        }
        return -1;
      }

      function getCurrentPage() {
        const input = document.querySelector('.ndfHFb-c4YZDc-DARUcf-NGme3c-YPqjbf');
        return input ? parseInt(input.value) : -1;
      }
    ''');
  }

  /// Hides the default page navigation UI in the Google Docs viewer.
  ///
  /// This injects CSS to hide the page display element in the viewer,
  /// allowing the Flutter app to provide its own navigation controls.
  Future<void> _hidePageNavigation() async {
    await _webController!.runJavaScript('''
      (function hidePageNumber() {
        // Add CSS to hide the page display element
        const style = document.createElement('style');
        style.textContent = '.ndfHFb-c4YZDc-q77wGc { opacity: 0 !important; }';
        document.head.appendChild(style);
        
        // Set up a periodic check to ensure it stays hidden
        setInterval(function() {
          const pageNumElement = document.querySelector('.ndfHFb-c4YZDc-q77wGc');
          if (pageNumElement) {
            pageNumElement.style.opacity = '0';
          }
        }, 1000);
      })();
    ''');
  }

  /// Hides the "Open with Google Drive" button in the Google Docs viewer.
  ///
  /// This injects CSS to hide the button, keeping the viewer interface clean
  /// and focused on document viewing.
  Future<void> _hideOpenInDriveButton() async {
    await _webController!.runJavaScript('''
      (function hideOpenInDriveButton() {
        // Add CSS to hide the page display element
        const style = document.createElement('style');
        style.textContent = '.ndfHFb-c4YZDc-Wrql6b { opacity: 0 !important; }';
        document.head.appendChild(style);
        
        // Set up a periodic check to ensure it stays hidden
        setInterval(function() {
          const pageNumElement = document.querySelector('.ndfHFb-c4YZDc-Wrql6b');
          if (pageNumElement) {
            pageNumElement.style.opacity = '0';
          }
        }, 1000);
      })();
    ''');
  }

  /// Navigates to a specific page in the document.
  ///
  /// [page] is the page number to navigate to, starting from 1.
  ///
  /// Returns a [Future] that completes with a boolean indicating whether
  /// the navigation was successful. Navigation may fail if the page number
  /// is invalid or the viewer is not ready.
  Future<bool> gotoPage(int page) async {
    if (!_isReady || page < 1 || (totalPages > 0 && page > totalPages)) {
      return false;
    }

    try {
      final result =
          await _webController!.runJavaScriptReturningResult('goToPage($page)');
      final newPage = int.tryParse(result.toString()) ?? -1;

      if (newPage > 0) {
        _currentPage = newPage;
        notifyListeners();

        // Trigger onPageChanged callback with current page and total pages
        onPageChanged?.call(_currentPage, _totalPages);

        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error navigating to page: $e');
      return false;
    }
  }

  /// Navigates to the next page in the document.
  ///
  /// Returns a [Future] that completes with a boolean indicating whether
  /// the navigation was successful. Navigation may fail if there is no next
  /// page or the viewer is not ready.
  Future<bool> nextPage() => gotoPage(_currentPage + 1);

  /// Navigates to the previous page in the document.
  ///
  /// Returns a [Future] that completes with a boolean indicating whether
  /// the navigation was successful. Navigation may fail if there is no previous
  /// page or the viewer is not ready.
  Future<bool> previousPage() => gotoPage(_currentPage - 1);

  /// Retrieves the total number of pages in the document.
  ///
  /// This injects JavaScript to extract the total page count from the
  /// Google Docs viewer interface.
  Future<void> _getTotalPages() async {
    try {
      final result = await _webController!.runJavaScriptReturningResult(r'''
        (function() {
          // Try direct page info extraction first
          const pageContainer = document.querySelector('.ndfHFb-c4YZDc-DARUcf-NnAfwf-j4LONd');
          if (pageContainer) {
            const text = pageContainer.textContent;
            const match = text.match(/of\s+(\d+)/);
            if (match) return match[1];
          }
          
          // Try alternate selectors
          const alternateContainer = document.querySelector('.ndfHFb-c4YZDc-DARUcf-NnAfwf-ibnC6b');
          if (alternateContainer) {
            const text = alternateContainer.textContent;
            const match = text.match(/of\s+(\d+)/);
            if (match) return match[1];
          }
          
          // Try any text that matches "of X" pattern
          const elements = document.querySelectorAll('*');
          for (const el of elements) {
            if (el.textContent && el.textContent.includes("of")) {
              const match = el.textContent.match(/of\s+(\d+)/);
              if (match) return match[1];
            }
          }
          
          return -1;
        })()
      ''');

      final total = int.tryParse(result.toString()) ?? 0;
      if (total > 0) {
        _totalPages = total;

        // Notify when total pages changes as this affects page info
        onPageChanged?.call(_currentPage, _totalPages);

        notifyListeners();
      } else {
        _scheduleRetryGetTotalPages();
      }
    } catch (e) {
      debugPrint('Error getting total pages: $e');
      _scheduleRetryGetTotalPages();
    }
  }

  /// Schedules a retry for retrieving the total page count.
  ///
  /// This is called if the initial attempt to retrieve the total page count
  /// fails, which can happen if the document is still loading.
  void _scheduleRetryGetTotalPages() {
    if (_totalPages == 0) {
      Future.delayed(const Duration(seconds: 2), _getTotalPages);
    }
  }

  /// Refreshes the total page count.
  ///
  /// This can be called to manually refresh the total page count, for example
  /// if the document has been reloaded or changed.
  Future<void> refreshTotalPages() => _getTotalPages();

  /// Releases resources used by the controller.
  ///
  /// This method should be called when the controller is no longer needed,
  /// to prevent memory leaks.
  @override
  void dispose() {
    super.dispose();
  }
}
