# ADR-0011: async dispatch is unsupported on the pinned NOX baseline

Status: accepted no-go; revalidated on NOX 2.1.0 / `fd107b922c67a804520dc30f849039d977542f6c`

## Context

Phase 7 requires a bounded multi-producer queue, explicit overflow policies, exact accounting, timeout-aware flush/close, worker completion and proven shared-memory lifetime on LLVM and QBE. The existing logger API is synchronous: `Logger.log` captures and redacts one record, then calls every sink before returning.

The pinned public APIs provide awaited blocking `Channel.send/recv`, awaited blocking `ThreadChannel.send/recv`, join-only `ThreadHandle`, cooperative `Task.cancel` and manually freed scalar atomic cells. Task cancellation is not a thread-worker shutdown primitive. There is no documented `try_send`, `try_recv`, channel close, timed receive, timed join or thread-handle cancellation.

## Executable evidence

`scripts/run-async-capability-audit.sh` exercises the following probes with the pinned compiler:

- LLVM accepts `ThreadChannel[Payload]`; QBE rejects the same class element type and permits only scalar-like elements.
- `ThreadChannel.try_send`, `ThreadHandle.cancel` and `ThreadHandle.join(timeout)` are rejected by the type checker.
- Calling `ThreadChannel.send` from a synchronous function without `await` passes `noxc check` but fails code generation; it is not a synchronous enqueue primitive.
- Two real workers reached an atomic peak of two on LLVM with `NOX_POOL_WORKERS=4` in the pinned local and supported CI evidence run. The bounded continuous probe reports whether a later runner observes that scheduling outcome without treating its absence as proof of a runtime defect; the pinned NOX source uses the same scheduling-sensitive classification for work stealing. The scalar channel/atomic lifetime probe completes on QBE. This proves that overlap can occur, not that Obsidian has a portable queue.
- Atomic cells are valid only until one explicit `free`, after every worker has completed. A handle used after free is invalid.

## Decision

Async dispatch is **unsupported** on the pinned baseline. Obsidian exposes no `AsyncLogger`, `QueueConfig`, overflow policy or background worker. The synchronous dispatcher remains the only supported path.

This is a portability and lifecycle decision, not a claim that NOX cannot run concurrent work. A portable Obsidian implementation cannot currently satisfy all required semantics:

1. A `LogRecord` cannot cross `ThreadChannel` on QBE.
2. The synchronous logger cannot perform the required awaited send without changing its public call contract or using unjoined fire-and-forget work.
3. Without non-blocking channel operations, `DROP_NEWEST`, `DROP_OLDEST` and `SYNC_FALLBACK` cannot be implemented with exact race-free capacity semantics over the public queue API.
4. Without channel close/cancellation-aware receive and timed join, bounded `flush(timeout)` and `close(timeout)` cannot guarantee worker completion.
5. Without proven completion, atomic cells or shared buffers cannot be freed safely.

No synthetic queue counters, fake worker or LLVM-only record transport will be added to make the phase appear complete.

## Rejected alternatives

- Serializing a record into `str` for QBE was rejected. It would add a second record codec and reconstruction boundary while leaving non-blocking overflow and bounded shutdown unsolved.
- Busy polling atomic counters was rejected. It does not cancel a worker blocked in `recv`, provides no timed join and can block the QBE scheduler or waste CPU.
- Fire-and-forget `spawn` per log call was rejected. Failures are unobserved, ordering is undefined and close cannot prove completion.
- Zig/NNI glue was rejected because no minimal boundary design exists and the missing semantics span queueing, cancellation, timing and ownership rather than one isolated primitive.

## Re-evaluation trigger

Re-open Phase 7 only after a pinned NOX revision publicly documents and tests portable record transfer plus non-blocking bounded queue operations and timeout-aware worker shutdown. A new ADR must repeat genuine LLVM overlap, QBE behavior, exact accounting, security-sentinel and lifetime stress tests.

## NOX 2.2.38 follow-up

Local macOS ARM64 probes on both hosted backends transferred a class payload and observed two overlapping workers. Synchronous `send` now fails during type checking. `try_send` and timed `ThreadHandle.join` are still rejected. Calling `cancel()` on a worker parked in an empty `ThreadChannel.recv` reports deadlock. The documented receive-readiness methods on task channels do not provide atomic enqueue or completion-aware shutdown. The no-go decision remains in force. The audit has distinct expectations for both compilers.

### Upstream acceptance criteria

1. A bounded channel exposes atomic non-blocking enqueue with distinct accepted, full and closed outcomes. An overflow policy must never infer capacity from a separate size read.
2. Closing a channel prevents future sends, wakes blocked senders and receivers, and has a documented drain/EOF contract. Cancellation while parked has a bounded completion path.
3. A timed completion primitive distinguishes completion, timeout and failure. A timeout preserves a valid handle for a later join, and record storage remains owned until completion is observed.
4. Hosted LLVM and QBE probes cover real producer overlap, enqueue/close races, exact counters, timeout followed by join, and cancellation while blocked. Repeat tests under load before enabling a public queue.

The owned-worker dispatcher test exercises synchronous logging within two independent workers. It does not use a queue of log records.

## NOX 2.2.70 follow-up

The 2.2.63 task cancellation change wakes a task parked in `Channel.recv`. On 2.2.70, the LLVM and QBE probes caught `CancelledError` and then reused the channel successfully. The separate parked `ThreadChannel[int].recv` experiment returned a scalar zero after cancellation, without throwing. The tagged contract does not guarantee typed interruption for `ThreadChannel`, blocked sends or thread joins. A receiver cannot treat a scalar zero as an unambiguous completion event. `try_send` and a timed `ThreadHandle.join` remain rejected, so the dispatcher remains synchronous.

See the [documented cancellation contract](https://github.com/mburakmmm/nox-lang/blob/v2.2.70/docs/language/concurrency.md#cancellation).

## NOX 2.2.107 follow-up

The same audit passed on both hosted backends using the checksum-verified macOS ARM64 release. It observed class transfer and overlapping workers, typed cancellation for a parked `Channel.recv`, and a scalar zero from a cancelled `ThreadChannel[int].recv`. The compile-fail fixtures still rejected `try_send` and timed `join`. The no-go decision remains in force. [Tagged thread API](https://github.com/mburakmmm/nox-lang/blob/v2.2.107/docs/stdlib/thread.md).
