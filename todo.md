# Obsidian geliştirme yol haritası

> Bu dosya `AGENTS.md` uygulama sözleşmesini yürütülebilir, sürüm bazlı işlere böler.
> Bir kutu yalnızca kod, test, belge ve desteklenen backend kanıtları birlikte mevcutsa işaretlenir.
> Planlama tarihi: 2026-11-05.

## 1. Mevcut durum

- [x] `AGENTS.md` okundu ve geliştirme kapıları bu plana aktarıldı.
- [x] Proje dizini incelendi: başlangıçta yalnızca `AGENTS.md` vardı; henüz Git deposu değildi.
- [x] Yerel araç gözlemleri kaydedildi: başlangıç `2.0.143`; Faz 9 önkoşulu olarak destek pini checksum-doğrulanmış `2.1.0` / `fd107b92…` sürümüne yükseltildi; final kanıt izole arşivden alınıyor.
- [x] Upstream ana dal gözlemi kaydedildi: `01fc411f3a17b969ceff984fbd46b9e857a592d1` (`v2.0.170`, 2026-11-05 tarihinde görülen son commit).
- [x] Test edilecek NOX revizyonu seçilip sabitlendi.
- [x] İzole final test derleyicisi, sabitlenen revizyon ve `docs/compatibility.md` aynı sürümü gösteriyor; ambient kullanıcı kurulumu destek kanıtına dahil edilmiyor.
- [x] Phase 0 yerel kapısı geçti; macOS arm64 LLVM/QBE kanıtı kaydedildi.
- [x] Phase 1 yerel kapısı geçti; senkron çekirdek iki backend'de doğrulandı.
- [x] GitHub CI üzerinden macOS arm64 ve Linux x64/arm64 kanıtı alındı.
- [x] Phase 2 formatter ve gerçek tüketici paket grafiği, GitHub CI run `42171234012` ile macOS arm64 ve Linux x64/arm64 üzerinde LLVM/QBE geçti.

Not: Yukarıdaki upstream commit yalnızca planlama anındaki gözlemdir; uyumluluk revizyonu olarak henüz onaylanmış değildir. Kurulu derleyici ile upstream arasında sürüm farkı bulunduğu için gerçek uyumluluk deneyi yapılmadan hiçbir NOX API'si varsayılmayacaktır.

## 2. Durum ve kanıt kuralları

Görev durumları:

- `[ ]`: başlanmadı veya kanıtı eksik.
- `[x]`: tanımlı kabul ölçütü karşılandı ve kanıtı kaydedildi.
- `BLOCKED`: dış bağımlılık ya da doğrulanmış platform eksikliği var; neden ve güvenli geri dönüş yazıldı.
- `DEFERRED`: mevcut sürüm kapsamı dışında; ilgili ADR/TODO bağlantısı var.

Bir faz kapatılmadan önce:

- Derleme ve test komutlarının tam metni kaydedilecek.
- Test vakası, assertion ve skip sayıları ayrı raporlanacak.
- Skip edilen test başarı olarak sayılmayacak.
- QBE/LLVM sonucu ayrı gösterilecek; çalıştırılmayan platform için destek iddiası yapılmayacak.
- Güvenlik testlerinde maskesiz sentinelin hiçbir sink, snapshot, hata veya tanı çıktısında bulunmadığı kanıtlanacak.
- Değişen API için aynı değişiklikte doküman, örnek, test ve `CHANGELOG.md` güncellenecek.
- “Güvenli”, “thread-safe”, “production-ready” ve benzeri iddialar yalnızca ölçülmüş kanıtla kullanılacak.

## 3. Sürüm–faz haritası

| Planlanan sürüm | AGENTS fazları | Çıktı | Yayın durumu |
|---|---:|---|---|
| `0.0.x` | 0 | Yetkinlik denetimi, iskelet, sabit araç zinciri | Yayınlanmaz |
| `0.1.x` | 1 | Senkron çekirdek, kayıt modeli, bellek sink'i | İç geliştirme |
| `0.2.x` | 2–4 | Güvenli text/JSONL, console/file sink, zorunlu redaction | Güvenlik kapısından sonra alpha |
| `0.3.x` | 5–6 | Immutable context, doğrulanmış config, rotation/retention | Alpha/beta adayı |
| `0.4.x` | 7–8 | Koşullu async, filtreleme, sampling, diagnostics | Yalnızca concurrency kanıtlanırsa |
| `0.5.x` | 9 | Bağımsız ekosistem adaptörleri | Entegrasyon önizlemesi |
| `0.9.x` | 10–11 | Hardening, benchmark, fuzz/stress, API freeze | Beta/RC |
| `1.0.0` | 12 | Doğrulanmış kararlı sürüm | Tüm release gate'leri geçince |

Bu sürümler yayınlanmış sürümler değildir. Bir sonraki sürüme geçiş, önceki fazın kapısını geçmeye bağlıdır. Phase 7 güvenli biçimde kanıtlanamazsa async kapalı ve desteklenmiyor olarak kalabilir; bu durum senkron çekirdeğin ilerlemesini engellemez.

---

## 4. `0.0.x` — Phase 0: yetkinlik denetimi ve iskelet

### 4.1 Kaynak ve araç zinciri sabitleme

- [x] Git deposunu başlat; varsayılan dal ve `.gitignore` politikasını belirle.
- [x] Upstream NOX için kullanılacak tam commit SHA'yı seç.
- [x] Sabitlenen SHA'nın sürüm numarasını, yayın/tag durumunu ve imza bilgisini kaydet.
- [x] `noxc --version` çıktısının seçilen revizyonla eşleşmesini sağla.
- [x] Derleyici kurulum/doğrulama adımlarını yeniden üretilebilir biçimde belgele.
- [x] Mevcut kullanıcı kurulumunu değiştirme; yerel test cache'ini ve CI araç zincirini proje/geçici dizinlerde izole et.
- [x] `noxc fmt`, `check`, `build`, `run`, `test`, `--backend llvm` ve `--backend qbe` komutlarını küçük deneylerle doğrula.

### 4.2 Zorunlu NOX uyumluluk denetimi

- [x] Sabit commit üzerinden `docs/stdlib/log.md` incelendi.
- [x] `docs/stdlib/json.md` incelendi; `JsonWriter` nesting doğrulaması yapmadığı için formatter test gereksinimi kaydedildi.
- [x] `docs/stdlib/fs.md` incelendi; path canonicalization/symlink ve açık handle yaşam döngüsü riskleri kaydedildi.
- [x] `docs/stdlib/os.md` incelendi; eksik env değişkeninde `OsError` davranışı doğrulandı.
- [x] `docs/stdlib/time.md` incelendi; wall clock ile monotonic clock ayrımı kaydedildi.
- [x] `docs/stdlib/thread.md` incelendi; backend tip sınırlamaları ve join semantiği kaydedildi.
- [x] `docs/stdlib/atomic.md` incelendi; explicit `free()` ve worker yaşam süresi riski kaydedildi.
- [x] `docs/language/concurrency.md` incelendi; LLVM M:N ve QBE cooperative ayrımı kaydedildi.
- [x] `docs/internals/architecture.md` incelendi; private ABI/runtime kullanım yasağı kaydedildi.
- [x] Gerçek paket/import kuralları ve `nox.json`/`nox.lock` davranışı deneyle doğrulandı.
- [x] Test framework'ünün assertion, fixture, stdout/stderr capture, temp path ve skip olanakları denetlendi; bulunmayan yardımcılar uyumluluk belgesine kaydedildi.
- [x] Exception introspection, TTY algılama, flush/fsync, path canonicalization ve random/seed API'lerinin varlığı ayrı ayrı denetlendi.
- [x] Eksik her yetenek için “fallback / defer / NNI gereksinimi” kararı yazıldı; hayali API eklenmedi.
- [x] Bulgular `docs/compatibility.md` içinde API, profil, LLVM, QBE, platform, kanıt ve kısıt sütunlarıyla kaydedildi.

### 4.3 İskelet ve tasarım belgeleri

- [x] NOX'un doğrulanmış proje-kökü modül düzenine göre source, `tests`, `examples` ve `docs` yapısını oluştur.
- [x] `nox.json` oluştur; sürüm, entry/package düzeni ve bağımlılık politikasını doğrula.
- [x] Üretilirse `nox.lock` dosyasını commit etme politikasını belgele.
- [x] `README.md`, `CHANGELOG.md`, `LICENSE` ve `SECURITY.md` başlangıç dosyalarını oluştur.
- [x] `docs/architecture.md` oluştur; saf katmanlar ile I/O katmanlarını ayır.
- [x] `docs/decisions/0001-core-architecture.md` oluştur.
- [x] `docs/decisions/0002-field-value-model.md` içinde typed model yönünü ve Phase 1 compile sorularını kaydet.
- [x] `docs/decisions/0003-error-policy.md` içinde raise/status/diagnostics yönünü ve gerekli kanıtları kaydet.
- [x] `docs/decisions/0004-package-layout.md` oluştur; denenmiş import söz dizimini kaydet.
- [x] Gerçek çok-modüllü tüketici probu sonrası ADR-0006 ile package self-import ve hermetik test düzenini düzelt.
- [x] CI iskeletini belgelenen macOS/Linux runner ve LLVM/QBE matrisiyle oluştur; sonuç gelene kadar platform desteği iddia etme.
- [x] CI; test vaka/assertion/skip sayılarını ayrı raporlayacak şekilde tasarlandı.

### 4.4 Minimal doğrulamalar

- [x] En küçük Obsidian modülü LLVM ile import edilip çalıştırıldı.
- [x] Aynı import QBE ile çalıştırıldı.
- [x] En küçük test her iki desteklenen backend'de çalıştı.
- [x] Yanlış import ve yanlış tip için negatif compile test eklendi.
- [x] Build çıktıları/temporary dosyalar kaynak dizini kirletmiyor.

### Phase 0 kapısı

- [x] Sabit NOX SHA, eşleşen `noxc`, dolu `docs/compatibility.md` ve yeniden üretilebilir hello-world kanıtı mevcut.
- [x] Hiçbir kaynak dosyasında doğrulanmamış NOX API'si yok.
- [x] Desteklenmeyen platform/backend kombinasyonları gerekçeli ve görünür.

---

## 5. `0.1.x` — Phase 1: senkron çekirdek

### 5.1 Seviye modeli

- [x] `TRACE`, `DEBUG`, `INFO`, `WARNING`, `ERROR`, `CRITICAL`, `OFF` sayısal olarak tanımlandı.
- [x] `WARN` alias kararı belgelendi ve `nox.log.WARN` eşlemesi test edildi.
- [x] Karşılaştırmalar string sırasına değil sayısal severity'ye dayanıyor.
- [x] Bilinmeyen seviye pozitif/negatif testlerle ele alınıyor.
- [x] `is_enabled` record/clock/formatlama yolundan önce sonuç veriyor; disabled çağrının clock okumadığı testli.

### 5.2 Alan ve kayıt modeli

- [x] `FieldValue`/`LogField` tipi gerçek NOX tip sistemiyle derleniyor.
- [x] String, int, float, bool, null politikası açık; nested array/object Phase 2 öncesi compile/ownership deneyine ertelendi.
- [x] Reserved key listesi ve collision politikası tanımlandı.
- [x] `Logger` clock'u tek sefer okuyup caller'dan izole `LogRecord` snapshot'ı oluşturuyor.
- [x] Caller-owned collection sonradan değişse bile record değişmiyor.
- [x] Logger adı sınırları uygulandı; message ve correlation ID sınırları Phase 5 typed config/context çalışmasına açıkça ertelendi.
- [x] Source/exception alanları bulunmadığında kayıt üretimi deterministik çalışıyor; capture API'si kanıtlanana kadar bu alanlar eklenmiyor.

### 5.3 Clock, sink ve logger

- [x] Production clock ve deterministik fake clock için doğrulanmış explicit abstraction var.
- [x] Sink sözleşmesi (`write`, `flush`, `close`, isim/yetenek) NOX ile compile edildi.
- [x] Bounded `MemorySink` ring buffer olarak uygulandı.
- [x] `MemorySink.snapshot()` mutable iç depoyu açığa çıkarmıyor.
- [x] Capacity aşımında drop-oldest davranışı ve sayacı test edildi.
- [x] `close()` idempotent; kapalı logger/sink davranışı belgeli.
- [x] `Logger` explicit ad/threshold/clock alıyor; default global logger yok.
- [x] Senkron dispatcher call order'ı koruyor.
- [x] Aynı captured timestamp/veri snapshot'ı tüm sink'lere gidiyor.
- [x] Stable sink registration ID, yalnız hedef sink'i kaldıran `remove_sink`, `flush`, `close` davranışları tanımlandı.
- [x] Sink callback re-entry sınırlaması uygulandı; recursion kontrolü test edildi.
- [x] Dispatcher lock-free; sink callback logging lock'u altında çağrılmıyor.

### 5.4 Phase 1 testleri ve belgeleri

- [x] Severity mapping ve threshold boundary testleri.
- [x] Disabled call'ın record/clock üretmediği test.
- [x] Record snapshot isolation testi.
- [x] Çoklu sink fan-out eşitliği testi.
- [x] Memory capacity/drop/snapshot testi.
- [x] Registration/remove/flush/idempotent close testleri.
- [x] Sink failure için negative test; hata çağırana geri dönüyor, sessiz veri kaybı yok.
- [x] Fake clock ile exact record fixture ve deterministik end-to-end örnek.
- [x] `docs/api.md` içinde internal/public API ayrımı.
- [x] `examples/hello.nox` ve `examples/memory_logging.nox` iki backend'de compile/run edildi.
- [x] Toplam en az 20 anlamlı test; 4 dosya ve 99 assertion ayrıca raporlandı.

### Phase 1 kapısı

- [x] Record construction, numeric filtering, lifecycle ve senkron sıralama kanıtlandı.
- [x] Gizli global mutable logger/context yok.
- [x] LLVM ve QBE deterministik test sonuçları kaydedildi.

---

## 6. `0.2.x` — Phase 2: text ve JSONL formatter

### 6.1 Text formatter

- [x] Tek satırlı varsayılan format ve stable field ordering tanımlandı.
- [x] Newline, tab, carriage return ve kontrol karakterleri log forging'i önleyecek biçimde escape ediliyor.
- [x] UTC timestamp biçimi doğrulanmış NOX time API'siyle üretiliyor.
- [x] Phase 2'de ANSI yolu yok; TTY kanıtlanana kadar renk kapalı ve `NO_COLOR` ile uyumlu.
- [x] ANSI JSON/file çıktısına sızmıyor.
- [x] Mesaj/string alanı 65.536 code point, fields/context bölümü 256 unique key ile bounded.

### 6.2 JSONL formatter

- [x] Şema sürümü ve reserved alanlar belgelendi.
- [x] `JsonWriter`/`dump_string` kullanılıyor; untrusted scalar değerler concat ile encode edilmiyor.
- [x] Her event tam bir JSON object ve tam bir newline üretiyor.
- [x] String/int/finite-float/bool/null korunuyor; nested model ADR-0002 kapsamında açıkça deferred.
- [x] Embedded newline JSON string içinde escape ediliyor.
- [x] Non-finite float politikası reject olarak açık ve testli.
- [x] Tagged model unknown/unsupported value'ları fail-closed reddediyor; invalid JSON üretmiyor.
- [x] Null, boş string ve eksik alan ayrımı korunuyor.

### 6.3 Formatter testleri

- [x] Unicode ve non-ASCII round-trip.
- [x] Quote, backslash ve tüm JSON kontrol karakterleri.
- [x] Multiline injection ve terminal escape girdileri.
- [x] Büyük mesaj ve sınır değerleri.
- [x] Her JSONL satırını `nox.json.parse` ile tekrar parse etme.
- [x] Tip koruma assertion'ları.
- [x] Exact golden yapı testi; incidental map order'a bağımlı değil.
- [x] Formatter hata yolunda orijinal unsafe record emit edilmiyor.
- [x] `examples/json_logging.nox`, ADR-0005 ve formatter API belgeleri.

### Phase 2 kapısı

- [x] Üretilen tüm JSONL satırları geçerli ve desteklenen scalar tipleri koruyor.
- [x] Text/JSON çıktısında test edilen kontrol karakterleri için injection kanıtı yok.

---

## 7. `0.2.x` — Phase 3: console ve temel file sink

### 7.1 Console sink

- [x] Target seçimi explicit; `CONSOLE_STDOUT` gerçek çıktı üretir, stderr fallback yapılmaz.
- BLOCKED: `CONSOLE_STDERR`, NOX 2.1.0 public API'sinde stderr yazımı olmadığı için sanitize `SinkError` ile kapalı; stderr önerisi dokümante edildi.
- [x] Write/flush/close ve kapalı sink davranışı testli; close idempotent.
- [x] Gerçek stdout exact-capture entegrasyon örneği LLVM/QBE harness'ında var.
- BLOCKED: `print` recoverable write-error ve stdio flush kanalı sunmadığı için console broken-pipe/flush kanıtı yok.

### 7.2 File sink

- [x] `nox.fs.open_append` ve explicit idempotent close ile uygulanıyor.
- [x] Directory creation explicit `create_parent` opt-in'iyle canonical root içinde sınırlandırıldı.
- [x] Parent/file canonicalization ile test edilen root dışı ve mevcut symlink kaçışları reddediliyor.
- [x] `..`, absolute path, control/non-portable path ve mevcut symlink edge-case'leri testli.
- BLOCKED: Pinned API `lstat`/no-follow/openat sağlamadığı için dangling leaf symlink ve concurrent hostile-directory yarışı güvenli biçimde kanıtlanamıyor; trusted root zorunlu.
- [x] Append/reopen ve Unicode byte size davranışı testli.
- [x] Permission denied ve missing directory negatif testleri; open hatası sanitize kategoriyle görünür.
- [x] Açılış sonrası validation hata yolu writer'ı kapatıyor; normal ve tekrar close testli.
- [x] `flush` ile `fsync` farkı açık; doğrulanmamış durability iddiası yok.
- [ ] Disk-full/post-open write failure simülasyonu çalıştırılmadı; eksik kanıt `docs/operations.md` içinde kayıtlı.
- [x] Bu fazda rotation/retention uygulanmadı.

### Phase 3 kapısı

- [x] Desteklenen stdout/file alt kümesinde yaşam döngüsü ve gözlemlenebilir sanitize hata kategorileri kanıtlandı; eksik public NOX yetenekleri BLOCKED olarak kayıtlı.
- [x] Test edilen destekli yollarda handle sızıntısı veya sessiz veri kaybı gözlenmedi; disk-full ve hostile-directory yarışına ilişkin eksik kanıt açık tutuldu.

---

## 8. `0.2.x` — Phase 4: güvenlik tabanı (alpha release blocker)

### 8.1 Redaction pipeline

- [x] Redaction sink fan-out'tan önce ve tek güvenli record üzerinde uygulanıyor.
- [x] Denylist case-insensitive normalize ediliyor.
- [x] Varsayılan denylist: password/passwd/token/access_token/refresh_token/authorization/api_key/secret/cookie/set-cookie/private_key.
- [x] Validasyonlu ve kopyalanan ek secret key'ler testli.
- [x] Nested dict/array scalar `FieldValue` sınırında compile-time güvenli biçimde reddediliyor.
- [x] Bearer token, Authorization, Cookie, Set-Cookie maskeleniyor.
- [x] DSN/URL userinfo ve credential query parametreleri maskeleniyor.
- [x] Mevcut message, logger name, fields, context, memory/custom/console/file sink ve sink error yolları aynı pre-sink sınırını kullanıyor.
- NOT YET: exception metadata, config-file loader, time rotation, diagnostics callback ve async queue henüz yok; eklendikleri fazda güvenlik matrisi tekrar zorunlu.
- [x] File isimlerinde credential-key bileşenleri reddediliyor; Phase 6 archive isimleri doğrulanmış basename + numeric suffix ile aynı politikaya bağlı.
- [x] Redaction başarısızlığında unsafe içerik drop ediliyor, exception metni gösterilmiyor ve saturating sanitize counter artıyor.
- [x] Synthetic sentinel fixture'ları gerçek secret içermiyor.
- [x] Redaction sınırlamaları `docs/security.md` içinde dürüstçe belgeli.

### 8.2 Güvenlik kabul matrisi

- [x] Mixed-case credential key.
- [x] Nested secrets güvenli compile-time reject; recursive destek iddiası yok.
- [x] Bearer token ve URL credential.
- [x] Multiline/log forging girdisi.
- [x] Unicode ve tüm ASCII kontrol karakterleri.
- [x] Secret içeren redactor exception mesajı dışarı çıkmıyor; application exception capture henüz desteklenmiyor.
- [x] Redaction function failure.
- [x] Custom sink ve recursive callback.
- [x] Console, memory ve file sink.
- [x] Sink hataları fixed sanitize kategori; emergency diagnostic callback henüz desteklenmiyor.
- [x] Snapshot ve test failure mesajları sentinel değerini göstermiyor.
- [x] Hermetic test/example çıktısı maskesiz `SYNTHETIC_` sentinel için taranıyor.

### Phase 4 kapısı

- [x] Mevcut yakalanan output, snapshot ve sink hata yollarında maskesiz sentinel yok; henüz var olmayan output türleri kapsam dışı olarak kayıtlı.
- [x] Fail-closed drop ve sayaç yolu kanıtlı.
- [x] Phase 1–4 uçtan uca yol çalışıyor: `Logger.info → immutable record → redaction → formatter → memory/console sink`.
- [x] Mevcut scalar kapsamın Faz 4 kapısı uzak matriste geçti; ilk alpha artık güvenlik açısından değerlendirilebilir, ancak lisans/sürüm/release kapıları tamamlanmadan yayımlanmaz.

---

## 9. `0.3.x` — Phase 5: context binding ve configuration

- [x] `bind(fields)` yeni immutable logger/context view döndürüyor.
- [x] Event field > bound context precedence'i, reserved alan istisnalarıyla testli.
- [x] Context caller map mutation'ından etkilenmiyor.
- [x] Request/trace/span ID boyut ve karakter doğrulaması var.
- [x] Explicit propagation MVP; implicit global request context yok.
- [x] Paralel request context isolation LLVM ve QBE semantiğine uygun testli; shared logger thread-safety iddiası yok.
- [x] `LoggerConfig`, `SinkConfig`, `RedactionConfig`, `FormatterConfig` typed ve validasyonlu.
- [x] `QueueConfig` async kapalıyken bilinçli olarak sunulmuyor.
- [x] Builder/factory API compile-test ile doğrulandı.
- [x] Geçersiz config mevcut çalışan logger'ı değiştirmiyor.
- [x] Runtime scalar reconfigure caller açısından atomic; sink seti değişmiyor; factory failure açtığı sink'leri kapatıyor.
- [x] Env override explicit; eksik değişken `OsError` ile güvenli ele alınıyor.
- [x] `.env`, home veya network config otomatik okunmuyor.
- [x] Config hata metni secret echo etmiyor.
- [x] `examples/request_context.nox` ve config dokümanı eklendi.

### Phase 5 kapısı

- [x] Bağlı context'ler sızmıyor; invalid reconfigure önceki logger'ı koruyor; yerel ve desteklenen uzak LLVM/QBE matrisi geçti (`42211416648`).

---

## 10. `0.3.x` — Phase 6: rotation ve retention

- [x] Rotation ADR: single-process ownership, naming, recovery ve sınırlar.
- [x] Önce size-based rotation uygulandı; UTF-8 byte ölçümü doğrulandı.
- [x] Time-based rotation değerlendirildi; rollback/restart/clock-injection sözleşmesi kanıtlanmadığı için devre dışı bırakıldı.
- [x] Rename failure aktif dosyayı kaybettirmiyor; sanitized error görünür.
- [x] Rotation filename secret/control/path traversal içeremiyor.
- [x] Retention yalnız yapılandırılmış log dizinindeki kendi dosyalarını seçiyor.
- [x] Symlink/unexpected file türleri güvenli biçimde reddediliyor; dangling/race sınırı belgeli.
- [x] Retention deterministic ve dry-run/test modu var.
- [x] Boundary, restart/crash-state simulation, rename failure ve cleanup testleri.
- [x] İlgisiz dosya silmeme testi.
- [x] Disk kullanımı yapılandırılmış sınır altında kalıyor; oversized input fail-closed.
- [x] Cross-process rotation desteklenmiyor olarak belgeli; kanıtsız vaat yok.
- [x] `examples/file_rotation.nox`, operations ve recovery dokümanı.

### Phase 6 kapısı

- [x] Beklenmeyen silme yok; retention dry-run exact; yerel ve desteklenen uzak LLVM/QBE matrisi geçti (`42250864512`, macOS attempt 2).
- [x] Yapılandırılmış depolama sınırı yerel ve desteklenen uzak LLVM/QBE matrisinde geçti (`42250864512`, macOS attempt 2).

---

## 11. `0.4.x` — Phase 7: async dispatcher (koşullu)

### 11.1 Go/no-go araştırması

- [x] Sabit NOX revizyonunda `Channel`, `ThreadChannel`, atomics, cancellation ve join kapasitesi executable problarla doğrulandı.
- [x] QBE scalar/type kısıtları değerlendirildi; class-valued `LogRecord` aktarımı reddedildiği için taşınabilir record queue tasarımı kanıtlanamadı.
- [x] Shared buffer/atomic yaşam süresi ve join-before-free şartı ADR-0011'de kaydedildi.
- [x] Gerçek iki-worker probu LLVM'de atomik peak `2` ile overlap gösterdi; bu bir Obsidian queue iddiası olarak kullanılmadı.
- [x] ADR-0011 no-go kararı verildi.

No-go ise:

- [x] Async API kapalı/unsupported; neden `docs/compatibility.md` ve API dokümanında açık.
- [x] Senkron dispatcher tek desteklenen yol olarak kalıyor.

Go ise:

- [ ] Bounded queue ve pozitif capacity validation.
- [ ] `BLOCK`, `DROP_NEWEST`, `DROP_OLDEST`, `SYNC_FALLBACK` politikaları.
- [ ] Worker kendi dolu kuyruğunda block etmiyor.
- [ ] accepted/emitted/dropped/failed/pending/high-water sayaçları exact.
- [ ] `flush(timeout)` kabul edilmiş record'ların işlenmesini bekliyor.
- [ ] `close(timeout)` idempotent ve worker completion/join yapıyor.
- [ ] Cancellation, worker panic, partial write ve timeout davranışları testli.
- [ ] Worker erişirken buffer/atomic free edilmiyor.
- [ ] LLVM gerçek overlap/stress; QBE cooperative davranış testi.
- [ ] Per-producer/per-sink/global ordering kapsamı belgeli.
- [ ] Async güvenlik sentinel matrisi tekrar çalıştırıldı.

### Phase 7 kapısı

- [x] Async destek iddiası yok; overlap kapasitesi kanıtlandı ancak exact accounting/completion/lifecycle eksikleri açıkça no-go sayıldı.
- [x] Async devre dışı; sentetik worker/counter ile taklit edilmedi; yedi problu genişletilmiş uzak matris geçti (`42301491991`).

---

## 12. `0.4.x` — Phase 8: gelişmiş filtreleme ve diagnostics

- [x] Exact logger-name filter.
- [x] Per-sink numeric threshold.
- [x] Filter exception fail-closed; unredacted record dışarı çıkmıyor.
- [x] Stable seeded sampling bu fazda bilinçli olarak eklenmedi; sabit hash sözleşmesi seçilmeden iddia yok.
- [x] Sampling olmadığı için güvenlik/audit event'leri örtük olarak elenmiyor.
- [x] Hierarchical prefix rules ayrı tasarım/test olmadan eklenmedi.
- [x] Public caller/file/line API kanıtlanmadığı için source metadata kapalı bırakıldı.
- [x] Sink failure counters bounded ve sanitized.
- [x] Diagnostics yalnız sabit kategorili sayaç; recursive emergency output/callback yolu yok.
- [x] User filter/sink callback internal logging lock'u altında değil.
- [x] Audit profile ve tamper-resistance iddiası yok.

### Phase 8 kapısı

- [x] Re-entry bounded/fail-closed, diagnostics saturating, filtre testleri deterministik; sampling unsupported olarak belgeli. Desteklenen uzak matris CI `42306338481` ile yeşil.

---

## 13. `0.5.x` — Phase 9: ekosistem adaptörleri

Her adaptör için bağımsız modül, minimal örnek, integration test, consumer kurulu değilken graceful davranış ve core'a ters bağımlılık olmadığının kanıtı gereklidir.

- [x] Nyx request logger/ID/status/duration adaptörü.
- [x] Aether middleware context/route diagnostics adaptörü.
- [x] Quartz memory capture/assertion adaptörü; production bağımlılığı yok.
- DEFERRED: Nova outbound timing/status; public API denetimi ve sabit tüketici sürümü ayrı dilimde yapılacak, auth/body varsayılan olarak loglanmayacak.
- DEFERRED: Feather query duration/safe query ID; public API sabitlenmeden raw params/credentials entegrasyonu eklenmeyecek.
- DEFERRED: Atlas pipeline stage/row count; consumer API denetimi olmadan sensitive row content yolu açılmayacak.
- DEFERRED: Rune CLI/no-color adaptörü; console API ve TTY yetenek denetimi sonrası, framework değiştirilmeden ele alınacak.
- DEFERRED: Chronos job context isolation; consumer context API'si sabitlenince bağımsız isolation testiyle ele alınacak.
- DEFERRED: Ember correlation; logging event transport yapılmadan consumer API denetimi sonrası ele alınacak.
- DEFERRED: VAULT optional config/secret integration; core import eklenmeden VAULT public sözleşmesi sabitlenince ele alınacak.
- DEFERRED: Pulse optional trace/span bridge; tracing engine eklenmeden Pulse public sözleşmesi sabitlenince ele alınacak.
- DEFERRED: Aura optional platform sink; UI blocking/lifecycle sözleşmesi kanıtlanmadan eklenmeyecek.
- [x] Dependency graph denetimi: Obsidian core yalnız stdlib/onaylı minimal utility'lere bağlı.

### Phase 9 kapısı

- [x] İlk yayımlanan Nyx/Aether/Quartz adaptörleri bağımsız LLVM/QBE tüketici problarında geçti ve hiçbir framework core tarafından import edilmiyor; desteklenen uzak matris CI `42310679970` ile yeşil.

---

## 14. `0.9.x` — Phase 10: benchmark ve hardening

- [x] Benchmark ortam şablonu: hardware, OS, NOX SHA, backend, warm-up, sample count, variance; clean commit `3834963` baseline'ı `docs/performance.md` içinde kayıtlı.
- [x] Disabled DEBUG overhead; Obsidian ve eşdeğer `nox.log` workload'u LLVM/QBE için ölçüldü, timer quantization limiti raporlandı.
- [x] Redirected INFO console formatting throughput; clean commit `31abb7b` üzerinde exact 14.202 satır ve sentinel taramasıyla LLVM/QBE ölçüldü.
- [x] JSONL throughput ve bytes/event; typed Unicode fixture iki backend'de ölçüldü ve 309 bytes/event raporlandı.
- [x] File sink throughput ve rotation pause; clean commit `394b6e3` üzerinde 242-byte file fixture ve her yazıda zorlanan 246-byte rotation fixture LLVM/QBE ölçüldü.
- [x] Async enqueue p50/p95/p99 ve drop counts uygulanamaz: ADR-0011/Phase 7 no-go nedeniyle async dispatcher yayımlanmadı; sahte metrik üretilmedi.
- [x] Async producer scaling uygulanamaz: LLVM overlap capability probu ve QBE cooperative davranışı Phase 7'de ayrı kanıtlandı, desteklenmeyen queue için scaling iddiası yapılmadı.
- [x] Slow/failing sink altında memory footprint; clean commit `f66c6ad` üzerinde empty/bounded/failing/slow peak RSS yedi fresh process ile LLVM/QBE ölçüldü.
- [x] Startup/logger construction overhead; in-process construct+close ve clean commit `1bde748` üzerinde prebuilt empty/Logger process launch LLVM/QBE ayrı ölçüldü.
- [x] Long message ve Unicode pathological fixture; `MAX_MESSAGE_LENGTH` sınırında 196.824 bytes/event JSONL iki backend'de ölçüldü.
- [x] Yalnız eşdeğer workload için `nox.log` baseline karşılaştırması; yalnız disabled DEBUG early-rejection karşılaştırıldı, oran iddiası yapılmadı.
- [x] UTF-8/control char/large field/malformed config/nested values property testleri; 101 deterministik vaka yerel ve CI `42395481106` LLVM/QBE'de geçti, nested values mevcut compile-fail sınırında reddedildi.
- [x] Rotation filenames ve path confinement property testleri; 106 deterministik vaka yerel ve CI `42398683809` LLVM/QBE'de geçti, raw control doğrulama sırası ve non-canonical component reddi sertleştirildi.
- [x] Bounded file/rotation stress: clean commit `15fed48` üzerinde LLVM/QBE için üç fresh process, yol başına toplam 120.000 olay, timeout/RSS/reopen/retention/sentinel kanıtı geçti; queue stress async no-go nedeniyle uygulanamaz. Bu bounded regresyon kanıtıdır, leak garantisi değildir.
- [x] Fixed-seed NOX fuzz korpusu: `20261109` tohumu ile 2.048 encoding/field/redaction/path/archive/config vakası yerel ve CI `42635939949` LLVM/QBE'de geçti; sensitive dizin bileşeni sınırı bulundu ve sabit regresyonla kapatıldı. Bu coverage-guided fuzzing iddiası değildir.
- [x] P0/P1 closeout düzeltme dilimi: callback-time route mutasyonu ile recursive `log`/`flush`/`close` yolları fail-closed ve bounded; logger başına 64 sink, context/event başına 256 field, saturating observable counters ve sink-ID exhaustion guard eklendi. Yerel ve CI `42640500312` LLVM/QBE 20 dosya/423 assertion/0 skip geçti.
- [x] Tüm desteklenen senkron kapsam P0/P1 bulguları kapalı; unsupported capability sınırları `docs/hardening.md` içinde belgeli.

### Phase 10 kapısı

- [x] Reproducible benchmark ve bounded stress raporu yayımlandı; sonuçlar clean commit/ortam/backend ile kayıtlı ve kanıtsız performans iddiası yok.
- [x] Desteklenen senkron kapsamda bilinen P0/P1 safety bug yok; CI `42640500312` kapanış matrisi yeşil.

---

## 15. `0.9.x` — Phase 11: beta API freeze

- [x] Public API beta adayı ve stability/versioning politikası `docs/public-api.md` ile ADR-0016'da listelendi; yerel ve CI `42765823934` LLVM/QBE 22 dosya/467 assertion/0 skip contract kanıtı geçti.
- [x] `obsidian.log.v1` required/optional alanları ve compatibility policy `docs/schema.md` içinde tamamlandı; additive-property consumer regresyonu desteklenen uzak matriste geçti.
- [x] `docs/api.md`, `security.md`, `operations.md`, `ecosystem.md`, `migration.md` beta-aday kapsamıyla güncel.
- [x] Downstream beta API ve schema-v1 upgrade/backward-compatibility testleri LLVM/QBE'de geçti.
- [x] Copy-vs-mutation, failure, flush, close ve registration/call/schema ordering garantileri açık; cross-thread total order açıkça desteklenmiyor.
- [x] Destek matrisi yalnız çalıştırılan CI `42765823934` kanıtlarını listeliyor; Windows unsupported.
- [x] Tüm core ve pinned adaptör örnekleri clean downstream checkout'tan LLVM/QBE compile/run oluyor.
- [x] MIT license, `0.9.0-beta.1` changelog bölümü ve `nox.json`/`version.nox` hizası immutable `v0.9.0-beta.1` etiketiyle `c2379fe493b8eb431220f8a5c2b1bd12b13f1867` commit'ine bağlandı.
- [x] `0.9.0-beta.1` release notu bilinen limitleri, exact matrix kanıtını ve yayımlanan artifact'ları içeriyor.

### Phase 11 kapısı

- [x] API adayı compatibility/upgrade testlerini geçti; MIT, version/changelog, immutable tag, GitHub prerelease ve registry submission kanıtları hizalı. Phase 11 kapısı kapandı.

---

## 16. `1.0.0` — Phase 12: kararlı sürüm

- [ ] Desteklenen tüm CI matrix job'ları yeşil.
- [ ] Test vaka, assertion ve skip toplamları release raporunda.
- [ ] Sıfır unredacted sentinel.
- [ ] Bilinen P0/P1 safety bug yok.
- [ ] Pinned NOX revision ile clean install başarılı.
- [ ] Tüm örnekler başarılı.
- [ ] Benchmark raporu release commit'ine ait.
- [ ] Public API ve schema freeze edilmiş.
- [ ] Artifact, tag, changelog ve commit aynı sürümü gösteriyor.
- [ ] İmza/provenance altyapı destekliyorsa doğrulandı.
- [ ] Registry submission sonrası admin onayı ve downstream install ayrıca doğrulandı.
- [ ] Immutable release tag sessizce yeniden hedeflenmedi.

### Phase 12 kapısı

- [ ] Yayınlanan artifact ve belgelerin tamamı aynı doğrulanmış commit'e ait.

---

## 17. Her görev için zorunlu çalışma şablonu

Yeni bir implementasyon görevine başlamadan önce aşağıdaki blok issue/PR/çalışma notuna kopyalanır:

```text
Görev / sürüm / faz:
Kapsam ve kapsam dışı:
Kabul ölçütleri:
Dokunulacak dosyalar:
NOX API ve sabit kaynak revizyonu:
Riskler: secret, ownership, race, recursion, cleanup, portability
Tasarım/ADR gereksinimi:
Test planı: unit, integration, negative, security, backend

Çalıştırılan komutlar ve sonuçlar:
Test vaka sayısı:
Assertion sayısı:
Skip sayısı ve nedenleri:
Bilinen limitler:
Sonraki görev:
```

## 18. Sürekli güvenlik ve kalite kontrol listesi

Her kod değişikliğinde yeniden gözden geçirilecek:

- [ ] Secret; message, fields, context, exception, path, diagnostics veya test failure'a sızmıyor.
- [ ] Redaction untrusted sink/callback'ten önce.
- [ ] Error path recursion veya unbounded allocation üretmiyor.
- [ ] Collection/queue/diagnostics/file usage bounded.
- [ ] Handle/worker/atomic yaşam döngüsü kapanışta güvenli.
- [ ] Callback internal lock altında çağrılmıyor.
- [ ] File path allowed root dışına çıkmıyor ve retention ilgisiz dosya silmiyor.
- [ ] API gerçek NOX derleyicisinde type-check/compile edildi.
- [ ] LLVM kanıtı QBE concurrency kanıtı gibi sunulmuyor; tersi de yapılmıyor.
- [ ] NOX runtime/ABI private sembolleri ve `__nox_*` kullanılmıyor.
- [ ] Zig/NNI yalnız belgelenmiş capability gap ve ADR sonrası kullanılıyor.
- [ ] Nyx/Aether/Aura/diğer consumer'lara core bağımlılığı eklenmiyor.
- [ ] Network/telemetry/upload explicit opt-in olmadan eklenmiyor.

## 19. İlk uygulanacak çalışma dilimi

Phase 0 tamamlanmadan Phase 1 koduna başlanmayacaktır. İlk sıra:

1. NOX commit'ini seç ve kurulu `noxc` ile hizala.
2. `docs/compatibility.md` denetimini sabit commit üzerinden tamamla.
3. Gerçek paket/import/test söz dizimini iki backend'de minimal dosyalarla kanıtla.
4. Repo iskeleti, manifest, temel belgeler, ADR'ler ve dürüst CI skeleton oluştur.
5. Phase 0 kapısını kanıtlarla kapat.
6. Sonra küçük bir PR/dilim halinde `Level → FieldValue → LogRecord → Clock → MemorySink → Logger` sırasıyla Phase 1'e geç.

Size-based rotation Phase 1–5 kanıtlarından sonra Phase 6'da tamamlandı. Phase 7 executable capability audit'i async için no-go verdi; senkron çekirdek Phase 8'e devam edebilir.

## 20. İlerleme günlüğü

| Tarih | Sürüm/faz | Değişiklik | Komut/test kanıtı | Sonuç / sonraki adım |
|---|---|---|---|---|
| 2026-11-05 | Planlama | `AGENTS.md` fazları sürüm bazlı görevlere ayrıldı; yerel/upstream NOX sürüm farkı kaydedildi | `noxc --version` → `2.0.143`; proje dosya envanteri | Phase 0: sabit revizyon ve uyumluluk denetimi |
| 2026-11-05 | `0.0.x` / Phase 0 | NOX `v2.0.143` / `a8940d2…` sabitlendi; gerçek root-module düzeni, belgeler, ADR'ler, test ve CI iskeleti oluşturuldu | LLVM/QBE hello: pass; test: backend başına 1 dosya/2 assertion/0 skip; 2 compile-fail fixture; downstream alias+lock probe: pass | Phase 0 yerel kapısı geçti; Linux CI kanıtı bekliyor, Phase 1 sırada |
| 2026-11-05 | `0.1.x` / Phase 1 | Numeric levels, typed scalar fields, caller-isolated records, injected clocks, sink protocol, bounded memory sink, synchronous logger ve baseline pre-sink redaction eklendi | LLVM/QBE: 4/4 test dosyası; 99 assertion; 0 skip; 2 expected compile-fail; deterministic sanitized example: pass | Phase 1 yerel kapısı geçti; `Logger.trace` compiler codegen kısıtı belgeli; Phase 2 formatter sırada |
| 2026-11-05 | Release altyapısı | CI matrisi, issue/PR şablonları, katkı ve güvenlik politikaları ile immutable tag tabanlı GitHub Release + `noxc publish` hattı eklendi | Workflow/YAML/shell doğrulaması ve iki backend regresyonu; ilk remote CI sonucu ayrıca kaydedilecek | `0.0.0` yayınlanmaz; ilk yayın seçilmiş lisans, dış operator registry oturumu ve ilgili faz kapısı sonrası |
| 2026-11-05 | Uzak CI kanıtı | GitHub Actions run `41983292400`; macOS arm64, Linux x64 ve Linux arm64 matrisi | Her platformda format, LLVM/QBE testleri, 2 compile-fail fixture ve paket alias/import probu geçti | Phase 0 uzak platform kapısı geçti; Phase 2 sırada |
| 2026-11-06 | `0.2.x` / Phase 2 | RFC3339 text/JSONL formatter, deterministic field ordering, scalar type preservation, size/count bounds, non-finite reject politikası ve doğru package self-importları eklendi | Doğrulanmış NOX 2.0.143 arşiviyle hermetik tüketicide LLVM/QBE: 6 test dosyası, 151 assertion, 0 skip; 3 exact örnek, transitive import/lock probu geçti | Uzak Phase 2 CI kanıtı push sonrası alınacak; Phase 3 sırada |
| 2026-11-06 | Phase 2 uzak CI kanıtı | GitHub Actions run `42171234012`; commit `7722752`; macOS arm64, Linux x64 ve Linux arm64 | Üç işte de pinned toolchain, format, LLVM/QBE tüketici süiti, 2 compile-fail fixture ve transitive alias/import-lock probu geçti | Phase 2 kapısı desteklenen matriste geçti; Phase 3 console/file sink sırada |
| 2026-11-06 | `0.2.x` / Phase 3 desteklenen alt küme | Explicit stdout `ConsoleSink`, trusted root için canonical-root kontrolleri yapan append-only `FileSink`, sanitize `SinkError`, opt-in parent creation ve gerçek I/O testleri eklendi | Pinned NOX 2.0.143 LLVM/QBE: 8 test dosyası, 185 assertion, 0 skip; exact stdout/file örnekleri, permission/traversal/existing-symlink/append/reopen/UTF-8 kanıtı geçti | Stderr, console write-error kanalı, dangling-symlink race ve disk-full kanıtı BLOCKED; Phase 3 kapısı açık tutuldu |
| 2026-11-06 | Phase 3 desteklenen alt küme uzak CI kanıtı | GitHub Actions run `42173270729`; commit `50a85a7`; macOS arm64, Linux x64 ve Linux arm64 | Üç işte de pinned toolchain, format, LLVM/QBE 8 dosya/185 assertion süiti, 2 compile-fail fixture ve dependency alias/import probu geçti | Desteklenen alt küme matriste yeşil; platform API eksikleri nedeniyle Phase 3 kapısı açık, Phase 4 başlatılmadı |
| 2026-11-06 | `0.2.x` / Phase 4 scalar güvenlik adayı | Case-insensitive default/ek denylist, header/Bearer/URL/query masking, fail-closed drop+sayaç, filename guard ve security matrix eklendi | Pinned NOX 2.0.143 LLVM/QBE: 9 test dosyası, 226 assertion, 0 skip; 3 expected compile-fail; 6 exact ve sentinel-scanned örnek; import/lock probu geçti | Yerel scalar güvenlik kapısı geçti; uzak CI kanıtı bekleniyor, exception/config/rotation/async yolları geldiklerinde matrise eklenecek |
| 2026-11-06 | Phase 4 scalar güvenlik uzak CI kanıtı | GitHub Actions run `42206489911`; commit `fe32ffd`; macOS arm64, Linux x64 ve Linux arm64 | Üç işte de pinned toolchain, format, LLVM/QBE 9 dosya/226 assertion süiti, 3 compile-fail fixture, sentinel taraması ve dependency alias/import probu geçti | Mevcut scalar Faz 4 kapısı geçti; alpha yayınlanmadı, Phase 5 context/configuration sırada |
| 2026-11-06 | `0.3.x` / Phase 5 context/configuration | Immutable explicit context view, request/trace/span ID, typed config/factory, atomic scalar reconfigure ve explicit env override eklendi | Pinned NOX 2.0.143 LLVM/QBE: 12 test dosyası, 276 assertion, 0 skip; 3 expected compile-fail; 7 exact örnek ve import/lock probu geçti | Uzak CI run `42211416648` ve final evidence run `42211681459` üç platformda yeşil; Phase 5 kapısı kapandı |
| 2026-11-06 | `0.3.x` / Phase 6 size-rotation | Single-process byte rotation, fixed-width archive sequence, dry-run retention, restart/rename recovery, symlink ve owned-file doğrulaması eklendi | Pinned NOX 2.0.143 yerel ve desteklenen CI LLVM/QBE: 14 test dosyası, 325 assertion, 0 skip; 3 expected compile-fail; 8 exact örnek ve import/lock probu geçti | Uzak CI run `42250864512` (macOS runner kapasitesi nedeniyle attempt 2) üç platformda yeşil; Phase 6 kapandı, time/cross-process rotation desteklenmiyor |
| 2026-11-06 | `0.4.x` / Phase 7 async go/no-go | Thread/channel/atomic/join/cancellation probları, gerçek overlap testi ve ADR-0011 eklendi | Pinned NOX 2.0.143 yerel ve CI `42257058031`: 14 dosya/325 assertion/0 skip, 6 capability probu; LLVM overlap peak `2`, QBE class-channel expected reject | No-go desteklenen üç platformda doğrulandı; async ve `QueueConfig` kapalı, senkron dispatcher tek desteklenen yol |
| 2026-11-07 | Phase 7 genişletilmiş matris | LLVM overlap probu bounded ve scheduling-aware yapıldı; QBE scalar channel/atomic lifecycle ayrı executable probla doğrulandı | Yerelde üç tekrar; CI `42301491991`: macOS ARM64, Linux x64, Linux ARM64 üzerinde LLVM/QBE 14 dosya/325 assertion/0 skip ve 7 capability probu geçti | Phase 7 kapandı; overlap gözlemi dürüstçe raporlanıyor, async no-go değişmedi; Phase 8 sırada |
| 2026-11-07 | Manuel registry başvurusu | Kullanıcı isteğiyle token yapılandırmasına dokunmadan `noxc publish github.com/mburakmmm/obsidian --ref main` çalıştırıldı | noxpkg submission `6bbd1c55-e95b-4fb1-b66d-15c15a6c7909` | Başvuru onay bekliyor; registry erişilebilirliği veya kararlı sürüm iddiası yok |
| 2026-11-07 | `0.4.x` / Phase 8 | Exact logger filtresi, sink başına threshold, sanitize clone filtre sınırı, saturating diagnostics ve strict sabit hata kategorileri eklendi | Pinned NOX 2.0.143 yerel ve CI `42306338481`: macOS ARM64, Linux x64, Linux ARM64 üzerinde LLVM/QBE 16 dosya/358 assertion/0 skip; 7 capability probu; 9 exact ve sentinel-scanned örnek; import/lock doğrulaması geçti | Phase 8 desteklenen matriste kapandı; typed route config derleyici kanıtı yok diye kapalı, sampling/source/prefix bilinçli kapalı |
| 2026-11-07 | Phase 9 araç zinciri önkoşulu | NOX pini kullanıcı yönlendirmesiyle `v2.1.0` / `fd107b92…` sürümüne yükseltildi; zorunlu stdlib/concurrency belgeleri kesin etikette yeniden doğrulandı | Resmi macOS ARM64 arşivi checksum geçti; LLVM/QBE 16 dosya/358 assertion, 9 örnek, 7 capability probu ve import/lock yerelde geçti; GitHub CI `42308138269` üç platformda yeşil; `Logger.trace` LLVM duplicate-symbol kısıtı sürüyor | NOX 2.1.0 yükseltme kapısı yerel ve uzak matriste geçti; adaptör dilimi başlatıldı |
| 2026-11-07 | `0.5.x` / Phase 9 ilk adaptör dilimi | Framework-neutral safe request metadata, optional Nyx/Aether request adaptörleri, bounded Quartz capture, üç minimal örnek, dependency audit ve ADR-0013 eklendi | NOX 2.1.0 yerel ve CI `42310679970`: core 17 dosya/392 assertion/0 skip; Nyx `v0.24.0`, Aether `v0.9.0`, Quartz `v0.9.15` için backend başına 3 bağımsız prob/36 explicit check ve 3 örnek macOS ARM64/Linux x64/Linux ARM64 LLVM/QBE'de geçti; sentinel çıktı taraması temiz. İlk run `42310389221`, runner'larda `rg` bulunmadığını gösterdi; audit POSIX `find`/`grep` ile düzeltildi | Faz 9 yayımlanan ilk adaptör seti için kapandı. Diğer consumer adaptörleri public API denetimlerine kadar explicit DEFERRED; Phase 10 benchmark/hardening sırada |
| 2026-11-07 | `0.9.x` / Phase 10 benchmark foundation | Environment schema, monotonic seven-sample stats, disabled DEBUG/eşdeğer `nox.log`, JSONL bytes/event ve in-process logger construct+close workload'ları ile ADR-0014 eklendi | Clean commit `3834963`, Apple M4/macOS 27.2 üzerinde LLVM/QBE `dirty=false` ölçüldü; exact mean/min/max/variance ve 309 JSON bytes/event `docs/performance.md` içinde. Sentinel benchmark çıktısında görünmedi; 1 ns `nox.log` sonucu quantization limiti olarak işaretlendi | İlk reproducible baseline tamamlandı; console/file/rotation/memory/process-startup/stress/fuzz ayrı dilimlerde kalıyor |
| 2026-11-07 | Phase 10 benchmark CI smoke | Benchmark harness her düzenli CI matrix işinde LLVM/QBE non-baseline smoke olarak çalıştırıldı; ARM CPU metadata fallback'i taşınabilir hale getirildi | CI `42363929287`: macOS ARM64, Linux x64 ve Linux ARM64 işlerinin tamamında core, adaptör ve iki-backend benchmark smoke adımları geçti | Shared-runner sayıları baseline olarak yayımlanmadı; harness taşınabilirlik kanıtı kaydedildi |
| 2026-11-07 | Phase 10 console/Unicode ölçüm dilimi | Redirect edilmiş stdout INFO yolu exact output accounting ile; maksimum 65.536 code-point Unicode JSONL fixture'ı bytes/event ile eklendi | Clean commit `31abb7b`, Apple M4/macOS 27.2: LLVM console 9.000 ns/event, long JSONL 3.157.142 ns/event; QBE console 9.428 ns/event, long JSONL 3.207.142 ns/event; 14.202 satır/backend, sentinel yok; core regresyonu 17 dosya/392 assertion/0 skip | Sonuçlar makineye özgü gözlem olarak yayımlandı; file/rotation/memory/startup/fuzz/stress bekliyor |
| 2026-11-07 | Phase 10 file/rotation ölçüm dilimi | Temporary-root JSONL append throughput ve her timed write'ta close/rename/reopen/retention zorlayan size rotation workload'ları eklendi | Clean commit `394b6e3`, Apple M4/macOS 27.2: LLVM file 9.285 ns/event, rotation 365.714 ns/event; QBE file 9.857 ns/event, rotation 374.285 ns/event; 14.200 uniform 242-byte record/backend, 720 rotation/backend, active=1, archive=0, sentinel yok; core 17 dosya/392 assertion/0 skip | Makineye özgü gözlem yayımlandı; fsync/disk-full/crash/cross-process iddiası yok; memory/startup/fuzz/stress bekliyor |
| 2026-11-07 | Phase 10 process-startup ölçüm dilimi | Prebuilt empty NOX ve bir Logger construct/close yapan NOX binary'leri, uzun ömürlü host monotonic harness ile derleme dışarıda tutularak ölçüldü | Clean commit `1bde748`, Apple M4/macOS 27.2, Python 3.15.2: LLVM empty 1.991.553 ns, Logger process 2.023.200 ns; QBE empty 2.009.690 ns, Logger process 2.095.360 ns; workload başına 10 warm-up + 7x50 launch, bütün child çıkışları zero ve stdout/stderr boş; core 17 dosya/392 assertion/0 skip | Sonuçlar ayrı makine gözlemleri; çıkarımla exact Logger maliyeti iddia edilmiyor; memory/fuzz/stress bekliyor |
| 2026-11-07 | Phase 10 peak-RSS ölçüm dilimi | Empty runtime, bounded MemorySink, repeated failing sink ve deterministic slow callback için yedi fresh process/sample `ru_maxrss` ölçümü ve platform byte normalization eklendi | Clean commit `f66c6ad`, Apple M4/macOS 27.2, Python 3.15.2: LLVM empty/bounded/failing/slow mean RSS 1.785.856/2.389.723/2.260.992/2.260.992 byte; QBE 1.832.667/3.080.192/2.881.243/2.897.627 byte. Bounded 50.000 event, capacity 128, drop 49.872; failing 50.000 exact failure; slow 10.000 callback; sentinel yok; core 17 dosya/392 assertion/0 skip | Empty değer çıkarılarak allocation iddiası yapılmıyor; CPU-delay gerçek I/O latency modeli değil; uzun stress/fuzz bekliyor |
| 2026-11-07 | Phase 10 deterministic property dilimi | UTF-8/control encoding, büyük scalar/message sınırları, tagged scalar alan modeli ve bozuk typed config için bounded corpus eklendi; nested değerler statik compile-fail sınırında kaldı | NOX 2.1.0 yerel ve CI `42395481106`: macOS ARM64/Linux x64/Linux ARM64 LLVM/QBE'de 18 dosya/396 assertion/0 skip; 101 deterministik corpus vakası; 3 expected compile-fail fixture; örnekler, adaptörler, capability audit ve benchmark smoke geçti | Randomized fuzz veya uzun stress iddiası yok; rotation/path property matrisi sırada |
| 2026-11-07 | Phase 10 rotation/path property dilimi | 10 valid path, 58 unsafe/control path, 28 archive name/sequence ve 10 component-confinement vakası eklendi; raw control'ler path/regex yardımcısından önce, `.`/`..` adayları confinement helper içinde reddediliyor | NOX 2.1.0 yerel ve CI `42398683809`: macOS ARM64/Linux x64/Linux ARM64 LLVM/QBE'de 19 dosya/407 assertion/0 skip; toplam 207 property vakası; 3 expected compile-fail fixture; örnekler, adaptörler, capability audit ve benchmark smoke geçti | Randomized fuzz veya hostile-directory race iddiası yok; uzun süreli file stress sırada |
| 2026-11-08 | CI/release toolchain indirme sertleştirmesi | Doğrudan release URL'leri iki koşuda üç platformda HTTP 504 verdiği için pinned NOX indirmesi GitHub Release API ve üç bounded retry ile değiştirildi; checksum zorunluluğu korundu | Gerçek macOS ARM64 arşivi yerelde API üzerinden indirilip SHA-256 ile doğrulandı; CI `42470080183` macOS ARM64/Linux x64/Linux ARM64 üzerinde kurulum, LLVM/QBE core, capability, adaptör ve benchmark smoke adımlarının tamamını geçti | Derleyici pini/provenance iddiası değişmedi; Phase 10 uzun süreli file stress sırada |
| 2026-11-08 | Phase 10 bounded file/rotation stress | Repeated flush/idempotent close/reopen, host timeout, fresh-process peak RSS, streamed JSONL/masking doğrulaması, exact rotation sequence ve storage budget harness'ı eklendi | Clean `15fed48`: backend başına 3 süreç, yol başına 120.000 olay; LLVM RSS 3.293.184–3.325.952 byte, QBE 3.522.560 byte; süreç başına 2.499 rotation/4 arşiv/19.600 retained byte. CI `42471701337` üç platformda LLVM/QBE smoke ile tamamen yeşil | Queue stress async no-go nedeniyle N/A; bounded sonuç leak/durability garantisi değil. Random fuzz ve P0/P1 kapanış denetimi sırada |
| 2026-11-09 | Phase 10 fixed-seed fuzz | NOX-native sabit PRNG ile 2.048 encoding/field/mixed-case redaction/path/archive/config vakası eklendi; sensitive dizin bileşeni sonrası `/` sınırı fuzz tarafından bulunup düzeltildi | Commit `e5936ed`; yerel ve CI `42635939949` macOS ARM64/Linux x64/Linux ARM64 LLVM/QBE: 20 dosya/414 assertion/0 skip, 208 fixed property + 2.048 seeded vaka, 3 expected compile-fail; adaptör, capability, benchmark ve file-stress smoke geçti | Reproducible bounded corpus; coverage-guided/unbounded fuzzing iddiası yok. P0/P1 kapanış denetimi sırada |
| 2026-11-09 | Phase 10 P0/P1 safety closeout | Callback route mutasyonu ve recursive lifecycle non-termination yolları kapatıldı; route/context/event/counter sınırları eklendi; ADR-0015 ve hardening risk kaydı yayımlandı | Commit `f71bbba`; yerel ve CI `42640500312` macOS ARM64/Linux x64/Linux ARM64 LLVM/QBE: 20 dosya/423 assertion/0 skip, 3 expected compile-fail; capability, import/dependency, adaptör, benchmark ve file-stress smoke geçti | Desteklenen senkron kapsamda bilinen P0/P1 safety bug yok; unsupported race/durability/async/nested-field/platform sınırları açıkça belgeli. Phase 10 kapandı; Phase 11 beta API freeze sırada |
| 2026-11-10 | Phase 11 beta API/schema adayı | Normative public API inventory, beta/preview/internal stability katmanları, `obsidian.log.v1` compatibility policy, migration guide ve iki downstream contract testi eklendi | Commit `5d20822`; yerel ve CI `42765823934` macOS ARM64/Linux x64/Linux ARM64 LLVM/QBE: 22 dosya/467 assertion/0 skip; 3 expected compile-fail, capability, import/dependency, adaptör, tüm örnekler, benchmark ve file-stress smoke geçti | API/schema adayı kanıtlı; license + version/changelog/tag hizası kullanıcı lisans kararı beklediği için Phase 11 kapısı açık |
| 2026-11-10 | `0.9.0-beta.1` / Phase 11 release | MIT lisansı ve sürüm/changelog hizası `c2379fe493b8eb431220f8a5c2b1bd12b13f1867` üzerinde immutable annotated tag ile yayımlandı; GitHub prerelease ve token-free registry sınırı ADR-0017 ile kaydedildi | Tag-driven run `42774325476`: üç platformda LLVM/QBE 22 dosya/467 assertion/0 skip ve tüm ek kapılar geçti; eski workflow registry-secret adımında durdu, tag yerel `noxc publish --ref v0.9.0-beta.1` ile başarıyla gönderildi; origin peeled tag exact commit ile eşleşiyor | Phase 11 kapandı; workflow artık registry credential işlemez ve prerelease tag'lerini latest stable yapmaz. Phase 12 stable release sırada |
