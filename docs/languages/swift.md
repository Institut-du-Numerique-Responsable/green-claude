# Ecodesign for Swift

**Version:** 1.0.0 | **Rules:** 5 | **Extensions:** swift

Ecodesign rules for Swift code: battery-aware background work, reused sessions, streamed data, no blocking of the main thread.

---

## Metadata

| Property | Value |
|---|---|
| **File** | `skills/green-claude/rules/langages/swift.json` |
| **Globs** | `**/*.swift` |
| **Extensions** | `swift` |
| **Rule Count** | 5 |

## Rules by Category

### Swift — device energy

On a phone the energy is the user's battery, and the sensors are the expensive part (RGESN UX/Algorithms).

| ID | Impact | Title | Recommendation |
|---|---|---|---|
| ECO-SW-01 | High | Sensor left running | Stop the updates as soon as the screen or the task that needed them goes away, ask for the coarsest accuracy that works, and prefer significant-change monitoring over continuous updates. |
| ECO-SW-02 | Medium | Timer used to poll | Drive the refresh from an event: a push notification, a WebSocket, a delegate callback. Where a timer is unavoidable, invalidate it when the view disappears and widen the interval. |

<details>
<summary>Example for ECO-SW-01</summary>

**Before:**
```
manager.startUpdatingLocation()
```

**After:**
```
manager.startUpdatingLocation()
// viewDidDisappear: manager.stopUpdatingLocation()
```

</details>

### Swift — resources and I/O

Reuse sessions, stream large data, keep the main thread free (RGESN Backend/Frontend).

| ID | Impact | Title | Recommendation |
|---|---|---|---|
| ECO-SW-03 | High | Main thread blocked | Keep the main thread for the interface. Move the work to a background queue or an async task, and update the UI when it returns. |
| ECO-SW-04 | Medium | Whole file or response held in memory | Use URLSession download or stream tasks, decode incrementally, and bound what you keep. |
| ECO-SW-05 | Medium | URLSession built per request | Share one session for the app or the service, configured once with its cache policy and timeouts. |

<details>
<summary>Example for ECO-SW-03</summary>

**Before:**
```
DispatchQueue.main.sync { render() }
```

**After:**
```
Task { let d = await load(); await MainActor.run { render(d) } }
```

</details>

---

[Back to all languages](./README.md) | [Main documentation](https://github.com/Institut-du-Numerique-Responsable/green-claude/blob/main/README.md)