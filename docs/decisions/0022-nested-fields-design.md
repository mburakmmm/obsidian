# ADR-0022 — Nested fields design

Status: proposed. Existing `FieldValue` constructors and the scalar `obsidian.log.v1` contract remain supported.

## API and ownership

Use a separate typed builder for null, boolean, finite number, string, array and object values. Validate and snapshot on the way into a record. A suggested v1 implementation stores a private flat tree with node kinds and child ranges in bounded lists. This avoids retaining a graph of mutable caller objects or requiring cyclic runtime types on NOX 2.1.0. The builder rejects duplicate object keys, invalid controls and non-finite numbers. No arbitrary object conversion or raw JSON string embedding.

Initial limits to benchmark are depth 8, 1,024 nodes across nested fields and 64 KiB of UTF-8 key/string content per record. Use checked accounting before allocation and enforce a separate encoded output budget. The final limits and error categories must be public contract decisions. Reject an invalid record before sink fan-out with a sanitized error or failure counter.

## Redaction and output

Apply the existing normalized key policy at every object boundary. A sensitive key masks its entire value without descending or revealing container shape. Array elements inherit their enclosing key's decision. Apply configured message redaction to unmasked string leaves. Validate and handle key names through the existing field policy before writing either keys or values. Filters, custom sinks, snapshots and fallback diagnostics receive only the sanitized snapshot or a fixed failure category.

Use a new opt-in JSON schema revision if existing scalar consumers would otherwise receive new kinds under the same schema ID. Preserve deterministic object ordering, array order, null/empty distinctions and single-line JSON. Text formatting must escape the same controls and enforce the same redaction boundary. Keep the existing compile-fail test for structured inputs to the scalar API.

Before stabilization, test mixed-case and custom keys deep under arrays, whole-subtree masking, caller mutation, boundary and over-limit sizes, invalid values and every sink/fallback. Capture no raw sentinel on either compiler/backend. Include golden output from old and new consumers and measure throughput and peak memory at the accepted limits.
