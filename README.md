# KernelSU Module Disabler

An ADB recovery script that waits for an existing Root My Galaxy bootstrap helper, then attempts to disable KernelSU modules by creating `disable` marker files.

**Run [disable-kernelsu-modules.sh](./disable-kernelsu-modules.sh) on your computer.** It is a shell script, not a ZIP module to install through KernelSU Manager.

## Why this exists

This script was written following an incompatible-module incident in a temporary-root setup: root access stopped working and the device restarted during the process. The idea is to use a brief working bootstrap-root window to mark modules as disabled before another recovery attempt.

Recovery depends on ADB and the root helper becoming usable. The script cannot recover a device that never provides that access.

## What it does

1. Checks that `adb` is available and waits for a connected device.
2. Polls for an executable `/data/local/tmp/ksu-helper` that can successfully run `-c id`.
3. Uses that helper to create a `disable` file in each immediate, non-hidden subdirectory of the paths below, and attempts to set its permissions to `0644`.
4. Runs `sync` and lists the directories and their marker files for manual verification.

| Path checked | Purpose |
| --- | --- |
| `/data/adb/modules` | Standard installed-module directory |
| `/data/adb/ksu/modules` | Additional location probed by this script |
| `/data/adb/modules_update` | Update/staging location probed by this script |
| `/data/adb/ksu/modules_update` | Additional update/staging location probed by this script |

KernelSU documents the `disable` marker as a module status flag. The other locations above are additional probes; their existence and handling depend on your setup. See the [KernelSU module guide](https://kernelsu.org/guide/module.html#kernelsu-modules).

**This affects every matching directory, not just the suspected incompatible module.** The script does not check `module.prop` before adding a marker.

## Requirements

- A computer with `sh`, `date`, fractional-second `sleep` support, and a writable `/tmp` directory.
- Android Platform Tools with `adb` available in your terminal.
- USB debugging enabled and this computer authorized on the phone. Check the connection with `adb devices`; see the [official ADB instructions](https://developer.android.com/tools/adb#Enabling).
- A Root My Galaxy setup that provides `/data/local/tmp/ksu-helper`, accepts `-c` commands, and can write to the relevant module directories.

The helper is not bundled or installed by this project. The script uses existing root access; it does not create root access or make temporary root persistent.

## Usage

Download the script, or clone this repository:

```sh
git clone https://github.com/Vishesh-093/KernelSU-Module-Disabler.git
cd KernelSU-Module-Disabler
```

Check that ADB sees the intended phone:

```sh
adb devices
```

Start the script from your computer:

```sh
sh disable-kernelsu-modules.sh
```

While it waits, start your existing Root My Galaxy bootstrap process on the phone. If the helper is already usable, the script proceeds immediately.

The default timeout value is **240 seconds**. Supply a positive integer to change it:

```sh
sh disable-kernelsu-modules.sh 600
```

If multiple devices or emulators are connected, select the phone using its serial from `adb devices`:

```sh
ANDROID_SERIAL=YOUR_DEVICE_SERIAL sh disable-kernelsu-modules.sh 600
```

## Verify the result

Read the terminal output before rebooting or retrying your root setup:

- Confirm that the helper output contains `uid=0`.
- Check the final `Verification:` listing for an actual `disable` file in each intended module directory.
- Treat `Permission denied`, missing marker files, or ADB errors as failures requiring investigation.
- If every checked base directory is missing, no modules were marked.

**The final `Done` message, a `disabled:` line, and the script's exit status are not reliable proof of success.** The current script does not enforce all write or verification results, and its readiness check tests command success rather than checking for UID 0.

After confirming the markers, follow your setup's reboot or root-restart procedure. Writing markers does not immediately unload active modules or undo changes they already made. Once stable, use KernelSU Manager to remove the incompatible module and re-enable only modules you have checked for compatibility.

## Troubleshooting and limitations

| Symptom | What to check |
| --- | --- |
| `adb not found in PATH` | Install Android Platform Tools and make `adb` available in the same terminal. |
| Device is `unauthorized` or `offline` | Check the phone's debugging authorization, USB connection, and `adb devices` output. |
| Waiting longer than the requested timeout | The timer starts at script launch, but `adb wait-for-device` and individual ADB calls have no enforced timeout. Use Ctrl+C to stop. |
| Bootstrap helper timeout | Confirm your setup actually provides the expected helper. Read `/tmp/disable-kernelsu-modules-check.log` on the computer for the latest helper-check output. |
| `Permission denied` | Confirm helper privileges and access to the module directories; a successful `id` command alone does not prove write access. |
| A base directory is reported missing | That path may not be used by your setup. Check whether any other listed path contains your modules. |

The timeout argument is not validated; use a positive integer. Each attempted helper `id` check overwrites the log; it may be absent if the helper never becomes executable. On timeout, the script also lists `/data/local/tmp` for diagnostics.

The script creates marker files rather than deleting module directories. It issues no reboot, bootloader-unlock, firmware-flashing, or partition-formatting commands. Its scope is module marking through an already available helper, not a universal bootloop repair.

## Validation

The supplied script passed `sh -n disable-kernelsu-modules.sh` (shell syntax validation). This check does not establish successful recovery on a device or compatibility across firmware and KernelSU versions.
