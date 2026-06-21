# WebSocket Binary Protocol Specification

## 1. Global Specifications
* **Endianness:** All multi-byte numeric primitives are **Little Endian**.
* **Strings:** Sequential ASCII bytes prefixed by an integer length indicator.

---

## 2. Packet Architecture (Cascading Layout)

A single WebSocket packet contains one or more consecutive **Channel Envelopes** stacked raw end-to-end.

### Layer 1: Channel Envelope Header

| Field Name | Type | Size (Bytes) | Description |
| :--- | :--- | :--- | :--- |
| `addrLen` | `uint8` | 1 | Length of the source address text. |
| `upstreamAddress` | `string` | Variable (`addrLen`) | Routing address identity string. |
| `payloadLen` | `uint32` | 4 | Total byte length of all nested stream sections inside. |

### Layer 2: Stream Section Header (Repeats inside Payload)

| Field Name | Type | Size (Bytes) | Description |
| :--- | :--- | :--- | :--- |
| `typeLen` | `uint8` | 1 | Length of the class identifier text. |
| `typeName` | `string` | Variable (`typeLen`) | Reflection type signature string. |

---

## 3. Polymorphic Core Variants (Layer 3 Payload Bodies)

### Variant A: `TimeSeriesType<T>` (`COMPACT` Format)

| Field Name | Type | Size (Bytes) | Description |
| :--- | :--- | :--- | :--- |
| `nsamples` | `uint32` | 4 | Matrix sample row count (N). |
| `ncolumns` | `uint32` | 4 | Signal channel column count (C). |
| `signalData` | `T[]` | N × C × `sizeof(T)` | Interleaved metrics in Row-Major matrix format. |
| `timestamps` | `uint64[]` | N × 8 | Continuous array of hardware microsecond markers. |

### Variant B: Discrete Event / State Logs

| Field Name | Type | Size (Bytes) | Description |
| :--- | :--- | :--- | :--- |
| `timestamp_len` | `uint8` | 1 | Size allocation parameter (Typically 8). |
| `hardware_timestamp` | `bytes` | Variable (`timestamp_len`) | High-resolution microsecond clock value. |
| `event_len` | `uint16` | 2 | Sizing boundary parameter for the text payload. |
| `event_text` | `string` | Variable (`event_len`) | Diagnostic log or trigger warning string. |
