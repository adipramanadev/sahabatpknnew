import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:sahabatpknnew/services/sikapPknService.dart';
import 'package:sahabatpknnew/widgets/app_bottom_nav.dart';
import 'package:sahabatpknnew/home.dart';

class SikapPKN extends StatefulWidget {
  const SikapPKN({super.key});

  @override
  State<SikapPKN> createState() => _SikapPKNState();
}

class _SikapPKNState extends State<SikapPKN> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = false;
  String _result = '';
  List<Map<String, dynamic>> _profileData = [];

  final String _apiUrl = "https://pkn.or.id/api/profile.php";
  final String _bearerToken = "Xp8b8F8hpfPy6bxK24pjTwt6m";

  // Alternative service
  final SikapService _service = SikapService(baseUrl: "https://pkn.or.id/api");

  // Tab sections
  List<String> _tabTitles = [];
  Map<String, String> _tabData = {};

  // Bottom navigation
  int currentIndex = 2; // Set to 2 for Account (Profile) tab

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 0, vsync: this);
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    setState(() {
      _loading = true;
      _result = "";
      _profileData = [];
      _tabData = {};
      _tabTitles = [];
    });

    try {
      print('Fetching data from: $_apiUrl');
      print('Using Bearer token: $_bearerToken');

      // Try POST request instead of GET
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $_bearerToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({'action': 'get_profile', 'request': 'profile_data'}),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        setState(() {
          _result = JsonEncoder.withIndent('  ').convert(jsonResponse);

          if (jsonResponse['status'] == true && jsonResponse['data'] != null) {
            _profileData = List<Map<String, dynamic>>.from(
              jsonResponse['data'],
            );
            _setupTabsFromAPI();
          } else if (jsonResponse['data'] != null) {
            // Even if status is false, try to parse data
            _profileData = List<Map<String, dynamic>>.from(
              jsonResponse['data'],
            );
            _setupTabsFromAPI();
          } else {
            // If API returns status false, still show the response
            print(
              'API returned status false: ${jsonResponse['message'] ?? 'No message'}',
            );
            // Don't use dummy data, leave empty to show error
          }
        });
      } else {
        // Try alternative method using SikapService
        try {
          print('Trying alternative method with SikapService...');
          final serviceResponse = await _service.postSikap(
            endpoint: "profile.php",
            payload: {"action": "get_profile"},
          );

          setState(() {
            _result = JsonEncoder.withIndent('  ').convert(serviceResponse);
            if (serviceResponse['status'] == true &&
                serviceResponse['data'] != null) {
              _profileData = List<Map<String, dynamic>>.from(
                serviceResponse['data'],
              );
              _setupTabsFromAPI();
            } else {
              // Don't use dummy data, leave empty
            }
          });
        } catch (serviceError) {
          setState(() {
            _result =
                "Primary Error: HTTP ${response.statusCode} - ${response.reasonPhrase}\nService Error: $serviceError\nResponse: ${response.body}";
            // Don't use dummy data
          });
        }
      }
    } catch (e) {
      print('Exception occurred: $e');
      setState(() {
        _result = "Error: $e";
        // Don't use dummy data on error
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  void _setupTabsFromAPI() {
    _tabTitles.clear();
    _tabData.clear();

    print(
      'Setting up tabs from API data. Profile data count: ${_profileData.length}',
    );

    // Focus only on slug and content_html pairs
    for (var dataItem in _profileData) {
      print('Processing data item: ${dataItem.keys.toList()}');
      
      String? slug = dataItem['slug']?.toString();
      String? contentHtml = dataItem['content_html']?.toString();
      
      if (slug != null && 
          contentHtml != null && 
          slug.trim().isNotEmpty && 
          contentHtml.trim().isNotEmpty &&
          slug.toLowerCase() != 'null' && 
          contentHtml.toLowerCase() != 'null') {
        
        // Create tab title from slug (make it readable)
        String tabTitle = _formatSlugToTitle(slug);
        
        _tabTitles.add(tabTitle);
        _tabData[tabTitle] = _cleanHtmlContent(contentHtml);
        
        print('Added tab: $tabTitle from slug: $slug');
        print('Content length: ${contentHtml.length}');
      }
    }

    print('Total tabs created: ${_tabTitles.length}');
    print('Tab titles: $_tabTitles');

    // Recreate TabController with new length
    if (_tabTitles.isNotEmpty) {
      _tabController.dispose();
      _tabController = TabController(length: _tabTitles.length, vsync: this);
    } else {
      // If no real data, don't show anything
      print('No data found from API');
    }
  }

  String _cleanHtmlContent(String content) {
    // Remove HTML tags and decode entities
    String cleaned = content
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .trim();

    // Replace multiple spaces/newlines with single space
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');

    return cleaned.isNotEmpty ? cleaned : 'Data tidak tersedia';
  }

  String _formatSlugToTitle(String slug) {
    // Convert slug to readable title
    return slug
        .replaceAll('-', ' ')
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty ? 
            word[0].toUpperCase() + word.substring(1).toLowerCase() : '')
        .join(' ')
        .trim();
  }





  Future<void> _refreshData() async {
    await _fetchProfileData();
  }

  Future<void> _forceUseAPIData() async {
    setState(() => _loading = true);
    
    try {
      // Try to fetch and force use any data returned
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $_bearerToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({'action': 'get_profile', 'request': 'profile_data'}),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        
        // Force setup tabs regardless of status
        if (jsonResponse['data'] != null) {
          setState(() {
            _result = "Forced API data usage:\n${JsonEncoder.withIndent('  ').convert(jsonResponse)}";
            _profileData = List<Map<String, dynamic>>.from(jsonResponse['data']);
            _setupTabsFromAPI();
          });
        } else {
          setState(() {
            _result = "No data field in response:\n${JsonEncoder.withIndent('  ').convert(jsonResponse)}";
          });
        }
      }
    } catch (e) {
      setState(() {
        _result = "Force API error: $e";
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _testApiCall() async {
    setState(() {
      _loading = true;
      _result = "Testing API call...\n";
    });

    try {
      // Test 1: Direct GET
      _result += "Test 1: Direct GET request\n";
      final getResponse = await http.get(
        Uri.parse(_apiUrl),
        headers: {'Authorization': 'Bearer $_bearerToken'},
      );
      _result +=
          "GET Response: ${getResponse.statusCode} - ${getResponse.body.substring(0, 200)}\n\n";

      // Test 2: POST with payload
      _result += "Test 2: POST with payload\n";
      final postResponse = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $_bearerToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({'action': 'get_profile'}),
      );
      _result +=
          "POST Response: ${postResponse.statusCode} - ${postResponse.body.substring(0, 200)}\n\n";

      // Test 3: Using SikapService
      _result += "Test 3: Using SikapService\n";
      final serviceResponse = await _service.postSikap(
        endpoint: "profile.php",
        payload: {"action": "get_profile"},
      );
      _result +=
          "Service Response: ${JsonEncoder.withIndent('  ').convert(serviceResponse)}\n";

      // Test 4: Try to setup tabs with any successful response
      if (postResponse.statusCode == 200) {
        final jsonData = json.decode(postResponse.body);
        if (jsonData['data'] != null) {
          _result += "\nTest 4: Analyzing data structure for slug/content_html\n";
          final dataList = List<Map<String, dynamic>>.from(jsonData['data']);
          
          for (int i = 0; i < dataList.length && i < 3; i++) {
            var item = dataList[i];
            _result += "Item $i keys: ${item.keys.toList()}\n";
            
            if (item.containsKey('slug')) {
              _result += "  - slug: ${item['slug']}\n";
            }
            if (item.containsKey('content_html')) {
              var content = item['content_html'].toString();
              _result += "  - content_html: ${content.length > 50 ? content.substring(0, 50) + '...' : content}\n";
            }
          }
          
          _profileData = dataList;
          _setupTabsFromAPI();
          _result += "\nTabs setup result: ${_tabTitles.length} tabs created\n";
          _result += "Tab titles: $_tabTitles\n";
        }
      }

      setState(() {});
    } catch (e) {
      setState(() {
        _result += "Error in test: $e";
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Profile PKN',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_alt),
            onPressed: _loading
                ? null
                : () {
                    // Force use API data even if status false
                    _forceUseAPIData();
                  },
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: _loading
                ? null
                : () {
                    // Test API with detailed debugging
                    _testApiCall();
                  },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _refreshData,
          ),
        ],
        bottom: _tabTitles.isNotEmpty
            ? TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 14,
                ),
                tabs: _tabTitles.map((title) => Tab(text: title)).toList(),
              )
            : null,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: _loading
            ? _buildLoadingWidget()
            : _tabTitles.isEmpty
            ? _buildErrorOrEmptyWidget()
            : TabBarView(
                controller: _tabController,
                children: _tabTitles
                    .map((title) => _buildTabContent(title))
                    .toList(),
              ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
          
          if (index == 0) {
            // Navigate to Home
            Get.to(() => const HomePage());
          } else if (index == 1) {
            // Navigate to Kartu (Membership card) - can be implemented later
            // Get.to(() => const KartuPage());
          } else if (index == 2) {
            // Current page (Profile/Account) - do nothing or refresh
            // Already on this page
          }
        },
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFFD32F2F), strokeWidth: 3),
          SizedBox(height: 16),
          Text(
            'Memuat data profile...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorOrEmptyWidget() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFFDECEE),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD32F2F)),
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFD32F2F), size: 48),
            const SizedBox(height: 16),
            const Text(
              'Gagal memuat data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD32F2F),
              ),
            ),
            const SizedBox(height: 8),
            if (_result.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Debug Response:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFFD32F2F),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 200),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    _result,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _refreshData,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(String title) {
    final content = _tabData[title] ?? '';
    final icon = _getIconForTab(title);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFD32F2F),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                content,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.justify,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForTab(String title) {
    final titleLower = title.toLowerCase();
    
    if (titleLower.contains('profil') || titleLower.contains('profile')) {
      return Icons.account_circle;
    } else if (titleLower.contains('sejarah') || titleLower.contains('history')) {
      return Icons.history_edu;
    } else if (titleLower.contains('visi') || titleLower.contains('vision')) {
      return Icons.visibility;
    } else if (titleLower.contains('misi') || titleLower.contains('mission')) {
      return Icons.flag;
    } else if (titleLower.contains('struktur') || titleLower.contains('organisasi')) {
      return Icons.account_tree;
    } else if (titleLower.contains('anggota') || titleLower.contains('member')) {
      return Icons.people;
    } else if (titleLower.contains('program') || titleLower.contains('kerja')) {
      return Icons.work;
    } else if (titleLower.contains('kegiatan') || titleLower.contains('aktivitas')) {
      return Icons.event;
    } else if (titleLower.contains('prestasi') || titleLower.contains('achievement')) {
      return Icons.emoji_events;
    } else if (titleLower.contains('kontak') || titleLower.contains('contact')) {
      return Icons.contact_phone;
    } else if (titleLower.contains('alamat') || titleLower.contains('address')) {
      return Icons.location_on;
    } else if (titleLower.contains('website') || titleLower.contains('web')) {
      return Icons.public;
    } else if (titleLower.contains('sosial') || titleLower.contains('media')) {
      return Icons.share;
    } else if (titleLower.contains('berita') || titleLower.contains('news')) {
      return Icons.newspaper;
    } else if (titleLower.contains('galeri') || titleLower.contains('foto')) {
      return Icons.photo_library;
    } else if (titleLower.contains('video')) {
      return Icons.video_library;
    } else if (titleLower.contains('dokumen') || titleLower.contains('document')) {
      return Icons.description;
    } else {
      return Icons.article;
    }
  }
}
