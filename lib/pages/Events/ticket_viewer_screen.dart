import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/event_service.dart';

class TicketViewerScreen extends StatefulWidget {
  final String registrationId;
  final String confirmationNumber;

  const TicketViewerScreen({
    Key? key,
    required this.registrationId,
    required this.confirmationNumber,
  }) : super(key: key);

  @override
  State<TicketViewerScreen> createState() => _TicketViewerScreenState();
}

class _TicketViewerScreenState extends State<TicketViewerScreen> {
  final EventService _eventService = EventService();
  bool _isLoading = true;
  String? _error;
  String? _ticketHtml;
  late WebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    _loadTicket();
    _initWebViewController();
  }

  void _initWebViewController() {
    _webViewController =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(Colors.white);
  }

  Future<void> _loadTicket() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final html = await _eventService.getTicketHtml(widget.registrationId);
      setState(() {
        _ticketHtml = html;
        _isLoading = false;
      });
      _webViewController.loadHtmlString(html);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _shareTicket() {
    final ticketUrl = _eventService.getTicketDownloadUrl(widget.registrationId);
    Share.share(
      'My Event Ticket - Confirmation: ${widget.confirmationNumber}\n\nView ticket: $ticketUrl',
      subject: 'Event Ticket',
    );
  }

  Future<void> _downloadTicket() async {
    try {
      // Request storage permission for Android
      if (await Permission.storage.request().isGranted ||
          await Permission.manageExternalStorage.request().isGranted) {
        final ticketUrl = _eventService.getTicketDownloadUrl(
          widget.registrationId,
        );
        final uri = Uri.parse(await ticketUrl);

        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ticket download started!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          throw Exception('Could not launch download URL');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Storage permission is required to download ticket',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Ticket'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareTicket,
            tooltip: 'Share Ticket',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _downloadTicket,
            tooltip: 'Download Ticket',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading your ticket...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Failed to load ticket',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadTicket,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return WebViewWidget(controller: _webViewController);
  }
}
