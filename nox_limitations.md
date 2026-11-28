# Obsidian’da doğrulanan NOX limitasyonları

Son doğrulama 28 Kasım 2026. Yerel tekrarlar macOS ARM64’te resmi NOX arşivleriyle yapıldı. NOX 2.2.107 kaynak revizyonu `37e80cf9f0e273da4f612da0bb1f1c01c9473c6f`, NOX 2.1.0 revizyonu `fd107b922c67a804520dc30f849039d977542f6c`. Ana CI, Obsidian `c9a7afd` üzerinde Linux x64, Linux ARM64 ve macOS ARM64’te iki NOX sürümünü de çalıştırdı. Belgedeki tekil derleyici tanıları ayrıca yerelde alındı. [NOX 2.2.107 yayını](https://github.com/mburakmmm/nox-lang/releases/tag/v2.2.107) · [Obsidian CI](https://github.com/mburakmmm/obsidian/actions/runs/46147038812)

Güncellik kontrolünde GitHub’ın son kararlı yayını, uzak `main` ve `v2.2.107` etiketi aynı kaynak revizyonunu gösterdi. Kurulu `noxc` dosyası SHA-256 doğrulamalı macOS arşivindeki derleyiciyle birebir eşleşti. Async ve terminal probları yeniden çalıştırıldı. Aşağıdaki kanal kapanışı ve süreli join sarmalayıcı kontrolleri bu denetimde eklendi.

## NOX 2.2.107’de açık olanlar

### 1. `ThreadChannel` için beklemeden gönderim ve kapanış

`ThreadChannel.try_send(value)` derleyicide reddediliyor. Normal `send` çağrısı task’ı askıya alır ve `await` gerektirir. [NOX thread API’si](https://github.com/mburakmmm/nox-lang/blob/v2.2.107/docs/stdlib/thread.md)

```sh
noxc check tests/capability/async_try_send.nox
noxc check tests/capability/async_sync_send.nox
```

Her komut çıkış kodu `1` döndürdü. İlgili tanılar:

```text
UndefinedMethod: ThreadChannel has no method 'try_send' (only send/recv)
TypeMismatch: 'send' suspends the task: write 'await ch.send(...)'
```

Obsidian’ın senkron çağrı yolunda, kuyruğa ekleme ile doluluk kararını tek işlemde veren bir public metot gerekiyor. `DROP_NEWEST`, `DROP_OLDEST` ve `SYNC_FALLBACK` politikalarının kesin muhasebesi bu sözleşmeye bağlı. Belgelenen `ThreadChannel` API’si ayrıca kanal kapatma, kapanıştan sonra tamponu boşaltma veya bekleyen gönderici ve alıcıları uyandırma sözleşmesi sunmuyor. [Kabul koşulları](docs/decisions/0011-async-dispatch-no-go.md#upstream-acceptance-criteria)

Kapanışı ve beklemeden almayı sınamak için aşağıdaki ilk satırı iki ayrı dosyaya yazıp her birine çağrılardan birini ekle. İki `noxc check` çalıştırması da çıkış kodu `1` ve ilgili metoda yönelik `UndefinedMethod` tanısı verdi.

```nox
q: ThreadChannel[int] = ThreadChannel[int](1)
q.close()
q.try_recv()
```

### 2. Worker için süreli tamamlanma

`ThreadHandle.join(timeout)` derlenmiyor. Obsidian’ın `close(timeout)` çağrısında zaman aşımını tamamlanmadan ayırması ve hâlâ çalışan worker’a ait kaynakları sonraki bir join’e kadar canlı tutması gerekiyor.

```sh
noxc check tests/capability/async_timed_join.nox
```

Çıkış kodu `1`. Tanı `ArgumentCountMismatch: 'join' takes no arguments`. [NOX thread API’si](https://github.com/mburakmmm/nox-lang/blob/v2.2.107/docs/stdlib/thread.md#start-and-threadhandlet)

`Task.wait(ms)` belgelenmiş bir süreli bekleme API’si. `ThreadHandle.join()` işlemini ayrı bir task’a taşımak için denenen iki yöntem LLVM ve QBE’de `TypeMismatch` verdi. `async def join_worker(handle: ThreadHandle[int]) -> int` imzası parametre türünün paketlenememesi nedeniyle reddedildi. İç async işlevde `handle` yakalamak da türün task ile paylaşılamaması nedeniyle reddedildi. [Task süre aşımı API’si](https://github.com/mburakmmm/nox-lang/blob/v2.2.107/docs/language/concurrency.md#timeouts-and-waiting-for-the-first-of-two-tasks)

İç işlev probu `noxc run --backend llvm join_capture.nox` ve `noxc run --backend qbe join_capture.nox` ile tekrar üretilebilir.

```nox
import nox.thread

async def worker(queue: ThreadChannel[int]) -> int:
    return await queue.recv()

async def probe() -> None:
    queue: ThreadChannel[int] = ThreadChannel[int](1)
    handle: ThreadHandle[int] = nox.thread.start(worker, queue)
    async def join_worker() -> int:
        return await handle.join()
    waiter: Task[int] = spawn join_worker()
    print(waiter.wait(20))
    await queue.send(7)
    print(await waiter)

await spawn probe()
```

### 3. Bekleyen thread alıcısının iptalinde ayırt edilemeyen değer

Boş `ThreadChannel[int]` üzerinde bekleyen worker iptal edildiğinde probun `join()` sonucu `0` oldu. Prob, `CancelledError` yakalarsa `-1` döndürüyor. `0` geçerli bir kanal verisi olduğundan iptal işareti olarak kullanılamaz. Aynı LLVM ve QBE koşusunda ayrı `Channel[int]` task probu `CancelledError` yakaladı ve kanal sonraki `7` değerini iletti. Denetim ayrıca iki backend’de sınıf nesnesi transferini ve iki worker’ın örtüşmesini gözledi. [NOX iptal sözleşmesi](https://github.com/mburakmmm/nox-lang/blob/v2.2.107/docs/language/concurrency.md#cancellation)

```sh
bash scripts/run-async-capability-audit.sh
```

```text
recv cancellation: backend=llvm task=typed-cancel thread=scalar-zero
recv cancellation: backend=qbe task=typed-cancel thread=scalar-zero
async capability audit: decision=no-go llvm-overlap=observed qbe-overlap=observed both-class-transfer=pass
```

Probe kaynakları [thread alıcısı](tests/capability/async_thread_recv_cancel.nox) ve [task alıcısı](tests/capability/async_task_recv_cancel.nox). Obsidian async dispatcher’ı kapalı.

### 4. Terminal yazımında stderr hedefi

`nox.terminal.write_raw(content)` yalnızca stdout’a yazıyor. `is_tty(2)` stderr’i sorgulayabiliyor. Yazma fonksiyonu dosya tanıtıcısı kabul etmiyor. Örneği `stderr.nox` olarak kaydedip `noxc check stderr.nox` ile çalıştırınca çıkış kodu `1` ve `ArgumentCountMismatch: 'nox_terminal_write_raw' expects 1 arguments, 2 were given` alındı. [NOX terminal API’si](https://github.com/mburakmmm/nox-lang/blob/v2.2.107/docs/stdlib/terminal.md)

```nox
import nox.terminal
nox.terminal.write_raw("probe", 2)
```

Stdout sıralaması, flush ve kapalı stdout’ta yazma hatası, mevcut terminal sink’inde LLVM ve QBE ile geçti. Tekrar komutu `OBSIDIAN_NOX22_PROBES=1 bash scripts/run-package-suite.sh llvm`. QBE için son argüman `qbe`. [Terminal probları](scripts/run-package-suite.sh)

### 5. Dosya açma, kalıcılık ve dizin listeleme

Aşağıdaki bulgular 2.2.107’nin etiketli `nox.fs` belgeleri ve arşivdeki public imzaların incelemesine dayanıyor. [NOX dosya API’si](https://github.com/mburakmmm/nox-lang/blob/v2.2.107/docs/stdlib/fs.md) · [Etiketli stdlib kaynağı](https://github.com/mburakmmm/nox-lang/blob/v2.2.107/stdlib/nox/fs.nox)

| Bulgular | Kanıt ve Obsidian’daki etkisi |
|---|---|
| Yol denetimi ile append açılışını birleştiren no-follow arayüzü | Public `open_append(path)` yalnızca yol alır. `nox.fs` yüzeyinde `lstat`, dizin tanıtıcısına göre açma veya no-follow seçeneği belgelenmiyor. Mevcut symlink kaçışı ve traversal, [paket probunda](tests/capability/nox22_path_clock.nox) reddediliyor. Kontrol ile açma arasında yolun değişebildiği dizinler için uygulamaya ait güvenilir kök gerekiyor. |
| Kalıcı depolama eşitlemesi | Public `FileWriter` sözleşmesi unbuffered `write` ve `close` sağlar. `fsync` eşdeğeri belgelenmiyor. Obsidian `flush()` için kalıcı depolama garantisi vermiyor. |
| Akışlı dizin listeleme | Public `read_dir(path) -> list[str]` ad listesini tek seferde döndürür. Obsidian retention taramasında işlenen girişleri sınırlar. İlk listenin tahsisi için ayrı bir bütçe sağlayamaz. |
| Çok süreçli rotasyon | `write_string_atomic` sabit `path + ".nox-tmp"` adı kullanır. İncelenen public dosya API’si süreçler arası rotasyon sahipliği protokolü sağlamıyor. Obsidian aynı aktif yol için tek süreçli sahiplik uygular. |

[Yazma hatası probu](tests/capability/file_write_limit.nox) Linux ve macOS’ta sıfır `RLIMIT_FSIZE` ile dosya açıldıktan sonra gelen yazma reddini doğrular. ENOSPC, kısmi yazma ve elektrik kesintisi için ayrı kanıt gerekir. [Dosya sink sözleşmesi](docs/operations.md)

### 6. `trace` sınıf metodunun ayrılmış adı

Aşağıdaki örneği `trace.nox` olarak kaydedip `noxc run --backend llvm trace.nox` ile çalıştır:

```nox
class Probe:
    value: str

    def __init__(self) -> None:
        self.value = "probe"

    def trace(self) -> str:
        return self.value

probe: Probe = Probe()
print(probe.trace())
```

NOX 2.1.0 LLVM, `invalid redefinition of function 'Probe_trace'` ile çıktı. NOX 2.2.107, LLVM çalıştırmasında ve `noxc check --backend qbe trace.nox` kontrolünde adı daha erken reddetti. Tanı `DuplicateDefinition: class 'Probe': the method name 'trace' is reserved`. Obsidian’da TRACE seviyesi için `trace_event` ve `log(TRACE, ...)` mevcut. [Kararlı API kararı](docs/decisions/0019-stable-api-promotion.md)

## Eski sürümde doğrulanan bulgular

| NOX 2.1.0 gözlemi | NOX 2.2.107 sonucu |
|---|---|
| `noxc run --backend qbe tests/capability/async_record_channel.nox` varsayılan derlemede sınıf tipli `ThreadChannel` için `TypeMismatch` döndürdü. Ayrı Obsidian worker dispatch probu 2.1.0 QBE’de CI tarafından atlanıyor. | Aynı sınıf taşıma probu ve Obsidian worker dispatch probu iki backend’de geçti. [Audit scripti](scripts/run-async-capability-audit.sh) · [Paket süiti](scripts/run-package-suite.sh) |
| Proje kökünde `noxc check logger.nox`, manifest adındaki öz içe aktarımlar için `import: unknown alias, or project file not found` döndürdü. İzole tüketici kurulumu geçti. | Aynı kök komutu `no type errors: logger.nox` döndürdü. [Paket düzeni kararı](docs/decisions/0006-package-self-imports.md) |
| Tek satırlık `max_float: float = 1.7976931348623157e308` dosyasına `noxc fmt` uygulandığında `error: NoSpaceLeft` ve çıkış kodu `1` alındı. | Aynı dosyayı formatlama çıkış kodu `0` ile tamamlandı. [Önceki uyumluluk kaydı](docs/compatibility.md) |

NOX 2.2.38’de boş thread kanalında bekleyen worker’ı iptal etme probu `deadlock detected` ile sonlanıyordu. Bu önceki denetimin kaydıdır. 2.2.70 ve 2.2.107 için güncel gözlem, yukarıdaki ayırt edilemeyen `0` dönüşüdür. [2.2.38 kanıtı](docs/decisions/0011-async-dispatch-no-go.md#nox-2238-follow-up) · [Sürüm bazlı denetim](scripts/run-async-capability-audit.sh)
