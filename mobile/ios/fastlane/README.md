fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios signing

```sh
[bundle exec] fastlane ios signing
```

Apple Distribution sertifikası + App Store provisioning profili oluştur

### ios build

```sh
[bundle exec] fastlane ios build
```

Flutter ile imzalı App Store IPA üret (prod API_BASE gömülü)

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Build + TestFlight'a yükle

### ios download_metadata

```sh
[bundle exec] fastlane ios download_metadata
```

App Store'dan mevcut metadata'yı çek (yedek için)

### ios update_review_info

```sh
[bundle exec] fastlane ios update_review_info
```

Sadece review information (notes + demo creds + iletişim) güncelle

### ios upload_metadata

```sh
[bundle exec] fastlane ios upload_metadata
```

App Store metadata + screenshot yükle (review'a göndermez)

### ios submit

```sh
[bundle exec] fastlane ios submit
```

App Store review'a gönder (App Privacy doldurulduktan sonra)

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
