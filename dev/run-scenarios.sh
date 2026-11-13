#!/usr/bin/env bash
# MTS + The Cave + this bridge in the real engine, with a real client. A
# headless server runs a fresh map with the three mods and
# dev/mods/mct-scenario-test; one graphical client at a time (private X
# display, dev/vdisplay.sh) joins and claims a team through MTS's landing pen.
# The test mod runs the script side from /mctt steps sent to the server console.
#
# Sessions (each a fresh map; two teams unless said otherwise). The second
# team is paused and resumed, then loses its base:
#   train           Train Interiors; the defeat resets the team in place  [base]
#   train-disband   Train Interiors; the defeat disbands the team         [base]
#   shelter         Shelter Defense; reset                                [base]
#   shelter-disband Shelter Defense; disband                              [base]
#   solo            Train Interiors, one team: The Cave's server reset    [base]
#   plain           The Cave's default settings: no base, no defeat       [base]
#   sa              train-disband with Space Age                     [space-age]
#   staged          Train Interiors with MTS Staged Start: no base until the
#                   leader presses Start Playing; one team                [base]
#   calibrate join, screenshot, quit (to find the pen button)
#
#   usage: dev/run-scenarios.sh [session ...]   (default: all eight)
#   HARNESS_PORT=<port>   server port (default MP_PORT in harness.conf)
#
# Exit status is non-zero on any MCT_TEST FAIL, a missing MCT_TEST DONE, a Lua
# or engine error, a desync or a failed step. Everything it started (client,
# server, display) is stopped on exit, also on failure. Logs and screenshots:
# .run/scen/<session>/.
set -uo pipefail
DEV="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=harness-lib.sh
. "$DEV/harness-lib.sh"
# shellcheck source=vdisplay.sh
. "$DEV/vdisplay.sh"
# shellcheck source=scenario-lib.sh
. "$DEV/scenario-lib.sh"
PORT="${HARNESS_PORT:-${MP_PORT:?set MP_PORT in dev/harness.conf}}"
TEST_MOD_DIR="$DEV/mods/mct-scenario-test"
PEN_BUTTON=(${PEN_BUTTON:-185 139})                 # "Start a new team" at 1280x720, UI scale 1
WELCOME_CLOSE=(${WELCOME_CLOSE:-846 53})            # the welcome window's close button
START_PLAYING=(${START_PLAYING:-640 488})          # the staged-start window's "Start Playing"
DEFEAT_WAIT=120                                     # The Cave's countdown from base lost to defeat
TEAM=""
trap scen_cleanup EXIT
trap 'exit 130' INT TERM

session() { # <name> <set> [cave mode] [reset|disband]
  RUN="$REPO/.run/scen/$1"; SET="$2"; SCEN_MODS="$RUN/mods"; CLIENT_N=0
  export CAVE_MODE="${3:-}" MCT_DISBAND=""
  [ "${4:-}" = disband ] && MCT_DISBAND=1
  rm -rf "$RUN"; mkdir -p "$RUN/server" "$RUN/shots"
  echo "== $1 ($2${3:+, $3}${4:+, $4})"
  harness_stage "$RUN" "$SET" "$TEST_MOD_DIR" || return 1
  scen_create "$RUN/world.zip" || return 1
  scen_server_start "$RUN/world.zip"
}

# A player joins under <name>; the one before must have left.
join_as() { # <name>
  SCEN_NAME="$1"
  scen_client_setup
  printf '{ "service-username": "%s" }\n' "$SCEN_NAME" > "$SCEN_GUI/userdata/player-data.json"
  scen_client_start
}

# Click the landing pen's "Start a new team" and wait until The Cave has built
# the team's base; sets TEAM.
claim_team() {
  local attempt line
  "$DEV/gui-drive.sh" click "${WELCOME_CLOSE[@]}"; sleep 0.5   # the first join opens the welcome window
  for attempt in 1 2 3; do
    scen_mark
    "$DEV/gui-drive.sh" click "${PEN_BUTTON[@]}"
    if scen_wait "MCT_TEST STEP team-created: " 15; then
      line=$(scen_line "MCT_TEST STEP team-created: ")
      TEAM="${line##*team-created: }"
      scen_wait "MCT_TEST STEP base: team=$TEAM " 120 || { scen_shot "no-base-$TEAM"; return 1; }
      line=$(scen_line "MCT_TEST STEP base: team=$TEAM ")
      echo "  $SCEN_NAME claimed $TEAM (${line##*STEP base: })"
      return 0
    fi
    scen_shot "claim-attempt-$attempt"
  done
  return 1
}

# Destroy <team>'s base, wait for The Cave's defeat, check the outcome.
defeat() { # <team> <reset|disband|server>
  scen_step "/mctt defeat $1" defeat || return 1
  scen_mark
  scen_wait "MCT_TEST STEP defeated: $1 " "$DEFEAT_WAIT" || { scen_shot "no-defeat-$1"; return 1; }
  sleep 3
  scen_shot "defeated-$1-$2"
  scen_step "/mctt after-defeat $1 $2" after-defeat || return 1
  echo "  $1 defeated ($2)"
}

finish() {
  scen_mark; scen_cmd "/mctt done"; scen_wait "MCT_TEST DONE" 10
  scen_client_stop; scen_server_stop
}

# Two teams; the second is paused and resumed, then defeated.
two_teams() { # <session> <set> [cave mode] [reset|disband]
  local first outcome="${4:-}"
  session "$@" || return 1
  join_as tester || return 1
  sleep 3; scen_shot pen
  scen_step "/mctt pen" pen || return 1
  claim_team || return 1
  first="$TEAM"
  scen_step "/mctt owned $first" owned || return 1
  scen_shot "team-$first"
  scen_client_stop
  join_as tester2 || return 1
  claim_team || return 1
  scen_step "/mctt owned $TEAM" owned || return 1
  scen_step "/mctt pause $TEAM" pause || return 1
  scen_step "/mctt resume $TEAM" resume || return 1
  if [ -n "$outcome" ]; then
    defeat "$TEAM" "$outcome" || return 1
    if [ "$outcome" = reset ]; then
      scen_mark; scen_wait "MCT_TEST STEP base: team=$TEAM " 120 || { scen_shot "no-rebuilt-base"; return 1; }
      echo "  $TEAM has a base again"
      scen_step "/mctt owned $TEAM" owned || return 1
    else   # the freed slot can be claimed again
      sleep 3; claim_team || return 1
      scen_step "/mctt owned $TEAM" owned || return 1
    fi
    scen_step "/mctt owned $first" owned || return 1
  fi
  finish
}

run_train()           { two_teams train base train-interiors reset; }
run_train-disband()   { two_teams train-disband base train-interiors disband; }
run_shelter()         { two_teams shelter base shelter-defense reset; }
run_shelter-disband() { two_teams shelter-disband base shelter-defense disband; }
run_plain()           { two_teams plain base; }
run_sa()              { two_teams sa space-age train-interiors disband; }

run_solo() {
  session solo base train-interiors || return 1
  join_as tester || return 1
  claim_team || return 1
  scen_step "/mctt owned $TEAM" owned || return 1
  defeat "$TEAM" server || return 1
  finish
}

run_staged() {
  session staged base train-interiors || return 1
  # MTS's Staged Start admin flag. The first Lua command on a server console
  # only asks to be repeated, so it is sent twice.
  local flag="/c __multi-team-support__ storage.admin_flags = storage.admin_flags or {}; storage.admin_flags.staged_start_enabled = true"
  scen_cmd "$flag"; sleep 1; scen_cmd "$flag"; sleep 1
  join_as tester || return 1
  "$DEV/gui-drive.sh" click "${WELCOME_CLOSE[@]}"; sleep 0.5
  scen_mark
  "$DEV/gui-drive.sh" click "${PEN_BUTTON[@]}"
  scen_wait "MCT_TEST STEP team-created: " 15 || { scen_shot no-claim; return 1; }
  TEAM=$(scen_line "MCT_TEST STEP team-created: "); TEAM="${TEAM##*team-created: }"
  sleep 8   # long enough for The Cave to have built a base if it were going to
  scen_step "/mctt staged $TEAM" staged || return 1
  scen_shot staged-waiting
  scen_mark
  "$DEV/gui-drive.sh" click "${START_PLAYING[@]}"
  scen_wait "MCT_TEST STEP clock-started: $TEAM" 15 || { scen_shot no-start; return 1; }
  scen_wait "MCT_TEST STEP base: team=$TEAM " 120 || { scen_shot no-base; return 1; }
  echo "  $TEAM pressed Start Playing and has its base"
  scen_step "/mctt owned $TEAM" owned || return 1
  finish
}

run_calibrate() {
  session calibrate base || return 1
  join_as tester || return 1
  sleep 3; scen_shot pen
  scen_cmd "/mctt done"; sleep 1
  scen_client_stop; scen_server_stop
}

WANT=("$@"); [ ${#WANT[@]} -eq 0 ] && WANT=(train train-disband shelter shelter-disband solo plain sa staged)
scen_preflight || exit 1
echo "Factorio $ENGINE_VERSION: $FACTORIO"
overall=0
for s in "${WANT[@]}"; do
  case "$s" in
    calibrate|train|train-disband|shelter|shelter-disband|solo|plain|sa|staged) ;;
    *) echo "unknown session: $s"; overall=1; continue ;;
  esac
  "run_$s" || { echo "  [$s] a step failed"; overall=1; }
  scen_cleanup
  [ "$s" = calibrate ] || scen_evaluate "$s" || overall=1
done
if [ $overall -eq 0 ]; then echo "ALL PASS"; else echo "FAILED"; fi
exit $overall
