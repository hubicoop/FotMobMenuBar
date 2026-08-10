# FotMob Menü Çubuğu

Favori takımların bugünkü maçlarını macOS menü çubuğunda gösteren küçük bir SwiftUI uygulaması. Canlı maçta 30 saniyede, diğer zamanlarda 2 dakikada bir yenilenir ve skor yükseldiğinde macOS bildirimi gönderir.

## Derleme

macOS 13 veya üzeri ve Swift 6 gerekir. Tam Xcode zorunlu değildir.

```sh
cd ~/FotMobMenuBar
./Scripts/build-app.sh
open dist/FotMobMenuBar.app
```

İlk açılışta bildirim izni verin. Uygulama yalnızca menü çubuğunda görünür; futbol topu simgesinden takım arayıp favori ekleyebilirsiniz.

## Oturum Açınca Başlatma

Uygulamayı bir kez `Applications` klasörüne taşıdıktan sonra macOS **Sistem Ayarları > Genel > Giriş Öğeleri** bölümünden ekleyebilirsiniz.

## Veri Kaynağı

Veriler FotMob web istemcisinin herkese açık olarak erişebildiği uçlardan okunur. FotMob resmi bir genel API sunmadığı için bu uçlar ileride değişebilir. Uygulama FotMob ile bağlantılı veya FotMob tarafından desteklenen resmi bir ürün değildir.
