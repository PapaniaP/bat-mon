# BatMon status export

## Goal and scope

Expose BatMon's current keyboard battery state as local JSON for a separate
SketchyBar agent to consume. Implement only the BatMon producer, tests, and
consumer documentation. Keep existing local changes intact. No SketchyBar
configuration, external executable invocation, new dependency, or sandbox change.

This is stage one of the SketchyBar integration: the status-file producer.
Refresh notification and the widget-triggered, anchored BatMon panel are separate
follow-up work. Stage one does not invoke SketchyBar, emit refresh events, or open
the panel.

## File contract

Write `BatMon/status.json` under the user Application Support directory resolved
by Foundation, following the existing theme storage convention. For sandboxed
release builds this is normally:

`~/Library/Containers/com.paolo.bat-mon/Data/Library/Application Support/BatMon/status.json`

Debug builds use the `com.paolo.bat-mon.local` container. Document both paths;
consumers must choose the running build's path rather than merge snapshots.

```json
{
  "version": 1,
  "connectionState": "connected",
  "keyboardName": "My keyboard",
  "leftPercent": 85,
  "rightPercent": null,
  "leftBatteryReadAt": "2026-10-14T12:00:00Z",
  "rightBatteryReadAt": null,
  "exportedAt": "2026-10-14T12:00:00Z",
  "pollingIntervalSeconds": 60,
  "lowBatteryThreshold": 20,
  "criticalBatteryThreshold": 10
}
```

All keys are always present. Optional values are explicit JSON nulls. Dates use
UTC ISO 8601. Connection states are stable lowercase strings: disconnected,
idle, searching, connecting, connected, reconnecting, failed. Do not expose error
messages, Bluetooth identifiers, or unrelated preferences. Use effectiveName
for the keyboard name. With no selected keyboard the name and readings are null.
Preserve cached readings and their original timestamps across connection changes;
consumers must only present live readings when state is connected and each half
is fresh. Zero percent is a valid reading.

## Producer

Create one small exporter retained by BluetoothManager. Observe the published
selected keyboard, connection state, and relevant preferences with Combine.
Emit an initial snapshot after saved keyboard loading. Every successful battery
read already reassigns the selected keyboard and timestamps that half, including
unchanged percentages; do not deduplicate those events. Capture published values
from the publisher rather than rereading properties during willSet delivery.

Construct an immutable, complete snapshot from the observed keyboard, connection
state, and relevant preferences on the main thread before dispatching disk work.
The writer must not read live BluetoothManager or preference properties. The
serial writer queue preserves snapshot publication order; per-half timestamps
retain the age of each reading even when values come from different BLE updates.

Serialize writes on a background queue so disk access does not block Bluetooth
callbacks. Create the directory as needed, encode the complete snapshot, and
replace the file atomically. Log failures without altering app state or stopping
future writes.

### Shutdown

AppDelegate.applicationWillTerminate synchronously posts a dedicated
`batMonWillTerminate` NotificationCenter notification before removing observers.
BluetoothManager subscribes during initialization and handles it synchronously
on the main thread, calling its retained exporter's shutdown method. This mirrors
the existing wake-notification pattern without giving the delegate ownership of
the manager. Do not dispatch this handler asynchronously to the main queue.

The shutdown method is idempotent and:

1. Stops accepting new snapshots on the main thread.
2. Captures a final immutable snapshot with disconnected state and a fresh
   exportedAt, retaining the previous readings and their timestamps.
3. Enqueues that final write after all previously accepted writes on the serial
   writer queue.
4. Waits for its completion for at most one second, using a completion signal
   that does not require the main thread. Logs a write failure or deadline expiry
   and returns so termination can proceed.

The deadline bounds shutdown waiting, not filesystem latency. Successful flush
leaves a disconnected snapshot; a timeout, failed final write, crash, or force
quit can leave the previous snapshot. Consumers must apply freshness rules.

## Consumer guidance

The SketchyBar side can watch the containing directory for atomic snapshot
replacements and trigger its own refresh event. Watching only the original file
inode can miss replacements. Keep polling and startup/wake reads as recovery
mechanisms. This watcher and refresh event are outside stage-one scope.

Hide unless connected.
Display unknown or stale halves as unknown rather than zero. A recommended
per-half freshness limit is max(180 seconds, 3 * pollingIntervalSeconds).
Missing, malformed, or unsupported-version snapshots must not display live
numbers. Read timestamps per half; exportedAt is not a battery freshness signal.

## Verification

Test explicit nulls, valid zero, independent half timestamps, stable state names,
threshold export, unchanged-percentage updates, initial/disconnected/forgotten
state, atomic replacement, and recovery after a write failure. Test immutable
snapshot capture, ordered writes, rejection of submissions after shutdown,
idempotent shutdown, successful final flush, and bounded waiting when a writer
stalls. Verify target
membership and run the Xcode tests and app build. Real BLE and SketchyBar behavior
require hardware/consumer testing and must not be claimed from unit tests.

## Touch points

New exporter and tests; BluetoothManager lifecycle/subscriptions; AppDelegate
termination notification; Xcode app/test
source membership; README consumer contract. No changes to Settings UI or the
existing reconnection logic are required.
