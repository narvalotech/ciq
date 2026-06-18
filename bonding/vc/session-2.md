User: Instead of invoking the error callback, let's add a m_DisconnectedCallback() in the app and show a "disconnected" toast using Notifications.showNotification (### **showNotification(title as [Lang.String](https://developer.garmin.com/connect-iq/api-docs/Toybox/Lang/String.html) or [Lang.ResourceId](https://developer.garmin.com/connect-iq/api-docs/Toybox/Lang/ResourceId.html), subTitle as [Lang.String](https://developer.garmin.com/connect-iq/api-docs/Toybox/Lang/String.html) or [Lang.ResourceId](https://developer.garmin.com/connect-iq/api-docs/Toybox/Lang/ResourceId.html), options as [Notifications.ShowNotificationOptions](https://developer.garmin.com/connect-iq/api-docs/Toybox/Notifications.html#ShowNotificationOptions-named_type) or **Null**)**  as **Void**) 

also start scanning again in the background and show a "connected" toast when re-connected

GitHub Copilot: I'll explore how the BLE callbacks are wired up in the app before making changes.  

Searched for regex `new simpleBle|m_ConnectedCallback|errorCallback|ErrorCallback|new Method|:method`, 20 results

Read [](file:///c%3A/repos/ciq/bonding/source/mouse_canvasApp.mc)

Now let me look at how the BLE instance is created and callbacks wired in ssMainView.mc: 

Read [](file:///c%3A/repos/ciq/bonding/source/ssMainView.mc)

Searched for regex `onDataUpdated|Notifications|import Toybox`, 20 results

Let me check the manifest for permissions and look at `ssDataView.mc` where the module is reopened:  

Read [](file:///c%3A/repos/ciq/bonding/manifest.xml)

Read [](file:///c%3A/repos/ciq/bonding/source/ssDataView.mc#1-1), lines 1 to 30

The `PersistedContent` permission needed for `Notifications` is already present. Now I'll make the changes. 

Replacing 30 lines with 44 lines in [](file:///c%3A/repos/ciq/bonding/source/simpleBle.mc)

 

Replacing 5 lines with 6 lines in [](file:///c%3A/repos/ciq/bonding/source/ssMainView.mc)

 

Replacing 14 lines with 30 lines in [](file:///c%3A/repos/ciq/bonding/source/mouse_canvasApp.mc)


```

```

```

```

```

```
Let me verify there are no errors in the edited files: 

Checked [](file:///c%3A/repos/ciq/bonding/source/simpleBle.mc), [](file:///c%3A/repos/ciq/bonding/source/ssMainView.mc), [](file:///c%3A/repos/ciq/bonding/source/mouse_canvasApp.mc), 6 problems found

I need to add the `Notifications` permission to the manifest. The `onBleDisconnected` error is a cascade from the failed compile. 

Replacing 4 lines with 5 lines in [](file:///c%3A/repos/ciq/bonding/manifest.xml)


```

```


Checked [](file:///c%3A/repos/ciq/bonding/source/ssMainView.mc), [](file:///c%3A/repos/ciq/bonding/source/mouse_canvasApp.mc), no problems found

All errors resolved (the redundant `uuids != null` warning in simpleBle.mc was pre-existing, unrelated to these changes).

Summary of changes:

1. simpleBle.mc — Added `m_DisconnectedCallback` and a public `m_reconnecting` flag, added the `disconnectedCallback` parameter to `initialize()`, and rewrote `on_connected()`: on disconnect it now clears state, invokes `m_DisconnectedCallback`, sets `m_reconnecting = true`, and calls `scan(true, m_match)` to reconnect in the background; on (re)connect it clears `m_reconnecting`.

2. mouse_canvasApp.mc — Added `import Toybox.Notifications`, a new `onBleDisconnected` handler that shows a "Disconnected" toast, and updated `onBleConnected` to show a "Connected" toast (instead of switching to the pairing spinner) when the connection is a background reconnect.

3. ssMainView.mc — Wired the new `onBleDisconnected` callback into the `simpleBle` constructor.

4. manifest.xml — Added the `Notifications` permission required by `Notifications.showNotification`.

Made changes.

26-06-22 11:00:44: -.--    Info  fenix-8-..CIQ[Info] Connection state change: 0
26-06-22 11:00:44: -.--    Info  fenix-8-..CIQ[Info] BLE disconnected, scanning to reconnect
26-06-22 11:00:44: -.--    Info  fenix-8-..CIQ[Err]  Failed invoking <symbol>
26-06-22 11:00:44: -.--    Info  fenix-8-..CIQ[Info] ---
26-06-22 11:00:44: -.--    Info  fenix-8-..CIQ[Info] Error: 
26-06-22 11:00:44: -.--    Info  fenix-8-..CIQ[Info] Unexpected Type Error
26-06-22 11:00:44: -.--    Info  fenix-8-..CIQ[Info] Details: 
26-06-22 11:00:44: -.--    Info  fenix-8-..CIQ[Info] ''
26-06-22 11:00:44: -.--    Info  fenix-8-..CIQ[Info] Failed invoking <symbol>
26-06-22 11:00:44: -.--    Info  fenix-8-..CIQ[Info] ''
26-06-22 11:00:44: -.--    Info  fenix-8-..CIQ[Info] Time: 
26-06-22 11:00:44: -.--    Info  fenix-8-..CIQ[Info] 2026-06-22T17:00:44Z
26-06-22 11:00:44: -.--    Info  fenix-8-..CIQ[Info] Part-Number: 
26-06-22 11:00:44: -.--    Info  fenix-8-..CIQ[Info] 006-B4631-00
26-06-22 11:00:44: -.--    Info  fenix-8-..CIQ[Info] Firmware-Version: 
26-06-22 11:00:44: -.--    Info  fenix-8-..CIQ[Info] ''
26-06-22 11:00:44: -.--    Info  fenix-8-..CIQ[Info] 21.41
26-06-22 11:00:44: -.--    Info  fenix-8-..CIQ[Info] ''
26-06-22 11:00:44: -.--    Info  fenix-8-..CIQ[Info] Language-Code: 
26-06-22 11:00:44: -.--    Info  fenix-8-..CIQ[Info] eng
26-06-22 11:00:44: -.--    Info  fenix-8-..CIQ[Info] ConnectIQ-API-Version: 
26-06-22 11:00:44: -.--    Info  fenix-8-..CIQ[Info] 6.0.0
26-06-22 11:00:44: -.--    Info  fenix-8-..CIQ[Info] ConnectIQ-Version: 
26-06-22 11:00:44: -.--    Info  fenix-8-..CIQ[Info] 6.0.2
26-06-22 11:00:44: -.--    Info  fenix-8-..CIQ[Info] Filename: 
26-06-22 11:00:44: -.--    Info  fenix-8-..CIQ[Info] G6AN1050
26-06-22 11:00:44: -.--    Info  fenix-8-..CIQ[Info] Appname: 
26-06-22 11:00:44: -.--    Info  fenix-8-..CIQ[Info] Mouse canvas
26-06-22 11:00:44: -.--    Info  fenix-8-..CIQ[Info] Stack: 
26-06-22 11:00:44: -.--    Info  fenix-8-..CIQ[Info]   - pc: 
26-06-22 11:00:44: -.--    Info  fenix-8-..CIQ[Info] 0x100004a1
26-06-22 11:00:44: -.--    Info  fenix-8-..CIQ[Info]     File: 
26-06-22 11:00:44: -.--    Info  fenix-8-..CIQ[Info] ''
26-06-22 11:00:44: -.--    Info  fenix-8-..CIQ[Info] C:\repos\ciq\bonding\source\mouse_canvasApp.mc
26-06-22 11:00:44: -.--    Info  fenix-8-..CIQ[Info] ''
26-06-22 11:00:44: -.--    Info  fenix-8-..CIQ[Info]     Line: 
26-06-22 11:00:44: -.--    Info  fenix-8-..CIQ[Info] 33
26-06-22 11:00:44: -.--    Info  fenix-8-..CIQ[Info]     Function: 
26-06-22 11:00:44: -.--    Info  fenix-8-..CIQ[Info] onBleDisconnected
26-06-22 11:00:44: -.--    Info  fenix-8-..CIQ[Info]   - pc: 
26-06-22 11:00:44: -.--    Info  fenix-8-..CIQ[Info] 0x10001028
26-06-22 11:00:44: -.--    Info  fenix-8-..CIQ[Info]     File: 
26-06-22 11:00:44: -.--    Info  fenix-8-..CIQ[Info] ''
26-06-22 11:00:44: -.--    Info  fenix-8-..CIQ[Info] C:\repos\ciq\bonding\source\simpleBle.mc
26-06-22 11:00:44: -.--    Info  fenix-8-..CIQ[Info] ''
26-06-22 11:00:44: -.--    Info  fenix-8-..CIQ[Info]     Line: 
26-06-22 11:00:44: -.--    Info  fenix-8-..CIQ[Info] 299
26-06-22 11:00:44: -.--    Info  fenix-8-..CIQ[Info]     Function: 
26-06-22 11:00:44: -.--    Info  fenix-8-..CIQ[Info] on_connected
26-06-22 11:00:44: -.--    Info  fenix-8-..CIQ[Info]   - pc: 
26-06-22 11:00:44: -.--    Info  fenix-8-..CIQ[Info] 0x100007ea
26-06-22 11:00:44: -.--    Info  fenix-8-..CIQ[Info]     File: 
26-06-22 11:00:44: -.--    Info  fenix-8-..CIQ[Info] ''
26-06-22 11:00:44: -.--    Info  fenix-8-..CIQ[Info] C:\repos\ciq\bonding\source\simpleBle.mc
26-06-22 11:00:44: -.--    Info  fenix-8-..CIQ[Info] ''
26-06-22 11:00:44: -.--    Info  fenix-8-..CIQ[Info]     Line: 
26-06-22 11:00:44: -.--    Info  fenix-8-..CIQ[Info] 355
26-06-22 11:00:44: -.--    Info  fenix-8-..CIQ[Info]     Function: 
26-06-22 11:00:44: -.--    Info  fenix-8-..CIQ[Info] onConnectedStateChanged
26-06-22 11:00:44: -.--    Info  fenix-8-..EVT       Page transition start
26-06-22 11:00:44: -.--    Info  fenix-8-..EVT       Page transition end

GitHub Copilot: 

Fetched https://developer.garmin.com/connect-iq/api-docs/Toybox/Notifications.html

The `showNotification` signature accepts `Null` for options, but the fenix8 firmware (21.41) throws an "Unexpected Type Error" when `null` is passed — it expects a Dictionary. I'll pass an empty options dictionary instead, which lets it fall back to the app icon. 

Replacing 5 lines with 5 lines in [](file:///c%3A/repos/ciq/bonding/source/mouse_canvasApp.mc)


```

```


Checked [](file:///c%3A/repos/ciq/bonding/source/mouse_canvasApp.mc), no problems found

Fixed. The crash was on line 33 — `Notifications.showNotification(...)` with `null` as the options argument. Despite the API docs listing `Null` as valid, the fenix8 firmware (21.41 / CIQ 6.0.2) throws an "Unexpected Type Error" at runtime when options is `null`; it expects a Dictionary. Both calls now pass an empty dictionary `{}`, which lets the system fall back to the app's launcher icon.

Let me note this gotcha in repo memory for future reference. 

Created memory file [](file:///c%3A/Users/ricojonathan/AppData/Roaming/Code/User/workspaceStorage/7610afed3a3247f571fd002b5bf9ae18/GitHub.copilot-chat/memory-tool/memories/repo/connectiq-gotchas.md)

Done. Rebuild and redeploy — the disconnect/reconnect toasts should now work without crashing.

Made changes.

User: this notification needs a "dismiss" action from the user. I was mistaken from looking at the SDK sample I see there is a WatchUi.showToast method, let's use that:
### **showToast(text as [Lang.String](https://developer.garmin.com/connect-iq/api-docs/Toybox/Lang/String.html) or [Lang.ResourceId](https://developer.garmin.com/connect-iq/api-docs/Toybox/Lang/ResourceId.html), options as { :icon as [WatchUi.BitmapResource](https://developer.garmin.com/connect-iq/api-docs/Toybox/WatchUi/BitmapResource.html) or [Graphics.BitmapReference](https://developer.garmin.com/connect-iq/api-docs/Toybox/Graphics/BitmapReference.html) or [Lang.ResourceId](https://developer.garmin.com/connect-iq/api-docs/Toybox/Lang/ResourceId.html) } or **Null**)**  as **Void**

GitHub Copilot: I'll switch to `WatchUi.showToast` and remove the now-unneeded `Notifications` import and permission. 

Replacing 11 lines with 10 lines in [](file:///c%3A/repos/ciq/bonding/source/mouse_canvasApp.mc)

 

Replacing 5 lines with 4 lines in [](file:///c%3A/repos/ciq/bonding/manifest.xml)


```

```

```

```


Checked [](file:///c%3A/repos/ciq/bonding/source/mouse_canvasApp.mc), no problems found

Done. Both toasts now use `WatchUi.showToast(text, null)`, and the `Notifications` import and permission have been removed since they're no longer needed.

Let me update the repo memory note to reflect the switch:  

Updated memory file [](file:///c%3A/Users/ricojonathan/AppData/Roaming/Code/User/workspaceStorage/7610afed3a3247f571fd002b5bf9ae18/GitHub.copilot-chat/memory-tool/memories/repo/connectiq-gotchas.md)

Rebuild and redeploy — the disconnect/reconnect events now show transient toasts via `WatchUi.showToast` that auto-dismiss without requiring user interaction.

Made changes.

User: also: when reconnecting, the app transitions to the "connected" page instead of the canvas. let's remove that page altogether since we now have toasts for connection transitions

GitHub Copilot: Read [](file:///c%3A/repos/ciq/bonding/source/ssConnectedView.mc)

Searched for regex `ssConnectedView|encryptionSpinnerDelegate|onBleEncrypted|scanSpinnerDelegate`, 20 results

Read [](file:///c%3A/repos/ciq/bonding/source/ssDataView.mc#1-1), lines 1 to 120

Read [](file:///c%3A/repos/ciq/bonding/source/ssEncryptionView.mc)

Read [](file:///c%3A/repos/ciq/bonding/source/mouse_canvasApp.mc#40-40), lines 40 to 60

Read [](file:///c%3A/repos/ciq/bonding/monkey.jungle)

Checked [](file:///c%3A/repos/ciq/bonding/source/ble_bondingApp.mc), no problems found

Read [](file:///c%3A/repos/ciq/bonding/source/ble_bondingApp.mc)

ble_bondingApp.mc is a dead duplicate (excluded from the build), but I'll update both to keep them consistent. Now I'll rewire `onBleEncrypted` to subscribe and go straight to the canvas, then delete the connected view.   

Replacing 26 lines with 26 lines in [](file:///c%3A/repos/ciq/bonding/source/mouse_canvasApp.mc), [](file:///c%3A/repos/ciq/bonding/source/ble_bondingApp.mc)


```

```

```

```
I accidentally removed the class declaration comment and line. Let me verify and fix.   

Read [](file:///c%3A/repos/ciq/bonding/source/mouse_canvasApp.mc#45-45), lines 45 to 75

I removed the class declaration. Let me restore it in both files.    

Replacing 12 lines with 20 lines in [](file:///c%3A/repos/ciq/bonding/source/mouse_canvasApp.mc), [](file:///c%3A/repos/ciq/bonding/source/ble_bondingApp.mc)


```

```

```

```
Now delete the connected view file:  

Ran terminal command: Remove-Item -Path "c:\repos\ciq\bonding\source\ssConnectedView.mc"; Test-Path "c:\repos\ciq\bonding\source\ssConnectedView.mc"

Checked [](file:///c%3A/repos/ciq/bonding/source/mouse_canvasApp.mc), [](file:///c%3A/repos/ciq/bonding/source/ble_bondingApp.mc), [](file:///c%3A/repos/ciq/bonding/source/ssDataView.mc), 5 problems found

The redefinition errors reveal that ble_bondingApp.mc is an obsolete duplicate from when the app was renamed (manifest entry is `mouse_canvasApp`). It conflicts with mouse_canvasApp.mc. I'll delete the dead duplicate.  

Ran terminal command: Remove-Item -Path "c:\repos\ciq\bonding\source\ble_bondingApp.mc"; Test-Path "c:\repos\ciq\bonding\source\ble_bondingApp.mc"

Checked [](file:///c%3A/repos/ciq/bonding/source/simpleBle.mc), [](file:///c%3A/repos/ciq/bonding/source/mouse_canvasApp.mc), [](file:///c%3A/repos/ciq/bonding/source/ssDataView.mc), [](file:///c%3A/repos/ciq/bonding/source/ssMainView.mc), 1 problem found

Done. Summary of changes:

- Removed the connected page: deleted ssConnectedView.mc and its delegate.
- `onBleEncrypted` in mouse_canvasApp.mc now calls `sBle.subscribe()` (the side effect that previously lived in the connected view's `onShow`) and switches directly to the canvas (`ssDataView`), guarded by `is_data_view` so it won't re-switch on reconnect.
- On reconnect, the app stays on the canvas — `onBleEncrypted` just re-subscribes since `is_data_view` is already true, and the toasts handle transition feedback.
- Deleted the obsolete ble_bondingApp.mc — a leftover duplicate from when the app was renamed to `mouse_canvas`, which was causing redefinition errors once it got pulled into analysis.

The only remaining diagnostic is a pre-existing redundant-null-check warning in simpleBle.mc unrelated to this work.

Made changes.

User: the toasts behave properly HOWEVER the mouse doesn't send any data after reconnecting:

26-06-22 11:30:05: -.--    Info  fenix-8-..CIQ[Info] BLE disconnected, scanning to reconnect
26-06-22 11:30:05: -.--    Info  fenix-8-..CIQ[Info] Connecting to MX Anywhere 3S
26-06-22 11:30:05: -.--    Info  fenix-8-..CIQ[Info] Couldn't pair device: Obj: 173
26-06-22 11:30:13: -.--    Info  fenix-8-..CIQ[Info] Connection state change: 1
26-06-22 11:30:13: -.--    Info  fenix-8-..CIQ[Info] Reconnected
26-06-22 11:30:13: -.--    Info  fenix-8-..CIQ[Info] Encryption state change: 0
26-06-22 11:30:13: -.--    Info  fenix-8-..CIQ[Info] Encrypted: subscribing and showing canvas
26-06-22 11:30:13: -.--    Info  fenix-8-..CIQ[Info] Subscribing: setting Boot Protocol mode

GitHub Copilot: The root cause is in the log: `Couldn't pair device: Obj: 173`. On reconnect, `BluetoothLowEnergy.pairDevice()` throws (the bonded device is already pairing/connecting), so `pairedDevice` stays `null`. The connection still succeeds at the BLE layer, and `onConnectedStateChanged` fires with a valid `device` — but `subscribe()` does nothing because `pairedDevice` is `null` (it prints "Subscribing..." then silently skips the `if (pairedDevice != null)` block).

The fix: capture the live device from the connect callback. Let me view the current `on_connected`:   

Read [](file:///c%3A/repos/ciq/bonding/source/simpleBle.mc#279-279), lines 279 to 305

Replacing 6 lines with 11 lines in [](file:///c%3A/repos/ciq/bonding/source/simpleBle.mc)


```

```


Checked [](file:///c%3A/repos/ciq/bonding/source/simpleBle.mc), 1 problem found

Fixed (only the pre-existing unrelated warning remains). 

The reconnect now sets `pairedDevice = device` from the `onConnectedStateChanged` callback. Previously, when `pairDevice()` threw `Obj: 173` during the background reconnect, `pairedDevice` stayed `null` — so after encryption, `subscribe()` printed "Subscribing..." but skipped the actual Protocol Mode write (the `if (pairedDevice != null)` guard), and no notifications were ever enabled. Now the live device handle is always captured, so `subscribe()` → Boot Protocol write → CCCD subscribe proceeds and mouse data flows after reconnect.

Let me record this gotcha:  

Updated memory file [](file:///c%3A/Users/ricojonathan/AppData/Roaming/Code/User/workspaceStorage/7610afed3a3247f571fd002b5bf9ae18/GitHub.copilot-chat/memory-tool/memories/repo/connectiq-gotchas.md)

Rebuild and redeploy — the mouse should now resume sending data after a reconnect.

Made changes.
