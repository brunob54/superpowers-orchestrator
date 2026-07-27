# Portable `timeout` fallback for systems without GNU coreutils (e.g. stock macOS).
# Source this file; it defines a `timeout` shell function ONLY when neither
# `timeout` nor `gtimeout` is already on PATH.

if ! command -v timeout >/dev/null 2>&1; then
  if command -v gtimeout >/dev/null 2>&1; then
    timeout() { gtimeout "$@"; }
  else
    timeout() {
      local duration="$1"
      shift
      # Accept GNU's suffixed durations (`60s`, `5m`, `1h`) as whole seconds.
      # Anything else (fractions, unknown suffixes) keeps the one-shot sleep
      # path below.
      local secs="$duration"
      case "$secs" in
        *[0-9]s) secs=${secs%s} ;;
        *[0-9]m) secs=$(( ${secs%m} * 60 )) ;;
        *[0-9]h) secs=$(( ${secs%h} * 3600 )) ;;
      esac
      case "$secs" in
        ''|*[!0-9]*) secs="" ;;
      esac
      "$@" &
      local child=$!
      # Two things matter here, both learned from a 30-minute hang:
      #  - The watcher is redirected away from the caller's stdout/stderr. In a
      #    pipeline (`timeout ... | reader`) an inherited pipe write end held
      #    open by the watcher stops the reader from ever seeing EOF, so the
      #    pipeline blocks for the full duration after the command has exited.
      #  - The watcher polls in short naps instead of one long `sleep`, and
      #    exits on its own as soon as the child is gone. A single long sleep
      #    outlives `kill`ing the watcher subshell (kill does not reach the
      #    sleep), and killing the sleep from here races the subshell's fork
      #    whenever the command finishes fast.
      (
        if [ -n "$secs" ]; then
          waited=0
          while [ "$waited" -lt "$secs" ]; do
            sleep 1
            kill -0 "$child" 2>/dev/null || exit 0
            waited=$(( waited + 1 ))
          done
        else
          sleep "$duration"
        fi
        kill -TERM "$child" 2>/dev/null
      ) >/dev/null 2>&1 &
      local watcher=$!
      local status
      wait "$child"
      status=$?
      kill "$watcher" 2>/dev/null
      wait "$watcher" 2>/dev/null
      return "$status"
    }
  fi
  # Make the function visible to child bash processes (e.g. sub-scripts run
  # by a runner that sourced this shim).
  export -f timeout
fi
