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

| Ürün | Fiyat |
|---|---|
| Rastgele kahraman (R %70 / SR %25 / SSR %5) | 50 ₺ |
| Seçilen SR kahraman | 79,99 ₺ |
| Seçilen SSR kahraman | 129,99 ₺ |
| Altın paketleri | 19,99 / 49,99 / 109,99 ₺ |

Altın paketlerinin verdiği miktar parti seviyesiyle ölçeklenir.
