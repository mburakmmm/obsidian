# ADR-0011: async dispatch is unsupported on the pinned NOX baseline

Status: accepted no-go for NOX 2.0.143 / `a8940d27826849a526c3e918126ac6dd6ef571d1`

## Context

Phase 7 requires a bounded multi-producer queue, explicit overflow policies, exact accounting, timeout-aware flush/close, worker completion and proven shared-memory lifetime on LLVM and QBE. The existing logger API is synchronous: `Logger.log` captures and redacts one record, then calls every sink before returning.

The pinned public APIs provide blocking `Channel.send/recv`, blocking `ThreadChannel.send/recv`, join-only `ThreadHandle`, cooperative task cancellation and manually freed scalar atomic cells. The scheduler documentation explicitly states that channel operations do not observe task cancellation. There is no documented `try_send`, `try_recv`, channel close, timed receive, timed join or thread-handle cancellation.

## Executable evidence

`scripts/run-async-capability-audit.sh` exercises the following probes with the pinned compiler:

- LLVM accepts `ThreadChannel[Payload]`; QBE rejects the same class element type and permits only scalar-like elements.
- `ThreadChannel.try_send`, `ThreadHandle.cancel` and `ThreadHandle.join(timeout)` are rejected by the type checker.
- Calling `ThreadChannel.send` from a synchronous function without `await` passes `noxc check` but fails code generation; it is not a synchronous enqueue primitive.
- Two real workers reach an atomic peak of two on LLVM with `NOX_POOL_WORKERS=4`. The scalar channel/atomic lifetime probe also completes on QBE. This proves overlap capability, not an Obsidian queue.
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
