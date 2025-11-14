import 'package:flutter/material.dart';
import 'package:sahabatpknnew/models/news.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:sahabatpknnew/services/newsService.dart';
import 'package:share_plus/share_plus.dart';

class DetailNewsPage extends StatefulWidget {
  final News news;
  const DetailNewsPage({super.key, required this.news});

  @override
  State<DetailNewsPage> createState() => _DetailNewsPageState();
}

class _DetailNewsPageState extends State<DetailNewsPage> {
  late Future<News> _futureDetail;
  static const String _token = "Xp8b8F8hpfPy6bxK24pjTwt6m";
  @override
  void initState() {
    super.initState();
    final key = (widget.news.seoUrl ?? widget.news.id ?? '').trim();
    _futureDetail = ApiService(authToken: _token).getNewsDetail(key);
  }

  Future<void> _reload() async {
    setState(() {
      final key = (widget.news.seoUrl ?? widget.news.id ?? '').trim();
      _futureDetail = ApiService(authToken: _token).getNewsDetail(key);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<News>(
          future: _futureDetail,
          builder: (context, s) {
            if (s.connectionState == ConnectionState.waiting) {
              return const _SkeletonPage();
            }

            if (s.hasError) {
              return _ErrorState(
                message: 'Gagal memuat detail berita: ${s.error}',
                onRetry: _reload,
              );
            }

            final n = s.data!;

            return RefreshIndicator(
              onRefresh: _reload,
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    expandedHeight: 240,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    actions: [
                      IconButton(
                        tooltip: 'Bagikan',
                        icon: const Icon(Icons.share),
                        onPressed: () async {
                          final url = _buildCanonicalUrl(n);
                          await Share.share(
                            '${n.judul ?? '(Tanpa judul)'}\n${url ?? ''}',
                          );
                        },
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: _HeaderImage(urlFile: n.gambar),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SafeArea(
                      top: false,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 820),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (n.judul?.trim().isNotEmpty ?? false)
                                      ? n.judul!.trim()
                                      : '(Tanpa judul)'.trim(),
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        height: 1.2,
                                      ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    _InfoChip(
                                      icon: Icons.event,
                                      label: _formatDate(n.tglPublish),
                                    ),
                                    const SizedBox(width: 8),
                                    if (_buildCanonicalUrl(n) != null)
                                      _InfoChip(
                                        icon: Icons.link,
                                        label: 'pkn.or.id',
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Card(
                                  elevation: 0,
                                  color: theme.colorScheme.surface,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                      color: theme.dividerColor.withOpacity(.3),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      18,
                                      16,
                                      4,
                                    ),
                                    child: HtmlWidget(
                                      n.konten ?? '',
                                      textStyle: theme.textTheme.bodyMedium
                                          ?.copyWith(height: 1.7, fontSize: 15),
                                      renderMode: RenderMode
                                          .column, // penting: hindari nested scroll
                                      enableCaching: true,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    FilledButton.icon(
                                      icon: const Icon(Icons.share),
                                      label: const Text('Bagikan'),
                                      onPressed: () async {
                                        final url = _buildCanonicalUrl(n);
                                        await Share.share(
                                          '${n.judul ?? '(Tanpa judul)'}\n${url ?? ''}',
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 12),
                                    OutlinedButton.icon(
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('Muat Ulang'),
                                      onPressed: _reload,
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
          },
        ),
      ),
    );
  }

  // ================= Helpers =================
  static String _formatDate(String? isoOrYmd) {
    if (isoOrYmd == null || isoOrYmd.isEmpty) return '-';
    try {
      final dt = DateTime.parse(isoOrYmd);
      const m = [
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
      return '${dt.day.toString().padLeft(2, '0')} ${m[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return isoOrYmd;
    }
  }

  static String? _buildCanonicalUrl(News n) {
    final seo = n.seoUrl?.trim();
    final id = n.id?.trim();
    if (seo != null && seo.isNotEmpty) return 'https://pkn.or.id/berita/$seo';
    if (id != null && id.isNotEmpty) return 'https://pkn.or.id/berita/$id';
    return null;
  }
}

// ================= Widgets =================

class _HeaderImage extends StatelessWidget {
  final String? urlFile;
  const _HeaderImage({required this.urlFile});

  @override
  Widget build(BuildContext context) {
    const fallback = 'assets/logopkn.png';

    if (urlFile == null || urlFile!.trim().isEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(fallback, fit: BoxFit.cover),
          const _HeaderGradient(),
        ],
      );
    }
    final url = 'https://pkn.or.id/assets/img/uploads/berita/$urlFile';

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          url,
          fit: BoxFit.cover,
          loadingBuilder: (c, child, progress) {
            if (progress == null) return child;
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          },
          errorBuilder: (_, __, ___) =>
              Image.asset(fallback, fit: BoxFit.cover),
        ),
        const _HeaderGradient(),
      ],
    );
  }
}

class _HeaderGradient extends StatelessWidget {
  const _HeaderGradient();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Color(0xCC000000), Color(0x33000000), Colors.transparent],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withOpacity(.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );

    return chip;
  }
}

class _SkeletonPage extends StatelessWidget {
  const _SkeletonPage();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverAppBar(
          pinned: true,
          expandedHeight: 240,
          flexibleSpace: FlexibleSpaceBar(
            background: DecoratedBox(
              decoration: BoxDecoration(color: Colors.black12),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          sliver: SliverList.list(
            children: const [
              _SkeletonBox(height: 28, width: 260),
              SizedBox(height: 12),
              Row(
                children: [
                  _SkeletonBox(height: 22, width: 100),
                  SizedBox(width: 8),
                  _SkeletonBox(height: 22, width: 80),
                ],
              ),
              SizedBox(height: 16),
              _SkeletonBox(height: 180, width: double.infinity),
              SizedBox(height: 16),
              _SkeletonBox(height: 44, width: 140),
            ],
          ),
        ),
      ],
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double height;
  final double width;
  const _SkeletonBox({required this.height, required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.06),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
