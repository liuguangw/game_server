#!/bin/sh
#start or stop ShareMemory
# Usage: shm start stop clear disp

userage() {
  echo "Usage: ./shm start|stop|clear|disp"
}

clrsm() {
  if pgrep -f "./ShareMemory" >/dev/null; then
    echo "ShareMemory already run, stop it first!"
  else
    ipcs >/tmp/tmp$$
    if test -e /tmp/tmp$$; then
      _runflag=0
      while read -r _line; do
        if [ "$_line" = "" ]; then
          continue
        fi

        _run=$(echo "$_line" | grep "Shared Memory Segments")
        if [ "$_run" != "" ]; then
          _runflag=1
          continue
        fi

        _run=$(echo "$_line" | grep "Semaphore Arrays")
        if [ "$_run" != "" ]; then
          break
        fi

        _tag=$(echo "$_line" | grep "^0x" | awk '{print $5}')
        if [ "$_tag" = "" ]; then
          continue
        fi
        if [ "$_tag" = "404" ]; then
          continue
        fi
        _tag=$(echo "$_line" | awk '{print $2}')
        ./smtool "$_tag"
      done </tmp/tmp$$
      return 0
    else
      echo "can't create /tmp/tmp$$, please retry!"
    fi
  fi
  return 1
}

start() {
  if pgrep -f "./ShareMemory" >/dev/null; then
    echo "ShareMemory already run, start failed!"
  else
    echo 1024000000 >/proc/sys/kernel/shmmax
    ./ShareMemory &
    return 0
  fi
  return 1
}

stop() {
  processID=$(pgrep -f "./ShareMemory")
  if [ -n "$processID" ]; then
    echo "ShareMemory not run, stop ok!"
    return 0
  else
    kill -9 "$processID"
    return 0
  fi
  return 1
}

disp() {
  if pgrep -f "./ShareMemory" >/dev/null; then
    echo "ShareMemory run ok!!"
    echo ""
    ipcs
  else
    echo "ShareMemory not run!"
    return 1
  fi
  return 0
}

if [ $# != 1 ]; then
  userage
  exit 1
fi

case $1 in
start)
  if clrsm && start; then
    echo "start ShareMemory ok! pls wait for it run in loop()..."
  else
    echo "some error occ when start ShareMemory, please retry!"
  fi
  ;;
stop)
  if stop; then
    echo "stop shm ok!"
  else
    echo "some error occ when stop shm, please retry!"
  fi
  ;;
clear)
  if clrsm; then
    echo "clear shm ok!"
  else
    echo "some error occ when clear shm, please retry!"
  fi
  ;;
disp)
  disp
  ;;
*)
  userage
  exit 1
  ;;
esac
