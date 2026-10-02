\pagebreak

# 20. Arayüz (UI/UX), Açılış Sekansı ve Oyun Akışı

## 20.1 Savaş Şeridi HUD Yerleşimi (Mantıksal 320x70 + Kontrol Paneli 48x70)

```
+--------------------------------------------------------------------------------------+---------+
| [Bölge: Sisli Orman Yolu 1-6]        [Boss Zamanlayıcı 0:42]           [Sandık(!)]   | P S M Q |
| (o) Kasaba                                                                            | [Kahrmn]|
| (o) DPS     [PET][K1][K2][K3][K4][K5] ---->   [D][D][D][E]                [Portal]     | [Çanta] |
| (o) AUTO    ===== Parti HP barı =====          (hasar sayıları)                        | [Gelişm]|
|                                                                                        | [Dünya] |
| [XP barı - ince 2px, şeridin en altında]                                              |   [≡]   |
+--------------------------------------------------------------------------------------+---------+
```

- Sol butonlar (yuvarlak, 12x12): Kasaba (kırmızı), DPS/istatistik (yeşil), AUTO (mavi; açıkken döner animasyon).
- Kontrol paneli 2x2 buton ızgarası: **Kahraman / Çanta / Gelişim / Dünya** + üstte küçük ikonlar (Güç = Duraklat/Çıkış, Ayarlar, Posta/Bildirim, Görevler, Ses) + "≡" ek menü (Taverna, Kodeks, Başarımlar, Kostüm, Lonca Salonu).
- Bildirim noktaları: Butonlarda yeni içerik varsa küçük kırmızı/mavi nokta (ör. dağıtılmamış stat puanı).

## 20.2 Panel Listesi

| Panel | Açılış Kısayolu | Boyut | İçerik |
|---|---|---|---|
| Kahraman | H | Orta | Skill / Kostüm sekmeleri, skill ızgarası, parti şeridi (alt kısımda 5 kahraman portresi ile geçiş) |
| Statlar | C | Küçük | 4 sekme (Tümü/Saldırı/Savunma/Diğer), +/- stat dağıtma, Otomatik |
| Portre | (Kahraman ile açılır) | Küçük | Vitray önünde tam boy kahraman, Level, XP barı, ad, sınıf, yıldız |
| Envanter (Çanta) | I / B | Orta | Ekipman ızgarası (12 slot) + iksir slotları + filtreler (Tümü/Silah/Zırh/Kask/Takı/Malzeme) + 60-120 slot + Depo/Demirci/Kule/Takas kısayolları |
| Depo | (Envanterden) | Orta | 7 sekme, 6x6 |
| Demirci | (Kasaba/Envanter) | Orta | Birleştir/Sat/Üret/Güçlendir/Sök |
| Dünya | M | Geniş | Harita, zorluk, perdeler |
| Gelişim | G | Geniş | Lonca Salonu, Fraksiyon, Paragon, Kodeks sekmeleri |
| Taverna | T | Orta | Kahraman teklifleri, kahraman yıldız yükseltme |
| Görevler | J | Küçük | Hikaye, günlük, haftalık |
| Ayarlar | Esc | Orta | Bölüm 21.3 |
| DPS İstatistik | D | Küçük | Kahraman başına hasar payı (bar grafik), son 5 dk öldürme/dk, XP/saat, altın/saat |
| Sen Yokken | otomatik | Orta | Offline özeti |

## 20.3 Etkileşim Kuralları

- **Sürükle-bırak:** Item sürükleme, slotlar arası; sağ tık = hızlı kuşan / depoya at; Shift+sağ tık = sat; Ctrl+tık = kilitle (kilitli item asla satılmaz/sökülmez/birleştirilmez).
- **Tooltip:** 0.25 sn gecikme; Shift basılıyken kuşanılmışla karşılaştırma; Alt basılıyken affix aralıklarını ve kademelerini göster (T1-T7).
- **Bildirim kuyruğu:** Sağ alt köşede, max 3 bildirim, 4 sn.
- **Klavye:** Tüm paneller kısayol ile açılır/kapanır; Esc açık en üst paneli kapatır.
- **Erişilebilirlik:** Renk körü modu (nadirlik rengine ek ikon/şekil), UI ölçeği, yazı boyutu (pixel font 1x/2x), ekran sarsıntısı kapatma, yanıp sönme azaltma.

## 20.4 Açılış Sekansı (İlk Çalıştırma, Saniye Saniye)

| Zaman | Ne olur | Teknik not |
|---|---|---|
| 0.0 sn | Kenarlıksız küçük açılış penceresi ekranın ortasında (480x270): Stüdyo logosu pixel animasyonu (1.5 sn) | Ses: tek "ding" |
| 1.5 sn | Godot/"Made with" logosu (0.8 sn, atlanabilir) | |
| 2.5 sn | **Başlık ekranı**: Aynı pencerede, gece gökyüzü, uzakta kale, ön planda kamp ateşi etrafında 3 kahraman (Kael, Lyra, Pip) idle animasyonla oturuyor. Logo yukarıdan düşer (bounce). Müzik: ana tema (lavta + flüt). | Logo: "IDLE PARTY" büyük pixel yazı, altında "Desktop Legends" |
| | Butonlar: **Yeni Oyun / Devam Et / Ayarlar / Çıkış** | |
| Yeni Oyun | **Pencere Yerleşim Sihirbazı** (tek ekran): "Partin nerede yaşasın?" 3 seçenek kartı: (1) Görev çubuğunun üstü [önerilen], (2) Ekranın üstü, (3) Serbest. Ölçek seçimi 1x/2x/3x canlı önizleme. "Her zaman üstte" kutucuğu. | Taskbar algılama burada çalışır |
| +0 | **Giriş Ara Sahnesi** (5 panel, her biri 3 sn, tıklayınca geçer, "Atla" butonu): 1) Parlayan Dünya Kristali. 2) Morvath'ın gölgesi kristali kırar. 3) Parçalar dört diyara dağılır. 4) Taşköprü kasabası, boş bir lonca binası, "Satılık" tabelası. 5) Oyuncunun (görünmeyen) eli tabelayı "Gezgin Lonca" olarak değiştirir; Kael kapıyı çalar. | Pixel art paneller 320x180 |
| +15 sn | Başlık penceresi küçülerek **şerit** haline dönüşür ve seçilen konuma "kayar" (0.6 sn animasyon). Bu an oyunun imza anı: oyuncu konsepti hemen anlar. | Pencere tween'i |
| +16 sn | Şeritte Kael tek başına koşmaya başlar. Konuşma balonu: "Lonca kurmuşsun ha? İlk işimiz: şu slime'lar!" | |
| +20 sn | İlk dalga (3 Yeşil Slime). Tutorial oku: "Kahramanlar kendi kendine savaşır. Sen sadece güçlendir!" | Tutorial balonu kapatılabilir |
| +45 sn | İlk item düşer (garantili Büyülü kılıç). Sandık ikonu zıplar. Tutorial: "Sandığa tıkla!" → Envanter paneli şeridin üstünde açılır. Kuşan oku. | İlk panel açılışı: Tam mod öğretilir |
| +1:30 | Level 2: Stat puanı tutorial'ı (Stat paneli). "Otomatik Dağıt" butonu gösterilir. | |
| +2:30 | Lyra katılır (ara diyalog: ağaçtan iner, slime'ı vurur). Parti 2 kişi. | |
| +4:00 | Level 3: İlk skill puanı. Kahraman paneli tutorial'ı. Kael'e "Kalkan Darbesi" öğretilir ve kuşanılır. | |
| +5:00 | Pip katılır (yanlışlıkla iyileştirme büyüsü yerine şimşek atar - komik an). Parti 3. | |
| +6:00 | Bölge 1 Boss: Dev Slime. Boss uyarısı ve zamanlayıcı tutorial'ı. Yenilince ikiye bölünür (küçük sürpriz). | |
| +8:00 | Bölge 2 açılır. Dünya haritası tutorial'ı (Dünya butonu yanıp söner). AUTO butonu tanıtılır: "AUTO açıkken parti kendi ilerler." | |
| +10:00 | Tutorial biter. Son mesaj: "Artık işine dönebilirsin. Biz buradayız!" — Bu cümle oyunun felsefesidir. Şerit kendi kendine devam eder. | Patron Tuşu ipucu bildirimi |

## 20.5 Özellik Açılış Zaman Çizelgesi

Özellikler kademeli açılır ki oyuncu boğulmasın. Kilitli butonlar gri + kilit ikonu + "Lv X'te açılır" tooltip.

| Level / Olay | Açılan |
|---|---|
| Lv 1 | Şerit, Envanter, Statlar, Kahraman paneli |
| Lv 2 | Stat dağıtımı |
| Lv 3 | Skill sistemi |
| Lv 3 | Tüccar |
| Lv 5 | Demirci (Sat, Birleştir) |
| Lv 6 | Nova katılır (4. kahraman) |
| Lv 8 | Taverna (5. slot açılır: ilk kahramanı oyuncu seçer, 3 R kahramandan biri) |
| Lv 10 | Görevler (günlük), Depo sekme 2 satın alınabilir, AUTO otomatik ilerleme |
| Lv 12 | Bjorn katılır (yedek), Fraksiyon koleksiyonu |
| Lv 15 | Güçlendirme +1~+9, Ganimet filtresi |
| Lv 18 | Evcil hayvanlar (ilk yumurta Perde 1 Boss'tan) |
| Lv 20 | Lonca Salonu, Finn katılır |
| Lv 25 | Kuyumcu (gemler), Destansı birleştirme |
| Lv 30 | 1. Sınıf İlerlemesi (Kâhin görevi: kahraman başına küçük bir boss sınavı) |
| Lv 35 | Üretim (Craft) |
| Lv 40 | Güçlendirme +10~+12 |
| Lv 50 (Normal bitti) | Kabus zorluğu, Sonsuz Kule |
| Lv 60 | Efsanevi birleştirme, Kostüm koleksiyonu |
| Lv 70 | 2. Sınıf İlerlemesi (uzmanlık seçimi), Yarıklar |
| Lv 75 (Kabus bitti) | Cehennem zorluğu, Mitik dropları |
| Lv 85 | +13~+15 güçlendirme |
| Lv 100 | Paragon, Dünya Boss'u liderlik tablosu |

## 20.6 Oyunun Başı, Ortası, Sonu (Deneyim Tasarımı)

### Başlangıç (0-3 saat): "Merak ve hızlı ödül"

- Her 2-5 dakikada yeni bir şey: kahraman katılımı, yeni panel, yeni bölge.
- Level hızlı (ilk 10 level 25 dk).
- Bossları kolay, kazanma garantili; ilk efsanevi item Perde 1 Boss'tan **garantili** ("Goblin Şefinin Tacı").
- Duygusal hedef: "Bu küçük partiyi sevdim."

### Orta Oyun (3-25 saat): "Build ve strateji"

- Sınıf ilerlemeleri, set parçaları, demirci ekonomisi ve kahraman koleksiyonu devreye girer.
- Bosslar artık build kontrolü ister (Buz Cadısı: ateş/soğuk direnci).
- Oyuncu günde birkaç kez göz atar: "Sen Yokken" penceresi + 5 dakikalık düzenleme.
- Hikaye: Perde 3 ihanet twisti ve Perde 4 finali; **Normal zorluk sonu: Morvath'ın yenilmesi ve "Yansıma Dünyası"nın açılması** (büyük ara sahne, jenerik kısaltması).

### Geç Oyun (25-60 saat): "Ustalık"

- Kabus/Cehennem: aynı dünyanın karanlık versiyonları, yeni boss mekanikleri (bosslara 1 ek mekanik eklenir).
- 2. ilerleme uzmanlıkları, 6 parçalı setler, gemler.
- Cehennem Perde 4 sonu = **Gerçek Final:** Morvath'ın arkasındaki gerçek kötü "Boşluk Annesi" ortaya çıkar; yenildiğinde kristal saflaşır, final ara sahnesi (tüm toplanan kahramanlar kasabada şölende — oyuncunun koleksiyonuna göre dinamik sahne!).

### Endgame (60+ saat): "Sonsuz hedefler"

- Kule, Yarıklar, Paragon, Mitik itemler, 48 kahramanı 6 yıldıza çıkarma, kodeks tamamlama, liderlik tabloları, sezonlar.

## 20.7 Ses Tasarımı

| Müzik Parçası | Kullanım | Süre / Stil |
|---|---|---|
| Ana Tema "Gezgin Lonca" | Başlık | 2:30, lavta + flüt + yaylılar, chiptune katmanı |
| Taşköprü | Kasaba | 3:00 loop, sıcak, akustik |
| Sisli Orman | Perde 1 | 3:00 loop, hafif ve neşeli |
| Donmuş Zirveler | Perde 2 | Çan ve rüzgâr |
| Yanık Çöller | Perde 3 | Darbuka, ud, ney renkleri |
| Uçurum Kapısı | Perde 4 | Koyu koro, org |
| Boss Teması x2 | Boss savaşları | Hızlı tempo |
| Morvath Final | Final | Epik, 3 faz geçişli |
| Kule / Yarık | Endgame | Elektronik-chiptune hibrit |
| Gece Varyantı | Her perdede | Aynı melodinin yumuşak gece versiyonu |

- **Odak modu:** Pencere odakta değilken müzik -%60, SFX -%80 (ayarlanabilir). Varsayılan genel ses %40.
- SFX listesi (min. 80 adet): vuruşlar (her silah türü 3 varyant), büyüler (her element), item drop (nadirlik başına ayrı; efsanevi drop sesi imza ses olmalı), level up, UI tıklama/hover/açma/kapama, altın, birleştirme başarı/başarısızlık, boss uyarı, ölüm, diriliş, kahraman "hmm/ha!" vokal blipleri (kelime yok, Animal Crossing tarzı ses blipleri).
- Ses tekrarını önlemek için pitch varyasyonu ±%8 ve aynı ses için 60 ms limit.

## 20.8 Lokalizasyon

- Lansman dilleri: **İngilizce, Türkçe**, Basitleştirilmiş Çince, Japonca, Korece, Almanca, Fransızca, İspanyolca, Portekizce (BR), Rusça. (Bu tür Asya'da çok güçlü; CJK pixel font desteği kritik.)
- Tüm metinler `localization/*.csv` anahtarlarıyla. Sayı formatları yerel ayara göre.

## 20.9 Yayıncı (Streamer) Modu

- Şerit için yeşil ekran (chroma key) arka plan seçeneği, OBS'de kolay kesim.
- Telif güvenli müzik garantisi (tüm müzik orijinal).
- Opsiyonel: Twitch sohbet entegrasyonu (lansman sonrası): izleyiciler "!heal" ile Rahibe'yi tetikleyebilir.
