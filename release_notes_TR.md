# İş Emri Uygulaması — Sürüm Notları
**Tarih:** 20.11.2026

---

## Genel Bakış

Bu güncelleme, İş Emri bakım ekranında test sürecinde tespit edilen bir dizi sorunu gidermektedir. Kullanıcılar artık tek bir kayıt işleminde birden fazla bileşen, operasyon ve partner ekleyebilir, değiştirebilir ve silebilir. Desteklenmeyen işlem kombinasyonları denendiğinde kullanıcıyı yönlendiren açık hata mesajları da eklenmiştir.

---

## Düzeltilen Hatalar

### 1. Aynı anda birden fazla bileşen ekleme artık çalışıyor

**Önceki durum:** Kullanıcı iki veya daha fazla yeni bileşen satırı ekleyip kaydettiğinde yalnızca sonuncusu iş emrine kaydediliyordu. İlk satırlar sessizce kayboluyordu.

**Yeni durum:** Eklenen tüm bileşen satırları tek bir kayıt işleminde doğru şekilde kaydedilir.

---

### 2. Aynı anda birden fazla bileşen silme artık çalışıyor

**Önceki durum:** Kullanıcı iki veya daha fazla mevcut bileşeni seçip sildiğinde yalnızca biri gerçekten iş emrinden kaldırılıyordu.

**Yeni durum:** Seçilen tüm bileşenler tek bir kayıt işleminde silinir.

---

### 3. Bileşen miktarı değiştirme artık hata vermiyor

**Önceki durum:** Mevcut bir bileşenin gerekli miktarı düzenlendiğinde "ölçü birimi dönüştürülemiyor" hatası oluşuyor ve değişiklik kaydedilemiyordu.

**Yeni durum:** Miktar ve birim değişiklikleri doğru şekilde kaydedilir.

---

### 4. Aynı anda birden fazla partner ekleme artık çalışıyor

**Önceki durum:** Kaydetmeden önce Partner Ekle düğmesine birden fazla kez basıldığında ikinci basışta sistem çöküyordu.

**Yeni durum:** Birden fazla partner hatasız olarak tek bir işlemde eklenip kaydedilebilir.

---

### 5. Aynı anda birden fazla partner silme artık çalışıyor

**Önceki durum:** Aynı anda birden fazla partner seçilip silindiğinde hata oluşuyor ve hiçbir partner kaldırılmıyordu.

**Yeni durum:** Seçilen tüm partnerlar tek bir kayıt işleminde başarıyla silinir.

---

### 6. Malzeme arama listesi artık iş emrinin tesisine göre filtreleniyor

**Önceki durum:** Bileşen için malzeme seçilirken arama listesi, tesisten bağımsız olarak sistemdeki tüm malzemeleri gösteriyordu.

**Yeni durum:** Malzeme araması artık yalnızca iş emrinin planlama tesisinde mevcut malzemeleri gösterir; alakasız sonuçlar azaltılarak seçim hızlandırılır.

---

## Yeni Doğrulama Kuralları

Sistemin otomatik olarak çözemediği hataları önlemek amacıyla aşağıdaki kısıtlamalar eklenmiştir. Bu kurallardan biri ihlal edilirse açık bir hata mesajı gösterilir ve kayıt engellenir. Kullanıcının taslağı atıp doğru sırayla yeniden denemesi gerekir.

---

### Kural 1: Aynı kayıtta partner eklenip silinemez

Aynı kayıt işleminde yeni bir partner ekleyip mevcut bir partneri silmek mümkün değildir. Bir işlemi yapıp kaydedin, ardından iş emrini tekrar açıp ikinci işlemi gerçekleştirin.

**Göreceğiniz hata mesajı:**
> *"Cannot add and delete partners in one save. Discard draft, then do only one operation."*
> *(Aynı kayıtta partner ekleyip silemezsiniz. Taslağı atın, ardından yalnızca bir işlem yapın.)*

---

### Kural 2: Daha önce kaydedilmiş bir partner doğrudan düzenlenemez

Bir partner sisteme daha önce kaydedilmişse, satır üzerinde düzenleme yapılarak alanları değiştirilemez. Partneri değiştirmek için mevcut olanı silin ve doğru değerlerle yeniden ekleyin.

**Göreceğiniz hata mesajı:**
> *"Partner already saved - changes not allowed. Discard the draft and delete/re-add the partner."*
> *(Partner zaten kaydedilmiş - değişikliklere izin verilmiyor. Taslağı atın ve partneri silip yeniden ekleyin.)*

---

### Kural 3: Kayıt başına yalnızca bir bölüm değiştirilebilir

SAP PM iş emri işlemesindeki teknik bir kısıtlama nedeniyle, aynı kayıt işleminde iki farklı bölümde (Bileşenler, Operasyonlar, Partnerlar) değişiklik kaydedilemez. Her bölüm ayrı ayrı kaydedilmelidir.

Örneğin: aynı kayıtta hem bileşen ekleyip hem partner eklemek mümkün değildir. Önce bileşeni kaydedin, ardından iş emrini tekrar açıp partneri ekleyin.

**Göreceğiniz hata mesajı:**
> *"Only one section per save (comp/op/partner). Discard draft and save each section separately."*
> *(Kayıt başına yalnızca bir bölüm - bileşen/operasyon/partner. Taslağı atın ve her bölümü ayrı ayrı kaydedin.)*

---

## Taslak Nasıl Atılır

Yukarıdaki hatalardan birini aldıysanız şu adımları izleyin:

1. Sipariş ekranının üst kısmındaki **Discard (At)** düğmesine tıklayın ("Draft" / "Taslak" göstergesinin yanında yer alır).
2. İstendiğinde atmayı onaylayın.
3. Sipariş en son kaydedilen durumuna döner.
4. Siparişi yeniden açın, yalnızca bir tür değişiklik yapın ve kaydedin.
