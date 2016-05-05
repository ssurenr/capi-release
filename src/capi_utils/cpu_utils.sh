function cpu_count() {
  declare platform
  platform=$(uname)
  case "${platform}" in
    Darwin)
      echo $(sysctl -n hw.ncpu)
      ;;
    Linux)
      echo $(grep -c ^processor /proc/cpuinfo)
      ;;
  esac
}
