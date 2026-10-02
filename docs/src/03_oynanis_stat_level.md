\pagebreak

# 7. Oynanış Döngüsü

## 7.1 Döngü Katmanları

| Döngü | Süre | İçerik |
|---|---|---|
| Mikro | 5-30 sn | Dalga temizle, düşen altın/itemi topla (otomatik), skill animasyonları |
| Kısa | 3-10 dk | Bölgenin 10 aşamasını bitir, boss'u yen, yeni bölge aç |
| Orta | 30-90 dk | Level atla, stat/skill puanı dağıt, ekipman değiştir, demircide birleştir |
| Uzun | 1-7 gün | Yeni Perde (Act), zorluk seviyesi, sınıf ilerlemesi, set tamamlama, fraksiyon koleksiyonu |
| Endgame | Haftalar | Sonsuz Kule, Yarıklar, Paragon seviyeleri, Mitik item avı, liderlik tablosu |

## 7.2 Savaş Şeridi Akışı (Bir Aşama)

1. Parti soldan sağa doğru koşar (run animasyonu, arka plan kayar).
2. Sağdan bir **dalga** gelir: 3-5 normal düşman (her 3. dalgada 1 elit şansı %20).
3. Kahramanlar menzile girince durur ve savaşır. Düşmanlar ölünce altın/item yere düşer ve otomatik olarak sandığa uçar (mıknatıs animasyonu 0.4 sn).
4. Bir aşama = **5 dalga**. Aşama numarası şeritte görünür: "Sisli Orman Yolu 1-6".
5. Her bölgede **10 aşama** vardır; 10. aşama **Boss aşaması**dır (boss + 2 yardımcı, 60 sn zaman sınırı).
6. Boss yenilirse sonraki bölge açılır. AUTO açıksa otomatik geçilir; kapalıysa parti mevcut bölgede "farm" yapar (aynı aşamayı tekrarlar).
7. Boss zaman sınırında yenilemezse parti 9. aşamaya döner ve farm moduna geçer; oyuncuya "Güçlen ve tekrar dene" bildirimi.

## 7.3 Parti Düzeni

- 5 slot, soldan sağa: **Arka 1 - Arka 2 - Orta - Ön 2 - Ön 1** (Ön 1 en sağda, düşmana en yakın).
- Yakın dövüş sınıfları ön slotlarda olmazsa %30 hasar cezası alır ("Pozisyon dışı").
- Düşmanlar varsayılan olarak **en öndeki (en sağdaki) canlı kahramanı** hedefler. Bazı düşmanlar (suikastçı tipi) en düşük HP'li veya en arkadaki kahramanı hedefler; bu, oyuncuya dizilim kararı verdirir.
- Tank sınıfı "Provoke" (tehdit) değeri taşır: Hedefleme ağırlığı = 1 + Tehdit.

## 7.4 Hedefleme ve Menzil

| Sınıf tipi | Menzil (mantıksal px) | Hedef seçimi |
|---|---|---|
| Yakın dövüş | 18 | En yakın düşman |
| Mızrak | 30 | En yakın, 2 hedef delme şansı |
| Menzilli (yay) | 140 | En yakın; skill ile en düşük HP |
| Büyücü | 120 | En yoğun düşman grubu (alan hasarı) |
| Destek | 120 | Müttefik: en düşük HP %; düşman: en yakın |

## 7.5 Ölüm ve Diriliş

- Ölen kahraman 15 sn sonra savaş içinde otomatik dirilir (Rahibe skilli ile daha hızlı).
- Tüm parti ölürse: 5 sn geri sayım, bölgenin 1. aşamasına geri dönülür, %0 ceza (idle oyunlarda ağır ceza sevilmez). Zorluk "Cehennem"de ölüm başına 30 sn "Yorgunluk" debuff'ı (-%20 hasar).

## 7.6 Otomatik Sistemler

- **Otomatik toplama:** Altın ve itemler otomatik toplanır.
- **Otomatik satış filtresi:** Oyuncu "Sıradan ve Büyülü itemleri otomatik sat" veya "Nadir altını sökerek malzemeye çevir" seçebilir (Bölüm 17.6).
- **Otomatik skill:** Skiller hazır olunca otomatik kullanılır. Gelişmiş ayar: "Bu skilli sadece boss'ta kullan", "HP %40 altında kullan".
- **Otomatik ekipman önerisi:** Daha iyi item düşünce ikon üzerinde yeşil ok; tek tıkla "En iyisini giy" butonu (puanlama: item gücü skoru, Bölüm 15.9).

## 7.7 Offline İlerleme

- Oyun kapalıyken geçen süre (max **12 saat**, Gelişim ile 24 saate çıkar) için simülasyon:
  - Son 5 dakikanın ortalama **öldürme/dakika**, **XP/dk**, **altın/dk** değerleri kaydedilir.
  - Offline kazanç = ortalama x süre x **%60 verim** (Gelişim ağacıyla %100'e kadar).
  - Item dropları: Toplam öldürme sayısına göre loot tablosundan **toplu roll** (en fazla 200 item; fazlası otomatik satılır, Efsanevi+ asla satılmaz).
  - Boss ilerlemesi offline'da olmaz (parti farm modunda kalır).
- Dönüşte **"Sen Yokken"** penceresi: süre, XP, altın, level atlamaları, en iyi 5 item (nadirlik sırasıyla), malzemeler. "Topla" butonu ile coin-burst animasyonu.

## 7.8 Kasaba (Hub)

Kasaba ayrı bir şerit sahnesidir (savaş yok). Butonla veya parti ölünce gidilir. Kasabadaki NPC'ler panel açar:

| NPC | Panel | Açılış |
|---|---|---|
| Demirci Borin | Birleştir / Sat / Üret / Güçlendir | Lv 5 |
| Tüccar Mira | Malzeme ve iksir satın alma, günlük teklif | Lv 3 |
| Meyhaneci Tobi | Kahraman toplama (Taverna), kahraman yükseltme | Lv 8 |
| Kâhin Selene | Stat/skill sıfırlama, sınıf ilerlemesi | Lv 30 |
| Kuyumcu Nyx | Gem kesme ve soket | Lv 25 |
| Depo Bekçisi | Depo (7 sekme) | Lv 1 |
| Lonca Panosu | Görevler, günlük/haftalık | Lv 10 |

\pagebreak

# 8. Savaş Sistemi ve Formüller

Tüm katsayılar `data/balance.json` içinde tutulur. Aşağıdaki değerler başlangıç değerleridir.

## 8.1 Tick Sistemi

- Simülasyon **10 tick/sn**. Her tick: buff süreleri azalır, saldırı zamanlayıcıları ilerler, skill cooldown'ları ilerler, DoT hasarı uygulanır (DoT 1 sn'de bir).
- Saldırı aralığı (sn) = `1 / (WeaponBaseAPS x (1 + AttackSpeed%))`

## 8.2 Hasar Hesabı

```
RawDamage   = Attack x SkillMultiplier x (1 + AddedDamage% + ElementBonus% + SkillDamage%)
            x Product(MoreMultipliers)            # set/efsanevi "x%30 daha fazla" etkileri
IsCrit      = rng < CritChance (cap %75)
CritDamage  = RawDamage x CritDMG (taban %150)
EffDEF      = TargetDEF x (1 - Penetrate%)
DR          = EffDEF / (EffDEF + 50 + 6 x AttackerLevel)     # cap %75
Elemental   = (1 - TargetResist% + ResistShred%)            # resist cap %75, min -%50
Final       = RawDamage x (1 - DR) x Elemental x rng(0.95, 1.05)
```

**Örnek (referans ekranla tutarlı):** Lv 50 saldırgana karşı DEF 276 → DR = 276 / (276 + 350) = **%44.1**. Referans görseldeki "276 (44%)" ile birebir.

## 8.3 Kaçınma, Blok, İsabet

- `HitChance = clamp(Accuracy / (Accuracy + Evasion x 0.5), %60, %98)` — normal düşmanlarda isabet varsayılan %95.
- Blok (kalkan): `BlockChance` (cap %50) — bloklanan hasar %60 azalır.
- Kritik Hasar Direnci: Saldırganın CritDMG'sini azaltır (Defense sekmesinde gösterilir).

## 8.4 İyileştirme ve Kalkan

- Heal = `SpellPower x HealMultiplier x (1 + HealingBonus%)`; aşırı iyileşme "Taşma Kalkanı"na dönüşmez (sadece belirli itemlerle).
- Kalkan (Shield) önce hasarı emer, 6 sn sürer, üst üste binmez (en büyüğü kalır).

## 8.5 Durum Etkileri

| Etki | Kaynak | Süre | Etki |
|---|---|---|---|
| Yanma (Burn) | Ateş | 3 sn | Saniyede vuruşun %20'si ateş hasarı, üst üste 3 yığın |
| Donma (Chill) | Soğuk | 2 sn | -%30 saldırı ve hareket hızı; 5 yığında 1 sn Dondurma (Freeze) |
| Şok (Shock) | Yıldırım | 4 sn | Hedef %15 fazla hasar alır |
| Zehir (Poison) | Kaos | 5 sn | Saniyede %12, sınırsız yığın (max 20) |
| Kanama (Bleed) | Fiziksel | 4 sn | Saniyede %15, hareket ederken x2 |
| Sersemleme (Stun) | Skill | 1 sn | Eylem yok; bosslarda %50 süre |
| Zayıflatma (Weaken) | Skill | 5 sn | Hedef -%20 hasar verir |
| Kırılgan (Vulnerable) | Skill | 5 sn | Hedef +%20 hasar alır |

## 8.6 Düşman Ölçekleme

```
EnemyHP(L)    = 40 x 1.075^L x TypeMult x DifficultyMult
EnemyATK(L)   = 8  x 1.065^L x TypeMult_ATK x DifficultyMult
EnemyDEF(L)   = 10 + 4.5 x L
TypeMult      : Normal 1.0 | Elit 3.5 | Mini-Boss 10 | Boss 25 | Perde Boss 40
TypeMult_ATK  : Normal 1.0 | Elit 1.6 | Mini-Boss 2.0 | Boss 2.5 | Perde Boss 3.0
DifficultyMult: Normal 1.0 | Kabus 1.6 | Cehennem 2.6 (+ Resist -%30 / -%60)
```

Detaylı tablo: Bölüm 25.

\pagebreak

# 9. Stat Sistemi

## 9.1 Ana Statlar (Primary)

Her levelde **5 Stat Puanı** gelir (+ her 10 levelde bonus 5). Oyuncu dağıtır veya "Otomatik Dağıt" (sınıf şablonuna göre) kullanır.

| Stat | TR | Etkisi (puan başına) |
|---|---|---|
| STR | Güç | +1.5 Saldırı (Güç sınıfları), +4 HP, +%0.2 Fiziksel Hasar |
| DEX | Çeviklik | +1.5 Saldırı (Çeviklik sınıfları), +%0.08 Kritik Şansı, +%0.25 Saldırı Hızı, +0.5 Kaçınma |
| INT | Zekâ | +1.5 Büyü Gücü, +%0.25 Büyü Hızı, +%0.3 Skill Hasarı, +%0.1 Bekleme Süresi Azaltma (cap %40) |
| VIT | Dayanıklılık | +12 HP, +0.4 Savunma, +%0.02 HP Yenilenme/sn |
| LUK | Şans | +%0.15 Item Bulma, +%0.12 Altın Bulma, +%0.03 Kritik Şansı |

- Her sınıfın **ana stat**ı vardır (Şövalye/Barbar: STR, Okçu/Suikastçı: DEX, Büyücü/Nekromant: INT, Rahibe/Ozan: INT+VIT hibrit). Saldırıya katkı sadece ana stattan gelir; diğer statlar ikincil faydaları verir.
- Sıfırlama: Kâhin'de, maliyet = `100 x Level^1.5` altın. İlk 2 sıfırlama ücretsiz.

## 9.2 Türetilmiş Statlar (Stat Paneli)

Referans görseldeki gibi Stat paneli 4 sekmelidir: **Tümü / Saldırı / Savunma / Diğer**. Her satır üzerine gelince tooltip ile açıklama ve kaynak dökümü (Taban + Stat + Ekipman + Pasif + Buff) gösterir.

| Sekme | Stat | Taban | Cap |
|---|---|---|---|
| Saldırı | Saldırı (Attack) | Sınıf tabanı + silah | - |
| Saldırı | Eklenen Hasar % | 0 | - |
| Saldırı | Elemental Hasar % | 0 | - |
| Saldırı | Kritik Şansı | %5 | %75 |
| Saldırı | Kritik Hasarı | %150 | %500 |
| Saldırı | Delme (Penetrate) | %0 | %60 |
| Saldırı | Saldırı Hızı | %100 | %225 |
| Saldırı | Büyü Hızı | %0 | %150 |
| Saldırı | Kahraman Aktif Skill Hasarı | %0 | - |
| Saldırı | Skill Menzili / Skill Alanı | %0 | %100 |
| Saldırı | Ateş / Soğuk / Yıldırım / Kaos Hasarı | %0 | - |
| Savunma | HP | Sınıf tabanı | - |
| Savunma | Savunma (DR %) | Sınıf tabanı | DR %75 |
| Savunma | Kritik Vuruş Direnci | %0 | %50 |
| Savunma | Ateş/Soğuk/Yıldırım/Kaos Direnci | %0 | %75 |
| Savunma | Kaçınma / Blok | %0 | %50 |
| Savunma | HP Yenilenme /sn | 0 | - |
| Savunma | Can Çalma % | 0 | %10 |
| Diğer | Item Bulma % | 0 | %400 |
| Diğer | Altın Bulma % | 0 | %400 |
| Diğer | XP Bonusu % | 0 | - |
| Diğer | Bekleme Süresi Azaltma | 0 | %40 |
| Diğer | Hareket Hızı | %100 | %150 |

## 9.3 Sınıf Taban Değerleri

| Sınıf | Taban HP | HP/Level | Taban Saldırı | Saldırı/Level | Taban DEF | DEF/Level | Silah APS |
|---|---|---|---|---|---|---|---|
| Şövalye | 220 | 38 | 14 | 3.0 | 20 | 4.0 | 1.10 |
| Barbar | 200 | 34 | 18 | 3.8 | 12 | 2.6 | 0.90 |
| Okçu | 150 | 24 | 16 | 3.6 | 8 | 1.8 | 1.00 |
| Suikastçı | 140 | 22 | 15 | 3.4 | 8 | 1.8 | 1.45 |
| Büyücü | 120 | 20 | 18 | 4.0 | 6 | 1.4 | 0.85 |
| Nekromant | 135 | 22 | 16 | 3.6 | 7 | 1.6 | 0.90 |
| Rahibe | 150 | 25 | 10 | 2.4 | 10 | 2.2 | 0.95 |
| Ozan | 160 | 26 | 11 | 2.6 | 10 | 2.2 | 1.00 |

\pagebreak

# 10. Level, XP ve İlerleme Hızı

## 10.1 Formüller

```
XP_per_kill(L)   = round(8 + 1.5 x L^1.5) x TypeXPMult     (Elit x4, Boss x30, Perde Boss x80)
Kills_to_level(L)= 40 + 9 x L
XP_required(L)   = XP_per_kill(L) x Kills_to_level(L)
LevelDiffPenalty : canavar seviyesi oyuncudan 5+ düşükse her level için -%10 XP (min %10)
                   canavar 3+ yüksekse her level için +%5 XP (max +%25)
Gold_per_kill(L) = round(3 + 0.8 x L^1.3) x (1 + GoldFind%)
```

- **Maksimum level: 100.** 100'den sonra **Paragon** sistemi (Bölüm 19.5).
- XP partideki her kahramana **tam** verilir (bölünmez). Yedek (partide olmayan) kahramanlar %25 "Antrenman XP"si alır (Gelişim ile %75'e kadar).

## 10.2 XP Tablosu (Seçili Levellar)

| Level | XP/Öldürme | Gerekli Öldürme | Gerekli XP | Level süresi (dk, aktif) | Toplam süre (saat) |
|---|---|---|---|---|---|
| 1 | 10 | 49 | 490 | 1.3 | 0.0 |
| 5 | 25 | 85 | 2,125 | 2.3 | 0.1 |
| 10 | 55 | 130 | 7,150 | 3.5 | 0.4 |
| 15 | 95 | 175 | 16,625 | 4.7 | 0.7 |
| 20 | 142 | 220 | 31,240 | 5.9 | 1.2 |
| 25 | 196 | 265 | 51,940 | 7.1 | 1.7 |
| 30 | 254 | 310 | 78,740 | 8.3 | 2.4 |
| 40 | 387 | 400 | 154,800 | 10.7 | 4.0 |
| 50 | 538 | 490 | 263,620 | 13.1 | 6.0 |
| 60 | 705 | 580 | 408,900 | 15.5 | 8.4 |
| 70 | 886 | 670 | 593,620 | 17.9 | 11.2 |
| 80 | 1,081 | 760 | 821,560 | 20.3 | 14.4 |
| 90 | 1,289 | 850 | 1,095,650 | 22.7 | 18.0 |
| 99 | 1,486 | 931 | 1,383,466 | 24.8 | 21.6 |

Not: "Saf öldürme süresi" 1.6 sn/öldürme varsayımıyla ~22 saattir. Boss denemeleri, kasaba ziyaretleri, ölümler ve bölge geçişleri ile **gerçek süre Lv 100'e 45-60 saat** (offline ilerleme dahil 2-3 hafta günlük kullanım) hedeflenir.

## 10.3 İlerleme Kilometre Taşları (Hedef Zamanlama)

| Gerçek oyun süresi | Beklenen durum |
|---|---|
| 0-10 dk | Lv 1-5, 3 kahraman, ilk boss (Goblin Şefi) |
| 1 saat | Lv 15, 5 kişilik tam parti, Demirci açık, ilk Nadir itemler |
| 3 saat | Lv 25-30, Perde 1 bitti, ilk Efsanevi (garantili hikaye ödülü) |
| 8 saat | Lv 40-45, Perde 3, 1. Sınıf İlerlemesi tamam (Lv 30) |
| 12 saat | Lv 50, Normal zorluk bitti, Kabus açıldı |
| 25 saat | Lv 70-75, 2. Sınıf İlerlemesi, Kabus bitti, Cehennem açıldı |
| 50 saat | Lv 95-100, Cehennem bitti, Endgame (Kule, Yarıklar) |
| 100+ saat | Paragon, Mitik itemler, set tamamlama, tüm fraksiyonlar |

## 10.4 Puan Kazanımları

| Kaynak | Stat Puanı | Skill Puanı |
|---|---|---|
| Her level | 5 | 1 |
| Her 10. level | +5 bonus | +1 bonus |
| Perde Boss ilk yenilgisi | 0 | +2 |
| Sınıf İlerlemesi | +10 | +3 |
| Paragon level | 0 (Paragon puanı ayrı) | 0 |
