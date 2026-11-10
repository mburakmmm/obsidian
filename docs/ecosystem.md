# Ecosystem adapters

Status: Phase 11 preview adapters verified on NOX 2.1.0 in local and supported CI matrices. They are intentionally excluded from the beta core compatibility guarantee.

Obsidian core has no Nyx, Aether, Quartz or other ecosystem dependency. Optional modules under `obsidian.adapters` are compiled only when imported by a consumer, and the consumer must add the corresponding framework package. The tested matrix is deliberately narrow:

| Module | Consumer dependency | Tested revision | Purpose |
|---|---|---|---|
| `obsidian.adapters.nyx` | Nyx `v0.24.0` | `b4ef854badb8478f074e4b89fd864b48633b023c` | Router before/after request completion logging |
| `obsidian.adapters.aether` | Aether `v0.9.0` | `d283a3badd1585dba1c58685dfa4d376f59262b8` | Aether interceptor request completion logging |
| `obsidian.adapters.quartz` | Quartz `v0.9.15` | `a8e0b9bd2d3e71bb61d192362b158a74c3212f38` | Bounded test capture and fixed-message assertions |

Compatibility outside those exact revisions has not been claimed.

## Safe request event schema

Nyx and Aether emit the fixed message `request completed` and only these default fields:

| Field | Policy |
|---|---|
| `method` | 1–16 uppercase ASCII letters, otherwise `UNKNOWN` |
| `status` | HTTP 100–599, otherwise `0` |
| `duration_ms` | non-negative monotonic duration, negative values become `0` |
| `route` | optional explicit stable route name/template; never inferred from the request target |

Request IDs use Obsidian's bounded correlation-ID alphabet. Invalid IDs are omitted. Status levels are `INFO` for 1xx–3xx, `WARNING` for 4xx and `ERROR` for 5xx.

The adapters do not log a raw path, query string, header map, request/response body, cookie, authorization value or framework context object. `set_route_name` must receive a constant logical name such as `payments.create` or a stable template such as `/payments/:id`; do not pass `ctx.path` or `request.target`. Route values are validated and sanitized, but explicit allowlisting remains the application's responsibility.

## Nyx

Add Nyx in the consuming project, then register one integration instance on the router:

```nox
import obsidian.adapters.nyx

request_logging: obsidian.adapters.nyx.NyxRequestLogging = obsidian.adapters.nyx.NyxRequestLogging(logger)
router.use_before(request_logging.before)
router.use_after(request_logging.after)
```

The adapter reads `nyx.runtime.request_id()` only for correlation. It uses task-local monotonic timing and clears its timer in the after hook. `log_completion` is also available for deterministic/manual framework integration and returns the underlying logger result.

## Aether

Add Aether in the consuming project and include the interceptor:

```nox
import obsidian.adapters.aether

request_logging: obsidian.adapters.aether.AetherRequestLogging = obsidian.adapters.aether.AetherRequestLogging(logger)
interceptors: list[InterceptorFns] = [request_logging.interceptor()]
```

Use `obsidian.adapters.aether.set_route_name(ctx, "payments.create")` only with an application-defined route identifier. Start time and route name live in Aether's request-scoped value bag, not process-global state.

## Quartz

Add Quartz only to a test project. `QuartzCapture` satisfies Obsidian's sink contract by delegating to a bounded `MemorySink`:

```nox
import obsidian.adapters.quartz

capture: obsidian.adapters.quartz.QuartzCapture = obsidian.adapters.quartz.QuartzCapture("events", 32)
logger.add_sink(capture)
logger.info("ready", [])
capture.assert_count(1)
capture.assert_level(0, "INFO")
```

`assert_no_secret(index, sentinel)` uses a fixed failure message and never includes the sentinel in assertion text. It scans the captured snapshot directly. Full redaction acceptance still belongs to `tests/security`, not to one capture assertion.

## Verification

Run the dependency audit and exact pinned integration matrix with:

```sh
bash scripts/audit-dependencies.sh
bash scripts/run-ecosystem-suite.sh all
```

The ecosystem suite builds three separate downstream consumers, verifies each lockfile's resolved commit, runs the probe and example on LLVM and QBE, and rejects captured output containing a synthetic security sentinel. Ordinary Obsidian tests run without any ecosystem package installed.

See ADR-0013 for the dependency and data-minimization decision. Remaining ecosystem adapters are deferred until their consumer APIs receive the same audit and isolated test treatment.
