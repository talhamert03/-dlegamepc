\pagebreak

# 11. Sınıflar ve Skiller

## 11.1 Sınıf Genel Bakış

Oyunda **8 temel sınıf** vardır. Her sınıfın **3 kademesi** vardır: Temel (Lv 1), 1. İlerleme (Lv 30, Kâhin görevi), 2. İlerleme (Lv 70, Kabus Perde 2 boss'u sonrası). 2. ilerlemede oyuncu iki uzmanlıktan birini seçer (sonradan Kâhin'de altınla değiştirilebilir).

| Sınıf | Rol | Ana Stat | Silahlar | Zırh | 1. İlerleme (Lv30) | 2. İlerleme A / B (Lv70) |
|---|---|---|---|---|---|---|
| Şövalye (Knight) | Tank / Ön hat | STR | Kılıç, Topuz + Kalkan | Ağır | Paladin Adayı | Kutsal Paladin / Kale Muhafızı |
| Barbar (Berserker) | Yakın DPS | STR | İki el Balta, İki el Kılıç | Ağır | Savaş Lordu | Kan Çılgını / Fırtına Reisi |
| Okçu (Archer) | Menzilli DPS | DEX | Yay, Arbalet + Ok Kılıfı | Orta | Avcı | Rüzgâr Nişancısı / Doğa Muhafızı |
| Suikastçı (Assassin) | Tekil hedef DPS | DEX | Çift Hançer, Kısa Kılıç | Orta | Gölge | Gece Bıçağı / Zehir Ustası |
| Büyücü (Mage) | Alan DPS | INT | Asa, Değnek + Küre | Hafif | Elementalist | Ateş Arşmagı / Buz Cadısı |
| Nekromant (Necromancer) | Çağırıcı / DoT | INT | Tırpan, Asa | Hafif | Ruh Bağlayıcı | Kemik Lordu / Veba Getiren |
| Rahibe (Cleric) | İyileştirici | INT/VIT | Topuz, Değnek + Kutsal Kitap | Orta | Başrahibe | Işık Azizi / Savaş Rahibesi |
| Ozan (Bard) | Buff / Destek | INT/VIT | Lavta, Flüt | Hafif | Âşık Usta | Savaş Marşçısı / Huzur Şairi |

## 11.2 Skill Sistemi Kuralları

- Her sınıfın kademe başına skill ağacı vardır: **Temel 6 skill** (2 aktif + 4 pasif), **1. İlerleme +4 skill**, **2. İlerleme +4 skill** (uzmanlığa özel) + **1 Nihai (Ultimate)**.
- Kahraman aynı anda en fazla **3 aktif skill** + **1 nihai** donatabilir (Equip). Pasifler öğrenildiğinde otomatik aktiftir.
- Skill levelleri Skill Puanı ile yükselir (referans: "Lv.3/3", "Lv.0/5", "Lv.10/11"). Bazı skillerin ön koşulu vardır (ör. "Kalkan Darbesi Lv 3").
- Aktif skill cooldown ile çalışır (mana yok). Nihai skill **Öfke barı** ile çalışır: verilen + alınan hasarla dolar, dolunca otomatik patlar.
- Skill paneli: üstte seçili skill büyük ikon + açıklama + bekleme süresi + "Sıfırla" ve "Level Atla" butonları; altında skill ikon ızgarası (referans görseldeki gibi).
- Skill açıklamaları dinamik: "%130 Fiziksel hasar" değeri levele göre güncellenir ve bir sonraki level değeri yeşil gösterilir.

## 11.3 Şövalye (Knight)

**Fantezi:** İmparatorluk ordusunun genç şövalyesi. Kalkanı partinin duvarıdır. **Silüet:** Gümüş zırh, mavi pelerin, kalkan, miğferde kırmızı tüy (1. ilerlemede), altın detaylar (2. ilerlemede).

| Skill | Tür | Max Lv | CD | Etki (Lv1 → Max) |
|---|---|---|---|---|
| Kalkan Darbesi | Aktif | 10 | 8 sn | %140→%320 hasar + 1 sn sersemletme |
| Toparlanma (Recovery) | Aktif | 3 | 15 sn | Tüm müttefiklere max HP'nin %20→%30'u kadar iyileşme |
| Demir Deri | Pasif | 10 | - | +%3→%30 Savunma |
| Meydan Okuma | Pasif | 6 | - | Tehdit +1→+3; ön slotta +%2→%12 HP |
| Kılıç Ustalığı | Pasif | 5 | - | Kılıç/topuz ile +%4→%20 saldırı |
| Son Kale | Pasif | 6 | - | HP %30 altına düşünce 4 sn %20→%50 hasar azaltma (60 sn CD) |
| Kutsal Yemin (İlerleme 1) | Aktif | 10 | 20 sn | 6 sn boyunca partiye Saldırının %50→%150'si kadar kalkan |
| Adalet Kılıcı (İlerleme 1) | Aktif | 10 | 10 sn | Önündeki 3 düşmana %180→%400 Kutsal hasar |
| Kalkan Duvarı (İlerleme 1) | Pasif | 5 | - | Blok şansı +%3→%15 |
| Sarsılmaz (İlerleme 1) | Pasif | 5 | - | Sersemleme/donma süresi -%10→%50 |
| Paladin: Işık Hükmü | Aktif | 10 | 25 sn | Ekrandaki tüm düşmanlara %300→%700 Kutsal, ölümsüzlere x2 |
| Paladin: Aura of Valor | Pasif | 10 | - | Partiye +%2→%20 Saldırı |
| Muhafız: Kale Formu | Aktif | 10 | 30 sn | 8 sn tüm hasarı üstüne çeker, -%40→%70 alınan hasar |
| Muhafız: Diken Zırh | Pasif | 10 | - | Aldığı yakın dövüş hasarının %10→%60'ını yansıtır |
| NİHAİ: İmparatorluk Sancağı | Nihai | 5 | Öfke | 10 sn: parti +%30→%60 hasar, +%20 DR, sancak sprite'ı dikilir |

## 11.4 Barbar (Berserker)

**Fantezi:** Kuzey dağlarından, savaşı şarkı gibi seven iri yarı savaşçı. **Silüet:** Çıplak gövde + kürk omuzluk, iki elli balta, örgülü kızıl sakal/saç, savaş boyası.

| Skill | Tür | Max Lv | CD | Etki |
|---|---|---|---|---|
| Kasırga | Aktif | 10 | 9 sn | 2 sn dönerek çevreye 4 kez %70→%160 hasar |
| Savaş Çığlığı | Aktif | 5 | 18 sn | 8 sn kendine +%15→%40 saldırı hızı |
| Öfke Yükselişi | Pasif | 10 | - | Eksik HP'nin her %10'u için +%1→%4 hasar |
| İki El Ustalığı | Pasif | 5 | - | İki elli silahlarla +%5→%25 saldırı |
| Kana Susamış | Pasif | 6 | - | Can çalma +%0.5→%3 |
| Yaralayıcı | Pasif | 5 | - | Vuruşların %10→%30 şansla Kanama uygular |
| Yer Sarsıntısı (İ1) | Aktif | 10 | 12 sn | Önündeki alana %200→%450 + 0.8 sn sersemleme |
| Atılım (İ1) | Aktif | 10 | 10 sn | En arkadaki düşmana atılır, %160→%360 |
| Delirme (İ1) | Pasif | 5 | - | Kritik vuruşlar %6→%30 öfke barı doldurur |
| Kalın Kafa (İ1) | Pasif | 5 | - | +%4→%20 HP |
| Kan Çılgını: Kızıl Trans | Aktif | 10 | 30 sn | 10 sn +%30→%80 hasar, her saniye %2 HP kaybeder |
| Kan Çılgını: Ölümsüz Öfke | Pasif | 5 | - | Ölümcül hasarda 2→4 sn ölümsüz (120 sn CD) |
| Fırtına Reisi: Gök Gürültüsü | Aktif | 10 | 14 sn | Baltayı vurur, 5 hedefe yayılan %220→%500 Yıldırım |
| Fırtına Reisi: Şimşek Silah | Pasif | 10 | - | Fiziksel hasarın %5→%40'ı ek Yıldırım olarak |
| NİHAİ: Ragnarök | Nihai | 5 | Öfke | Gökten dev balta iner, %800→%2000 alan hasarı |

## 11.5 Okçu (Archer)

**Fantezi:** Orman elfi ırkından sarışın avcı (referans görseldeki Okçu). **Silüet:** Pembe-beyaz hafif zırh, uzun yay, at kuyruğu, ok kılıfı.

| Skill | Tür | Max Lv | CD | Etki |
|---|---|---|---|---|
| Çoklu Atış | Aktif | 10 | 7 sn | 5 ok, her biri %60→%140 |
| Toprak Darbesi (Earth Strike) | Aktif | 5 | 8.2 sn | Yerden dev dikenler, %130→%260 Fiziksel, max 3 hedef, menzil 3.5 |
| Keskin Göz | Pasif | 11 | - | +%1→%11 Kritik Şansı |
| Rüzgâr Adımı | Pasif | 3 | - | +%5→%15 Saldırı Hızı, +%5 kaçınma |
| Delici Oklar | Pasif | 6 | - | %10→%35 şansla ok hedefi deler (ikinci hedefe %50) |
| Avcı İşareti | Pasif | 5 | - | Elit/Boss'a +%4→%20 hasar |
| Ok Yağmuru (İ1) | Aktif | 10 | 15 sn | 3 sn alan, saniyede %80→%180 |
| Bağlayan Sarmaşık (İ1) | Aktif | 10 | 16 sn | 3 düşmanı 2 sn köklendirir + Kırılgan |
| Nişancı (İ1) | Pasif | 5 | - | +%8→%40 Kritik Hasar |
| Hızlı Çekiş (İ1) | Pasif | 5 | - | Skill bekleme -%2→%10 |
| Rüzgâr Nişancısı: Fırtına Oku | Aktif | 10 | 12 sn | Tüm hattı delen dev ok %350→%800 |
| Rüzgâr Nişancısı: Tetik | Pasif | 10 | - | Her 5. normal atış ikili atış |
| Doğa Muhafızı: Kurt Çağır | Aktif | 10 | 30 sn | 20 sn süren kurt yoldaş (saldırının %40→%100'ü) |
| Doğa Muhafızı: Ormanın Lütfu | Pasif | 10 | - | Partiye +%1→%10 HP yenilenme / Toprak skilleri x1.3 |
| NİHAİ: Yıldızkıran Ok | Nihai | 5 | Öfke | Gökyüzünden yıldız yağmuru, %1000→%2400 |

## 11.6 Suikastçı (Assassin)

**Fantezi:** Gölge Loncası'ndan maskeli kadın suikastçı (referans afişteki kırmızı-siyah karakter). **Silüet:** Başlık, yüz maskesi, iki hançer, kırmızı atkı.

| Skill | Tür | Max Lv | CD | Etki |
|---|---|---|---|---|
| Gölge Adımı | Aktif | 10 | 8 sn | En düşük HP'li düşmanın arkasına ışınlanır, %200→%450 |
| Zehirli Bıçak | Aktif | 5 | 10 sn | %120→%240 + 5 yığın Zehir |
| Çift Bıçak Ustalığı | Pasif | 10 | - | +%3→%30 Saldırı Hızı |
| Ölümcül Hassasiyet | Pasif | 10 | - | +%10→%60 Kritik Hasar |
| Sinsi | Pasif | 5 | - | Savaş başında ilk vuruş %100 kritik |
| Zayıf Nokta | Pasif | 5 | - | +%3→%15 Delme |
| Dans Eden Bıçaklar (İ1) | Aktif | 10 | 12 sn | 8 hızlı vuruş, %45→%100 |
| Duman Bombası (İ1) | Aktif | 10 | 20 sn | 4 sn parti kaçınma +%30 |
| İnfaz (İ1) | Pasif | 5 | - | HP'si %20 altındaki düşmana +%10→%50 hasar |
| Gölge Pelerini (İ1) | Pasif | 5 | - | Tehdit -1, kaçınma +%2→%10 |
| Gece Bıçağı: Ay Tutulması | Aktif | 10 | 18 sn | 3 sn gizlenir, sonra %600→%1400 tekil vuruş |
| Gece Bıçağı: Gece Avcısı | Pasif | 10 | - | Gerçek saat gece ise +%5→%25 hasar |
| Zehir Ustası: Veba Bulutu | Aktif | 10 | 15 sn | Zehir alanı, her saniye 2 yığın |
| Zehir Ustası: Zehir Patlaması | Pasif | 10 | - | Zehirli ölen düşman çevresine yığınlarını yayar |
| NİHAİ: Bin Bıçak | Nihai | 5 | Öfke | Ekranda gölge klonlar, %1200→%2800 dağıtılmış |

## 11.7 Büyücü (Mage)

**Fantezi:** Öz Kulesi'nin beyaz saçlı genç büyücüsü (referans afişteki beyaz saçlı karakter). **Silüet:** Sivri şapka, uzun cübbe, ucu parlayan kristal asa.

| Skill | Tür | Max Lv | CD | Etki |
|---|---|---|---|---|
| Ateş Topu | Aktif | 10 | 6 sn | %150→%340 Ateş, küçük patlama, Yanma |
| Buz Mızrağı | Aktif | 10 | 7 sn | %130→%300 Soğuk, delici, 2 yığın Donma |
| Arkana Odak | Pasif | 10 | - | +%4→%40 Büyü Gücü |
| Element Uyumu | Pasif | 6 | - | Tüm element hasarı +%3→%18 |
| Mana Kalkanı | Pasif | 5 | - | Hasarın %5→%25'ini emen kalıcı kalkan (her 10 sn yenilenir) |
| Hızlı Büyü | Pasif | 5 | - | +%4→%20 Büyü Hızı |
| Meteor (İ1) | Aktif | 10 | 18 sn | 1.5 sn gecikmeli, %400→%900 alan Ateş |
| Zincir Şimşek (İ1) | Aktif | 10 | 11 sn | 5 hedefe sekiyor, %140→%320 Yıldırım |
| Element Döngüsü (İ1) | Pasif | 5 | - | Farklı element kullanınca +%4→%20 hasar (5 sn) |
| Öz Pınarı (İ1) | Pasif | 5 | - | Bekleme süresi -%2→%10 |
| Ateş Arşmagı: Cehennem Halkası | Aktif | 10 | 20 sn | Ekranda 5 sn yanan halka, sn başı %150→%350 |
| Ateş Arşmagı: Kor Yüreği | Pasif | 10 | - | Yanma yığın sınırı 3→6 |
| Buz Cadısı: Mutlak Sıfır | Aktif | 10 | 22 sn | Tüm düşmanları 2 sn dondurur + %250→%600 |
| Buz Cadısı: Kristal Zırh | Pasif | 10 | - | Partiye +%2→%20 DR; donmuş düşmanlara +%30 kritik |
| NİHAİ: Arkana Fırtınası | Nihai | 5 | Öfke | Her elementten 12 büyü yağmuru, %1500→%3500 toplam |

## 11.8 Nekromant (Necromancer)

**Fantezi:** Uçurum Tapınağı'ndan sürgün edilmiş, iyi kalpli ama ürkütücü görünen genç. **Silüet:** Mor kukuleta, yeşil alevli tırpan, omzunda küçük kafatası maskotu.

| Skill | Tür | Max Lv | CD | Etki |
|---|---|---|---|---|
| İskelet Çağır | Aktif | 10 | 14 sn | 2→4 iskelet savaşçı (saldırının %30→%60'ı), 15 sn |
| Ruh Çekimi | Aktif | 10 | 9 sn | %140→%300 Kaos + verilen hasarın %10'u kadar parti iyileşmesi |
| Kemik Zırh | Pasif | 6 | - | Her çağrılan yaratık +%2→%6 DR |
| Karanlık Bilgi | Pasif | 10 | - | +%3→%30 Kaos Hasarı |
| Ceset Patlatma | Pasif | 5 | - | Ölen düşmanlar %10→%30 şansla patlar (max HP %15 alan hasarı) |
| Lanet | Pasif | 5 | - | Saldırılar 4 sn Zayıflatma uygular |
| Kemik Mızrağı (İ1) | Aktif | 10 | 8 sn | Delici, %180→%400 Fiziksel |
| Ölüm Laneti (İ1) | Aktif | 10 | 16 sn | Hedef 6 sn Kırılgan + Kaos direnci -%20 |
| Lejyon (İ1) | Pasif | 5 | - | Max çağrı +1→+3 |
| Ruh Hasadı (İ1) | Pasif | 5 | - | Her öldürme öfke barını +%1→%3 doldurur |
| Kemik Lordu: Kemik Golem | Aktif | 10 | 40 sn | Kalıcı golem (tank, tehdit +3) |
| Kemik Lordu: Kemik Hükümdarı | Pasif | 10 | - | Çağrılar +%5→%50 hasar ve HP |
| Veba Getiren: Kara Ölüm | Aktif | 10 | 14 sn | Tüm düşmanlara 5 yığın Zehir + yayılma |
| Veba Getiren: Çürüme | Pasif | 10 | - | Zehir hasarı +%5→%60 |
| NİHAİ: Ölüler Ordusu | Nihai | 5 | Öfke | 12 sn boyunca 10 hayalet asker hücum eder |

## 11.9 Rahibe (Cleric)

**Fantezi:** Kutsal Krallık'tan neşeli, sarı saçlı rahibe (referans afişteki sarışın küçük karakter). **Silüet:** Beyaz-altın cübbe, başında hale, büyük kutsal kitap, kısa topuz.

| Skill | Tür | Max Lv | CD | Etki |
|---|---|---|---|---|
| Şifa Işığı | Aktif | 10 | 5 sn | En düşük HP'li müttefik %120→%300 Büyü Gücü iyileşme |
| Kutsal Şimşek | Aktif | 10 | 8 sn | %130→%280 Kutsal hasar, ölümsüzlere x2 |
| Kutsal Bilgelik | Pasif | 10 | - | İyileştirme +%3→%30 |
| Koruyucu Melek | Pasif | 5 | - | Ölen müttefik 15→7 sn'de dirilir |
| Kutsama | Pasif | 6 | - | Partiye +%1→%6 Savunma ve tüm direnç |
| Arınma | Pasif | 3 | - | İyileştirme durum etkilerini temizler (Lv3: 2 etki) |
| Toplu Şifa (İ1) | Aktif | 10 | 15 sn | Tüm parti %80→%180 iyileşme |
| Işık Kalkanı (İ1) | Aktif | 10 | 12 sn | Ön slottakine %200→%500 kalkan |
| Diriliş (İ1) | Pasif | 1 | - | 90 sn'de bir ölen müttefiği anında diriltir |
| Lütuf (İ1) | Pasif | 5 | - | İyileştirilen müttefik 3 sn +%2→%10 hasar |
| Işık Azizi: Cennet Kapısı | Aktif | 10 | 30 sn | 6 sn parti her sn %10→%25 iyileşir |
| Işık Azizi: Mucize | Pasif | 10 | - | İyileştirmeler %5→%25 kritik yapabilir (x2) |
| Savaş Rahibesi: Kutsal Topuz | Aktif | 10 | 9 sn | %220→%500 Kutsal + parti iyileşmesi hasarın %20'si |
| Savaş Rahibesi: İnanç Gücü | Pasif | 10 | - | Büyü Gücünün %10→%60'ı Saldırı olarak eklenir |
| NİHAİ: Tanrıça'nın Gözyaşı | Nihai | 5 | Öfke | Tüm parti tam iyileşir + 5→10 sn ölümsüzlük |

## 11.10 Ozan (Bard)

**Fantezi:** Gezgin, şakacı, tüylü şapkalı genç. Kahramanlara moral verir. **Silüet:** Yeşil-turuncu kıyafet, tüylü şapka, sırtta lavta, nota parçacıkları.

| Skill | Tür | Max Lv | CD | Etki |
|---|---|---|---|---|
| Cesaret Şarkısı | Aktif | 10 | 20 sn | 10 sn partiye +%10→%30 hasar |
| Uyumsuz Akor | Aktif | 10 | 9 sn | %120→%260 Yıldırım alan + Şok |
| Ritim | Pasif | 10 | - | Partiye +%1→%10 Saldırı Hızı |
| Neşe | Pasif | 5 | - | Partiye +%2→%10 XP bonusu |
| Hızlı Parmaklar | Pasif | 5 | - | Buff süresi +%5→%25 |
| Şans Melodisi | Pasif | 6 | - | Partiye +%3→%18 Item Bulma |
| Ninni (İ1) | Aktif | 10 | 18 sn | 3 düşmanı 1.5→3 sn uyutur |
| Kahramanlık Destanı (İ1) | Aktif | 10 | 25 sn | 8 sn tüm parti skill bekleme -%30 |
| Koro (İ1) | Pasif | 5 | - | Aynı anda 2 şarkı aktif olabilir |
| Altın Ses (İ1) | Pasif | 5 | - | +%4→%20 Altın Bulma |
| Savaş Marşçısı: Davul Gürültüsü | Aktif | 10 | 20 sn | 10 sn parti +%15→%40 kritik hasar ve hız |
| Savaş Marşçısı: Marş | Pasif | 10 | - | Cesaret Şarkısı etkisi x1.5 |
| Huzur Şairi: Huzur Melodisi | Aktif | 10 | 18 sn | 6 sn sn başı %3→%8 parti iyileşmesi + durum temizleme |
| Huzur Şairi: Sükunet | Pasif | 10 | - | Parti +%2→%15 tüm direnç |
| NİHAİ: Efsanelerin Şarkısı | Nihai | 5 | Öfke | 12 sn: tüm parti nihai barı x2 hızla dolar, +%40 tüm hasar |

## 11.11 Sınıf Sinerjileri (Parti Bonusları)

Belirli sınıf kombinasyonları ek bonus verir (Parti panelinde ikonla gösterilir):

| Sinerji | Gereken | Bonus |
|---|---|---|
| Kutsal Üçlü | Şövalye + Rahibe + Ozan | +%10 tüm parti HP |
| Element Fırtınası | Büyücü + Okçu (Doğa) veya Barbar (Fırtına) | +%10 element hasarı |
| Gölgeler | Suikastçı + Nekromant | +%8 kritik şansı |
| Demir Duvar | 2 Ağır zırh sınıfı ön slotta | +%10 Savunma |
| Tam Orkestra | 5 farklı sınıf | +%5 tüm statlar, +%10 XP |
| Aynı Sınıf x2 | 2 aynı sınıf | -%5 (çeşitliliği teşvik) |
