# Windows ilk deneme kontrol listesi

Oyun Windows'ta henüz hiç denenmedi. Aşağıdakileri sırayla dene; bir madde tutmazsa ekran görüntüsü ve
kısa bir not yeterli.

## Kurulum
- [ ] `IdleParty-windows` zip'i açıldı, `IdleParty.exe` çift tıkla açılıyor (SmartScreen: Ek bilgi → Yine de çalıştır)
- [ ] Kayıt klasörü oluştu: `%APPDATA%\IdleParty` (Win+R → `%APPDATA%\IdleParty`)

## Pencere ve şerit
- [ ] Başlık ekranı ve giriş hikâyesi ekranın ortasında, arkası karartılmış görünüyor
- [ ] Oyun başlayınca savaş şeridi görev çubuğunun hemen üstünde, arkası **saydam** (masaüstü görünüyor)
- [ ] Şeridin dışındaki boş alana tıklayınca arkadaki pencere/masaüstü tıklanıyor (oyun tıklamayı yutmuyor)
- [ ] Yazılar ve ikonlar keskin; Ayarlar → Ölçek'te ekranına uygun seçenekler var
- [ ] Bir paneli (Kahraman) açıp sürükleyebiliyorsun, kapatma × çalışıyor

## Görev çubuğu modu
- [ ] Kontrol panelindeki "—" düğmesi oyunu görev çubuğunun üzerine küçük bir şerit olarak indiriyor
- [ ] Küçük şerit saatin/sistem tepsisinin üstüne binmiyor; tıklayınca geri açılıyor
- [ ] Sistem tepsisinde Idle Party ikonu var; sağ tık menüsü (Göster / Sessiz / Çıkış) çalışıyor

## Ses ve performans
- [ ] Müzik ve vuruş sesleri geliyor; nota düğmesi sesi kapatıp açıyor
- [ ] Görev Yöneticisi'nde oyun arka plandayken CPU düşük (birkaç %), GPU makul

## Kayıt
- [ ] Oyunu kapatıp açınca ilerleme duruyor; "Sen yokken" penceresi kazanımları gösteriyor

## Bilinen eksikler
- `.exe` dosya ikonu artık oyunun ikonu olmalı; Godot logosu görürsen haber ver.
- Mağaza test modunda: ödeme alınmaz, ürün doğrudan verilir.
- Steam entegrasyonu bu derlemede kapalı.
