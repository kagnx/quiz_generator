# 🤖 Quiz Generator AI

**Quiz Generator AI**, belgelerinizden (Word, Excel, PowerPoint) yapay zeka desteğiyle saniyeler içinde profesyonel çoktan seçmeli testler üreten, modern ve kullanıcı dostu bir Flutter uygulamasıdır.

## 🌟 Öne Çıkan Özellikler

- 📄 **Geniş Belge Desteği:** `.docx`, `.xlsx` ve `.pptx` dosyalarını doğrudan cihaz üzerinde analiz eder.
- 🤖 **5 Farklı AI Sağlayıcısı:** 
  - **Claude** (Anthropic)
  - **ChatGPT** (OpenAI)
  - **Gemini** (Google) - *Ücretsiz kota desteği*
  - **DeepSeek**
  - **Ollama** (Tamamen yerel ve ücretsiz)
- 📚 **Chunking Mimarisi:** Devasa ders kitaplarını veya uzun belgeleri "parçalayarak" işleme yeteneği sayesinde "Token Limit" hatalarına düşmez.
- 📊 **Profesyonel Analiz:** Sınav sonunda başarı oranınızı gösteren interaktif pasta grafikleri ve istatistik kartları.
- 📤 **Çoklu Dışa Aktarma:**
  - **PDF:** Yazdırılabilir, cevap anahtarlı sınav kağıdı.
  - **İnteraktif HTML:** Herhangi bir tarayıcıda çalışan, anlık geri bildirimli dijital test.
  - **Word:** Düzenlenebilir belge formatı.
- 🎨 **Modern UI/UX:** Material 3 tasarımı, büyük fontlar (okuma konforu), akıcı animasyonlar ve "Premium" uygulama hissi.
- 🔐 **Güvenlik:** API anahtarlarınız cihazınızda şifreli (Encrypted) olarak saklanır.

## 🛠️ Kurulum ve Çalıştırma

Projeyi yerel bilgisayarınızda çalıştırmak için aşağıdaki adımları izleyin:

### Gereksinimler
- **Flutter SDK:** `3.2.0` veya üzeri
- **Java JDK:** `17` veya üzeri
- **Android SDK:** API 36 (Compile SDK)
- **Windows için:** Visual Studio 2022 (C++ Build Tools yüklü olmalı)

### Adımlar

1.  **Projeyi Klonlayın:**
    ```bash
    git clone https://github.com/kullanici-adiniz/quiz_generator_flutter.git
    cd quiz_generator_flutter
    ```

2.  **Bağımlılıkları Yükleyin:**
    ```bash
    flutter pub get
    ```

3.  **Android Yapılandırması:**
    `android/local.properties` dosyasının içine SDK yollarınızı ekleyin:
    ```properties
    sdk.dir=C:\\Users\\Kullanici\\AppData\\Local\\Android\\Sdk
    flutter.sdk=C:\\flutter
    ```

4.  **Uygulamayı Çalıştırın:**
    - Android için: `flutter run -d android`
    - Windows için: `flutter run -d windows`
    - Web için: `flutter run -d chrome`

## 📦 APK Alma (Release Build)

Uygulamanın optimize edilmiş APK dosyasını oluşturmak için:

```bash
flutter build apk --release --split-per-abi
```
*Çıktı konumu: `build/app/outputs/flutter-apk/`*

## 💡 AI Sağlayıcı Kurulumu (Ollama Örneği)
Uygulamanın en güçlü özelliklerinden biri tamamen yerel çalışan **Ollama** desteğidir:
1. Bilgisayarınıza [Ollama](https://ollama.com) kurun.
2. `ollama pull llama3.2` komutuyla modeli indirin.
3. Telefonunuzla bilgisayarınızı aynı Wi-Fi ağına bağlayın.
4. Ayarlar kısmından bilgisayarınızın yerel IP adresini girin (Örn: `http://192.168.1.5:11434`).

## 👨‍💻 Geliştirici
**Oğuz Kaan FIRAT**
- 📸 Instagram: [@kagnx](https://instagram.com/kagnx)
- 👥 Facebook: [@kagnx](https://facebook.com/kagnx)

## 📜 Lisans
Copyright © 2026 Her Hakkı Saklıdır.
Bu proje eğitim ve kişisel kullanım amacıyla geliştirilmiştir.
