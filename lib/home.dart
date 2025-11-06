import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:sahabatpknnew/DetailNewsPage.dart';
import 'package:sahabatpknnew/pkncenter.dart';
import 'package:sahabatpknnew/profile_pkn.dart';
import 'package:sahabatpknnew/agenda_pkn.dart';
import 'package:sahabatpknnew/models/news.dart';
import 'package:sahabatpknnew/services/newsService.dart';
import 'package:sahabatpknnew/widgets/app_bottom_nav.dart';
import 'package:sahabatpknnew/debug_api_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // ===== Controllers
  final PageController _bannerPageController = PageController(
    viewportFraction: 0.92,
  );
  final PageController _newsPageController = PageController(initialPage: 0);

  // ===== Timers
  Timer? _bannerTimer;
  Timer? _newsTimer;

  // ===== Banner dummy count
  static const int _bannerCount = 3;

  // ===== News (diambil dari API)
  late Future<List<News>> _futureNews;
  static const String _token = "Xp8b8F8hpfPy6bxK24pjTwt6m";

  int currentIndex = 0;

  @override
  void initState() {
    super.initState();

    _futureNews = ApiService(authToken: _token).getNews(_token);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startBannerAutoScroll();
      // news auto-scroll DIHIDUPKAN setelah data berita ready (lihat _buildNewsSection)
    });
  }

  void _reloadNews() {
    print('🔄 Reloading news...');
    setState(() {
      _futureNews = ApiService(authToken: _token).getNews(_token);
    });
  }

  // ----------------- Timers -----------------
  void _startBannerAutoScroll() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_bannerPageController.hasClients) return;
      final current = _bannerPageController.page?.round() ?? 0;
      final next = (current + 1) % _bannerCount;
      _bannerPageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    });
  }

  void _restartNewsAutoScroll(int itemCount) {
    // dipanggil setiap kali data berita sudah ada/berubah
    _newsTimer?.cancel();
    if (itemCount <= 1) return; // kalau cuma 1 berita, tidak perlu auto-scroll

    _newsTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_newsPageController.hasClients) return;
      final current = _newsPageController.page?.round() ?? 0;
      final next = (current + 1) % itemCount;
      _newsPageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _newsTimer?.cancel();
    _newsPageController.dispose();
    _bannerPageController.dispose();
    super.dispose();
  }

  // ----------------- UI -----------------
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: SafeArea(
          bottom: false,
          child: AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            centerTitle: false,
            titleSpacing: 16,
            title: Row(
              children: [
                Image.asset('assets/logopkn.png', height: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Partai Kebangkitan Nusantara',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.normal,
                      fontSize: 15.0,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.bug_report, color: Colors.white),
                onPressed: () {
                  Get.to(() => const DebugApiPage());
                },
              ),
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          children: [
            _buildBanner(),
            _buildFinanceGrid(),
            _buildJoinPKN(),
            _buildNewsSection(size), // <<--- pakai data API
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: currentIndex,
        onTap: (i) {
          setState(() {
            currentIndex = i;

            if (i == 0) {
              // Already on Home page, do nothing or refresh
            } else if (i == 1) {
              // Get.to(() => BlankPage()); // Kartu page - implement later
            } else if (i == 2) {
              //l
            }
          });
        },
      ),
    );
  }

  Widget _buildBanner() {
    final w = MediaQuery.of(context).size.width;
    final bannerHeight = (w * 0.5).clamp(160.0, 260.0);

    // daftar URL gambar slider kamu
    final List<String> bannerImages = [
      'https://pkn.or.id/assets/img/uploads/slider/slider1.webp',
      'https://pkn.or.id/assets/img/uploads/slider/slider2.webp',
      'https://pkn.or.id/assets/img/uploads/slider/slider3.webp',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        SizedBox(
          height: bannerHeight,
          child: PageView.builder(
            controller: _bannerPageController,
            itemCount: bannerImages.length,
            itemBuilder: (context, index) {
              final imageUrl = bannerImages[index];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // 🔹 Network Image dengan fallback asset
                      Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint('Gagal load banner: $imageUrl');
                          return Image.asset(
                            'assets/logopkn.png',
                            fit: BoxFit.cover,
                          );
                        },
                      ),

                      // 🔹 Overlay gelap + teks
                      Container(
                        alignment: Alignment.bottomLeft,
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Widget _buildBanner() {
  //   final w = MediaQuery.of(context).size.width;
  //   final bannerHeight = (w * 0.5).clamp(160.0, 260.0);

  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       const SizedBox(height: 8),
  //       SizedBox(
  //         height: bannerHeight,
  //         child: PageView.builder(
  //           controller: _bannerPageController,
  //           itemCount: _bannerCount,
  //           itemBuilder: (context, index) {
  //             return Padding(
  //               padding: const EdgeInsets.symmetric(
  //                 horizontal: 16,
  //                 vertical: 8,
  //               ),
  //               child: ClipRRect(
  //                 borderRadius: BorderRadius.circular(12),
  //                 child: Stack(
  //                   fit: StackFit.expand,
  //                   children: [
  //                     Image.asset('assets/logopkn.png', fit: BoxFit.cover),
  //                     Container(
  //                       color: Colors.black.withAlpha(76),
  //                       alignment: Alignment.bottomLeft,
  //                       padding: const EdgeInsets.all(12),
  //                       child: Text(
  //                         'Slide Banner ${index + 1}',
  //                         style: const TextStyle(
  //                           color: Colors.white,
  //                           fontSize: 16,
  //                           fontWeight: FontWeight.w600,
  //                         ),
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             );
  //           },
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildFinanceGrid() {
    final List<Map<String, dynamic>> items = [
      {'label': 'Sikap PKN', 'svg': 'assets/sikappkn.svg'},
      {'label': 'Agenda', 'svg': 'assets/agenda.svg'},
      {'label': 'PKN Center', 'svg': 'assets/pkncenter.svg'},
    ];

    const columns = 3;
    const crossSpacing = 12.0;
    const horizontalPadding = 16.0 * 2;
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth =
        (screenWidth - horizontalPadding - crossSpacing * (columns - 1)) /
        columns;

    const itemHeight = 88.0;
    final aspectRatio = itemWidth / itemHeight;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: aspectRatio,
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          return ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            ),
            onPressed: () {
              //menu home
              if (item['label'] == 'Sikap PKN') {
                Get.to(() => SikapPKN());
              } else if (item['label'] == 'Agenda') {
                Get.to(() => AgendaPage());
              } else if (item['label'] == 'PKN Center') {
                Get.to(() => PKNCenterPage());
              }
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  item['svg'],
                  theme: const SvgTheme(currentColor: Color(0xfff44336)),
                  width: 25,
                  height: 25,
                ),
                const SizedBox(width: 12),
                Text(
                  item['label'],
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildJoinPKN() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Image.asset(
              'assets/header.png',
              fit: BoxFit.cover,
              height: 190,
              width: double.infinity,
            ),
            Container(
              height: 190,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black54],
                ),
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(),
                    const Text(
                      'Gabung Bareng Sahabat Nusantara',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        shadows: [
                          Shadow(
                            blurRadius: 6,
                            color: Colors.black54,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xfff44336),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () {},
                      child: const Text(
                        'Gabung Sekarang',
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== BERITA PKN (PAKAI API) =====================
  Widget _buildNewsSection(Size size) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Berita PKN',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
        ),

        // Pakai FutureBuilder untuk load berita
        FutureBuilder<List<News>>(
          future: _futureNews,
          builder: (context, snapshot) {
            // Loading
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 180,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            // Error
            if (snapshot.hasError) {
              print('❌ Error in FutureBuilder: ${snapshot.error}');

              String errorMessage = 'Gagal memuat berita.';
              if (snapshot.error.toString().contains('Failed to fetch') ||
                  snapshot.error.toString().contains('ClientException')) {
                errorMessage =
                    'Tidak dapat terhubung ke server.\nPeriksa koneksi internet Anda.';
              } else if (snapshot.error.toString().contains('401')) {
                errorMessage = 'Token autentikasi tidak valid.';
              } else if (snapshot.error.toString().contains('timeout')) {
                errorMessage = 'Koneksi timeout. Coba lagi.';
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  elevation: 0,
                  color: const Color(0xFFFDECEE),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(height: 8),
                        Text(
                          errorMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _reloadNews,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            final items = snapshot.data ?? [];
            if (items.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  height: 160,
                  child: Center(child: Text('Belum ada berita')),
                ),
              );
            }

            // Mulai/ulang auto-scroll sesuai jumlah berita
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _restartNewsAutoScroll(items.length);
            });

            // Tinggi kartu berita
            final double cardHeight = size.height * 0.25;

            // PageView horizontal (slide)
            return SizedBox(
              height: cardHeight,
              child: PageView.builder(
                controller: _newsPageController,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final n = items[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // gambar dengan fallback asset
                          _buildThumbnail(n.gambar),
                          Container(color: Colors.black.withAlpha(76)),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    n.judul ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatDate(n.tglPublish ?? ''),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // klik ke detail berita
                          Positioned.fill(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  // TODO: Get.to(DetailNewsPage(news: n));
                                  Get.to(DetailNewsPage(news: n));
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  // ===================== Helpers =====================
  Widget _buildThumbnail(String? imageUrl) {
    const fallbackAsset = 'assets/logopkn.png';

    if (imageUrl == null || imageUrl.trim().isEmpty) {
      return Image.asset(fallbackAsset, fit: BoxFit.cover);
    }

    // Clean up the URL - remove any "../" and fix double slashes
    String cleanUrl = imageUrl
        .replaceAll('../', '')
        .replaceAll('//', '/')
        .replaceFirst('http:/', 'http://')
        .replaceFirst('https:/', 'https://');

    debugPrint('Loading image: $cleanUrl'); // lihat di console

    return Image.network(
      cleanUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        debugPrint('Gagal load gambar: $cleanUrl');
        return Image.asset(fallbackAsset, fit: BoxFit.cover);
      },
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
      },
    );
  }

  // Widget _buildThumbnail(String? fileName) {
  //   const fallbackAsset = 'assets/logopkn.png';

  //   if (fileName == null || fileName.trim().isEmpty) {
  //     return Image.asset(fallbackAsset, fit: BoxFit.cover);
  //   }

  //   // Hapus spasi, slash ganda, dan pastikan path benar
  //   final cleanedName = fileName.replaceAll(RegExp(r'^/+|/+$'), '');
  //   final imageUrl = "https://pkn.or.id/assets/img/uploads/berita/$cleanedName";

  //   return Image.network(
  //     imageUrl,
  //     fit: BoxFit.cover,
  //     loadingBuilder: (context, child, progress) {
  //       if (progress == null) return child;
  //       return const Center(child: CircularProgressIndicator(strokeWidth: 2));
  //     },
  //     errorBuilder: (_, __, ___) =>
  //         Image.asset(fallbackAsset, fit: BoxFit.cover),
  //   );
  // }

  // Widget _buildThumbnail(String? fileName) {
  //   const fallbackAsset = 'assets/logopkn.png';

  //   if (fileName == null || fileName.trim().isEmpty) {
  //     return Image.asset(fallbackAsset, fit: BoxFit.cover);
  //   }

  //   final imageUrl = 'https://pkn.or.id/assets/img/uploads/berita/$fileName';

  //   return Image.network(
  //     imageUrl,
  //     fit: BoxFit.cover,
  //     loadingBuilder: (context, child, progress) {
  //       if (progress == null) return child;
  //       return const Center(child: CircularProgressIndicator(strokeWidth: 2));
  //     },
  //     errorBuilder: (_, __, ___) =>
  //         Image.asset(fallbackAsset, fit: BoxFit.cover),
  //   );
  // }

  String _formatDate(String isoOrYmd) {
    try {
      final dt = DateTime.parse(isoOrYmd);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];
      return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return isoOrYmd;
    }
  }
}
