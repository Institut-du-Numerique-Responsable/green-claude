# Ecodesign for Swift

**Version:** 1.1.0 | **Rules:** 15 | **Extensions:** swift

Ecodesign rules for Swift code: battery-aware sensors, timers and background work, reused sessions that respect Low Data Mode, downsampled images, SwiftUI object lifetime, bounded Core Data fetches, no blocking of the main thread.

---

## Metadata

| Property | Value |
|---|---|
| **File** | `skills/green-claude/rules/langages/swift.json` |
| **Globs** | `**/*.swift` |
| **Extensions** | `swift` |
| **Rule Count** | 15 |

## Rules by Category

### Swift — device energy

On a phone the energy is the user's battery, and the sensors are the expensive part (RGESN UX/Algorithms).

| ID | Impact | Title | Recommendation |
|---|---|---|---|
| ECO-SW-01 | High | Sensor left running | Stop the updates as soon as the screen or the task that needed them goes away, ask for the coarsest accuracy that works, and prefer significant-change monitoring over continuous updates. |
| ECO-SW-02 | Medium | Timer used to poll | Drive the refresh from an event: a push notification, a WebSocket, a delegate callback. Where a timer is unavoidable, invalidate it when the view disappears and widen the interval. |
| ECO-SW-06 | High | Highest location accuracy requested | Ask for the coarsest accuracy the feature needs (kCLLocationAccuracyHundredMeters, kCLLocationAccuracyKilometer, or reduced accuracy), and raise it only while the user is navigating. |
| ECO-SW-07 | Medium | Location kept running in the background | Prefer significant-change or visit monitoring in the background. If continuous updates are required, set pausesLocationUpdatesAutomatically and an activityType so the system can pause them. |
| ECO-SW-08 | Low | Timer with no tolerance | Set timer.tolerance to at least a tenth of the interval, or pass tolerance: to Timer.publish. |
| ECO-SW-09 | Medium | Screen kept awake | Set it only while the feature that needs it runs (video playback, navigation), and set it back to false when that ends or the view disappears. |
| ECO-SW-10 | Medium | Heavy background task that does not wait for power | Set requiresExternalPower = true (and requiresNetworkConnectivity only if needed) so the work runs while the device charges. |

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

<details>
<summary>Example for ECO-SW-06</summary>

**Before:**
```
manager.desiredAccuracy = kCLLocationAccuracyBest
```

**After:**
```
manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
```

</details>

<details>
<summary>Example for ECO-SW-08</summary>

**Before:**
```
Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in check() }
```

**After:**
```
let t = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in check() }
t.tolerance = 2
```

</details>

<details>
<summary>Example for ECO-SW-10</summary>

**Before:**
```
let request = BGProcessingTaskRequest(identifier: id)
```

**After:**
```
let request = BGProcessingTaskRequest(identifier: id)
request.requiresExternalPower = true
```

</details>

### Swift — resources and I/O

Reuse sessions, stream large data, keep the main thread free (RGESN Backend/Frontend).

| ID | Impact | Title | Recommendation |
|---|---|---|---|
| ECO-SW-03 | High | Main thread blocked | Keep the main thread for the interface. Move the work to a background queue or an async task, and update the UI when it returns. |
| ECO-SW-04 | High | Remote resource loaded synchronously and whole | Fetch with a shared URLSession (data(from:) or a download task for large files), which reuses connections, honours the HTTP cache and runs off the main thread. |
| ECO-SW-05 | Medium | URLSession built per request | Share one session for the app or the service, configured once with its cache policy and timeouts. |
| ECO-SW-11 | Low | Network session ignores Low Data Mode | For prefetching, sync and large media, set allowsConstrainedNetworkAccess = false (and allowsExpensiveNetworkAccess = false where it fits), and fall back to a lighter request when it fails with constrained network. |
| ECO-SW-12 | Medium | Image decoded at full size for a small display | Downsample to the display size with CGImageSourceCreateThumbnailAtIndex (kCGImageSourceThumbnailMaxPixelSize) or preparingThumbnail(of:), and cache the result. |
| ECO-SW-13 | Medium | Observed object created by the view | Use @StateObject (or @State with an @Observable class) for an object the view owns, and @ObservedObject only for one passed in. |
| ECO-SW-14 | Medium | Core Data fetch with no limit | Set fetchBatchSize for lists, fetchLimit when you need a few rows, propertiesToFetch for a subset of fields, or count(for:) when you only need the number. |
| ECO-SW-15 | Low | UserDefaults synchronize() | Remove the call. UserDefaults saves on its own. |

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

<details>
<summary>Example for ECO-SW-04</summary>

**Before:**
```
let data = try Data(contentsOf: URL(string: "https://api.example.org/feed")!)
```

**After:**
```
let (data, _) = try await session.data(from: feedURL)
```

</details>

<details>
<summary>Example for ECO-SW-13</summary>

**Before:**
```
@ObservedObject var model = FeedModel()
```

**After:**
```
@StateObject private var model = FeedModel()
```

</details>

<details>
<summary>Example for ECO-SW-14</summary>

**Before:**
```
let request = NSFetchRequest<Item>(entityName: "Item")
```

**After:**
```
let request = NSFetchRequest<Item>(entityName: "Item")
request.fetchBatchSize = 50
```

</details>

---

[Back to all languages](./README.md) | [Main documentation](https://github.com/Institut-du-Numerique-Responsable/green-claude/blob/main/README.md)