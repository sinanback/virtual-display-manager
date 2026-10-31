$script:Strings = @{
    tr = @{
        App='Virtual Display Manager'; Subtitle='Sanal ekran ve fiziksel monitör yönetimi'; Language='English'; Editor='Editör'; Dashboard='Genel bakış'; Activity='Cihaz işlemleri'; Guide='Kullanıcı kılavuzu'
        Checking='Cihaz durumu okunuyor…'; On='SANAL EKRAN AÇIK'; Off='SANAL EKRAN KAPALI'; Missing='SÜRÜCÜ KURULU DEĞİL'; Fault='SÜRÜCÜ DİKKAT GEREKTİRİYOR'; Unknown='DURUM DOĞRULANAMADI'
        Physical='Fiziksel ekran'; Device='Aygıt'; DeviceId='Aygıt kimliği'; ErrorCode='Windows durum kodu'; Updated='Son kontrol'; NoDevice='Sanal ekran sürücüsü bulunamadı.'
        Install='Sürücüyü kur'; Remove='Sürücüyü kaldır'; Enable='Sanal ekranı aç'; Disable='Sanal ekranı kapat'; Refresh='Durumu yenile'; Auto='Fiziksel ekrana göre otomatik aç / kapat'
        AutoHint='Fiziksel ekran varsa VDD kapanır. Son fiziksel ekran söküldüğünde VDD yeniden açılır.'; ManualHint='Elle kontrol açık. Otomatik geçiş için yukarıdaki seçeneği etkinleştirin.'
        Busy='İşlem sürüyor…'; Ready='Hazır'; Query='Durum sorgusu'; Pending='Ekran bağlantısı doğrulanıyor…'; Failure='İşlem tamamlanamadı'; SafeError='Ekran bağlantısı doğrulanamadı. Mevcut aygıt durumu korundu.'
        HideTitle='VDD arka planda çalışmaya devam edecek'; HideBody='Bu pencereyi kapatmak uygulamayı sonlandırmaz. Otomatik ekran kontrolü saat yanındaki VDD simgesinde çalışmaya devam eder.\n\nPencereyi açmak için simgeye çift tıklayın. Tamamen kapatmak için simgeye sağ tıklayın ve “Tamamen çık” seçeneğini kullanın. Simge görünmüyorsa gizli simgeler okuna bakın.'
        Show='Pencereyi aç'; Exit='Tamamen çık'; AutoMenu='Otomatik kontrol'; ExitTitle='Uygulamadan çıkılsın mı?'; ExitBody='Otomatik ekran takibi duracak. VDD mevcut açık/kapalı durumunda kalacak. Devam edilsin mi?'
        DisableTitle='Uzak bağlantı uyarısı'; DisableBody='Fiziksel ekran yokken VDDʼyi kapatmak uzak görüntüyü kesebilir. Devam edilsin mi?'
        RemoveTitle='Sürücüyü kaldır'; RemoveBody='Sanal ekran aygıtı Windowsʼtan kaldırılacak ve otomatik kontrol kapatılacak. Yeniden kullanmak için sürücüyü tekrar kurmanız gerekir. Devam edilsin mi?'
        InstallTitle='Çevrimdışı sürücü kurulumu'; InstallBody='Paket içindeki x64 sürücü ve Microsoft Visual C++ bileşenleri kurulacak. Bu işlem ekran düzenini değiştirebilir. Devam edilsin mi?'
        OfflineMissing='Çevrimdışı sürücü paketi bulunamadı. Tek dosyalı CMD paketini kullanın veya sürücü paketini ayrıca sağlayın.'
        Already='Virtual Display Manager zaten çalışıyor. Saat yanındaki VDD simgesine çift tıklayın.'; Elevation='Uygulama için yönetici izni gerekiyor. Başlatma iptal edildi.'
        Time='Zaman'; Level='Tür'; Operation='İşlem'; Detail='Ayrıntı'; Export='Kayıtları dışa aktar'; OpenLogs='Kayıt klasörünü aç'; LogHint='Yalnızca bu uygulamanın yaptığı işlemler ve gözlediği durum değişimleri kaydedilir. Windows genel etkinlik geçmişi değildir.'
        Info='Bilgi'; Warning='Uyarı'; Error='Hata'; Started='Uygulama başlatıldı.'; Changed='Aygıt durumu değişti'; ModeChanged='Kontrol modu değiştirildi'; AutoEnabled='Otomatik'; AutoDisabled='Elle'; LangChanged='Arayüz dili değiştirildi'; Hidden='Pencere bildirim alanına gizlendi.'; Stopped='Uygulama kapatıldı; otomatik izleme durduruldu.'
        Requested='İşlem başlatıldı'; Completed='İşlem tamamlandı'; AutoReason='Otomatik ekran kuralı'; ManualReason='Kullanıcı isteği'; Reboot='Windows yeniden başlatma istiyor. Lütfen bilgisayarı yeniden başlatın.'; NotVerified='İşlem gönderildi ancak istenen aygıt durumu henüz doğrulanamadı.'; Exported='Kayıt dosyası kaydedildi.'; SavingError='Ayar veya kayıt dosyası yazılamadı.'
        GuideText=@'
Virtual Display Manager · Kullanıcı kılavuzu

1. Amaç ve gereksinimler
Uygulama Virtual Display Driver aygıtını yönetir. Windows 10/11 x64, Windows PowerShell 5.1 ve yönetici izni gerektirir. EXE kurulmaz. PowerShell arka planda çalışır; kalıcı Terminal penceresi açılmaz.

2. Başlatma ve bildirim alanı
CMD dosyasını çalıştırın ve Windows yönetici iznini onaylayın. Ana pencere açılır. Çarpı veya küçültme düğmesi pencereyi saat yanındaki simgeye gizler; izleme devam eder. Simgeye çift tıklayarak pencereyi açın. Tamamen kapatmak için simgeye sağ tıklayın → Tamamen çık. Windows simgeyi gizli simgeler bölümüne taşıyabilir.

3. Otomatik ekran kontrolü
Otomatik modda aktif fiziksel ekran varsa VDD kapatılır; son fiziksel ekran söküldüğünde yeniden açılır. Dahili dizüstü ekranı da fiziksel ekran sayılır. İki ardışık kontrol ve işlem öncesi son doğrulama bağlantı dalgalanmalarını azaltır. Normal tepki süresi yaklaşık 3–6 saniyedir; Windows aygıt geçişi süreyi uzatabilir. Algılama hatasında mevcut durum korunur ve uyarı gösterilir. Uyku/uyanma sonrası kontrol devam eder.

4. Elle kontrol
Otomatik kontrol kutusunu kapatın, ardından Sanal ekranı aç/kapat düğmelerini kullanın. Fiziksel ekran bulunmadığında VDDʼyi elle kapatmak uzak bağlantınızı kesebilir. İkinci erişim kanalınız olduğundan emin olun.

5. Sürücü kurulumu ve kaldırma
Tek dosyalı pakette sürücü, devcon ve Visual C++ bileşenleri bulunur. Kurulum yalnızca Sürücüyü kur düğmesiyle başlar; açılışta paket diske çıkarılmaz. Sürücüyü kaldır, aygıtı kaldırır ve otomatik modu kapatır. Windows sürücü deposundaki paket kalabilir. Yeniden başlatma gerekirse bildirim gösterilir.

6. Simge renkleri
Yeşil: VDD açık. Gri: kapalı veya kurulu değil. Turuncu: aygıt/algılama hatası. Simgenin üzerine gelerek kısa durumu okuyun. Görev çubuğunda kalıcı PowerShell/Terminal penceresi bulunmaz.

7. Dil, kayıtlar ve gizlilik
Sağ üstteki dil düğmesi Türkçe ve İngilizce arasında geçiş yapar; seçim sonraki açılış için saklanır. Cihaz işlemleri sekmesi, uygulamanın başlattığı işlemleri ve algılanan değişimleri gösterir. Kayıtlar yalnızca bu bilgisayarda %LOCALAPPDATA%\VDD-Yonetici altında tutulur. Uygulama telemetri göndermez. JSONL dışa aktarımında zamanlar UTC, ayrıntılar ve aygıt kimlikleri bulunabilir; paylaşmadan önce inceleyin.

8. Sorun giderme
Durumu yenile düğmesini kullanın. Uyarı sürerse Cihaz işlemleri sekmesindeki teknik ayrıntıyı ve Windows Aygıt Yöneticisi durumunu kontrol edin. Uygulama bu sürümde Windows açılışına otomatik eklenmez; her oturumda bir kez başlatın. Çıkış yapmak VDD durumunu değiştirmez.
'@
    }
    en = @{
        App='Virtual Display Manager'; Subtitle='Virtual display and physical monitor management'; Language='Türkçe'; Editor='Editor'; Dashboard='Overview'; Activity='Device activity'; Guide='User guide'
        Checking='Reading device status…'; On='VIRTUAL DISPLAY ENABLED'; Off='VIRTUAL DISPLAY DISABLED'; Missing='DRIVER NOT INSTALLED'; Fault='DRIVER NEEDS ATTENTION'; Unknown='STATUS UNAVAILABLE'
        Physical='Physical displays'; Device='Device'; DeviceId='Device instance ID'; ErrorCode='Windows status code'; Updated='Last checked'; NoDevice='Virtual display driver not found.'
        Install='Install driver'; Remove='Uninstall driver'; Enable='Enable virtual display'; Disable='Disable virtual display'; Refresh='Refresh status'; Auto='Automatically switch based on physical displays'
        AutoHint='VDD is disabled while a physical display is active and enabled when the last physical display is disconnected.'; ManualHint='Manual control is active. Enable the option above to resume automatic switching.'
        Busy='Operation in progress…'; Ready='Ready'; Query='Status query'; Pending='Confirming display connection…'; Failure='Operation could not be completed'; SafeError='The display connection could not be verified. The current device state was preserved.'
        HideTitle='VDD will keep running in the background'; HideBody='Closing this window does not exit the application. Automatic display monitoring continues through the VDD icon next to the clock.\n\nDouble-click the icon to reopen the window. To exit completely, right-click the icon and select “Exit application”. If the icon is not visible, check the hidden icons menu.'
        Show='Open window'; Exit='Exit application'; AutoMenu='Automatic control'; ExitTitle='Exit the application?'; ExitBody='Automatic monitoring will stop. VDD will keep its current enabled/disabled state. Continue?'
        DisableTitle='Remote connection warning'; DisableBody='Disabling VDD without a physical display may interrupt your remote session. Continue?'
        RemoveTitle='Uninstall driver'; RemoveBody='The virtual display device will be removed from Windows and automatic control will be turned off. Reinstall the driver to use it again. Continue?'
        InstallTitle='Offline driver installation'; InstallBody='The bundled x64 driver and Microsoft Visual C++ components will be installed. This may change your display arrangement. Continue?'
        OfflineMissing='The offline driver bundle is unavailable. Use the single-file CMD package or supply the driver bundle separately.'
        Already='Virtual Display Manager is already running. Double-click the VDD icon next to the clock.'; Elevation='Administrator permission is required. Startup was cancelled.'
        Time='Time'; Level='Type'; Operation='Operation'; Detail='Details'; Export='Export activity'; OpenLogs='Open log folder'; LogHint='Only actions initiated by this application and observed device changes are recorded. This is not a complete Windows activity history.'
        Info='Information'; Warning='Warning'; Error='Error'; Started='Application started.'; Changed='Device status changed'; ModeChanged='Control mode changed'; AutoEnabled='Automatic'; AutoDisabled='Manual'; LangChanged='Interface language changed'; Hidden='Window hidden to the notification area.'; Stopped='Application closed; automatic monitoring stopped.'
        Requested='Operation started'; Completed='Operation completed'; AutoReason='Automatic display rule'; ManualReason='User request'; Reboot='Windows requires a restart. Please restart the computer.'; NotVerified='The command was submitted, but the requested device state has not yet been verified.'; Exported='Activity file saved.'; SavingError='The settings or activity file could not be written.'
        GuideText=@'
Virtual Display Manager · User guide

1. Purpose and requirements
This application manages Virtual Display Driver. It requires Windows 10/11 x64, Windows PowerShell 5.1 and administrator permission. No application EXE is installed. PowerShell runs in the background without a persistent Terminal window.

2. Starting and using the notification area
Run the CMD file and approve the Windows administrator prompt. The main window opens. The close or minimize button hides it to the VDD icon next to the clock; monitoring continues. Double-click the icon to reopen it. To exit completely, right-click the icon → Exit application. Windows may place the icon in the hidden icons menu.

3. Automatic display control
While an active physical display is present, VDD is disabled. When the last physical display is disconnected, VDD is enabled again. A laptop's built-in panel also counts as a physical display. Two consecutive samples and a final check before switching reduce connection flicker. Typical response time is around 3–6 seconds; Windows device transitions may take longer. Detection failures preserve the current state and display a warning. Monitoring continues after sleep/resume.

4. Manual control
Clear the automatic control checkbox, then use Enable/Disable virtual display. Disabling VDD without a physical display can interrupt remote access. Make sure you have another access channel.

5. Installing and uninstalling the driver
The single-file package includes the driver, devcon and Visual C++ components. Installation starts only when you choose Install driver. The driver bundle is not extracted at startup. Uninstall driver removes the device and disables automatic control. A copy of the driver package may remain in the Windows driver store. A restart notice is shown when Windows requests it.

6. Icon colors
Green: VDD enabled. Gray: disabled or not installed. Orange: device or detection error. Hover over the icon for a short status message. No persistent PowerShell/Terminal taskbar window is required.

7. Language, activity and privacy
The language button in the upper-right switches between Turkish and English; the choice is saved for the next launch. Device activity lists application actions and observed changes. Logs stay on this computer under %LOCALAPPDATA%\VDD-Yonetici. The application sends no telemetry. JSONL exports contain UTC timestamps and may include technical details and device identifiers; review them before sharing.

8. Troubleshooting
Choose Refresh status. If a warning remains, inspect the technical details in Device activity and the device status in Windows Device Manager. This version does not register itself to start with Windows; launch it once per session. Exiting does not change the current VDD state.
'@
    }
}
