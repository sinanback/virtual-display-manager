"""Build the static bilingual project website. Python stdlib only."""
from pathlib import Path
from html import escape
import argparse
import json
import shutil
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'docs'
REPO = 'https://github.com/sinanback/virtual-display-manager'
RELEASE = REPO + '/releases/tag/v2.0.1-preview.1'
DOWNLOAD = REPO + '/releases/download/v2.0.1-preview.1/Virtual-Display-Manager-Portable.cmd'
AUTHOR = {'@type': 'Person', 'name': 'Muhammed Sinan Aydın', 'url': 'https://github.com/sinanback'}
parser = argparse.ArgumentParser()
parser.add_argument('--base-url', default='https://sinanback.github.io/virtual-display-manager/')
BASE = parser.parse_args().base_url.rstrip('/') + '/'

PAGES = {
    'home': ('', 'en/'),
    'black': ('monitorsuz-uzak-baglanti-siyah-ekran/', 'en/headless-remote-desktop-black-screen/'),
    'dummy': ('hdmi-dummy-plug-alternatifi/', 'en/hdmi-dummy-plug-alternative/'),
}

def url(path=''):
    return BASE + path

def a(href, text, cls=''):
    return f'<a href="{escape(href)}"' + (f' class="{cls}"' if cls else '') + f'>{text}</a>'

def render(key, lang, title, description, heading, body, *, home=False):
    i = 0 if lang == 'tr' else 1
    path, other = PAGES[key][i], PAGES[key][1-i]
    tr = lang == 'tr'
    canonical = url(path)
    short = 'Monitörsüz uzaktan erişim' if tr else 'Headless remote access'
    schema = {
        '@context': 'https://schema.org', '@graph': [
            {'@type': 'WebPage', '@id': canonical + '#page', 'url': canonical,
             'name': title, 'description': description, 'inLanguage': lang,
             'author': AUTHOR, 'dateModified': '2026-10-31'},
        ]
    }
    if home:
        schema['@graph'].append({
            '@type': 'SoftwareApplication', '@id': url() + '#software',
            'name': 'Virtual Display Manager', 'url': canonical,
            'description': description, 'applicationCategory': 'UtilitiesApplication',
            'operatingSystem': 'Windows 10 x64, Windows 11 x64',
            'softwareVersion': '2.0.1 public preview', 'inLanguage': ['tr', 'en'],
            'downloadUrl': DOWNLOAD, 'releaseNotes': RELEASE, 'author': AUTHOR,
            'image': url('assets/cover.png'),
            'offers': {'@type': 'Offer', 'price': '0', 'priceCurrency': 'USD', 'url': RELEASE},
            'softwareRequirements': 'Windows PowerShell 5.1; .NET Framework; administrator permission; Virtual Display Driver',
        })
    else:
        schema['@graph'].append({
            '@type': 'TechArticle', '@id': canonical + '#article', 'headline': heading,
            'description': description, 'inLanguage': lang, 'author': AUTHOR,
            'datePublished': '2026-10-31', 'dateModified': '2026-10-31',
            'mainEntityOfPage': canonical,
        })
        schema['@graph'].append({
            '@type': 'BreadcrumbList', 'itemListElement': [
                {'@type': 'ListItem', 'position': 1, 'name': 'Virtual Display Manager', 'item': url(PAGES['home'][i])},
                {'@type': 'ListItem', 'position': 2, 'name': heading, 'item': canonical},
            ],
        })
    nav = f'''<a class="brand" href="{url(PAGES['home'][i])}"><img src="{url('assets/icon.png')}" width="32" height="32" alt=""><span>Virtual Display Manager</span></a>
    <nav aria-label="{'Ana menü' if tr else 'Main navigation'}">
    {a(url(PAGES['black'][i]), 'Siyah ekran rehberi' if tr else 'Black-screen guide')}
    {a(REPO, 'GitHub')}
    {a(url(other), 'English' if tr else 'Türkçe', 'language')}
    </nav>'''
    alternate = ''.join(f'<link rel="alternate" hreflang="{code}" href="{url(PAGES[key][j])}">' for j, code in enumerate(('tr', 'en')))
    foot = ('Açıkça belirtilen sistemlerde denenmesi gereken bir ön sürümdür. Her uzak erişim aracıyla uyumluluk garantisi verilmez.'
            if tr else 'Public preview. Verify it with your hardware and remote-access software; compatibility is not guaranteed.')
    html = f'''<!doctype html>
<html lang="{lang}"><head><meta charset="utf-8"><meta name="google-site-verification" content="GTbShs8GZY4VhBnX5NeE3VAkS19RFsAqSMqlHfDTfgc"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>{escape(title)}</title><meta name="description" content="{escape(description)}">
<meta name="robots" content="index,follow,max-image-preview:large"><meta name="theme-color" content="#14253c">
<link rel="canonical" href="{canonical}">{alternate}<link rel="alternate" hreflang="x-default" href="{url(PAGES[key][0])}">
<meta property="og:type" content="{'website' if home else 'article'}"><meta property="og:site_name" content="Virtual Display Manager">
<meta property="og:title" content="{escape(title)}"><meta property="og:description" content="{escape(description)}">
<meta property="og:url" content="{canonical}"><meta property="og:locale" content="{'tr_TR' if tr else 'en_US'}">
<meta property="og:image" content="{url('assets/cover.png')}"><meta property="og:image:width" content="1200"><meta property="og:image:height" content="630">
<meta property="og:image:alt" content="Virtual Display Manager — {short}">
<meta name="twitter:card" content="summary_large_image"><meta name="twitter:title" content="{escape(title)}">
<meta name="twitter:description" content="{escape(description)}"><meta name="twitter:image" content="{url('assets/cover.png')}">
<link rel="icon" href="{url('assets/icon.png')}" type="image/png"><link rel="stylesheet" href="{url('assets/style.css')}">
<script type="application/ld+json">{json.dumps(schema, ensure_ascii=False, separators=(',', ':')).replace('</', '<\\/')}</script>
</head><body><a class="skip" href="#content">{'İçeriğe geç' if tr else 'Skip to content'}</a>
<header class="site-header"><div class="wrap nav-row">{nav}</div></header>
<main id="content">{body}</main>
<footer><div class="wrap"><div class="footer-row"><strong>Virtual Display Manager</strong><span>{a('https://github.com/sinanback', 'Muhammed Sinan Aydın')} · {a(REPO, 'GitHub')} · {a(RELEASE, 'Sürüm ve indirme' if tr else 'Release & downloads')}</span></div><p>{foot}</p><p>{'Windows 10/11 x64 · Türkçe / English · Yerel işlem kayıtları' if tr else 'Windows 10/11 x64 · Turkish / English · Local activity logs'}</p></div></footer>
<script src="{url('assets/site.js')}" defer></script></body></html>'''
    target = OUT / path / 'index.html'
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(html, encoding='utf-8')

def home(lang):
    tr = lang == 'tr'
    i = 0 if tr else 1
    title = 'Virtual Display Manager | Monitörsüz Uzak Erişim' if tr else 'Virtual Display Manager | Headless Windows Remote Access'
    desc = ('Monitörsüz Windows bilgisayarlarda uzak erişim için VDD sanal ekranı. HDMI dummy plug yerine yazılımsal çözüm, otomatik monitör geçişi ve hazır CMD indirmesi.' if tr else
            'A VDD virtual monitor for headless Windows remote access. A software HDMI dummy plug alternative with automatic display switching. Download the ready-to-run CMD.')
    h1 = 'Monitör yok.<br><em>Uzak erişim var.</em>' if tr else 'No monitor.<br><em>Still a desktop.</em>'
    lead = ('Sanal ekran adaptörü takmadan, monitörsüz bilgisayarınıza uzaktan erişin. Virtual Display Manager, uygun Windows sistemlerinde VDD ile yazılımsal bir ekran sağlar ve fiziksel monitör bağlandığında geçişi yönetir.' if tr else
            'Access a headless Windows PC without attaching a physical dummy display adapter. Virtual Display Manager uses VDD to provide a software screen in suitable setups and switches it off when a physical monitor is active.')
    download = 'Windows için CMD indir' if tr else 'Download Windows CMD'
    physical = 'Fiziksel monitör' if tr else 'Physical monitor'
    virtual = 'Sanal ekran · VDD' if tr else 'Virtual display · VDD'
    state = 'Bağlı değil' if tr else 'Disconnected'
    on = 'AÇIK' if tr else 'ON'
    body = f'''<section class="hero"><div class="wrap hero-grid"><div>
<p class="eyebrow">WINDOWS 10 / 11 · TR / EN</p><h1>{h1}</h1><p class="lead">{lead}</p>
<div class="actions">{a(DOWNLOAD, download + ' <span aria-hidden="true">↗</span>', 'button primary')}{a(REPO, 'Kaynağı incele' if tr else 'View source', 'button secondary')}</div>
<p class="fine">{'Tek dosya · Yaklaşık 25 MB · Yönetici izni gerekir' if tr else 'One file · About 25 MB · Administrator permission required'}</p></div>
<div class="diagram" data-lang="{lang}"><div class="diagram-head"><span class="window-dots" aria-hidden="true">● ● ●</span><span>{'Otomatik ekran kontrolü' if tr else 'Automatic display control'}</span></div>
<div class="device"><span class="device-symbol" aria-hidden="true">▣</span><div><strong>{physical}</strong><p id="physical-state">{state}</p></div><span id="physical-dot" class="dot off" aria-hidden="true"></span></div>
<div class="flow" aria-hidden="true">↓</div>
<div class="device vdd"><span class="device-symbol" aria-hidden="true">▧</span><div><strong>{virtual}</strong><p id="virtual-note">{'Yakalanabilecek bir ekran kaynağı' if tr else 'A screen available for capture'}</p></div><span id="virtual-state" class="status on">{on}</span></div>
<div class="scenario" role="group" aria-label="{'Davranış örneği' if tr else 'Behavior example'}"><button type="button" data-monitor="off" aria-pressed="true">{'Monitör yok' if tr else 'No monitor'}</button><button type="button" data-monitor="on" aria-pressed="false">{'Monitör bağlandı' if tr else 'Monitor connected'}</button></div>
<p class="diagram-caption">{'Davranış örneği; bu sayfa cihazınıza erişmez.' if tr else 'Illustration only; this page does not access your devices.'}</p></div></div></section>'''
    if tr:
        body += f'''<section class="section wrap" id="nasil-calisir"><div class="section-heading"><p class="eyebrow">SORUN → ÇÖZÜM</p><h2>Bağlantı var, görüntü yok mu?</h2><p>Monitör söküldüğünde bazı sistemler uzak erişim aracının yakalayabileceği aktif bir ekran sunmaz. Sonuç siyah ekran veya “görüntü bekleniyor” olabilir. VDD, Windows'a yazılımsal bir monitör ekler; bu uygulama onu sizin yerinize yönetir.</p></div>
<ol class="steps"><li><span>01</span><h3>Monitör yokken açar.</h3><p>Uygulama çalışırken, aktif fiziksel ekran bulunmadığında kurulu ve kapalı VDD etkinleştirilir.</p></li><li><span>02</span><h3>Monitör bağlanınca kapatır.</h3><p>En az bir aktif fiziksel ekran algılandığında sanal ekran devre dışı bırakılır.</p></li><li><span>03</span><h3>Son monitör sökülünce geri açar.</h3><p>Bağlantı iki kontrolde doğrulanır. Algılama belirsizse mevcut durum korunur.</p></li></ol>
<p class="note">Bu araç uzak bağlantıyı kendisi kurmaz. Ağ, parola veya oturum sorunlarını çözmez; fiziksel ekran yokluğundan kaynaklanan görüntü ihtiyacına yöneliktir. Her siyah ekranın sebebi monitör eksikliği değildir.</p></section>
<section class="section pale"><div class="wrap split"><div><p class="eyebrow">KİMLER İÇİN?</p><h2>Masada ekran olmayan<br>Windows bilgisayarlar için.</h2></div><div class="use-list"><article><h3>Mini PC ve ev sunucusu</h3><p>Masaüstüne uygun bir uzak erişim aracıyla ulaşmak istediğiniz, sürekli monitör bağlı tutmadığınız cihazlarda sanal ekran yönetimi.</p></article><article><h3>Uzaktan teknik destek</h3><p>Birinin fiziksel ekran takmasını beklemeden, önceden kurulmuş ve çalışan sanal ekran düzenini kullanma.</p></article><article><h3>Masaüstü ve oyun aktarımı</h3><p>Sanal monitör yakalamayı destekleyen düzenlerde ekran kaynağı. Yayın yazılımında GPU ve ekran seçimi ayrıca gerekebilir.</p></article></div></div></section>
<section class="section wrap split product"><div><p class="eyebrow">TEK YERDEN KONTROL</p><h2>Arka planda çalışır.<br>Kontrol sizde kalır.</h2><p>Türkçe/İngilizce arayüz, elle aç/kapat, kullanıcı kılavuzu ve yerel işlem geçmişi. Çarpıya bastığınızda izleme saat yanındaki simgede devam eder.</p><p>Tamamen çıkmak için simgeye sağ tıklayıp <strong>Tamamen çık</strong> seçeneğini kullanın. Bu sürüm Windows başlangıcına otomatik eklenmez; her oturumda bir kez çalıştırın.</p></div><figure><img src="{url('assets/app.png')}" width="896" height="739" alt="Virtual Display Manager arayüzü: ekran durumu, otomatik kontrol ve cihaz işlemleri" loading="lazy" decoding="async"><figcaption>Gerçek uygulama görünümü. Aygıt durumu ve seçili kontrol modu örnektir.</figcaption></figure></section>
<section class="section download-section"><div class="wrap"><p class="eyebrow">İNDİR VE ÇALIŞTIR</p><h2>Kaynak kodu derlemeniz gerekmez.</h2><p>Hazır CMD içinde uygulama ve çevrimdışı kurulum bileşenleri bulunur. VDD kurulu değilse uygulamadaki <strong>Sürücüyü kur</strong> düğmesini kullanın. Ayrı PS1 dosyası gerekmez.</p><div class="actions">{a(DOWNLOAD, download, 'button primary')}{a(RELEASE, 'Sürüm notları ve SHA-256', 'button secondary')}</div><p class="fine">Windows 10/11 x64 · Windows PowerShell 5.1 · .NET Framework · Yönetici izni</p><p class="fine">Ücretsiz indirme · v2.0.1 public preview · Kaynaklar ve lisans koşulları GitHub'da</p></div></section>'''
        faqs = [
            ('Fiziksel HDMI dummy plug yerine geçer mi?', 'Uygun Windows/sürücü/uzak erişim düzenlerinde aynı ekran ihtiyacını yazılımsal bir sanal monitörle karşılayabilir. Her donanım ve yazılımla uyumluluk garantisi verilmez.'),
            ('AnyDesk, TeamViewer veya diğer araçlarla çalışır mı?', 'Ekran yakalama desteği ve kullanılan sürüm belirleyicidir. Bu projede uygulama bazlı uyumluluk testleri yapılmadı. Bazı uzak erişim araçları kendi sanal monitör desteğini sunar; ek VDD her durumda gerekmez.'),
            ('Dizüstünün kendi ekranı da sayılır mı?', 'Evet. Windows tarafından aktif fiziksel ekran olarak bildirilen dahili panel de sayılır. Böyle bir ekran aktifken otomatik mod VDD’yi kapatır.'),
            ('Pencereyi kapatınca izleme durur mu?', 'Hayır. Çarpı pencereyi bildirim alanına gizler. Saat yanındaki simgeden tamamen çıkmadığınız sürece uygulama çalışmaya devam eder.'),
            ('Güvenlik ve test durumu nedir?', 'Bu bir ön sürümdür. Arayüz, simüle geçiş, simge, başlatıcı ve salt okunur donanım sorgusu testleri geçti. Gerçek kablo tak/çıkar ve sürücü kurulum/kaldırma bu yayın hazırlığında test edilmedi. Önce bir test cihazında doğrulayın.'),
            ('Uzak bağlantımı kesebilir mi?', 'Fiziksel ekran yokken VDD’yi elle kapatmak uzak görüntüyü kesebilir. Değişiklikleri denemeden önce alternatif bir erişim yolunuz olduğundan emin olun.'),
        ]
        guides = [(PAGES['black'][i], 'Monitörsüz uzak bağlantıda siyah ekran', 'Görüntü eksikliği ile ağ/oturum sorunlarını ayırın; adım adım kontrol edin.'), (PAGES['dummy'][i], 'HDMI dummy plug yerine sanal ekran', 'Fiziksel adaptör ve yazılımsal monitörün farkını anlayın.')]
    else:
        body += f'''<section class="section wrap"><div class="section-heading"><p class="eyebrow">THE PROBLEM → A DISPLAY SOURCE</p><h2>Connected, but no picture?</h2><p>On some Windows systems, unplugging a monitor leaves no active screen for remote-access software to capture. You may see a black screen or “waiting for image”. VDD adds a software monitor; this utility manages when it is enabled.</p></div>
<ol class="steps"><li><span>01</span><h3>No monitor: enable VDD.</h3><p>While the manager runs, an installed, disabled VDD is enabled when no physical display is active.</p></li><li><span>02</span><h3>Monitor connected: disable VDD.</h3><p>The virtual display is disabled when at least one active physical monitor is detected.</p></li><li><span>03</span><h3>Last monitor unplugged: restore VDD.</h3><p>Two consistent samples confirm a change. Uncertain detection preserves the current state.</p></li></ol>
<p class="note">This utility does not establish remote connections or fix network, password or session issues. It addresses the display-source problem; not every black screen is caused by a missing monitor.</p></section>
<section class="section pale"><div class="wrap split"><div><p class="eyebrow">WHO IT IS FOR</p><h2>Windows computers<br>without a desk display.</h2></div><div class="use-list"><article><h3>Mini PCs and home servers</h3><p>Manage a virtual screen for desktop access through suitable remote-control software without keeping a monitor attached.</p></article><article><h3>Remote technical support</h3><p>Use a virtual display configured and running in advance when nobody is available to attach a monitor.</p></article><article><h3>Desktop and game streaming</h3><p>Provide a screen for software that supports virtual-monitor capture. GPU routing and capture-display selection may need separate setup.</p></article></div></div></section>
<section class="section wrap split product"><div><p class="eyebrow">ONE PLACE TO MANAGE IT</p><h2>Runs in the background.<br>Keeps you in control.</h2><p>Turkish/English UI, manual switching, an in-app guide and local activity history. Closing the window keeps monitoring in the notification area.</p><p>Right-click the tray icon and choose <strong>Exit application</strong> to stop it completely. This version does not register Windows autostart; launch it once per session.</p></div><figure><img src="{url('assets/app.png')}" width="896" height="739" alt="Virtual Display Manager window with display status, automatic control and device activity tabs" loading="lazy" decoding="async"><figcaption>Actual application window. Device state and selected mode are illustrative.</figcaption></figure></section>
<section class="section download-section"><div class="wrap"><p class="eyebrow">DOWNLOAD AND LAUNCH</p><h2>No source build required.</h2><p>The ready-to-run CMD includes the application and offline installation components. If VDD is not installed, choose <strong>Install driver</strong> in the app. No separate PS1 file is needed.</p><div class="actions">{a(DOWNLOAD, download, 'button primary')}{a(RELEASE, 'Release notes & SHA-256', 'button secondary')}</div><p class="fine">Windows 10/11 x64 · Windows PowerShell 5.1 · .NET Framework · Administrator permission</p><p class="fine">Free download · v2.0.1 public preview · Source and licensing information on GitHub</p></div></section>'''
        faqs = [
            ('Can this replace a physical HDMI dummy plug?', 'In suitable Windows, driver and remote-capture configurations, a software virtual monitor can serve the same display-source need. Compatibility with every setup is not guaranteed.'),
            ('Does it work with AnyDesk, TeamViewer or other remote tools?', 'It depends on capture support and software version. Application-specific compatibility has not been tested for this project. Some tools already provide their own virtual-monitor support.'),
            ('Does a built-in laptop screen count?', 'Yes. An internal panel reported as an active physical display counts. Automatic mode disables VDD while it is active.'),
            ('Does closing the window stop monitoring?', 'No. The close button hides the window to the notification area. Use the tray menu’s Exit application action to stop monitoring.'),
            ('What has been tested?', 'This is a public preview. UI, simulated switching, icon, startup and read-only hardware checks passed. Actual cable changes and driver installation/removal were not tested in this release preparation. Verify it on a test device first.'),
            ('Can it interrupt remote access?', 'Manually disabling VDD without a physical display may remove the remote picture. Keep an alternative access method when testing device changes.'),
        ]
        guides = [(PAGES['black'][i], 'Headless remote desktop black screen', 'Separate display-capture problems from network and session issues.'), (PAGES['dummy'][i], 'HDMI dummy plug vs. a virtual monitor', 'Understand the hardware and software approaches before choosing.')]
    body += '<section class="section wrap faq"><p class="eyebrow">FAQ</p><h2>' + ('İndirmeden önce bilmeniz gerekenler' if tr else 'Before you download') + '</h2>'
    body += ''.join(f'<details><summary>{q}</summary><p>{ans}</p></details>' for q, ans in faqs) + '</section>'
    body += '<section class="section wrap guides"><p class="eyebrow">' + ('REHBERLER' if tr else 'GUIDES') + '</p><h2>' + ('Sorunu anlayın, doğru çözümü seçin.' if tr else 'Understand the issue. Choose the right approach.') + '</h2>'
    body += ''.join(f'<article>{a(url(p), "<h3>" + t + " <span aria-hidden=\"true\">↗</span></h3>")}<p>{d}</p></article>' for p, t, d in guides) + '</section>'
    render('home', lang, title, desc, 'Virtual Display Manager', body, home=True)

ARTICLES = {
    ('black', 'tr'): (
        'Monitörsüz Uzak Bağlantıda Siyah Ekran | VDM',
        'Monitör bağlı değilken uzak masaüstünde siyah ekran veya görüntü bekleniyor sorunu: ekran, ağ ve oturum kontrolleri; VDD ile sanal monitör seçeneği.',
        'Monitör yokken uzak bağlantıda neden görüntü gelmez?',
        '''<p class="article-lead">Uzak cihaza bağlanabiliyorsunuz ama masaüstü görüntüsü gelmiyor. Harici monitör takınca görüntü geri dönüyorsa sorun, bağlantının kendisinden çok kullanılabilir bir ekran kaynağının bulunmaması olabilir.</p>
<h2>Önce iki farklı durumu ayırın</h2><ul><li><strong>Hiç bağlantı kurulamıyor:</strong> cihazın açık olması, internet/ağ, hizmetin çalışması, erişim izni ve oturum bilgileri kontrol edilmelidir. Sanal monitör bunları düzeltmez.</li><li><strong>Bağlantı var ama görüntü yok:</strong> ekran yakalama, sürücü, aktif oturum veya monitörün bulunmaması incelenebilir.</li></ul>
<h2>Adım adım kontrol</h2><ol><li>Bir fiziksel monitör bağlayın ve uzak görüntünün değişip değişmediğini gözleyin.</li><li>Windows Aygıt Yöneticisi'nde görüntü bağdaştırıcısı ve monitör durumunu kontrol edin. Sürücü hatası varsa önce onu giderin.</li><li>Uzak erişim yazılımının ekran yakalama ve monitörsüz kullanım belgelerine bakın. Bazı araçların kendi sanal monitör desteği vardır.</li><li>Sorun yalnızca fiziksel monitör yokken oluşuyorsa, uyumlu bir sanal monitör sürücüsü veya fiziksel HDMI dummy plug seçeneklerini değerlendirin.</li><li>VDD kullanacaksanız güvenilir bir erişim kanalınız varken kurulum yapın, yeniden bağlanmayı test edin ve uygulamayı oturumda çalışır durumda tutun.</li></ol>
<h2>Virtual Display Manager hangi noktada yardımcı olur?</h2><p>Hazır CMD'nin kurulum akışı VDD sanal monitörünü Windows'a ekleyebilir. Otomatik mod fiziksel monitör yokken bu aygıtı etkinleştirir; monitör bağlandığında kapatır. Bu, destekleyen uzak erişim araçlarına yakalanabilecek bir ekran kaynağı sunmayı amaçlar.</p>
<p>Dahili dizüstü paneli aktif bir fiziksel ekran olarak sayılır. Otomatik geçiş yalnızca yönetici uygulaması çalışırken gerçekleşir; Windows başlangıç görevi bu sürümde kurulmaz.</p>
<h2>Uzak erişim araçlarının belgeleri ne söylüyor?</h2><p><a href="https://support.anydesk.com/docs/waiting-for-image">AnyDesk'in görüntü bekleme açıklaması</a> ve <a href="https://help.realvnc.com/hc/en-us/articles/360004012211-Display-issues-when-connecting-to-RealVNC-Connect-for-Windows">RealVNC'nin monitörsüz Windows rehberi</a>, aktif ekran bulunmamasının görüntü yakalamayı etkileyebildiğini anlatır. Bu, Virtual Display Manager'ın bu ürünlerle doğrulanmış entegrasyonu olduğu anlamına gelmez.</p>
<p><a href="https://www.teamviewer.com/en/global/support/knowledge-base/teamviewer-remote/troubleshooting/black-screen-after-starting-a-connection/">TeamViewer'ın güncel belgeleri</a> Windows için yerleşik sanal monitör desteği bulunduğunu belirtir. Bu nedenle ek VDD her kurulumda gerekli değildir. Kendi aracınızın sürümüne göre karar verin.</p>
<h2>Bir kontrol listesi</h2><ul><li>Monitör takınca uzak görüntü geliyor mu?</li><li>İlgili görüntü sürücüleri sağlıklı mı?</li><li>Uzak yazılım, sanal monitörü yakalayabiliyor mu?</li><li>Uygun bir Windows masaüstü oturumu aktif mi?</li><li>Bir sorun çıkarsa kullanabileceğiniz ikinci erişim yolu var mı?</li></ul>'''),
    ('black', 'en'): (
        'Headless Remote Desktop Black Screen | VDM',
        'Black screen or waiting for image without a monitor? Check Windows display capture, sessions and drivers, then evaluate a VDD virtual monitor for remote access.',
        'Why is remote desktop black without a monitor?',
        '''<p class="article-lead">You can connect to the PC, but no desktop picture arrives. If connecting a physical monitor restores the image, the issue may be the absence of an active capture display rather than the remote connection itself.</p>
<h2>Distinguish connection from capture problems</h2><ul><li><strong>No connection:</strong> check power, network access, the remote service, permissions and sign-in information. A virtual monitor does not fix these.</li><li><strong>Connected but no picture:</strong> investigate capture support, graphics/display drivers, active sessions and whether Windows has a usable display.</li></ul>
<h2>A practical troubleshooting sequence</h2><ol><li>Attach a physical monitor and observe whether remote capture starts working.</li><li>Inspect graphics and monitor status in Windows Device Manager. Resolve driver errors first.</li><li>Check the remote tool's documentation for headless capture and its own virtual-display support.</li><li>If the problem is specific to monitor-free operation, evaluate a compatible virtual-monitor driver or a physical HDMI dummy plug.</li><li>Install and verify a virtual display while you still have a reliable access channel. Test reconnecting before leaving the PC unattended.</li></ol>
<h2>Where Virtual Display Manager fits</h2><p>The ready-to-run CMD can install VDD to add a software monitor to Windows. The manager enables it when no physical display is active and disables it when a real monitor is connected. This aims to provide a capture target for software that supports the resulting display.</p><p>An active built-in laptop panel counts as a physical screen. Automatic switching only runs while the manager is open in the session; this release does not configure Windows autostart.</p>
<h2>What remote-access vendors document</h2><p><a href="https://support.anydesk.com/docs/waiting-for-image">AnyDesk's image-waiting guidance</a> and <a href="https://help.realvnc.com/hc/en-us/articles/360004012211-Display-issues-when-connecting-to-RealVNC-Connect-for-Windows">RealVNC's Windows display guide</a> describe monitor-related capture failures. These references explain the problem, not tested compatibility of this manager with those products.</p><p><a href="https://www.teamviewer.com/en/global/support/knowledge-base/teamviewer-remote/troubleshooting/black-screen-after-starting-a-connection/">Current TeamViewer documentation</a> describes built-in Windows virtual-monitor support, so an additional VDD is not needed for every setup.</p>
<h2>Before leaving the PC unattended</h2><ul><li>Does attaching a physical monitor restore capture?</li><li>Are the display drivers healthy?</li><li>Can your remote software capture the virtual monitor?</li><li>Is the expected Windows desktop session active?</li><li>Do you have another access method if the display changes?</li></ul>'''),
    ('dummy', 'tr'): (
        'HDMI Dummy Plug Alternatifi: Sanal Ekran | VDM',
        'HDMI dummy plug ve yazılımsal sanal monitör arasındaki farkı öğrenin. Monitörsüz Windows uzak erişimi için VDD ne zaman fiziksel adaptörün yerini alabilir?',
        'HDMI dummy plug yerine yazılımsal sanal ekran',
        '''<p class="article-lead">Sanal ekran adaptörü olarak da anılan HDMI dummy plug, bilgisayara bir monitör bağlıymış gibi görünen fiziksel bir donanımdır. VDD ise ekran aygıtını Windows'a yazılım sürücüsü üzerinden ekler.</p>
<h2>İkisi hangi ihtiyacı karşılar?</h2><p>Uygun bir görüntü yakalama düzeninde ikisi de monitörsüz bilgisayarda bir ekran kaynağının bulunmasını sağlayabilir. Kullanılan GPU, sürücü, uzak erişim aracı ve oturum davranışı sonucu etkiler. Donanım adaptörünü her sistemde birebir değiştirdikleri varsayılmamalıdır.</p>
<div class="table-scroll"><table><thead><tr><th>Özellik</th><th>Fiziksel dummy plug</th><th>VDD sanal monitör</th></tr></thead><tbody><tr><td>Nasıl eklenir?</td><td>Uygun görüntü portuna takılır.</td><td>Windows sürücüsü olarak kurulur.</td></tr><tr><td>Fiziksel bağlantı</td><td>Port kullanır.</td><td>Harici adaptör gerektirmez.</td></tr><tr><td>Yönetim</td><td>Donanım ve Windows ekran ayarlarına bağlıdır.</td><td>Aygıt etkinleştirilip devre dışı bırakılabilir.</td></tr><tr><td>Uyumluluk</td><td>Port, donanım ve adaptör özelliklerine bağlıdır.</td><td>Windows, sürücü ve yakalama yazılımına bağlıdır.</td></tr></tbody></table></div>
<h2>Virtual Display Manager'ın eklediği kolaylık</h2><p>VDD'yi elle açıp kapatmak yerine, fiziksel ekran durumuna göre otomatik kontrol eder. Gerçek monitör bağlandığında VDD kapanır; son fiziksel ekran söküldüğünde yeniden açılır. Geçiş için uygulamanın çalışması gerekir.</p>
<h2>Hangi durumlarda değerlendirebilirsiniz?</h2><ul><li>Monitör bağlamadan eriştiğiniz bir Windows mini PC'de yazılımsal ekran istiyorsanız.</li><li>Fiziksel görüntü portunu bir adaptörle meşgul etmek istemiyorsanız.</li><li>Bilgisayara bazen gerçek monitör takıyor, sanal ekranı tekrar tekrar elle yönetmek istemiyorsanız.</li></ul>
<h2>Oyun aktarımı ve GPU seçimi</h2><p>Sanal ekranın bulunması, yayın yazılımının onu doğru GPU üzerinden yakaladığı anlamına gelmez. <a href="https://docs.lizardbyte.dev/projects/sunshine/latest/md_docs_2getting__started.html">Sunshine'ın Windows yakalama açıklaması</a> ekran/GPU ilişkisinin önemini belirtir. Donanım kodlama, oturum, ekran seçimi ve uygulama ayarlarını ayrıca doğrulayın. Bu projede belirli oyun aktarım yazılımlarıyla uyumluluk testi yapılmadı.</p>
<h2>Kısa cevap</h2><p><strong>Uygun Windows ve uzak erişim düzenlerinde VDD, fiziksel sanal ekran adaptörü ihtiyacını yazılımsal bir monitörle karşılayabilir.</strong> Önce mevcut bağlantı yolunuzu koruyarak deneme yapın; her siyah ekran sorununun sebebi ekran eksikliği değildir.</p>'''),
    ('dummy', 'en'): (
        'HDMI Dummy Plug Alternative for Windows | VDM',
        'Compare a physical HDMI dummy plug with a VDD software virtual monitor for headless Windows remote access, including capture compatibility and automatic switching.',
        'A software alternative to an HDMI dummy plug',
        '''<p class="article-lead">An HDMI dummy plug is a physical display emulator: it makes a computer detect an attached monitor. VDD supplies a display device through a Windows software driver instead.</p>
<h2>The display-source need</h2><p>Both approaches can provide a capture target in suitable monitor-free setups. The GPU, drivers, remote-access software and desktop session all affect the result. They should not be assumed to behave identically on every system.</p>
<div class="table-scroll"><table><thead><tr><th>Aspect</th><th>Physical dummy plug</th><th>VDD virtual monitor</th></tr></thead><tbody><tr><td>Setup</td><td>Attach it to a compatible display port.</td><td>Install a Windows display driver.</td></tr><tr><td>Hardware port</td><td>Uses a physical connector.</td><td>No external adapter required.</td></tr><tr><td>Management</td><td>Depends on hardware and Windows display settings.</td><td>The device can be enabled or disabled.</td></tr><tr><td>Compatibility</td><td>Depends on the port, GPU and adapter.</td><td>Depends on Windows, driver and capture software.</td></tr></tbody></table></div>
<h2>What the manager adds</h2><p>Instead of manually toggling VDD, the utility checks physical-display availability. It disables VDD while a physical monitor is active, then enables it when the last physical screen is unplugged. The manager must be running for this automation.</p>
<h2>When to consider it</h2><ul><li>You want a software display for a headless Windows mini PC.</li><li>You prefer not to occupy a display port with an emulator.</li><li>You occasionally connect a real monitor and want less manual device switching.</li></ul>
<h2>Streaming and GPU routing</h2><p>A virtual monitor does not by itself make streaming software capture the intended GPU. <a href="https://docs.lizardbyte.dev/projects/sunshine/latest/md_docs_2getting__started.html">Sunshine's Windows capture documentation</a> explains the display/GPU constraint. Verify capture-display selection, hardware encoding and session settings separately. Specific game-streaming compatibility has not been tested for this project.</p>
<h2>The short answer</h2><p><strong>In suitable Windows remote-access configurations, a VDD software monitor can remove the need for a physical dummy display adapter.</strong> Test it while retaining another access method. A missing monitor is only one possible reason for a remote black screen.</p>'''),
}

for lang in ('tr', 'en'):
    home(lang)
    for key in ('black', 'dummy'):
        title, desc, heading, text = ARTICLES[key, lang]
        tr = lang == 'tr'
        i = 0 if tr else 1
        related = 'dummy' if key == 'black' else 'black'
        related_title = ARTICLES[related, lang][2]
        body = f'''<article class="article wrap"><div class="breadcrumbs">{a(url(PAGES['home'][i]), 'Virtual Display Manager')} <span aria-hidden="true">/</span> {'Rehber' if tr else 'Guide'}</div>
<p class="eyebrow">{'UYGULAMALI REHBER' if tr else 'PRACTICAL GUIDE'} · 31 {'EKİM' if tr else 'OCTOBER'} 2026</p><h1>{heading}</h1>{text}
<aside class="article-cta"><h2>{'Hazır uygulamayı deneyin' if tr else 'Try the ready-to-run application'}</h2><p>{'Windows 10/11 x64 ve yönetici izni gerekir. Ön sürüm; test cihazında doğrulayın.' if tr else 'Requires Windows 10/11 x64 and administrator access. Public preview; verify on a test device.'}</p>{a(DOWNLOAD, 'Hazır CMD indir' if tr else 'Download CMD', 'button primary')} {a(url(PAGES['home'][i]), 'Uygulama ve gereksinimler' if tr else 'Application & requirements', 'button secondary')}</aside>
<div class="related"><p class="eyebrow">{'İLGİLİ REHBER' if tr else 'RELATED GUIDE'}</p>{a(url(PAGES[related][i]), related_title)}</div></article>'''
        render(key, lang, title, desc, heading, body)

assets = OUT / 'assets'
assets.mkdir(exist_ok=True)
shutil.copyfile(ROOT / 'assets' / 'cover.png', assets / 'cover.png')
shutil.copyfile(ROOT / 'assets' / 'icon-source' / 'icon_32.png', assets / 'icon.png')
(OUT / '.nojekyll').write_text('', encoding='utf-8')

ns = 'http://www.sitemaps.org/schemas/sitemap/0.9'
xhtml = 'http://www.w3.org/1999/xhtml'
ET.register_namespace('', ns)
ET.register_namespace('xhtml', xhtml)
tree = ET.Element(f'{{{ns}}}urlset')
for paths in PAGES.values():
    for path in paths:
        entry = ET.SubElement(tree, f'{{{ns}}}url')
        ET.SubElement(entry, f'{{{ns}}}loc').text = url(path)
        ET.SubElement(entry, f'{{{ns}}}lastmod').text = '2026-10-31'
        for lang, alternate in zip(('tr', 'en', 'x-default'), (*paths, paths[0])):
            ET.SubElement(entry, f'{{{xhtml}}}link', rel='alternate', hreflang=lang, href=url(alternate))
ET.indent(tree)
ET.ElementTree(tree).write(OUT / 'sitemap.xml', encoding='utf-8', xml_declaration=True)
(OUT / '404.html').write_text(f'''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="robots" content="noindex"><title>Page not found | Virtual Display Manager</title><link rel="stylesheet" href="{url('assets/style.css')}"><main class="article wrap"><h1>Page not found / Sayfa bulunamadı</h1><p>{a(url(), 'Türkçe ana sayfa')} · {a(url('en/'), 'English home')}</p></main></html>''', encoding='utf-8')
print(f'Built {len(PAGES) * 2} crawlable pages in {OUT}')
