\pagebreak

# 15. Ekipman Sistemi

## 15.1 Ekipman Slotları (Kahraman başına 12)

Referans "Inventory" panelinin üstündeki ekipman ızgarası gibi:

| Slot | Örnek | Ana stat (implicit) |
|---|---|---|
| Ana El (Silah) | Kılıç, yay, asa | Silah Hasarı (Saldırı), APS |
| Yan El | Kalkan, ok kılıfı, küre, kutsal kitap | Blok / Kritik / Büyü Gücü |
| Kask | Miğfer, başlık, şapka | Savunma, HP |
| Gövde | Zırh, ceket, cübbe | Savunma, HP |
| Eldiven | | Savunma + Saldırı Hızı şansı |
| Bot | | Savunma + Hareket Hızı |
| Kemer | | HP, Yan iksir kapasitesi |
| Pelerin | | Kaçınma / Direnç |
| Kolye | | Rastgele güçlü stat |
| Yüzük x2 | | Rastgele stat |
| Tılsım | Rün, kutsal emanet | Benzersiz pasif (sadece Destansı+) |

İki özel "Hızlı Kullanım" slotu: otomatik iksirler (HP %35 altına düşünce içilir; bekleme süreleri envanterde "4.4s" gibi görünür).

## 15.2 Item Nadirliği ve Affix Sayısı

| Nadirlik | Affix | Drop oranı (taban) | Satış (altın çarpanı) | Not |
|---|---|---|---|---|
| Sıradan | 0 | %70 | x1 | Sadece taban stat |
| Büyülü | 1-2 | %22 | x3 | |
| Nadir | 3-4 | %6.5 | x8 | |
| Destansı | 4-5 | %1.2 | x20 | 1 soket şansı |
| Efsanevi | 4 + benzersiz etki | %0.25 | x50 | Sabit isimli, özel etki |
| Set | 3 + set bonusu | %0.05 | x50 | Set parçası |
| Mitik | 6 + benzersiz + 1 "Mitik affix" | %0.005 (sadece Cehennem+) | x200 | Endgame avı |

- Drop oranları Item Bulma (IF) ile ölçeklenir: `p_rarity_final = p_rarity x (1 + IF% x RarityWeight)` (Nadir 1.0, Destansı 0.7, Efsanevi 0.5, Set/Mitik 0.35).
- Her canavar öldürmede item düşme şansı: Normal %8, Elit %60 (+1 garanti Büyülü+), Boss %100 x3 item (1 Nadir+ garanti), Perde Boss x5 (1 Destansı+ garanti).
- **Akıllı loot:** Düşen itemlerin %60'ı partideki sınıfların kullanabildiği türlerden seçilir.

## 15.3 Item Level ve Kademeler

- Item Level (iLvl) = canavar seviyesi. Affix aralıkları iLvl'ye bağlı **7 kademe (T1-T7)** ile belirlenir.
- Taban item türleri 7 kademe görünüme sahiptir (gereken level: 1, 12, 25, 40, 55, 70, 85). Daha yüksek kademe = daha güçlü taban stat + farklı ikon.

| Kademe | Gereken Lv | Taban stat çarpanı | Görsel |
|---|---|---|---|
| T1 | 1 | 1.0 | Demir/ahşap, sade |
| T2 | 12 | 1.8 | Çelik, küçük detay |
| T3 | 25 | 3.2 | Süslü, renkli kumaş |
| T4 | 40 | 5.5 | Gümüş/mitril, parlak taş |
| T5 | 55 | 9.0 | Altın kakmalı, rün |
| T6 | 70 | 14.0 | Elementel parıltı, efekt pikseli |
| T7 | 85 | 21.0 | Efsanevi malzemeler, animasyonlu ikon (2 kare parıltı) |

## 15.4 Silahlar (Tüm Taban Türleri)

Silah hasarı formülü: `WeaponATK = BaseATK x TierMult x (1 + 0.02 x (iLvl - TierReqLvl))`

| Tür | Sınıflar | El | APS | BaseATK | Implicit |
|---|---|---|---|---|---|
| Kılıç | Şövalye, Suikastçı | Tek | 1.15 | 10 | +%5 Kritik Hasarı |
| Topuz | Şövalye, Rahibe | Tek | 1.05 | 11 | %5 Sersemletme şansı |
| İki El Kılıç | Barbar, Şövalye | Çift | 0.90 | 18 | +%10 Kritik Hasarı |
| İki El Balta | Barbar | Çift | 0.85 | 20 | %8 Kanama şansı |
| Hançer | Suikastçı | Tek (çift taşınır) | 1.50 | 7 | +%3 Kritik Şansı |
| Yay | Okçu | Çift | 1.00 | 14 | +%5 Saldırı Hızı |
| Arbalet | Okçu | Çift | 0.80 | 19 | +%8 Delme |
| Asa | Büyücü, Nekromant | Çift | 0.85 | 16 | +%15 Büyü Gücü |
| Değnek | Büyücü, Rahibe | Tek | 1.00 | 10 | +%8 Büyü Hızı |
| Tırpan | Nekromant | Çift | 0.90 | 17 | +%10 Kaos Hasarı |
| Lavta | Ozan | Çift | 1.00 | 12 | +%8 Buff Süresi |
| Flüt | Ozan | Tek | 1.10 | 9 | +%5 Bekleme Azaltma |

**Silah isimleri (kademe sırasıyla T1→T7):**

| Tür | T1 | T2 | T3 | T4 | T5 | T6 | T7 |
|---|---|---|---|---|---|---|---|
| Kılıç | Paslı Kılıç | Lejyoner Kılıcı | Şövalye Kılıcı | Mitril Uzun Kılıç | Rün Kılıcı | Ejder Dişi Kılıcı | Yıldız Çeliği |
| Topuz | Sopa | Demir Topuz | Yıldız Topuz | Kutsal Topuz | Rünlü Gürz | Gök Gürzü | Tanrı Çekici |
| İki El Kılıç | Ağır Kılıç | Claymore | Cellat Kılıcı | Dev Kılıç | Titan Kılıcı | Ejder Avcısı | Dünya Yaran |
| İki El Balta | Oduncu Baltası | Savaş Baltası | Kuzey Baltası | Çift Ağızlı Balta | Kan Baltası | Fırtına Baltası | Ragnarök Baltası |
| Hançer | Mutfak Bıçağı | Hançer | Kıvrık Hançer | Gölge Bıçağı | Ay Hançeri | Hiçlik Dişi | Kader Kesici |
| Yay | Kısa Yay | Av Yayı | Uzun Yay | Elf Yayı | Rüzgâr Yayı | Anka Yayı | Göksel Yay |
| Arbalet | Hafif Arbalet | Askerî Arbalet | Ağır Arbalet | Tekrarlı Arbalet | Rünlü Arbalet | Ejder Arbaleti | Yıldız Atar |
| Asa | Çırak Asası | Meşe Asa | Kristal Asa | Âlim Asası | Arşmag Asası | Element Asası | Sonsuzluk Asası |
| Değnek | Dal Değnek | Kemik Değnek | Ametist Değnek | Mühürlü Değnek | Ay Değneği | Güneş Değneği | Yaratılış Değneği |
| Tırpan | Orak | Mezarcı Tırpanı | Kemik Tırpan | Ruh Hasatçısı | Kara Tırpan | Uçurum Tırpanı | Ölümün Kendisi |
| Lavta | Eski Lavta | Gezgin Lavtası | Saray Lavtası | Gümüş Lavta | Ezgi Lavtası | Fırtına Lavtası | Efsane Lavtası |
| Flüt | Kamış Flüt | Ahşap Flüt | Gümüş Flüt | Peri Flütü | Rüya Flütü | Ruh Flütü | Göksel Flüt |

**Yan el itemleri (T1→T7):**

| Tür | Sınıflar | T1 | T3 | T5 | T7 | Implicit |
|---|---|---|---|---|---|---|
| Kalkan | Şövalye | Ahşap Kalkan | Kule Kalkanı | Rün Kalkanı | Aegis | +Blok %5-15 |
| Ok Kılıfı | Okçu | Deri Kılıf | Avcı Kılıfı | Rüzgâr Kılıfı | Sonsuz Sadak | +Kritik %2-6 |
| Küre | Büyücü, Nekromant | Cam Küre | Kristal Küre | Öz Küresi | Kozmos Küresi | +Büyü Gücü %5-20 |
| Kutsal Kitap | Rahibe | Dua Kitabı | İlahi Kitap | Aziz Kodeksi | Yaratılış Kitabı | +İyileştirme %5-20 |
| Yan Hançer | Suikastçı | Bıçak | Gölge Bıçak | Ay Bıçağı | Kader Bıçağı | +Saldırı Hızı %4-12 |

## 15.5 Zırhlar

Üç ağırlık sınıfı: **Ağır** (Şövalye, Barbar) +Savunma, **Orta** (Okçu, Suikastçı, Rahibe) +Kaçınma/denge, **Hafif** (Büyücü, Nekromant, Ozan) +Büyü Gücü/direnç.

| Ağırlık | Savunma çarpanı | Ek implicit |
|---|---|---|
| Ağır | x1.5 | +%HP |
| Orta | x1.0 | +Kaçınma |
| Hafif | x0.6 | +Büyü Gücü veya +Tüm direnç |

**Gövde zırhı isimleri:**

| Kademe | Ağır | Orta | Hafif |
|---|---|---|---|
| T1 | Zincir Gömlek | Yastıklı Ceket | Keten Cübbe |
| T2 | Pullu Zırh | Deri Zırh | Çırak Cübbesi |
| T3 | Plaka Zırh | Avcı Yeleği | Büyücü Cübbesi |
| T4 | Mitril Plaka | Gölge Deri | Yıldızlı Cübbe |
| T5 | Rün Plakası | Ejder Derisi Zırh | Arşmag Cübbesi |
| T6 | Titan Zırhı | Fırtına Postu | Element Örtüsü |
| T7 | Göksel Plaka | Gece Postu | Sonsuzluk Cübbesi |

**Kask / Eldiven / Bot / Kemer / Pelerin (örnek isimler):**

| Kademe | Kask (Ağır/Orta/Hafif) | Eldiven | Bot | Kemer | Pelerin |
|---|---|---|---|---|---|
| T1 | Demir Miğfer / Deri Başlık / Keten Şapka | Deri Eldiven | Deri Çizme | İp Kuşak | Yırtık Pelerin |
| T2 | Lejyoner Miğferi / Avcı Başlığı / Çırak Şapkası | Zincir Eldiven | Asker Çizmesi | Deri Kemer | Gezgin Pelerini |
| T3 | Şövalye Miğferi / Gölge Başlık / Büyücü Şapkası | Plaka Eldiven | Plaka Çizme | Ağır Kemer | Şövalye Pelerini |
| T4 | Mitril Miğfer / Kuzgun Maskesi / Yıldız Şapkası | Mitril Eldiven | Rüzgâr Çizmesi | Mitril Kuşak | Gece Pelerini |
| T5 | Rün Miğferi / Ejder Başlığı / Arşmag Tacı | Rün Eldiven | Rün Çizme | Şampiyon Kemeri | Kraliyet Pelerini |
| T6 | Titan Miğferi / Fırtına Maskesi / Element Tacı | Titan Pençesi | Fırtına Adımı | Titan Kuşağı | Anka Pelerini |
| T7 | Göksel Miğfer / Gece Kralı Maskesi / Kozmos Tacı | Tanrı Eldiveni | Göksel Adım | Sonsuzluk Kuşağı | Yıldız Pelerini |

**Takılar:** Kolye (Bakır Kolye → Gümüş → Altın → Yakut Muska → Ejder Gözü → Anka Tüyü Kolye → Yıldız Kalbi), Yüzük (Bakır Halka → Gümüş → Altın → Safir → Rün → Element → Kader Yüzüğü), Tılsım (sadece Destansı+: Rün Taşı, Kutsal Emanet, Kafatası Fetişi, Ay Taşı).

## 15.6 Affix Havuzu

Ön ek (Prefix) = saldırı/savunma sayıları; Son ek (Suffix) = yüzde ve yardımcılar. Bir item en fazla 3 prefix + 3 suffix taşır. Değer aralıkları T7 için verilmiştir; düşük kademeler oransal (T1 = T7 x 0.12, T2 0.2, T3 0.32, T4 0.46, T5 0.62, T6 0.8).

| Affix | Tip | Slotlar | T7 Aralığı |
|---|---|---|---|
| +Saldırı (düz) | Prefix | Silah, Yüzük, Kolye, Eldiven | 180-260 |
| +% Fiziksel Hasar | Prefix | Silah | %60-90 |
| +% Ateş / Soğuk / Yıldırım / Kaos Hasarı | Prefix | Silah, Kolye, Yan el | %40-65 |
| +Büyü Gücü | Prefix | Silah, Yan el, Kolye | 160-240 |
| +HP (düz) | Prefix | Zırh, Kemer, Kask | 900-1400 |
| +% HP | Prefix | Gövde, Kemer | %10-15 |
| +Savunma | Prefix | Zırh parçaları | 120-180 |
| +% Savunma | Prefix | Zırh parçaları | %30-50 |
| +Kalkan (Shield) başlangıçta | Prefix | Yan el | Max HP %8-12 |
| +Güç / Çeviklik / Zekâ / Dayanıklılık / Şans | Suffix | Tümü | 40-65 |
| +Tüm Statlar | Suffix | Kolye, Yüzük | 18-28 |
| +% Kritik Şansı | Suffix | Silah, Kolye, Yüzük, Eldiven | %4-7 |
| +% Kritik Hasarı | Suffix | Silah, Kolye, Eldiven | %25-45 |
| +% Saldırı Hızı | Suffix | Silah, Eldiven, Yüzük | %8-14 |
| +% Büyü Hızı | Suffix | Silah, Kolye | %8-14 |
| +% Delme | Suffix | Silah | %6-10 |
| +% Ateş/Soğuk/Yıldırım/Kaos Direnci | Suffix | Zırh, Takı | %25-40 |
| +% Tüm Direnç | Suffix | Takı, Pelerin | %12-18 |
| +% Kaçınma | Suffix | Bot, Pelerin | %4-7 |
| +% Blok | Suffix | Kalkan | %5-8 |
| +% Can Çalma | Suffix | Silah, Yüzük | %1-2 |
| +HP Yenilenme/sn | Suffix | Zırh, Kemer | 40-70 |
| +% Bekleme Azaltma | Suffix | Kask, Kolye, Tılsım | %4-8 |
| +% Item Bulma | Suffix | Kask, Yüzük, Kolye | %12-20 |
| +% Altın Bulma | Suffix | Eldiven, Yüzük, Kemer | %15-25 |
| +% XP Bonusu | Suffix | Kask, Kolye | %5-10 |
| +X Belirli Skill Seviyesi | Suffix | Kask, Kolye, Silah (Destansı+) | +1/+2 |
| +% Elit/Boss Hasarı | Suffix | Silah, Tılsım | %10-20 |
| +% Skill Alanı | Suffix | Kask, Asa | %10-20 |
| +% Hareket Hızı | Suffix | Bot | %10-20 |

## 15.7 Efsanevi Itemler (Seçki: 32 adet)

Efsanevi itemler sabit isimli ve benzersiz etkilidir. Her biri belirli bir taban türde ve minimum bölgede düşer.

| Ad | Taban | Benzersiz Etki |
|---|---|---|
| Kral Aldric'in Yemini | Kılıç | Kalkan Darbesi 2 hedefe sıçrar, sersemletme +1 sn |
| Ejderkalp | Gövde (Ağır) | HP %50 altına düşünce 1 kez/60 sn tam iyileşme |
| Goblin Şefinin Tacı | Kask | Altın Bulma +%60, her öldürmede %1 şansla altın patlaması |
| Bin Yıllık Meşe | Yay | Ok Yağmuru alanı +%50, süre +2 sn |
| Ay Fısıltısı | Hançer | Gece kritik şansı +%15; gündüz -%5 |
| Anka Tüyü | Pelerin | Ölünce 3 sn sonra %50 HP ile dirilir (180 sn CD) |
| Kozmik Göz | Kolye | Bekleme süreleri -%15, Nihai bar +%20 hızlı |
| Ragnarök'ün Kıvılcımı | İki El Balta | Kasırga her dönüşte Yıldırım çarpar |
| Buzul Kalbi | Küre | Donma 3 yığında olur (5 yerine) |
| Kara Alev Grimoire | Asa | Ateş büyüleri ayrıca %50 Kaos hasarı verir |
| Vex'in Oyuncağı | Tırpan | İskeletler patlayarak ölür (%200 alan) |
| Tanrıçanın Gözyaşı | Kutsal Kitap | Aşırı iyileşme kalkan olur (max %30 HP) |
| Gezgin Ozanın Lavtası | Lavta | Tüm şarkılar 2 kat süre, Neşe XP +%10 |
| Sonsuz Sadak | Ok Kılıfı | Her 4. ok 3'e bölünür |
| Titanın Kemeri | Kemer | +%20 HP, ağır zırh cezası yok, iksirler 2 kez |
| Gölge Adım Çizmeleri | Bot | Gölge Adımı bekleme -%40 |
| Hazine Avcısının Yüzüğü | Yüzük | Item Bulma +%40, Altın +%40, -%10 hasar |
| Kanlı Gül | Yüzük | Kanama hasarı x2 |
| Fırtına Çağıran | Değnek | Zincir Şimşek +3 sekme |
| Yıldızkıran | Arbalet | Kritik vuruşlarda küçük meteor düşer |
| Ölümsüz Muhafız | Kalkan | Blok başarılıysa 2 sn hasar bağışıklığı (10 sn CD) |
| Kum Saati | Tılsım | Offline verim +%20 (hesap genelinde, sadece kuşanıldığında) |
| Kurt Kralının Pençesi | Eldiven | Kurt Çağır 2 kurt çağırır |
| Ruh Kafesi | Tılsım | Her 100 öldürmede +%1 hasar (bölge değişince sıfırlanır, max %30) |
| Abyssal Taç | Kask | Kaos hasarı +%40, Kaos direnci -%20 |
| Paladin Mührü | Yüzük | Kutsal hasar ölümsüz olmayanlara da x1.5 |
| Soğuk Çelik | Kılıç | Vuruşlar %100 Donma uygular |
| Cellat | İki El Kılıç | %10 HP altındaki normal düşmanları anında öldürür |
| Sihirbazın Şapkası | Kask (Hafif) | Her büyü %15 şansla rastgele ikinci büyüyü bedava yapar |
| Zaman Bükücü | Kolye | Tüm parti saldırı hızı +%15, düşmanlar -%10 |
| Pip'in Şans Kurabiyesi | Tılsım | Her boss sonrası %25 şansla ekstra efsanevi roll |
| Uçurum Gözü | Küre | Lanet artık yayılır (2 düşman) |

> İçerik AI notu: Efsanevi listesi lansmanda **80 adet** olmalı (her taban türünden en az 3). Yukarıdaki 32 adet tasarım kalıbıdır; kalanları aynı formatta (her sınıfın en az 2 skillini değiştiren item) üret.

## 15.8 Set Itemleri (8 Set)

| Set | Parçalar | 2 Parça | 4 Parça | 6 Parça |
|---|---|---|---|---|
| İmparatorluk Muhafızı (Şövalye) | Kask, Gövde, Eldiven, Bot, Kalkan, Kılıç | +%20 DR | Kalkan Darbesi tüm düşmanlara | Tehdit altındayken parti +%40 hasar |
| Kuzeyli Öfkesi (Barbar) | Kask, Gövde, Kemer, Bot, Balta, Pelerin | +%25 Saldırı Hızı | Kasırga sürekli | Öfke barı x2 |
| Elf Gözcüsü (Okçu) | Kask, Gövde, Eldiven, Bot, Yay, Kılıf | +%8 Kritik | Çoklu Atış +5 ok | Her ok %30 şansla patlar |
| Gece Kraliçesi (Suikastçı) | Maske, Gövde, Eldiven, Bot, 2 Hançer | +%15 Kaçınma | Gölge Adımı 3 kez zincir | Kritikler %300 ek hasar |
| Element Sonsuzluğu (Büyücü) | Taç, Cübbe, Eldiven, Bot, Asa, Küre | +%20 Element | Element Döngüsü max yığın x3 | Her büyü tüm elementlerden hasar verir |
| Kemik Hükümdarı (Nekromant) | Taç, Cübbe, Kemer, Pelerin, Tırpan, Küre | +2 Çağrı | Çağrılar ölümsüz 10 sn | Çağrılar sahibin statlarını %100 kopyalar |
| Aziz'in Işığı (Rahibe) | Hale, Cübbe, Eldiven, Bot, Kitap, Topuz | +%25 İyileştirme | İyileştirmeler zincirlenir (3 müttefik) | Parti ölümsüz 2 sn her 30 sn |
| Efsanevi Turne (Ozan) | Şapka, Kıyafet, Bot, Pelerin, Lavta, Yüzük | +%20 Buff süresi | 3 şarkı aynı anda | Şarkılar nihai barı sürekli doldurur |

## 15.9 Item Gücü Skoru (Otomatik Kuşanma)

`ItemPower = Σ (affix_value / affix_T7_max) x affix_weight[class] x 100 + BaseStat x TierMult`

- Her sınıf için affix ağırlıkları `classes.json` içinde (ör. Okçu: Çeviklik 1.0, Kritik 1.0, Saldırı Hızı 0.9, Zekâ 0.1).
- Tooltip'te karşılaştırma: DPS ve EHP (Etkin HP) değişimi yüzde olarak.

\pagebreak

# 16. Gemler ve Soketler

- Destansı+ itemlerde 0-2 soket (Kuyumcu ile açılabilir).
- Gem türleri (5 kademe: Yontulmamış → Kusurlu → Normal → Kusursuz → Kraliyet; 3 aynı gem = 1 üst kademe):

| Gem | Silaha | Zırha | Takıya |
|---|---|---|---|
| Yakut | +Ateş hasarı | +HP | +Ateş direnci |
| Safir | +Soğuk hasarı | +Savunma | +Soğuk direnci |
| Topaz | +Yıldırım hasarı | +Item Bulma | +Altın Bulma |
| Zümrüt | +Kritik Hasar | +Kaçınma | +Kritik Şansı |
| Ametist | +Kaos hasarı | +Can Çalma | +Kaos direnci |
| Elmas | +Tüm hasar | +Tüm direnç | +Tüm statlar |
| Kafatası | +Can Çalma | +HP Yenilenme | +Bekleme Azaltma |

\pagebreak

# 17. Demirci ve Ekonomi

## 17.1 Demirci Paneli (Sekmeler)

Referans görseldeki gibi: **Birleştir / Sat / Üret** + bizim eklediğimiz **Güçlendir** ve **Sök**. Demircinin kendi seviyesi vardır (Lv 1-50); her işlem Demirci XP'si verir. Demirci seviyesi yeni özellikleri açar (ör. "Demirci Lv.30 → Lv.45-65 itemleri birleştirmeyi açar").

## 17.2 Birleştir (Combine)

- **9 item → 1 item** (referans: 3x3 ızgara, "9/9 - Başarı %90").
- Aynı nadirlikte 9 item birleşince bir üst nadirlikte, ortalama iLvl + 2 seviyesinde, kuşananın sınıfına uygun rastgele item üretilir.
- Başarı oranı: Sıradan→Büyülü %100, Büyülü→Nadir %90, Nadir→Destansı %75, Destansı→Efsanevi %35 (Demirci Lv 25+), Efsanevi→Mitik %10 (Lv 45+, 9 Efsanevi + Mitik Öz).
- **Merhamet sayacı (pity):** "0/10 (10 başarısızlıktan sonra sonraki birleştirme garantili)". Başarısızlıkta itemlerin 6'sı yok olur, 3'ü geri döner.
- Butonlar: **Otomatik Doldur** (seçili nadirlik ve level aralığından, kilitli itemleri atlayarak), level aralığı seçici (Lv.1~20), "Depoyu dahil et" kutucuğu, **Birleştir**, **İstatistik**.

## 17.3 Güçlendirme (Enhance +1 → +15)

| Seviye | Başarı | Maliyet (altın x iLvl) | Başarısızlıkta | Bonus |
|---|---|---|---|---|
| +1 ~ +5 | %100 | 50 | - | Her seviye taban stat +%5 |
| +6 ~ +9 | %80 → %50 | 150 | Seviye korunur | +%6 / seviye |
| +10 ~ +12 | %40 → %25 | 400 + Parlak Öz | -1 seviye | +%8 / seviye, +10'da parlama efekti |
| +13 ~ +15 | %15 → %5 | 1000 + Yıldız Tozu | -1 seviye (Koruma Parşömeni ile korunur) | +%10, +15'te rarity renginde aura |

Item ASLA yok olmaz (oyuncu dostu).

## 17.4 Üret (Craft)

- Malzemeler + altın ile belirli taban türde, seçilen kademede item üretimi. Nadirlik rastgele (Nadir garantili tarifler var).
- Efsanevi hedefli üretim: Kodekste bulunan efsanevi itemler için "Efsanevi Şablon" + 50 Efsanevi Öz ile yeniden üretim (endgame sink).

## 17.5 Sök (Salvage) ve Malzemeler

| Malzeme | Kaynak | Kullanım |
|---|---|---|
| Demir Parçası | Sıradan/Büyülü sökme | Güçlendirme +1~+9, üretim |
| Parlak Öz | Nadir sökme | Güçlendirme +10~+12, üretim |
| Destansı Öz | Destansı sökme | Reroll, soket açma |
| Efsanevi Öz | Efsanevi sökme | Efsanevi üretim, Mitik birleştirme |
| Yıldız Tozu | Kule, Yarık | +13~+15 |
| Mitik Öz | Cehennem Perde Boss, Yarık 50+ | Mitik birleştirme |
| Ruh Parçası | Boss'lar | Kahraman yıldızı |
| Taverna Mührü | Boss'lar, görevler | Kahraman toplama |
| Lonca Nişanı | Perde boss, haftalık görev | Lonca Salonu |

## 17.6 Ganimet Filtresi ve Otomatik İşlem

Ayarlar > Ganimet: her nadirlik için **Tut / Sat / Sök** seçimi; "Daha iyi olmayanları sat" seçeneği; Efsanevi+ her zaman tutulur. Envanter dolduğunda (ilk 60 slot, genişletme altınla max 120) otomatik filtre uygulanır.

## 17.7 Depo (Stash)

- 7 sekme (1. sekme ücretsiz, diğerleri altınla açılır: 10K, 50K, 200K, 1M, 5M, 20M). Her sekme 6x6 = 36 slot.
- Tüm kahramanlar arasında paylaşılır. "Çantaya / Depoya" toplu taşıma butonları ve sıralama (nadirlik, tür, level).

## 17.8 Ekonomi Dengesi (Kaynaklar ve Musluklar)

| Para | Kaynak (faucet) | Harcama (sink) |
|---|---|---|
| Altın | Öldürme, satış, görevler, offline | Güçlendirme, depo, sıfırlama, Lonca Salonu, Taverna, iksir, envanter genişletme |
| Malzemeler | Sökme, boss, Kule | Güçlendirme, üretim, reroll |
| Mühür/Nişan | Boss, görev | Kahraman, Lonca Salonu |

Hedef: Oyuncu her oturum açtığında harcayacak anlamlı bir şeyi olsun; altın asla "anlamsız yığın"a dönüşmesin (Lonca Salonu üst seviyeleri üstel maliyetli sink).
