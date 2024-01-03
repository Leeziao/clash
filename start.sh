# Setup Clash on Linux Server
# Reference: https://blog.iswiftai.com/posts/clash-linux/#dashboard-%E5%A4%96%E9%83%A8%E6%8E%A7%E5%88%B6

export Server_Dir=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)

Conf_Dir="$Server_Dir/conf"
Temp_Dir="$Server_Dir/temp"
Log_Dir="$Server_Dir/logs"

mkdir -p $Conf_Dir
mkdir -p $Temp_Dir
mkdir -p $Log_Dir

# 加载.env变量文件
source $Server_Dir/env.sh
chmod +x $Server_Dir/clash
chmod +x $Server_Dir/scripts/*
chmod +x $Server_Dir/tools/subconverter/subconverter

curl -L -k -sS --retry 5 -m 10 -o $Temp_Dir/clash.yaml $URL

cp -a $Temp_Dir/clash.yaml $Temp_Dir/clash_config.yaml

# 取出代理相关配置 
sed -n '/^proxies:/,$p' $Temp_Dir/clash_config.yaml > $Temp_Dir/proxy.txt
# 合并形成新的config.yaml
cat ${Server_Dir}/template_config.yaml > $Temp_Dir/config.yaml
cat $Temp_Dir/proxy.txt >> $Temp_Dir/config.yaml
cp $Temp_Dir/config.yaml $Conf_Dir/

# set dashboard
Work_Dir=$(cd $(dirname $0); pwd)
Dashboard_Dir="${Work_Dir}/dashboard/public"
sed -ri "s@^# external-ui:.*@external-ui: ${Dashboard_Dir}@g" $Conf_Dir/config.yaml

# if secret is set...
if [ -n "$Secret" ]; then
	sed -ri "s@^# secret:.*@secret: ${Secret}@g" $Conf_Dir/config.yaml
	echo "Secret: ${Secret}"
fi


nohup $Server_Dir/clash -d $Conf_Dir &> $Log_Dir/clash.log &
ReturnStatus=$?
if [ $ReturnStatus -ne 0 ]; then
	echo "Clash Start Failed!"
	exit 1
fi

echo -e "Clash Start Success!"
echo -e "Clash Dashboard: http://<ip>:9090/ui"

# Generate proxy_on and proxy_off
cat>~/clash.sh<<EOF
# 开启系统代理
function on() {
	export http_proxy=http://127.0.0.1:7890
	export https_proxy=http://127.0.0.1:7890
	export all_proxy=socks5://127.0.0.1:7890
	echo -e "\033[32m[√] 已开启代理\033[0m"
}

# 关闭系统代理
function off(){
	unset http_proxy
	unset https_proxy
	unset all_proxy
	echo -e "\033[31m[×] 已关闭代理\033[0m"
}
EOF

# check "source ~/clash.sh" in ~/.zshrc or ~/.bashrc
if [ -f ~/.zshrc ] && [ -z "$(grep "source ~/clash.sh" ~/.zshrc)" ]; then echo "source ~/clash.sh" >> ~/.zshrc; fi
if [ -f ~/.bashrc ] && [ -z "$(grep "source ~/clash.sh" ~/.bashrc)" ]; then echo "source ~/clash.sh" >> ~/.bashrc; fi