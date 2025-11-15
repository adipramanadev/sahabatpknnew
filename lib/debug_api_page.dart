import 'package:flutter/material.dart';
import 'package:sahabatpknnew/services/newsService.dart';

class DebugApiPage extends StatefulWidget {
  const DebugApiPage({super.key});

  @override
  State<DebugApiPage> createState() => _DebugApiPageState();
}

class _DebugApiPageState extends State<DebugApiPage> {
  String _status = 'Ready to test';
  bool _isLoading = false;
  static const String _token = "Xp8b8F8hpfPy6bxK24pjTwt6m";

  Future<void> _testApi() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing API...';
    });

    try {
      final apiService = ApiService(authToken: _token);
      final news = await apiService.getNews(_token);
      
      setState(() {
        _isLoading = false;
        _status = 'SUCCESS! Got ${news.length} news items:\n\n';
        for (int i = 0; i < news.length; i++) {
          _status += '${i + 1}. ${news[i].judul ?? 'No title'}\n';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _status = 'ERROR: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug API'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'API Test Tool',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Token: Xp8b8F8hpfPy6bxK24pjTwt6m'),
            const Text('URL: https://pkn.or.id/api/news.php'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _testApi,
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Test API'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Result:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _status,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}