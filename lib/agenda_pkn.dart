import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class AgendaPage extends StatefulWidget {
  const AgendaPage({super.key});
  @override
  State<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> {
  late final WebViewController _c;
  bool _loading = true;

  @override
  void initState() {
    super.initState();

    _c = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..addJavaScriptChannel(
        'JSBridge',
        onMessageReceived: (msg) {
          // debug dari JS -> Flutter
          debugPrint('JS: ${msg.message}');
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _loading = true),
          onPageFinished: (_) async {
            // >>> INJEKSI: sembunyikan elemen yang tidak perlu, tampilkan hanya target
            await _c.runJavaScript(r"""
(function() {
  // helper
  const hide = (sel) => document.querySelectorAll(sel).forEach(el => el.style.display='none');

  // 1) Sembunyikan header/footer/elemen global umum
  hide('header, nav, .navbar, .site-header, .topbar, footer, .site-footer, .cookie, .cookie-banner, .ads, .sidebar, #sidebar');

  // 2) Cari konten agenda (EDIT selector sesuai struktur situs)
  const target =
    document.querySelector('#agenda') ||
    document.querySelector('.agenda') ||
    document.querySelector('[data-section="agenda"]') ||
    document.querySelector('.main-content'); // fallback

  if (target) {
    // Bersihkan body & tempel konten yang diinginkan saja
    const clone = target.cloneNode(true);
    document.body.innerHTML = '';
    document.body.appendChild(clone);

    // Rapikan body
    document.body.style.margin = '0';
    document.body.style.padding = '0';
    document.documentElement.style.scrollBehavior = 'smooth';

    // Pastikan font kontras/rapi
    const style = document.createElement('style');
    style.textContent = `
      body { background:#fff; color:#111; }
      img { max-width:100%; height:auto; }
      * { box-sizing: border-box; }
      a { color: #d32f2f; }
      .btn, button { display:none !important; } /* kalau tak perlu tombol */
    `;
    document.head.appendChild(style);
    JSBridge.postMessage('Agenda target found & applied');
  } else {
    JSBridge.postMessage('Agenda target NOT found; adjust selector');
  }
})();
""");
            setState(() => _loading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse('https://pkn.or.id/agenda'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agenda PKN')),
      body: Stack(
        children: [
          WebViewWidget(controller: _c),
          if (_loading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
