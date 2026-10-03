# Mağaza ve Steam ödemeleri

## Şu anki durum
- Mağaza: kasabadaki **Mağaza** tabelası → `scripts/ui/panels/shop_panel.gd`.
- Ürünler: `game/data/shop.json`.
  - `price.gold_kills`: ürün oyun içi altınla alınır.
  - `price.try` / `price.usd`: ürün gerçek parayla alınır.
- Satın alma mantığı `scripts/systems/shop.gd` dosyasında:
  - Her sipariş `GameState.purchases[order_id]` içine yazılır.
  - Aynı sipariş ikinci kez verilmez.
  - Oyun satın almadan hemen sonra kaydedilir.
- Ödeme `SteamService.purchase()` üzerinden geçer. Varsayılan mod **direct**: ödeme alınmaz, ürün hemen verilir. Mağazada "Test modu" yazar.

## Steam'e bağlamak için
Steam mikro işlemleri bir sunucu gerektirir, çünkü yayıncı Web API anahtarı oyunun içine konamaz.

1. Steamworks'te uygulama için mikro işlemleri aç. Yayıncı Web API anahtarını yalnızca sunucuda tut.
2. Küçük bir backend yaz. İki uç noktası olsun:
   - `POST /init` — `{steamid, item, product, language}` alır.
     - `ISteamMicroTxn/InitTxn/v3` çağırır. Bu çağrıya `orderid`, `itemid[0]`, `qty`, `amount`, `currency` ve açıklama gider.
     - `{order_id}` döner.
     - Tutar ve para birimi sunucu tarafında, oyuncunun bölgesine göre belirlenir. İstemciye güvenilmez.
   - `POST /finalize` — `{order_id}` alır.
     - `ISteamMicroTxn/FinalizeTxn/v2` çağırır.
     - Başarılıysa `{result: "OK"}` döner.
3. Oyuna GodotSteam eklentisini ekle.
4. Project Settings'te iki ayar yap:
   - `idle_party/payments/mode = "steam"`
   - `idle_party/payments/backend_url = "https://..."`
5. Akış şöyle işler:
   1. İstemci `/init` çağırır.
   2. Steam overlay açılır.
   3. Oyuncu onaylar.
   4. `microtransaction_auth_response` sinyali gelir.
   5. İstemci `/finalize` çağırır.
   6. `Shop.grant()` ürünü verir.

`steam_item` alanı, InitTxn'e giden `itemid` değeridir.

## Fiyatlar (TL)
Mağazada her şey gerçek parayla alınır. Savaşta sandık düşmesi eskisi gibi devam eder.

| Ürün | İçerik | Fiyat |
|---|---|---|
| Demir Sandık Yığını | 5 Demir Sandık | 10 ₺ |
| Altın Sandık Dörtlüsü | 4 Altın Sandık | 20 ₺ |
| Kristal Üçlüsü | 3 Kristal Sandık | 34,99 ₺ |
| Kraliyet Hazinesi | 5 Kraliyet Sandığı | 89,99 ₺ |
| Altın paketleri | Parti seviyesine göre ölçeklenir | 19,99 / 49,99 / 109,99 ₺ |
| Rastgele Kahraman | R %70 · SR %25 · SSR %5 | 25 ₺ |
| Seçilen SR kahraman | 1 SR kahraman | 50 ₺ |
| Seçilen SSR kahraman | 1 SSR kahraman | 80 ₺ |
| Başlangıç Paketi (tek sefer) | 2 rastgele kahraman, 5 Kristal sandık, 75.000 altın | 100 ₺ |
| Zaman Kum Saati (tek sefer) | Kalıcı +%15 offline verim, +4 saat | 50 ₺ |
| Büyük Çanta | +20 yer (en fazla 3 kez) | 24,99 ₺ |
| Taverna Mühürleri | 5 mühür | 39,99 ₺ |
