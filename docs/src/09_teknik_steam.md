\pagebreak

# 21. Performans, Optimizasyon ve Ayarlar

## 21.1 Performans Bütçesi (Zorunlu)

| Metrik | Hedef (Widget modu, odak dışı) | Hedef (Tam mod, odakta) | Ölçüm |
|---|---|---|---|
| CPU | < %2 (4 çekirdek i5 8. nesil) | < %8 | Windows Görev Yöneticisi, 10 dk ortalama |
| GPU | < %3 | < %10 (entegre GPU'da) | |
| RAM | < 250 MB | < 350 MB | |
| FPS | 15 (odak dışı), 0 (gizli) | 60 | |
| Açılış süresi | < 3 sn (SSD) | | |
| Kurulum boyutu | < 300 MB | | |
| Pil (laptop) | Saatte < %3 ek tüketim | | |

## 21.2 Optimizasyon Teknikleri

- **Düşük işlemci modu:** `OS.low_processor_usage_mode = true` odak dışındayken; ekran sadece değişiklik olduğunda yeniden çizilir.
- **Dinamik FPS:** `Engine.max_fps` odak durumuna göre 60 / 15 / gizliyken render kapalı (`RenderingServer.render_loop_enabled = false`), simülasyon `Timer` ile devam.
- **Simülasyon ve render ayrımı:** Savaş mantığı 10 tick/sn; görsel interpolasyon.
- **Nesne havuzları:** Hasar rakamları, mermiler, VFX, düşen itemler, düşmanlar havuzlanır (oyun içinde `instantiate()` yok).
- **Texture atlasları:** Tüm UI ve item ikonları atlas; draw call < 100.
- **Parçacıklar:** `CPUParticles2D` (GL Compatibility uyumlu), max 40 parçacık / sistem; odak dışında parçacıklar yarı yoğunlukta.
- **Envanter UI:** Görünmeyen slotlar render edilmez; tooltip tek instance.
- **Kayıt:** Ana thread'i bloklamayan arka plan thread'inde JSON yazma.
- **Bellek:** Kullanılmayan perde arka planları ve müzikleri bölge değişiminde boşaltılır (ResourceLoader cache temizliği).
- **Profil testi:** Her milestone sonunda 8 saatlik "soak test": bellek sızıntısı olmamalı (RAM artışı < %5).

## 21.3 Ayarlar Menüsü

| Kategori | Ayarlar |
|---|---|
| Ekran | Ölçek (1x/2x/3x/4x), Şerit konumu (Alt/Üst/Serbest), Monitör seçimi, Her zaman üstte, Tam ekran uygulamada gizle, Şerit şeffaflığı (%50-100), Arka plan gizle (sadece karakterler) |
| Performans | Odakta FPS (30/60/144), Odak dışı FPS (5/10/15/30), Parçacık yoğunluğu, Hasar rakamları, Işık efektleri |
| Ses | Genel, Müzik, SFX, Odak dışı ses azaltma %, Kahraman sesleri, Sessiz başlat |
| Oynanış | AUTO ilerleme, Otomatik kuşanma, Ganimet filtresi, Boss'ta duraklat, Kahraman konuşma sıklığı, Bildirim türleri |
| Sistem | Windows ile başlat, Tepsiye küçült, Patron tuşu, Dil, Bulut kaydı, Kayıt yedekleri (Dışa/İçe aktar) |
| Erişilebilirlik | Renk körü modu, Yazı boyutu, Ekran sarsıntısı, Yanıp sönme azaltma, Yüksek kontrast UI |

## 21.4 Platform Notları

- **Windows:** Taskbar konumu `SHAppBarMessage(ABM_GETTASKBARPOS)` (GDExtension küçük C++ modülü veya `OS.execute` olmadan çözüm için Godot `DisplayServer.screen_get_usable_rect()` farkından hesaplanır). Tam ekran uygulama algılama: `SHQueryUserNotificationState` (QUNS_BUSY / QUNS_RUNNING_D3D_FULL_SCREEN).
- **macOS:** Dock'un üstü; menü çubuğu ikonu. Şeffaf pencere desteklenir.
- **Linux / Steam Deck:** Wayland'da always-on-top kısıtlı; Steam Deck'te "Tam Mod" varsayılan, kontrolcü desteği (D-pad ile panel navigasyonu).

\pagebreak

# 22. Steam Entegrasyonu ve Yayın

## 22.1 Steamworks Özellikleri

- **GodotSteam** (GDExtension). `SteamService` Steam kapalıysa sessizce devre dışı (DRM-free build mümkün).
- Steam Cloud (Auto-Cloud: `%APPDATA%/Godot/app_userdata/IdleParty/saves/*`).
- Rich Presence: "Perde 2 - Donmuş Göl (Kabus) - Lv 63".
- Başarımlar (60), İstatistikler (toplam öldürme, efsanevi sayısı, kule katı).
- Liderlik Tabloları: Kule (haftalık + tüm zamanlar), Dünya Boss'u hasarı, Yarık anahtar seviyesi.
- Steam Trading Cards (lansmandan sonra, 8 kart: 8 sınıf), rozet, profil arka planları, emoji.
- Steam Deck: "Playable" hedefi.

## 22.2 Başarım Listesi (Seçki)

| ID | Ad | Koşul |
|---|---|---|
| ACH_FIRST_BLOOD | İlk Kan | İlk düşmanı öldür |
| ACH_FULL_PARTY | Tam Kadro | 5 kahramanlık partiyi tamamla |
| ACH_GOBLIN_KING | Taç Kimin? | Goblin Kralı'nı yen |
| ACH_ICE_WITCH | Bahar Geldi | Buz Cadısı Isolde'yi yen |
| ACH_TRAITOR | İhanet | Corvus'u yen |
| ACH_MORVATH | Kristal Kurtarıldı | Normal'de Morvath'ı yen |
| ACH_NIGHTMARE | Kâbuslardan Uyan | Kabus zorluğunu bitir |
| ACH_HELL | Cehennemden Dönen | Cehennem'i bitir |
| ACH_LV100 | Efsane | Bir kahramanı Lv 100 yap |
| ACH_FIRST_LEGENDARY | Turuncu Işık | İlk efsanevi itemini bul |
| ACH_FIRST_MYTHIC | İmkânsız Şans | İlk mitik itemini bul |
| ACH_SET_COMPLETE | Tam Takım | Bir seti 6/6 tamamla |
| ACH_ENHANCE_15 | Mükemmeliyet | Bir itemi +15 yap |
| ACH_COMBINE_PITY | Israrcı | Merhamet sayacıyla garantili birleştirme yap |
| ACH_FACTION_FULL | Sadakat | Bir fraksiyonu 8/8 tamamla |
| ACH_ALL_HEROES | Lonca Efsanesi | 48 kahramanın hepsini topla |
| ACH_6STAR | Altı Yıldız | Bir kahramanı 6 yıldız yap |
| ACH_TOWER_50 / 100 / 200 | Kule Tırmanıcısı I/II/III | Kule katı |
| ACH_RIFT_50 / 100 | Yarık Yürüyücüsü I/II | Yarık seviyesi |
| ACH_KILLS_10K / 100K / 1M | Katliam I/II/III | Toplam öldürme |
| ACH_GOLD_1M / 1B | Hazine I/II | Toplam altın |
| ACH_OFFLINE_12H | Uyuyan Lonca | 12 saatlik offline ödülü topla |
| ACH_NIGHT_OWL | Gece Kuşu | Gece saatlerinde 1 saat oyna |
| ACH_TREASURE_GOBLIN | Yakaladım! | Hazine Goblinini öldür |
| ACH_MOON_RABBIT | Ay Tavşanı | Ay Tavşanını yakala |
| ACH_BONBON | Bonbon'un Dostu | Vex ile 1000 iskelet çağır |
| ACH_NO_DEATH_BOSS | Kusursuz | Bir Perde boss'unu kimse ölmeden yen |
| ACH_PARAGON_100 | Sonsuzluk | Paragon 100 |

> İçerik AI notu: Toplam 60 başarım hedefle; aynı formatta tamamla (sınıf başına 2 adet "skill ustalığı" başarımı ekle).

## 22.3 Steam Mağaza Sayfası Varlıkları

| Varlık | Boyut | İçerik önerisi |
|---|---|---|
| Header Capsule | 920x430 | Logo + 5 kahraman koşarken (referans afiş tarzı) |
| Small Capsule | 462x174 | Sadece logo + 2 kahraman, okunaklı |
| Main Capsule | 1232x706 | Büyük kahraman ilüstrasyonu (yüksek detay pixel) + logo |
| Vertical Capsule | 748x896 | Dikey kompozisyon |
| Library Capsule | 600x900 | |
| Library Hero | 3840x1240 | Logo olmadan panorama |
| Library Logo | 1280x720 (şeffaf PNG) | |
| Ekran görüntüleri | 1920x1080 x 8 | 1) Masaüstünde şerit + gerçek masaüstü (Excel/kod editörü açık) — türü anlatan ana görsel; 2) 3 panel açık (Stat/Kahraman/Portre); 3) Envanter/Depo/Demirci; 4) Dünya haritası; 5) Boss savaşı; 6) Fraksiyon koleksiyonu; 7) Efsanevi drop anı; 8) Gece bölgesi |
| Fragman | 60-90 sn | İlk 5 sn: masaüstünde çalışan biri, alt kısımda şerit (konsepti anında anlat). Sonra özellikler hızlı kurgu. |

**Kısa açıklama (EN):** "Your party of five heroes fights, loots and grows on a tiny strip above your taskbar while you work. Open the menus anytime to master gear, skills and 48 collectible heroes."

**Etiketler:** Idler, RPG, Pixel Graphics, Cute, Loot, Auto Battler, Desktop Companion (varsa), Casual, Singleplayer, Fantasy, Character Customization, Hack and Slash, Relaxing.

## 22.4 Yayın Stratejisi

1. **Mağaza sayfası** erken açılır (geliştirmenin ~%40'ında) → wishlist toplama.
2. **Demo** (Perde 1, Lv 1-15, ilerleme tam oyuna aktarılır) → **Steam Next Fest**'e katılım.
3. Reddit (r/incremental_games, r/pixelart, r/IndieGaming), TikTok/YouTube Shorts: "Çalışırken oynanan oyun" kısa videoları.
4. Tür yayıncılarına ve idle oyun YouTuber'larına key gönderimi.
5. Lansman: %10-15 lansman indirimi, ilk 2 haftada 1 içerik yaması (QoL), 2. ayda ücretsiz "Perde 5" güncellemesi yol haritası duyurusu.
6. Supporter Pack DLC (2.99 USD): 6 kostüm + dijital artbook + OST.

## 22.5 Yasal ve Telif Notları

- Oyun adı ve karakter isimleri için ticari marka araştırması yap (Steam ve EUIPO/USPTO). "IDLE PARTY" çalışma adıdır.
- Hiçbir asset referans oyunlardan kopyalanmaz; tüm sanat ve müzik orijinal veya ticari lisanslı olmalı. AI ile üretilen sanat kullanılıyorsa Steam'in "AI Generated Content" beyan formunu doldur.
- Fontlar OFL lisanslı olmalı; lisans dosyaları `credits/` klasöründe.
