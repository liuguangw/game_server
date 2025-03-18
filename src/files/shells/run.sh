#!/bin/sh
trap 'sigStop=1;stop_gs' TERM INT

#颜色
colorRed="\033[31m"
colorGreen="\033[32m"
colorReset="\033[0m"
#定义变量
exitCode=-1
sigStop=0

#如果目录不存在,则尝试解压
if [ ! -d "/home/tlbb" ] && [ -f "/home/tlbb.tar.gz" ]; then
  cd /home || exit 1
  tar -zxf tlbb.tar.gz
  #修改所有者
  chown -R "$(stat -c '%u:%g' /home/tlbb.tar.gz)" /home/tlbb
fi

#目录不存在
if [ ! -d "/home/tlbb" ]; then
  echo "dir /home/tlbb not found"
  exit 1
fi

#billing
billDir="/home/bill"
if [ ! -d "${billDir}" ]; then
  mkdir -p "${billDir}"
  #修改所有者
  chown -R "$(stat -c '%u:%g' /home)" ${billDir}
fi

#copy 脚本
cp /root/shells/shm.sh /home/tlbb/Server/shm
#添加执行权限
chmod -R +x /home/tlbb/Server
#copy配置文件模板
cp /root/config/etc/* /etc/
cp /root/config/server/* /home/tlbb/Server/Config/

#初始化变量
initAppVariable() {
  eval "currentValue=\"\$$1\""
  #echo "currentValue=\"\$$1\""
  if [ -z "${currentValue}" ]; then
    eval "$1=\"\$2\""
    #echo "$1=\"\$2\""
  fi
}
#初始化
initAppVariable GAME_SERVER_IP 127.0.0.1
initAppVariable GAME_SERVER_PORT 3731
initAppVariable BILLING_SERVER_IP 127.0.0.1
initAppVariable BILLING_SERVER_PORT 12680
initAppVariable SMU_INTERVAL 1200000
initAppVariable DATA_INTERVAL 900000
initAppVariable WITH_GAME_LOG "yes"
#mysql
initAppVariable DB_HOST db_server
initAppVariable DB_PORT 3306
initAppVariable DB_USERNAME root
initAppVariable DB_PASSWORD root
initAppVariable DB_GAME_NAME tlbbdb
initAppVariable DB_ACCOUNT_NAME web

# 根据模板生成配置文件
replaceConfigFile() {
  sed -i "s#$1#$2#g" "$3"
}

# 根据数据库模板生成配置文件
replaceDbConfig() {
  replaceConfigFile "$1" "$2" /etc/odbc.ini
  replaceConfigFile "$1" "$2" /home/tlbb/Server/Config/LoginInfo.ini
  replaceConfigFile "$1" "$2" /home/tlbb/Server/Config/ShareMemInfo.ini
}
#replace ip and port
replaceConfigFile GAME_SERVER_IP "${GAME_SERVER_IP}" /home/tlbb/Server/Config/ServerInfo.ini
replaceConfigFile GAME_SERVER_PORT "${GAME_SERVER_PORT}" /home/tlbb/Server/Config/ServerInfo.ini
#replace billing config
replaceConfigFile BILLING_SERVER_IP "${BILLING_SERVER_IP}" /home/tlbb/Server/Config/ServerInfo.ini
replaceConfigFile BILLING_SERVER_PORT "${BILLING_SERVER_PORT}" /home/tlbb/Server/Config/ServerInfo.ini
#replace 存档时间
replaceConfigFile SMU_INTERVAL "${SMU_INTERVAL}" /home/tlbb/Server/Config/ShareMemInfo.ini
replaceConfigFile DATA_INTERVAL "${DATA_INTERVAL}" /home/tlbb/Server/Config/ShareMemInfo.ini

#replace DB_HOST
replaceDbConfig DB_HOST "${DB_HOST}"
#replace DB_PORT
replaceDbConfig DB_PORT "${DB_PORT}"
#replace DB_USERNAME
replaceDbConfig DB_USERNAME "${DB_USERNAME}"
#replace DB_PASSWORD
replaceDbConfig DB_PASSWORD "${DB_PASSWORD}"
#replace DB_GAME_NAME
replaceDbConfig DB_GAME_NAME "${DB_GAME_NAME}"

#billing 配置文件
billConfPath="${billDir}/config.yaml"
if [ ! -f "${billConfPath}" ]; then
  # 复制配置文件
  cp /root/config/billing/config.yaml "${billConfPath}"
  replaceConfigFile DB_HOST "${DB_HOST}" "${billConfPath}"
  replaceConfigFile DB_PORT "${DB_PORT}" "${billConfPath}"
  replaceConfigFile DB_USERNAME "${DB_USERNAME}" "${billConfPath}"
  replaceConfigFile DB_PASSWORD "${DB_PASSWORD}" "${billConfPath}"
  replaceConfigFile DB_ACCOUNT_NAME "${DB_ACCOUNT_NAME}" "${billConfPath}"
fi

#检测MySQL服务器状态
checkMysql() {
  MYSQL_PWD="${DB_PASSWORD}" mysql -h "${DB_HOST}" -P "${DB_PORT}" -u "${DB_USERNAME}" --connect-timeout=6 -e "SELECT VERSION() AS mysql_version"
}
sleep 5
tryConnCount=0
connectSuccess=0
until [ $connectSuccess -eq 1 ]; do
  tryConnCount=$((tryConnCount + 1))
  echo "[${tryConnCount}] try connect mysql"
  if checkMysql; then
    #连接成功
    connectSuccess=1
  elif [ $tryConnCount -ge 20 ]; then
    #重试的次数>=20次,依然失败
    echo connect failed
    exit 1
  else
    #等一会儿再试
    sleep 5
  fi
done

#创建Server日志目录
serverLogDir="/home/tlbb/Server/logs"
if [ ! -d $serverLogDir ]; then
  mkdir $serverLogDir
fi

# 创建billing日志文件(如果不存在)
billingLogPath="${billDir}/billing.log"
if [ ! -f "${billingLogPath}" ]; then
  touch "${billingLogPath}"
  chown "$(stat -c '%u:%g' /home)" "${billingLogPath}"
fi

###### start Billing Server ######
cd ${billDir} || exit 1
echo "start Billing ......"
/root/billing_server/billing up --log-path "${billingLogPath}" -d

cd /home/tlbb/Server/ || exit 1
ulimit -n 65535

###### start ShareMemory ######
echo "start ShareMemory ......"
gLogPath="${serverLogDir}/ShareMemory.log"
if [ "$WITH_GAME_LOG" != "yes" ]; then
  gLogPath=/dev/null
fi
./shm clear >>${gLogPath}
rm -rf exit.cmd quitserver.cmd
./shm start >>${gLogPath}
sleep 10

###### start World ######
echo "start World ......"
gLogPath="${serverLogDir}/World.log"
if [ "$WITH_GAME_LOG" != "yes" ]; then
  gLogPath=/dev/null
fi
./World >>${gLogPath} &
sleep 10

###### start Login ######
echo "start Login ......"
gLogPath="${serverLogDir}/Login.log"
if [ "$WITH_GAME_LOG" != "yes" ]; then
  gLogPath=/dev/null
fi
./Login >>${gLogPath} &
sleep 10

###### start Server ######
echo "start Server ......"
gLogPath="${serverLogDir}/Server.log"
if [ "$WITH_GAME_LOG" != "yes" ]; then
  gLogPath=/dev/null
fi
./Server >>${gLogPath} &

sleep 3
#修改日志文件的所有者
chown -R "$(stat -c '%u:%g' /home)" "${serverLogDir}"

#检测进程状态,如果意外退出，则返回1
checkProcessStatus() {
  #已经收到终止信号了
  if [ $sigStop -ne 0 ]; then
    return 0
  fi
  processNames=$1
  pStatus=0
  for processName in $processNames; do
    #某个进程意外退出了
    if ! pgrep -f "./${processName}" >/dev/null; then
      echo "${colorRed}${processName} is not running${colorReset}"
      pStatus=1
    fi
  done
  return $pStatus
}

#等待所有进程结束
waitAllProcessExit() {
  for processName in $1; do
    #等待进程退出
    while pgrep -f "./${processName}" >/dev/null; do
      sleep 1
    done
  done
}

processNames="billing ShareMemory World Login Server"
while [ $exitCode -lt 0 ]; do
  if ! checkProcessStatus "$processNames"; then
    echo "${colorRed}unexpected process exit${colorReset}"
    # 等日志刷入文件
    sleep 2
    exitCode=1
    break
  fi
  if [ $sigStop -eq 0 ]; then
    #等待下一轮检测
    sleep 5
  else
    #已收到停止信号,等待进程全部结束
    waitAllProcessExit "$processNames"
    #进程已经全部终止
    echo "${colorGreen}all server stopped${colorReset}"
    exitCode=0
  fi
done

exit $exitCode
