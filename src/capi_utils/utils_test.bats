#!/usr/bin/env bats

# Note that when running processes in the background for test purposes, we need
# to redirect file descriptor 3, so that the process does not lock on the file
# descriptor used by the test suite.
# see: https://github.com/sstephenson/bats/issues/80

setup() {
  SKIP_SYS_LOG_TEE=1
  ## override stubs with original functions
  source ./utils.sh

  TMPDIR=$(mktemp -dt "utils_test.XXXXXXX")
  PIDFILE="${TMPDIR}/test.pid"
  FD3="${TMPDIR}/fd3"
}

teardown() {
  rm -rf ${TMPDIR}
}

assertContains() {
  local e
  for e in "${@:2}"; do [[ "$e" == "$1" ]] && return 0; done
  return 1
}

###
### pid_is_running
###

@test "pid_is_running returns 0 if pid exists" {
  sleep 5 3>${FD3} &
  run pid_is_running $!
  [ "$status" -eq 0 ]
}

@test "pid_is_running returns 1 if pid does not exist" {
  run pid_is_running 84753
  [ "$status" -eq 1 ]
}


###
### pid_guard
###

@test "pid_guard exits 1 and does not delete the pid file if pid file exists and process is running" {
  sleep 5 3>${FD3} &
  echo $! > ${PIDFILE}

  run pid_guard ${PIDFILE} "sleep"
  [ "$status" -eq 1 ]
  [ -e ${PIDFILE} ]
  assertContains "sleep is already running, please stop it first" "${lines[@]}"
}

@test "pid_guard exits 0 and deletes the pid file if the pidfile is empty" {
  touch ${PIDFILE}

  run pid_guard ${PIDFILE} "empty pidfile"
  [ "$status" -eq 0 ]
  [ ! -e ${PIDFILE} ]
  assertContains "Removing stale pidfile..." "${lines[@]}"
}

@test "pid_guard exits 0 and deletes the pid file if pid file exists and process is NOT running" {
  touch ${PIDFILE} 3>${FD3} &
  echo $! > ${PIDFILE}

  run pid_guard ${PIDFILE} "fast process"
  [ "$status" -eq 0 ]
  [ ! -e ${PIDFILE} ]
  assertContains "Removing stale pidfile..." "${lines[@]}"
}

@test "pid_guard exits 0 if pid file does not exist" {
  run pid_guard ${PIDFILE} "no pidfile"
  [ "$status" -eq 0 ]
}

###
### kill_and_wait
###

@test "kill_and_wait exits 0 with a warning when the pidfile does not exist" {
  run kill_and_wait ${PIDFILE} 1
  [ "$status" -eq 0 ]
  assertContains "Pidfile ${PIDFILE} doesn't exist" "${lines[@]}"
}

@test "kill_and_wait exits 0 and removes pidfile with a warning when the pidfile exists but the process is not running" {
  touch ${PIDFILE} 3>${FD3} &
  pid=$!
  echo ${pid} > ${PIDFILE}

  run kill_and_wait ${PIDFILE} 1
  [ "$status" -eq 0 ]
  [ ! -e ${PIDFILE} ]
  assertContains "Process ${pid} is not running" "${lines[@]}"
}

@test "kill_and_wait exits 0 if when the pidfile exists and the process is running" {
  sleep 5 3>${FD3} &
  echo $! > ${PIDFILE}

  run kill_and_wait ${PIDFILE} 1
  [ "$status" -eq 0 ]
}

@test "kill_and_wait removes pidfile if process actually stops" {
  sleep 5 3>${FD3} &
  echo $! > ${PIDFILE}

  run kill_and_wait ${PIDFILE} 1

  [ "$status" -eq 0 ]
  assertContains "Stopped" "${lines[@]}"
  [ ! -e ${PIDFILE} ]
}

@test "kill_and_wait exits 1 when the pidfile is empty" {
  echo "" > ${PIDFILE}

  run kill_and_wait ${PIDFILE} 1
  [ "$status" -eq 1 ]
  assertContains "Unable to get pid from ${PIDFILE}" "${lines[@]}"
}

@test "kill_and_wait exits 1 and times out when we don't try very hard to kill the process" {
  pid_is_running() {
    true
  }

  wait_pid_death() {
    true
  }

  sleep 5 3>${FD3} &
  echo $! > ${PIDFILE}

  run kill_and_wait ${PIDFILE} 1

  [ "$status" -eq 1 ]
  [ -e ${PIDFILE} ]
  assertContains "Timed Out" "${lines[@]}"
}


###
### wait_pid_death
###

@test "wait_pid_death exits 0 if process is not running" {
  touch ${PIDFILE} 3>${FD3} &
  pid=$!

  run wait_pid_death ${pid} 1
  [ "$status" -eq 0 ]
}

@test "wait_pid_death exits 0 if process stops before timeout" {
  sleep 0.3 3>${FD3} &
  pid=$!

  run wait_pid_death ${pid} 1
  [ "$status" -eq 0 ]
}

@test "wait_pid_death exits 1 when the process does not stop within timeout" {
  sleep 5 3>${FD3} &
  pid=$!

  run wait_pid_death ${pid} 1
  [ "$status" -eq 1 ]
}

@test "wait_pid_death prints a . for each second before it exits" {
  sleep 5 3>${FD3} &
  pid=$!

  run wait_pid_death ${pid} 2
  [ "$output" = ".." ]
}
