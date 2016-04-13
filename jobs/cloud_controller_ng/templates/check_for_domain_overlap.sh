#!/usr/bin/env bash


function check_for_domain_overlap {
  system_domain=$1
  shift
  app_domains=($@)

  for app_domain in "${app_domains[@]}"; do
    if [[ $app_domain == *$system_domain ]]; then
      echo "Invalid configuration: app_domains contains the value ${app_domain} which is a sub-domain of the system_domain, ${system_domain}."
      return 1
    fi
  done
}

