import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Controller for managing PDF viewer state and navigation
class FlutterDocumentViewerController extends ChangeNotifier {
  FlutterDocumentViewerController({
    this.onReady,
    this.onPageChanged,
  });

  WebViewController? _webController;
  int _currentPage = 1;
  int _totalPages = 0;
  bool _isReady = false;

  /// Current page number
  int get currentPage => _currentPage;

  /// Total number of pages
  int get totalPages => _totalPages;

  /// Whether the PDF viewer is ready
  bool get isReady => _isReady;

  final VoidCallback? onReady;

  /// Callback when page changes, provides current page and total pages
  final void Function(int currentPage, int totalPages)? onPageChanged;

  /// Initialize the controller with WebViewController
  void initWebController(WebViewController controller) {
    if (_webController != null) {
      return;
    }
    _webController = controller;
    _setupController();
  }

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

  /// Set up an observer to detect page changes from Google Docs interface
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

  /// Injects JavaScript helpers for PDF navigation
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

  /// Hides the default page navigation UI
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

  /// Hides the default page navigation UI
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

  /// Navigate to a specific page
  Future<bool> gotoPage(int page) async {
    // if (!_isReady || page < 1 || (totalPages > 0 && page > totalPages)) {
    //   return false;
    // }

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

  /// Go to the next page
  Future<bool> nextPage() => gotoPage(_currentPage + 1);

  /// Go to the previous page
  Future<bool> previousPage() => gotoPage(_currentPage - 1);

  /// Retrieve the total number of pages
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

  void _scheduleRetryGetTotalPages() {
    if (_totalPages == 0) {
      Future.delayed(const Duration(seconds: 2), _getTotalPages);
    }
  }

  /// Refresh total pages count
  Future<void> refreshTotalPages() => _getTotalPages();

  /// Dispose resources
  @override
  void dispose() {
    super.dispose();
  }
}
