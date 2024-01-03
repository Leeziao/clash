#!/bin/bash

# 关闭clash服务
PID_NUM=`ps -ef | grep [c]lash | wc -l`
PID=`ps -ef | grep [c]lash | awk '{print $2}'`
if [ $PID_NUM -ne 0 ]; then
	kill -9 $PID
fi

echo -e "\nShutdown Clash!\n"
 