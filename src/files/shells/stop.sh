#!/bin/sh

#等待进程退出
waitForExit() {
  while pgrep -f "./$1" >/dev/null; do
    sleep 1
  done
  echo "$1 stopped completely !!!!!!"
}

#kill进程,并等待退出
killByName() {
  processPID=$(pgrep -f "./$1")
  if [ -z "$processPID" ]; then
    echo "$1 already stopped !!"
    return 0
  fi
  kill -9 "$processPID"
  waitForExit "$1"
}

cd /home/tlbb/Server || exit

###### stop Server ######
echo "stopping Server ......"
touch quitserver.cmd
waitForExit "Server"

###### stop Login ######
echo "stopping Login ......"
killByName "Login"

###### stop billing ######
billPID=$(pgrep -f billing)
if kill ${billPID}; then
  echo "billing stopped completely !!!!!!"
fi

#cd
cd /home/tlbb/Server || exit

###### stop World ######
echo "stopping World ......"
killByName "World"

###### stop ShareMemory ######
echo "ShareMemory is saving data ......"
touch exit.cmd
waitForExit "ShareMemory"

###### transfer logs ######
#DIR=`date +%Y%m%d-%H%M`
#mkdir -p /home/tlbb/logbak/$DIR
#mv /home/tlbb/Server/Log/* /home/tlbb/logbak/$DIR
#echo "log transfer to "/home/tlbb/logbak/" completely !!!!!!"
