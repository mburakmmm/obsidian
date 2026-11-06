# Obsidian geliştirme yol haritası

> Bu dosya `AGENTS.md` uygulama sözleşmesini yürütülebilir, sürüm bazlı işlere böler.
> Bir kutu yalnızca kod, test, belge ve desteklenen backend kanıtları birlikte mevcutsa işaretlenir.
> Planlama tarihi: 2026-11-05.

## 1. Mevcut durum

- [x] `AGENTS.md` okundu ve geliştirme kapıları bu plana aktarıldı.
- [x] Proje dizini incelendi: başlangıçta yalnızca `AGENTS.md` vardı; henüz Git deposu değildi.
- [x] Yerel araç gözlemleri kaydedildi: başlangıçta `noxc 2.0.143`; 2026-11-06 ambient kurulum `2.0.181`, final faz kanıtı izole `2.0.143` arşiviyle alındı.
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
- BLOCKED: `CONSOLE_STDERR`, NOX 2.0.143/2.0.181 public API'sinde stderr yazımı olmadığı için sanitize `SinkError` ile kapalı; stderr önerisi dokümante edildi.
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

- [ ] Console/file yaşam döngüsü ve hata görünürlüğü kanıtlandı.
- [ ] Kaynak handle sızıntısı ve sessiz veri kaybı bilinen testlerde yok.

---

## 8. `0.2.x` — Phase 4: güvenlik tabanı (alpha release blocker)

### 8.1 Redaction pipeline

- [ ] Redaction sink fan-out'tan önce ve tek güvenli record üzerinde uygulanıyor.
- [ ] Denylist case-insensitive normalize ediliyor.
- [ ] Varsayılan denylist: password/passwd/token/access_token/refresh_token/authorization/api_key/secret/cookie/set-cookie/private_key.
- [ ] Configurable ek secret key'ler testli.
- [ ] Nested dict/array redaction destekleniyor ya da güvenli biçimde reddediliyor.
- [ ] Bearer token, Authorization, Cookie, Set-Cookie maskeleniyor.
- [ ] DSN, URL credentials ve credential query parametreleri maskeleniyor.
- [ ] Message, fields, context, exception, config error, sink error ve diagnostics aynı güvenlik sınırından geçiyor.
- [ ] File/rotation isimlerine secret girişi reddediliyor.
- [ ] Redaction başarısızlığında unsafe içerik drop/replace ediliyor ve yalnız sanitized counter artıyor.
- [ ] Synthetic sentinel fixture'ları gerçek secret içermiyor.
- [ ] Redaction sınırlamaları `docs/security.md` içinde dürüstçe belgeli.

### 8.2 Güvenlik kabul matrisi

- [ ] Mixed-case credential key.
- [ ] Nested secrets.
- [ ] Bearer token ve URL credential.
- [ ] Multiline/log forging girdisi.
- [ ] Unicode ve kontrol karakterleri.
- [ ] Secret içeren exception mesajı.
- [ ] Redaction function failure.
- [ ] Custom sink ve recursive callback.
- [ ] Console, memory ve file sink.
- [ ] Sink/diagnostic fallback error.
- [ ] Snapshot ve test failure çıktısı.
- [ ] Maskesiz sentinel için repo/test çıktısı genel taraması.

### Phase 4 kapısı

- [ ] Hiçbir yakalanan output, snapshot, diagnostic veya fixture içinde maskesiz sentinel yok.
- [ ] Fail-closed yollar kanıtlı.
- [ ] Phase 1–4 uçtan uca yol çalışıyor: `Logger.info → immutable record → redaction → formatter → memory/console sink`.
- [ ] Ancak bu kapıdan sonra ilk alpha değerlendirilebilir.

---

## 9. `0.3.x` — Phase 5: context binding ve configuration

- [ ] `bind(fields)` yeni immutable logger/context view döndürüyor.
- [ ] Event field > bound context precedence'i, reserved alan istisnalarıyla testli.
- [ ] Context caller map mutation'ından etkilenmiyor.
- [ ] Request/trace/span ID boyut ve karakter doğrulaması var.
- [ ] Explicit propagation MVP; implicit global request context yok.
- [ ] Paralel request context isolation LLVM ve QBE semantiğine uygun testli.
- [ ] `LoggerConfig`, `SinkConfig`, `RedactionConfig`, `FormatterConfig` typed ve validasyonlu.
- [ ] `QueueConfig` yalnız async açıldığında etkin.
- [ ] Builder/factory API compile-test ile doğrulandı.
- [ ] Geçersiz config mevcut çalışan logger'ı değiştirmiyor.
- [ ] Runtime reconfigure caller açısından atomic; yarım sink seti/handle leak yok.
- [ ] Env override explicit; eksik değişken `OsError` ile güvenli ele alınıyor.
- [ ] `.env`, home veya network config otomatik okunmuyor.
- [ ] Config hata metni secret echo etmiyor.
- [ ] `examples/request_context.nox` ve config dokümanı eklendi.

### Phase 5 kapısı

- [ ] Bağlı context'ler sızmıyor; invalid reconfigure önceki logger'ı koruyor.

---

## 10. `0.3.x` — Phase 6: rotation ve retention

- [ ] Rotation ADR: single-process ownership, naming, recovery ve sınırlar.
- [ ] Önce size-based rotation uygulandı; byte ölçümü doğrulandı.
- [ ] Time-based rotation yalnız güvenilir UTC/clock kanıtından sonra değerlendirildi.
- [ ] Rename failure aktif dosyayı kaybettirmiyor; sanitized error görünür.
- [ ] Rotation filename secret/control/path traversal içeremiyor.
- [ ] Retention yalnız yapılandırılmış log dizinindeki kendi dosyalarını seçiyor.
- [ ] Symlink/unexpected file türleri güvenli biçimde reddediliyor.
- [ ] Retention deterministic ve dry-run/test modu var.
- [ ] Boundary, restart, crash simulation, rename failure ve cleanup testleri.
- [ ] İlgisiz dosya silmeme testi.
- [ ] Disk kullanımı yapılandırılmış sınır altında kalıyor.
- [ ] Cross-process rotation desteklenmiyor olarak belgeli; kanıtsız vaat yok.
- [ ] `examples/file_rotation.nox`, operations ve recovery dokümanı.

### Phase 6 kapısı

- [ ] Beklenmeyen silme yok; retention hedefleri dry-run ile doğrulanıyor.
- [ ] Yapılandırılmış durumda depolama bounded.

---

## 11. `0.4.x` — Phase 7: async dispatcher (koşullu)

### 11.1 Go/no-go araştırması

- [ ] Sabit NOX revizyonunda `Channel`, `ThreadChannel`, atomics, cancellation ve join kapasitesi deneylerle doğrulandı.
- [ ] QBE scalar/type kısıtlarıyla taşınabilir record aktarım tasarımı kanıtlandı.
- [ ] Shared buffer/atomic yaşam süresi ADR'si tamamlandı.
- [ ] Gerçek multi-producer testi LLVM'de overlap gösterebiliyor.
- [ ] Go/no-go kararı ADR'de verildi.

No-go ise:

- [ ] Async API kapalı/unsupported; neden `docs/compatibility.md` ve API dokümanında açık.
- [ ] Senkron dispatcher varsayılan ve tam destekli kalıyor.

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

- [ ] Destek iddiası varsa gerçek overlap, exact accounting, completion ve memory lifecycle kanıtı var.
- [ ] Kanıt yoksa async devre dışı; sentetik worker/counter ile taklit edilmedi.

---

## 12. `0.4.x` — Phase 8: gelişmiş filtreleme ve diagnostics

- [ ] Exact logger-name filter.
- [ ] Per-sink numeric threshold.
- [ ] Filter exception fail-closed; unredacted record dışarı çıkmıyor.
- [ ] Stable seeded sampling uygulanacaksa deterministik testli.
- [ ] Güvenlik/audit event'leri explicit izin olmadan sample edilmiyor.
- [ ] Hierarchical prefix rules yalnız ayrı testlerle ekleniyor.
- [ ] Source metadata mevcut public API ile alınabiliyorsa ekleniyor; başarısızlığı emit'i bozmaz.
- [ ] Sink failure counters bounded ve sanitized.
- [ ] Emergency diagnostic recursion yapmıyor ve secret sızdırmıyor.
- [ ] User callback internal logging lock'u altında değil.
- [ ] Audit profile için tamper-resistance iddiası yok.

### Phase 8 kapısı

- [ ] Recursion yok, diagnostics bounded, filter/sampling testleri deterministik.

---

## 13. `0.5.x` — Phase 9: ekosistem adaptörleri

Her adaptör için bağımsız modül, minimal örnek, integration test, consumer kurulu değilken graceful davranış ve core'a ters bağımlılık olmadığının kanıtı gereklidir.

- [ ] Nyx request logger/ID/status/duration adaptörü.
- [ ] Aether middleware context/route diagnostics adaptörü.
- [ ] Quartz memory capture/assertion adaptörü; production bağımlılığı yok.
- [ ] Nova outbound timing/status; auth/body default loglanmıyor.
- [ ] Feather query duration/safe query ID; raw params/credentials yok.
- [ ] Atlas pipeline stage/row count; sensitive row content yok.
- [ ] Rune CLI/no-color adaptörü; console framework değiştirilmez.
- [ ] Chronos job context isolation.
- [ ] Ember correlation; logging event transport değildir.
- [ ] VAULT optional config/secret integration; core import yok.
- [ ] Pulse optional trace/span bridge; tracing engine yok.
- [ ] Aura optional platform sink; UI blocking ve hard dependency yok.
- [ ] Dependency graph denetimi: Obsidian core yalnız stdlib/onaylı minimal utility'lere bağlı.

### Phase 9 kapısı

- [ ] Her yayımlanan adaptör bağımsız testli; hiçbir ecosystem framework core tarafından import edilmiyor.

---

## 14. `0.9.x` — Phase 10: benchmark ve hardening

- [ ] Benchmark ortam şablonu: hardware, OS, NOX SHA, backend, warm-up, sample count, variance.
- [ ] Disabled DEBUG overhead.
- [ ] Redirected INFO console formatting throughput.
- [ ] JSONL throughput ve bytes/event.
- [ ] File sink throughput ve rotation pause.
- [ ] Async varsa enqueue p50/p95/p99 ve drop counts.
- [ ] LLVM producer scaling; QBE cooperative davranışı ayrı.
- [ ] Slow/failing sink altında memory footprint.
- [ ] Startup/logger construction overhead.
- [ ] Long message ve Unicode pathological fixtures.
- [ ] Yalnız eşdeğer workload için `nox.log` baseline karşılaştırması.
- [ ] UTF-8/control char/large field/malformed config/nested values fuzz/property testleri.
- [ ] Rotation filenames ve path confinement fuzz testleri.
- [ ] Uzun süreli file/queue stress ve tekrarlı deadlock/leak kontrolleri.
- [ ] Tüm P0/P1 bulguları kapalı; açık riskler belgeli.

### Phase 10 kapısı

- [ ] Reproducible benchmark raporu yayımlandı; kanıtsız performans iddiası yok.
- [ ] Bilinen P0/P1 safety bug yok.

---

## 15. `0.9.x` — Phase 11: beta API freeze

- [ ] Public API listesi ve stability/versioning işaretleri tamam.
- [ ] JSON schema version ve compatibility policy tamam.
- [ ] `docs/api.md`, `security.md`, `operations.md`, `ecosystem.md`, `migration.md` güncel.
- [ ] Upgrade/backward-compatibility testleri.
- [ ] Copy-vs-mutation, failure, flush, close ve ordering garantileri açık.
- [ ] Destek matrisi yalnız çalıştırılan CI kanıtlarını listeliyor.
- [ ] Tüm örnekler clean checkout'tan compile/run oluyor.
- [ ] License, changelog ve sürüm/tag hizası doğrulandı.
- [ ] Beta/RC release notes bilinen limitleri içeriyor.

### Phase 11 kapısı

- [ ] API adayı compatibility ve upgrade testlerini geçiyor.

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

File rotation ve async çalışma, sırasıyla Phase 1–4 ve Phase 6 kapıları geçilmeden başlatılmayacaktır.

## 20. İlerleme günlüğü

| Tarih | Sürüm/faz | Değişiklik | Komut/test kanıtı | Sonuç / sonraki adım |
|---|---|---|---|---|
| 2026-11-05 | Planlama | `AGENTS.md` fazları sürüm bazlı görevlere ayrıldı; yerel/upstream NOX sürüm farkı kaydedildi | `noxc --version` → `2.0.143`; proje dosya envanteri | Phase 0: sabit revizyon ve uyumluluk denetimi |
| 2026-11-05 | `0.0.x` / Phase 0 | NOX `v2.0.143` / `a8940d2…` sabitlendi; gerçek root-module düzeni, belgeler, ADR'ler, test ve CI iskeleti oluşturuldu | LLVM/QBE hello: pass; test: backend başına 1 dosya/2 assertion/0 skip; 2 compile-fail fixture; downstream alias+lock probe: pass | Phase 0 yerel kapısı geçti; Linux CI kanıtı bekliyor, Phase 1 sırada |
| 2026-11-05 | `0.1.x` / Phase 1 | Numeric levels, typed scalar fields, caller-isolated records, injected clocks, sink protocol, bounded memory sink, synchronous logger ve baseline pre-sink redaction eklendi | LLVM/QBE: 4/4 test dosyası; 99 assertion; 0 skip; 2 expected compile-fail; deterministic sanitized example: pass | Phase 1 yerel kapısı geçti; `Logger.trace` compiler codegen kısıtı belgeli; Phase 2 formatter sırada |
| 2026-11-05 | Release altyapısı | CI matrisi, issue/PR şablonları, katkı ve güvenlik politikaları ile immutable tag tabanlı GitHub Release + `noxc publish` hattı eklendi | Workflow/YAML/shell doğrulaması ve iki backend regresyonu; ilk remote CI sonucu ayrıca kaydedilecek | `0.0.0` yayınlanmaz; ilk yayın seçilmiş lisans, `NOXPKG_TOKEN` ve ilgili faz kapısı sonrası |
| 2026-11-05 | Uzak CI kanıtı | GitHub Actions run `41983292400`; macOS arm64, Linux x64 ve Linux arm64 matrisi | Her platformda format, LLVM/QBE testleri, 2 compile-fail fixture ve paket alias/import probu geçti | Phase 0 uzak platform kapısı geçti; Phase 2 sırada |
| 2026-11-06 | `0.2.x` / Phase 2 | RFC3339 text/JSONL formatter, deterministic field ordering, scalar type preservation, size/count bounds, non-finite reject politikası ve doğru package self-importları eklendi | Doğrulanmış NOX 2.0.143 arşiviyle hermetik tüketicide LLVM/QBE: 6 test dosyası, 151 assertion, 0 skip; 3 exact örnek, transitive import/lock probu geçti | Uzak Phase 2 CI kanıtı push sonrası alınacak; Phase 3 sırada |
| 2026-11-06 | Phase 2 uzak CI kanıtı | GitHub Actions run `42171234012`; commit `7722752`; macOS arm64, Linux x64 ve Linux arm64 | Üç işte de pinned toolchain, format, LLVM/QBE tüketici süiti, 2 compile-fail fixture ve transitive alias/import-lock probu geçti | Phase 2 kapısı desteklenen matriste geçti; Phase 3 console/file sink sırada |
| 2026-11-06 | `0.2.x` / Phase 3 desteklenen alt küme | Explicit stdout `ConsoleSink`, trusted root için canonical-root kontrolleri yapan append-only `FileSink`, sanitize `SinkError`, opt-in parent creation ve gerçek I/O testleri eklendi | Pinned NOX 2.0.143 LLVM/QBE: 8 test dosyası, 185 assertion, 0 skip; exact stdout/file örnekleri, permission/traversal/existing-symlink/append/reopen/UTF-8 kanıtı geçti | Stderr, console write-error kanalı, dangling-symlink race ve disk-full kanıtı BLOCKED; Phase 3 kapısı açık tutuldu |
