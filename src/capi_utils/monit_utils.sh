#!/usr/bin/env bash

function wait_for_server_to_become_unavailable() {
  local url=$1
  local timeout=$2
  for _ in $(seq "${timeout}"); do
    set +e
    curl -k -f --connect-timeout 1 "${url}" > /dev/null 2>&1
    if [ $? -ne 0 ]; then
      return 0
    fi
    set -e
    sleep 1
  done

  echo "Endpoint ${url} did not go down after ${timeout} seconds"
  return 1
}

function wait_for_server_to_become_healthy() {
  local url=$1
  local timeout=$2
  for _ in $(seq "${timeout}"); do
    set +e
    curl -k -f --connect-timeout 1 "${url}" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
      return 0
    fi
    set -e
    sleep 1
  done

  echo "Endpoint ${url} failed to become healthy after ${timeout} seconds"
  return 1
}

function monit_unmonitor_job() {
  local job_name="$1"
  sudo /var/vcap/bosh/bin/monit unmonitor "${job_name}"
}

function drain_job() {
  local job_name="$1"
  sudo "/var/vcap/jobs/${job_name}/bin/drain"
}

function monit_start_job() {
  local job_name="$1"
  sudo /var/vcap/bosh/bin/monit start "${job_name}"
}

function monit_stop_job() {
  local job_name="$1"
  sudo /var/vcap/bosh/bin/monit stop "${job_name}"
}
