Godot Android XR Template
=========================

This is a lightweight Godot project that is already setup to run on
Android XR or Meta Quest 3!

For XR glasses like project Aura, this defaults to a "passthrough" rather
than "immersive" experience.

For an immersive design like a VR HMD, we specify immersive.

<p align="center">
  <img width="430" alt="BowleramaXR — synthwave bowling, immersive view"
       src="https://github.com/user-attachments/assets/0803d880-b03f-408d-b3d2-3ebd3363adea" />
</p>

## Godot XR Tools

This template comes with the
[Godot XR Tools](https://github.com/GodotVR/godot-xr-tools) addon
pre-installed.

It provides many useful XR utilities, for example, rendering 2D UIs
and letting the user interact with them via a pointer attached to
their hands.

Please see the
[XR Tools documentation](https://github.com/GodotVR/godot-xr-tools/wiki)
for more information.

## Installation

Getting an Android XR / Meta Quest project to actually build is the part that
is poorly documented. Here is the full, tested sequence.

### 1. Install Godot 4.7

Android XR support and the OpenXR vendor plugins require **Godot 4.7 or newer**
(the standard build — you do *not* need the .NET/Mono build unless you are
writing C#). Download it from [godotengine.org](https://godotengine.org/download)
or use the exact editor you already have, e.g.:

```
C:\Users\<you>\dev\tools\godot.windows.editor.x86_64.exe
```

### 2. Install the matching Export Templates

The editor ships *without* the platform export binaries. Install them so Godot
can produce an `.apk`:

1. Open the project in Godot.
2. **Editor → Manage Export Templates…**
3. Either **Download and Install** the templates that match your editor version
   exactly (4.7), or, if you downloaded the
   `Godot_v4.7-stable_export_templates.tpz` archive manually, choose
   **Install from File** and point at it.

The version of the templates **must** match the editor version, or exports fail
with a "templates not found / version mismatch" error.

### 3. Install the Android Build Template (Gradle build)

XR requires a **custom Gradle build** so the OpenXR vendor libraries (Meta /
Android XR) and the GDExtension plugin can be packaged into the APK. The stock,
non-Gradle export path will *not* include them.

**Where do the Android sources come from?** You do **not** download them
separately. The Android build template (`android_source.zip`) is bundled *inside*
the export templates you installed in step 2. Godot just needs you to unpack that
bundled copy into your project:

1. **Project → Install Android Build Template…**
2. This unpacks the bundled `android_source.zip` into `res://android/build` in
   your project. You should see an `android/` folder appear next to `game/`,
   `addons/`, etc. This folder is the Gradle project Godot compiles on export —
   it is generated, so you normally don't edit or commit it.
3. In **Project → Export… → Android**, make sure **Gradle Build → Use Gradle
   Build** is enabled (this template's presets already have it on).

> The template version is tied to your editor: if you update Godot or
> re-download the export templates, delete `res://android/build` and re-run
> *Install Android Build Template* so the sources match the new version.
> A stale build template is a common cause of confusing Gradle errors.

### 4. Android SDK / JDK prerequisites

Godot drives the Gradle build using your local Android SDK and a JDK:

- **OpenJDK 17** (required by the current Android Gradle Plugin).
- **Android SDK** with platform-tools, a recent build-tools, and an SDK
  platform (API 34+). The easiest way to get a consistent set is to install
  [Android Studio](https://developer.android.com/studio) once and let it pull
  the SDK, or use the command-line `sdkmanager`.

Then point Godot at them in **Editor → Editor Settings → Export → Android**:

- **Android SDK Path** → your SDK root (e.g. `C:\Users\<you>\AppData\Local\Android\Sdk`).
- A **debug keystore** is generated automatically on first export; for release
  builds set your own.

### 5. Choosing the deploy target (Meta Quest vs Android XR)

This project carries **two export presets**, identical except for which OpenXR
vendor is bundled:

| Preset       | Vendor plugin enabled | Runs on              |
|--------------|-----------------------|----------------------|
| `Meta Quest` | Meta                  | Quest 2 / 3 / 3S / Pro |
| `Android XR` | Android XR (Google)   | Android XR devices / emulator, e.g. Aura |

Only **one preset can be "Runnable" at a time**, and that flag is what Remote
Deploy uses. Switch targets in **Project → Export…** by checking **Runnable** on
the preset you want.

> Mismatch symptom: deploying the `Android XR` preset to a Quest fails with
> `INSTALL_FAILED_MISSING_SHARED_LIBRARY ... libopenxr.google.so`. That library
> only exists on Google Android XR devices — the Quest uses the Meta runtime.
> Switch the Runnable preset back to `Meta Quest`.

### 6. Put the Meta Quest into Developer Mode

Before a Quest will accept a sideloaded build, you have to enable Developer Mode.
This is a **one-time setup** done from your phone, not the headset itself.

1. **Create a Meta developer account / organization.** Sign in at the
   [Meta Horizon developer dashboard](https://developers.meta.com/horizon/) with
   the same Meta account your headset uses, and create an *organization* (any
   name). Meta requires the account to be **verified** before Developer Mode can
   be turned on — this means enabling **two-factor authentication** on the
   account (older docs may mention adding a payment method; 2FA is what's
   enforced today).
2. **Install the Meta Horizon app** on your phone (iOS/Android) — this is the
   former "Meta Quest" / "Oculus" app — and **pair it with your headset** (the
   headset must be on the same account).
3. In the app: **Menu → Devices → select your headset → Headset settings →
   Developer Mode**, and toggle it **on**.
4. **Reboot the headset** (hold power → Restart) so the change takes effect.

### 7. Install the Windows USB (ADB) driver

On Windows the Quest needs Meta's USB driver before `adb` can see it (macOS and
Linux do not need this):

1. Download and unzip the **Oculus ADB Drivers** from the
   [Meta developer downloads](https://developers.meta.com/horizon/downloads/package/oculus-adb-drivers/).
2. Right-click `android_winusb.inf` → **Install**.

> Prefer a GUI? [**Meta Quest Developer Hub (MQDH)**](https://developers.meta.com/horizon/documentation/unity/ts-odh/)
> is Meta's optional desktop app for Windows/macOS. It bundles ADB, installs the
> USB driver for you, and gives you device management, file transfer, and screen
> casting. It's not required — Godot's Remote Deploy works with plain ADB — but
> it's the easiest way to confirm the headset connects.

### 8. Deploy to the headset

1. Connect the headset to the PC over **USB** (a data-capable cable — some cables
   are charge-only).
2. **Put on the headset** and accept the **"Allow USB debugging"** prompt. Tick
   *"Always allow from this computer"* so you aren't re-prompted every session.
   Until you accept this, the device shows as `unauthorized` and will not appear
   in Remote Deploy.
3. From a terminal, confirm the headset is visible and authorized:
   ```
   adb devices
   ```
   You want a line ending in `device` (not `unauthorized` or `no permissions`).
4. Back in Godot, confirm **`Meta Quest`** is the Runnable preset (see step 5),
   then click the **Remote Deploy** button — the little Android/OpenXR icon in
   the top-right toolbar — to build and install onto the headset.
5. The app installs under **App Library → Unknown Sources** on the Quest.

> **Troubleshooting**
> - *No devices / `unauthorized`* → re-check the USB-debugging prompt inside the
>   headset, replug the cable, and run `adb kill-server && adb devices`.
> - *`INSTALL_FAILED_MISSING_SHARED_LIBRARY ... libopenxr.google.so`* → you
>   deployed the `Android XR` preset to a Quest; switch the Runnable preset back
>   to `Meta Quest` (step 5).
> - *Build succeeds but nothing appears* → look under *Unknown Sources*, not the
>   main library grid.

## Viewing the experience with scrcpy

Because the action happens inside the headset, the easiest way to *see and
record* what the player sees — for debugging, demos, or screenshots — is
[**scrcpy**](https://github.com/Genymotion/scrcpy), a free, open-source,
cross-platform (Windows / macOS / Linux) screen-mirroring tool that works over
the same ADB connection.

```
# Windows (Scoop / Chocolatey), macOS (Homebrew), or Linux (apt) — for example:
scoop install scrcpy        # Windows
brew install scrcpy         # macOS
sudo apt install scrcpy     # Linux

# Mirror the connected headset:
scrcpy
```

On a Meta Quest the mirror shows the **stereo (dual-eye) render**, which is why
the capture below is split into a left and right view:

<p align="center">
  <img width="800" alt="BowleramaXR mirrored from the headset via scrcpy (stereo view)"
       src="https://github.com/user-attachments/assets/e77cca67-bfa1-4fad-8f85-bff94a632c79" />
</p>

Handy tips:

- `scrcpy --crop 1832:1920:0:0` (or similar) to mirror just one eye.
- `scrcpy --record demo.mp4` to capture a video for sharing.
- Add `--no-audio` if you only want the video stream.

## Godot MCP and AI integration

There are numerous MCP servers available for Godot, all with somewhat
different approaches.

We recommend [Coding-Solo/godot-mcp](https://github.com/Coding-Solo/godot-mcp),
which is one of the most popular. It's also easy to install (it can be
run via `npx`) and limit to working on the intended Godot project.

The template already includes an `.mcp.json` which will be picked up automatically
by Claude Code.

See [the documentation](https://github.com/Coding-Solo/godot-mcp#quick-start)
for instructions on how to use it with other MCP clients.
