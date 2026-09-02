#!/bin/sh
set -u

HELPER="/data/local/tmp/ksu-helper"
TIMEOUT_SECONDS="${1:-240}"
START_TIME="$(date +%s)"

if ! command -v adb >/dev/null 2>&1; then
  echo "adb not found in PATH" >&2
  exit 1
fi

echo "Waiting up to ${TIMEOUT_SECONDS}s for Root My Galaxy bootstrap root..."
adb wait-for-device

while :; do
  now="$(date +%s)"
  elapsed=$((now - START_TIME))

  if [ "$elapsed" -ge "$TIMEOUT_SECONDS" ]; then
    echo "FAILED: bootstrap root helper did not become usable within ${TIMEOUT_SECONDS}s." >&2
    adb shell "ls -la /data/local/tmp 2>/dev/null || true"
    exit 1
  fi

  if adb shell "[ -x '$HELPER' ]" &&
     adb shell "$HELPER -c id" >/tmp/disable-kernelsu-modules-check.log 2>&1; then
    echo "Bootstrap root helper is available. Disabling modules now."
    break
  fi

  sleep 0.1
done

adb shell "$HELPER -c '
echo root-helper-start uid=\$(id)

for base in /data/adb/modules /data/adb/ksu/modules /data/adb/modules_update /data/adb/ksu/modules_update; do
  if [ -d \"\$base\" ]; then
    echo \"module-base: \$base\"
    for module in \"\$base\"/*; do
      [ -d \"\$module\" ] || continue
      name=\$(basename \"\$module\")
      touch \"\$module/disable\"
      chmod 0644 \"\$module/disable\" 2>/dev/null || true
      echo \"disabled: \$base/\$name\"
    done
  else
    echo \"missing: \$base\"
  fi
done

sync
echo root-helper-done uid=\$(id)
'"

echo "Verification:"
adb shell "$HELPER -c '
for base in /data/adb/modules /data/adb/ksu/modules /data/adb/modules_update /data/adb/ksu/modules_update; do
  if [ -d \"\$base\" ]; then
    echo \"module-base: \$base\"
    for module in \"\$base\"/*; do
      [ -d \"\$module\" ] || continue
      ls -ld \"\$module\" \"\$module/disable\" 2>&1
    done
  fi
done
'"

echo "Done. Reboot or rerun Root My Galaxy with modules disabled."
