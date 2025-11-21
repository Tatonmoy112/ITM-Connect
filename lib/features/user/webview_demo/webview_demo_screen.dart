import 'package:flutter/material.dart';
import 'package:itm_connect/widgets/webview_widget.dart';

/// Demo screen showing how to use the WebView widget
class WebViewDemoScreen extends StatefulWidget {
  final String? initialUrl;
  final String title;

  const WebViewDemoScreen({
    super.key,
    this.initialUrl,
    this.title = 'WebView',
  });

  @override
  State<WebViewDemoScreen> createState() => _WebViewDemoScreenState();
}

class _WebViewDemoScreenState extends State<WebViewDemoScreen> {
  late String _currentUrl;

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.initialUrl ?? 'https://www.example.com';
  }

  @override
  Widget build(BuildContext context) {
    return AppWebView(
      url: _currentUrl,
      title: widget.title,
      showAppBar: true,
      onPageStarted: (url) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Loading: $url'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      onPageFinished: (url) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Loaded: $url'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
    );
  }
}

/// Example of WebView with inline HTML content
class WebViewHtmlDemoScreen extends StatelessWidget {
  const WebViewHtmlDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final htmlContent = '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        body {
          font-family: Arial, sans-serif;
          margin: 20px;
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          color: #333;
        }
        .container {
          max-width: 800px;
          margin: 0 auto;
          background: white;
          padding: 20px;
          border-radius: 10px;
          box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }
        h1 {
          color: #667eea;
          text-align: center;
        }
        .feature {
          margin: 15px 0;
          padding: 10px;
          background: #f5f5f5;
          border-left: 4px solid #667eea;
          border-radius: 4px;
        }
        .feature strong {
          color: #667eea;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <h1>🚀 ITM Connect WebView</h1>
        <p>This is an example of displaying HTML content in Flutter WebView.</p>
        
        <div class="feature">
          <strong>✓ Full HTML5 Support</strong>
          <p>Render complete web pages and interactive content seamlessly.</p>
        </div>
        
        <div class="feature">
          <strong>✓ JavaScript Enabled</strong>
          <p>Run dynamic JavaScript for interactive experiences.</p>
        </div>
        
        <div class="feature">
          <strong>✓ Responsive Design</strong>
          <p>Content adapts to different screen sizes automatically.</p>
        </div>
        
        <div class="feature">
          <strong>✓ Error Handling</strong>
          <p>Built-in error handling and retry mechanisms.</p>
        </div>
      </div>
    </body>
    </html>
    ''';

    return AppWebView(
      htmlContent: htmlContent,
      title: 'HTML Demo',
      showAppBar: true,
    );
  }
}
