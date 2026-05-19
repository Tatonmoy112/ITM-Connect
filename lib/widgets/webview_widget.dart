import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Reusable WebView Widget for displaying web content
/// Supports both URLs and inline HTML content
class AppWebView extends StatefulWidget {
  final String? url;
  final String? htmlContent;
  final String title;
  final bool showAppBar;
  final ValueChanged<String>? onPageStarted;
  final ValueChanged<String>? onPageFinished;
  final ValueChanged<NavigationRequest>? onNavigationRequest;

  const AppWebView({
    super.key,
    this.url,
    this.htmlContent,
    required this.title,
    this.showAppBar = true,
    this.onPageStarted,
    this.onPageFinished,
    this.onNavigationRequest,
  }) : assert(url != null || htmlContent != null, 'Either url or htmlContent must be provided');

  @override
  State<AppWebView> createState() => _AppWebViewState();
}

class _AppWebViewState extends State<AppWebView> {
  late WebViewController _webViewController;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _errorMessage = null;
            });
            widget.onPageStarted?.call(url);
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            widget.onPageFinished?.call(url);
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _errorMessage = error.description;
              _isLoading = false;
            });
            debugPrint('WebView Error: ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) {
            widget.onNavigationRequest?.call(request);
            return NavigationDecision.navigate;
          },
        ),
      );

    // Load content based on what's provided
    if (widget.url != null) {
      _webViewController.loadRequest(Uri.parse(widget.url!));
    } else if (widget.htmlContent != null) {
      _webViewController.loadHtmlString(widget.htmlContent!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    
    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: Text(
                widget.title,
                style: TextStyle(
                  fontSize: isTablet ? 20 : 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: const Color(0xFF185a9d),
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: Colors.black.withValues(alpha: 0.3),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  iconSize: isTablet ? 28 : 24,
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _errorMessage = null;
                    });
                    if (widget.url != null) {
                      _webViewController.loadRequest(Uri.parse(widget.url!));
                    } else if (widget.htmlContent != null) {
                      _webViewController.loadHtmlString(widget.htmlContent!);
                    }
                  },
                  tooltip: 'Refresh',
                ),
              ],
            )
          : null,
      body: Stack(
        children: [
          WebViewWidget(controller: _webViewController),
          // Loading Overlay
          if (_isLoading)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.8),
                    Colors.white.withValues(alpha: 0.9),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: isTablet ? 80 : 56,
                        height: isTablet ? 80 : 56,
                        child: CircularProgressIndicator(
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF43cea2),
                          ),
                          strokeWidth: isTablet ? 5 : 4,
                        ),
                      ),
                      SizedBox(height: isTablet ? 24 : 16),
                      Text(
                        'Loading...',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontSize: isTablet ? 18 : 14,
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Error Overlay
          if (_errorMessage != null)
            Container(
              color: Colors.white.withValues(alpha: 0.98),
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 64 : 24,
                      vertical: isTablet ? 40 : 24,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isTablet ? 600 : double.infinity,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(isTablet ? 24 : 16),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(isTablet ? 24 : 16),
                              border: Border.all(
                                color: Colors.red.withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: isTablet ? 80 : 64,
                            ),
                          ),
                          SizedBox(height: isTablet ? 28 : 20),
                          Text(
                            'Error Loading Page',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontSize: isTablet ? 24 : 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                          ),
                          SizedBox(height: isTablet ? 16 : 12),
                          Text(
                            _errorMessage ?? 'An unknown error occurred',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontSize: isTablet ? 16 : 14,
                                  color: Colors.black54,
                                  height: 1.6,
                                ),
                          ),
                          SizedBox(height: isTablet ? 40 : 32),
                          Wrap(
                            spacing: isTablet ? 20 : 12,
                            runSpacing: isTablet ? 16 : 12,
                            alignment: WrapAlignment.center,
                            children: [
                              SizedBox(
                                width: isTablet ? 200 : 140,
                                height: isTablet ? 52 : 44,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  icon: const Icon(Icons.arrow_back),
                                  label: const Text('Go Back'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF185a9d),
                                    side: const BorderSide(
                                      color: Color(0xFF185a9d),
                                      width: 2,
                                    ),
                                    textStyle: TextStyle(
                                      fontSize: isTablet ? 16 : 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: isTablet ? 200 : 140,
                                height: isTablet ? 52 : 44,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _isLoading = true;
                                      _errorMessage = null;
                                    });
                                    if (widget.url != null) {
                                      _webViewController.loadRequest(Uri.parse(widget.url!));
                                    } else if (widget.htmlContent != null) {
                                      _webViewController.loadHtmlString(widget.htmlContent!);
                                    }
                                  },
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Retry'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF43cea2),
                                    foregroundColor: Colors.white,
                                    textStyle: TextStyle(
                                      fontSize: isTablet ? 16 : 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
