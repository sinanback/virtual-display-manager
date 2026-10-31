# Changelog

## 2.0.0

### Türkçe

- Kalıcı Türkçe/İngilizce dil seçimi; arayüz, uyarılar, simge menüsü ve kullanıcı kılavuzu için eşleşen çeviriler.
- Genel bakış, cihaz işlemleri ve kullanıcı kılavuzu sekmeleri.
- Açılışta görünen ana pencere; çarpı ile açıklama göstererek bildirim alanına gizleme, simgeden geri açma ve açık bir tam çıkış seçeneği.
- Yerel, dönen JSONL işlem kaydı ve son 500 kaydı dışa aktarma.
- Yeniden kullanılan arka plan çalışma alanında aygıt sorguları; arayüzde engelleyici WMI/PnP beklemesi kaldırıldı.
- Büyük sürücü paketinin açılışta çıkarılması kaldırıldı; kurulum onayına kadar paket yalnızca CMD içinde tutulur.
- Sağlıklı/kapalı aygıt durumları, hata koruması, iki örnekli bağlantı doğrulaması ve işlem öncesi son kontrol.
- EXE gerektirmeyen, konsol oluşturmayan CMD başlatıcıları; kaynak derleme betiği, testler ve SHA-256 listesi.

### English

- Persistent Turkish/English language selection with matching UI, prompts, tray menus and user manuals.
- Overview, device activity and user guide tabs.
- Visible main window on launch; an explanatory close-to-tray prompt, tray restore and an explicit full-exit action.
- Local rotating JSONL activity logs and export of the latest 500 records.
- Reusable background runspace for hardware queries; WMI/PnP work no longer blocks the interface.
- Lazy extraction of the offline driver bundle only after installation is confirmed.
- Explicit healthy/disabled device handling, safe detection failures, two-sample debounce and a final pre-mutation connection check.
- Console-free CMD launchers without an application EXE, source build script, automated checks and SHA-256 manifest.

