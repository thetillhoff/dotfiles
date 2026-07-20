---
name: proton-launch-debug
description: >
  Diagnose and fix Windows games that fail to launch, crash on launch, or close
  instantly under Steam Proton on Linux (Bazzite, SteamOS, any distro). Use
  whenever a game "closes immediately after I hit Play", "won't start", "shows
  running for a second then stops", "Play button does nothing", or "worked before,
  broke after an update" - especially Ubisoft Connect / uplay, Denuvo, EA App, or
  Epic titles. Also use for interpreting PROTON_LOG output, "game already running"
  states, or picking between GE-Proton / Experimental / bleeding-edge. Triggers on:
  Proton, Steam Deck, Bazzite, wine prefix, compatdata, Ubisoft Connect, Denuvo,
  vkd3d, DXVK, ntsync, split_lock, "game won't launch on Linux".
---

# Proton Launch Debugging

A game that won't launch under Proton is a debugging problem, not a guessing
game. Work the evidence in order. The single highest-value idea:

**A game process that dies in under ~1 second with no crash dialog, no coredump,
no Wine exception, and no GPU fault was killed from *below* Wine - by the kernel.**
Proton can only log what happens inside the Wine process; a kernel `SIGBUS`/`SIGKILL`
happens underneath it, so the log just shows a clean load then silence. That
*absence* is the fingerprint. On recent kernels the usual culprits are new kernel
features Proton now uses by default. Check those first - they're free and fix the
most stubborn cases.

## Fast path: the below-Wine kills (try before deep diagnosis)

Recent kernels (roughly 6.14+, and any 2025+ build) shipped features that silently
kill anti-tamper/DRM code. This is the most common cause of "worked months ago,
instant-closes now, unfixable by reinstalling anything." All are near-free to try.

| Symptom / check | Fix |
| --- | --- |
| `/dev/ntsync` exists (`ls /dev/ntsync`) | Launch option: `PROTON_NO_NTSYNC=1 %command%` |
| `sysctl kernel.split_lock_mitigate` returns `1` | `sudo sysctl kernel.split_lock_mitigate=0` (per boot; persist via `/etc/sysctl.d/` if it helps) |
| Still dying, or fsync-sensitive game | Add `PROTON_NO_FSYNC=1` (then also `PROTON_NO_ESYNC=1`) |

`ntsync` is the #1 fix for Ubisoft Connect / Denuvo games on current kernels: it's
an in-kernel Windows-sync driver that all recent Proton builds auto-use, which is
why the failure is **invariant across every Proton version** - the tell that you're
chasing a kernel feature, not a Proton bug. Set it as a launch option and relaunch:

```text
PROTON_NO_NTSYNC=1 %command%
```

Bazzite already ships `split_lock_mitigate=0`, so on Bazzite ntsync is the likely
one. Confirm the whole set in one shot:

```sh
ls -l /dev/ntsync 2>/dev/null && echo "ntsync ON -> try PROTON_NO_NTSYNC=1"
sysctl kernel.split_lock_mitigate
```

If the fast path fixes it, stop. Remove any `PROTON_LOG=1` you added and keep the
`PROTON_*` launch option.

## Capturing a Proton log

Set the game's **Launch Options** (Properties → General) - this is the reliable way
to inject env, because a game launched by an already-running Steam does **not**
inherit env from a `PROTON_LOG=1 steam ...` shell command:

```text
PROTON_LOG=1 %command%
```

Launch, let it fail, then read the log on the machine:

- Native Steam: `~/steam-<appid>.log`
- Flatpak Steam: `~/.var/app/com.valvesoftware.Steam/steam-<appid>.log`

The log is enormous and mostly trace spam. Filter it:

```sh
L=~/steam-<appid>.log
# Real errors, minus known-benign noise:
grep -aE ":err:" "$L" | grep -avE "NtGetContextThread|ToastNotification|RoGetActivation|marshal_object|com_get_class|IRpcStub|get_stub_manager|ZwLoadDriver|combase|hacks_init"
# Real tail (strip the trace floods):
grep -avE "trace:seh:NtGetContextThread|trace:seh:QueryWorkingSetEx|dump_unwind_info|RtlVirtualUnwind|:loaddll:" "$L" | tail -60
```

### Measure the real game's lifetime

This is the key move. Find the actual game exe's PID and how long it lived:

```sh
# Find the game exe's first load (gives you its pid, e.g. 0150):
grep -anE "Loaded L\".*<GameExe>\.exe\"" "$L" | head
# First and last timestamp for that pid = lifetime:
grep -aE "^[0-9.]+:0150:" "$L" | head -1 | cut -d: -f1
grep -aE "^[0-9.]+:0150:" "$L" | tail -1 | cut -d: -f1
```

- **< ~1s, no error, last lines are DLL loads (crypto, DRM, `uplay_aux`, `dbdata.dll`)**
  → external kill. Go to the fast path (ntsync / split-lock).
- **Seconds, reaches DXVK/vkd3d frame submission, then silent** → later crash;
  check `coredumpctl`, GPU fault, shader issues.
- **Reaches a Wine exception / `Unhandled exception` / backtrace** → in-Wine crash;
  read the stack, missing DLL, or dependency.

### Don't confuse the launcher with the game

For Ubisoft titles the game exe is often a **bootstrap**: it loads the DRM +
`uplay_aux`, spawns Ubisoft Connect, then exits *by design*, expecting Connect to
relaunch the real game. A **working** launch shows the game exe loaded **twice**
(bootstrap, then the real run). These processes are the launcher, not the game -
their graphics init is not the game's:

- `upc.exe`, `UbisoftConnect.exe`, `UbisoftGameLauncher.exe`, `UplayWebCore.exe`, `xalia.exe`

DXVK/vkd3d `info:  Game:` and `Program name: "..."` banners tell you which exe owns
a given D3D device. A D3D12/DXR device created by `UplayWebCore.exe` is Ubisoft
Connect's browser, **not** the game rendering.

Ubisoft's own launcher log is often clearer than the Proton log:

```text
<prefix>/drive_c/Program Files (x86)/Ubisoft/Ubisoft Game Launcher/logs/launcher_log.txt
```

## Check the kernel side

A kill or a real GPU hang shows here even when the Proton log is silent:

```sh
coredumpctl list --since "30 min ago"
journalctl -k -b | grep -aiE "amdgpu|ring.*timeout|gpu reset|page fault|gfxhub|split.lock|#AC|traps|segfault"
```

No coredump + no GPU fault + sub-second death = the below-Wine kill. A real
`amdgpu ... ring timeout / GPU reset` is a different problem (driver/mesa hang),
not this.

## Is it even a local problem?

Before deep work, check whether the game works for other people. If ProtonDB says
Gold/Platinum and it fails only for you, the fault is **local** (your env, prefix,
account, or kernel) - don't waste time blaming the game or Proton:

```sh
curl -sL "https://www.protondb.com/api/v1/reports/summaries/<appid>.json"
```

## Broader fix ladder (when the fast path isn't it)

Cheapest / most-informative first. Each rung also *rules something out*.

1. **GE-Proton** - community Proton fork with launcher/DRM fixes ahead of
   Experimental. Install to `~/.steam/root/compatibilitytools.d/`, then **restart
   Steam** (only scanned at startup):

   ```sh
   TAG=$(curl -s https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/latest | grep -oP '"tag_name": "\K[^"]+')
   curl -fL "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/$TAG/$TAG.tar.gz" \
     | tar -xz -C ~/.steam/root/compatibilitytools.d/
   ```

   (ProtonPlus is only the *installer* for GE - GE is the actual Proton. Installing
   by CLI skips it.)
2. **Prefix rebuild** - fixes a prefix left inconsistent by Proton-version swaps.
   Back up rather than delete (saves live inside, and are usually cloud-synced):

   ```sh
   mv ~/Games/Steam/steamapps/compatdata/<appid>{,.bak}   # adjust library path
   ```

   Relaunch; Steam rebuilds a fresh prefix (slow first launch, reinstalls the
   launcher inside it - normal).
3. **Verify integrity of game files** - catches a partial/corrupt update.
4. **Proton Experimental → `bleeding-edge` beta** (Tools → Proton Experimental →
   Properties → Betas) - newest handoff/DRM fixes.
5. **Older stable Proton (9.0)** - different sync/seccomp handling; occasionally
   sidesteps a new-kernel interaction.

**Denuvo activation limit** (~5 hardware activations / 24h): each Proton version
swap looks like new hardware and **burns one**. Don't switch versions repeatedly -
pick one and rebuild. A true lockout lets the process live several seconds while it
phones home; a sub-second death is **not** a lockout, it's the below-Wine kill.

## Cleanup: stale processes / "Game already running"

Failed Ubisoft launches leave `upc.exe` / `UplayWebCore.exe` alive, so Steam/Ubisoft
report "already running" and block relaunch. Kill the tree (they run inside Steam's
pressure-vessel sandbox, so kill the container root or by name):

```sh
pkill -9 -f "UbisoftConnect|UbisoftGameLauncher|UplayWebCore|upc.exe|UplayService|<GameExe>"
pgrep -af "reaper SteamLaunch AppId=<appid>"   # if present, kill it -> Steam shows "not running"
```

If Steam still shows "running", fully restart Steam. Leave Steam's own
`steamrt64/pv-runtime` bwrap alone - that's the client, not the game.

## Inspect Ubisoft Connect standalone

To see the account, entitlement, or a hidden prompt the game-starter mode swallows,
run Connect standalone in the game's own prefix:

```sh
STEAM_COMPAT_DATA_PATH="$HOME/Games/Steam/steamapps/compatdata/<appid>" \
STEAM_COMPAT_CLIENT_INSTALL_PATH="$HOME/.local/share/Steam" \
"$HOME/.steam/root/compatibilitytools.d/GE-Proton<N>/proton" run \
"$STEAM_COMPAT_DATA_PATH/pfx/drive_c/Program Files (x86)/Ubisoft/Ubisoft Game Launcher/UbisoftConnect.exe"
```

Check: is the right account logged in, does it *own* the game (watch for lapsed
Ubisoft+ subscription titles showing as "installed"), any pending EULA/2FA/update.

## Harmless noise (don't chase these)

- `libextest.so ... wrong ELF class: ELFCLASS32` - Steam input shim, benign.
- `err:ole:marshal_object` / `RoGetActivationFactory ... ToastNotification` /
  `com_get_class_object not registered` - overlay/accessibility, benign.
- `fixme:` lines - unimplemented stubs, almost always benign.
- `ScheduledTask ... AutoUpdate failed` in Ubisoft's log - can't set Windows
  scheduled tasks under Wine, benign.
