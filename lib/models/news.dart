class News {
  final String? id;
  final String? seoUrl;
  final String? judul;
  final String? konten;
  final String? tglPublish;
  final String? gambar;

  News({
    this.id,
    this.seoUrl,
    this.judul,
    this.konten,
    this.tglPublish,
    this.gambar,
  });

  factory News.fromJson(Map<String, dynamic> j) {
    return News(
      id: j['id']?.toString(),
      seoUrl: j['seo_url'] as String?,
      judul: j['judul'] as String?,
      // fallback ke key lain / kosong
      konten: (j['konten'] ?? j['content'] ?? j['isi'])?.toString(),
      // tanggal bisa datang dengan key berbeda
      tglPublish: (j['tgl_publish'] ?? j['published_at'] ?? j['date'])?.toString(),
      gambar: (j['gambar'] ?? j['image'] ?? j['thumbnail'])?.toString(),
    );
  }
}
