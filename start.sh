# Setup Clash on Linux Server
# Reference: https://blog.iswiftai.com/posts/clash-linux/#dashboard-%E5%A4%96%E9%83%A8%E6%8E%A7%E5%88%B6

export Server_Dir=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)

Conf_Dir="$Server_Dir/conf"
Temp_Dir="$Server_Dir/temp"
Log_Dir="$Server_Dir/logs"

echo "=== Clash Linux 服务器配置脚本 ==="
echo "服务器目录: $Server_Dir"
echo "配置目录: $Conf_Dir"
echo "临时目录: $Temp_Dir"
echo "日志目录: $Log_Dir"

echo "正在创建必要的目录..."
mkdir -p $Conf_Dir
mkdir -p $Temp_Dir
mkdir -p $Log_Dir
echo "✓ 目录创建完成"

# 加载.env变量文件
echo "正在加载环境变量..."
source $Server_Dir/env.sh
echo "✓ 环境变量加载完成"

echo "正在设置文件权限..."
chmod +x $Server_Dir/clash
chmod +x $Server_Dir/scripts/*
chmod +x $Server_Dir/tools/subconverter/subconverter
echo "✓ 文件权限设置完成"

# 支持手动指定 clash.yaml 文件
# 使用方法: ./start.sh [clash_config_file]
# 如果提供了参数，使用本地文件；否则从 URL 下载
if [ -n "$1" ]; then
    CLASH_CONFIG_FILE="$1"
    echo "使用手动指定的配置文件: $CLASH_CONFIG_FILE"
    
    # 检查文件是否存在
    if [ ! -f "$CLASH_CONFIG_FILE" ]; then
        echo "❌ 错误: 指定的配置文件不存在: $CLASH_CONFIG_FILE"
        exit 1
    fi
    
    echo "正在复制本地配置文件..."
    cp "$CLASH_CONFIG_FILE" $Temp_Dir/clash.yaml
    if [ $? -eq 0 ]; then
        echo "✓ 本地配置文件复制成功"
    else
        echo "❌ 错误: 复制本地配置文件失败"
        exit 1
    fi
else
    # 从 URL 下载配置文件
    if [ -z "$URL" ]; then
        echo "❌ 错误: 未指定配置文件路径，且环境变量 URL 为空"
        echo "使用方法:"
        echo "  1. 手动指定配置文件: ./start.sh /path/to/clash.yaml"
        echo "  2. 在 env.sh 中设置 URL 变量"
        exit 1
    fi
    
    echo "正在从 URL 下载配置文件: $URL"
    curl -L -k -sS --retry 5 -m 10 -o $Temp_Dir/clash.yaml $URL
    
    if [ $? -eq 0 ] && [ -f $Temp_Dir/clash.yaml ]; then
        echo "✓ 配置文件下载成功"
    else
        echo "❌ 错误: 配置文件下载失败"
        exit 1
    fi
fi

echo "正在备份原始配置文件..."
cp -a $Temp_Dir/clash.yaml $Temp_Dir/clash_config.yaml
echo "✓ 原始配置文件备份完成"

echo "正在处理配置文件..."
# 取出代理相关配置
echo "  - 提取代理配置..."
sed -n '/^proxies:/,$p' $Temp_Dir/clash_config.yaml > $Temp_Dir/proxy.txt

# 检查是否成功提取到代理配置
if [ ! -s $Temp_Dir/proxy.txt ]; then
    echo "❌ 警告: 未找到代理配置 (proxies 部分)"
    echo "请检查配置文件格式是否正确"
	exit 0
fi

# 合并形成新的config.yaml
echo "  - 合并模板配置和代理配置..."
cat ${Server_Dir}/template_config.yaml > $Temp_Dir/config.yaml
cat $Temp_Dir/proxy.txt >> $Temp_Dir/config.yaml
cp $Temp_Dir/config.yaml $Conf_Dir/
echo "✓ 配置文件处理完成"

# set dashboard
echo "正在配置 Dashboard..."
Work_Dir=$(cd $(dirname $0); pwd)
Dashboard_Dir="${Work_Dir}/dashboard/public"
sed -ri "s@^# external-ui:.*@external-ui: ${Dashboard_Dir}@g" $Conf_Dir/config.yaml
echo "✓ Dashboard 路径设置完成: $Dashboard_Dir"

# if secret is set...
if [ -n "$Secret" ]; then
	echo "正在设置 API 密钥..."
	sed -ri "s@^# secret:.*@secret: ${Secret}@g" $Conf_Dir/config.yaml
	echo "✓ API 密钥设置完成: ${Secret}"
else
	echo "ℹ️  未设置 API 密钥 (可在 env.sh 中配置 Secret 变量)"
fi

echo "正在启动 Clash 服务..."
nohup $Server_Dir/clash -d $Conf_Dir &> $Log_Dir/clash.log &
ReturnStatus=$?
if [ $ReturnStatus -ne 0 ]; then
	echo "❌ Clash 启动失败!"
	echo "请检查日志文件: $Log_Dir/clash.log"
	exit 1
fi

# 等待一下让服务启动
sleep 2

# 检查进程是否真的在运行
if pgrep -f "$Server_Dir/clash" > /dev/null; then
    echo "✅ Clash 启动成功!"
    echo "📊 Clash Dashboard: http://<ip>:9090/ui"
    echo "📝 日志文件: $Log_Dir/clash.log"
    echo "⚙️  配置文件: $Conf_Dir/config.yaml"
else
    echo "❌ Clash 进程未正常启动，请检查日志文件"
    exit 1
fi

echo ""
echo "正在生成代理控制脚本..."
# Generate proxy_on and proxy_off
cat>~/clash.sh<<EOF
# 开启系统代理
function on() {
	export http_proxy=http://127.0.0.1:7890
	export https_proxy=http://127.0.0.1:7890
	export all_proxy=socks5://127.0.0.1:7890
	echo -e "\033[32m[√] 已开启代理\033[0m"
	echo -e "\033[36m   HTTP/HTTPS: http://127.0.0.1:7890\033[0m"
	echo -e "\033[36m   SOCKS5: socks5://127.0.0.1:7890\033[0m"
}

# 关闭系统代理
function off(){
	unset http_proxy
	unset https_proxy
	unset all_proxy
	echo -e "\033[31m[×] 已关闭代理\033[0m"
}

# 显示代理状态
function status(){
	if [ -n "\$http_proxy" ]; then
		echo -e "\033[32m[√] 代理已开启\033[0m"
		echo -e "\033[36m   HTTP: \$http_proxy\033[0m"
		echo -e "\033[36m   HTTPS: \$https_proxy\033[0m"
		echo -e "\033[36m   ALL: \$all_proxy\033[0m"
	else
		echo -e "\033[31m[×] 代理已关闭\033[0m"
	fi
}
EOF
echo "✓ 代理控制脚本生成完成: ~/clash.sh"

echo "正在配置 Shell 环境..."
# check "source ~/clash.sh" in ~/.zshrc or ~/.bashrc
shell_updated=false
if [ -f ~/.zshrc ] && [ -z "$(grep "source ~/clash.sh" ~/.zshrc)" ]; then
    echo "source ~/clash.sh" >> ~/.zshrc
    echo "✓ 已添加到 ~/.zshrc"
    shell_updated=true
fi
if [ -f ~/.bashrc ] && [ -z "$(grep "source ~/clash.sh" ~/.bashrc)" ]; then
    echo "source ~/clash.sh" >> ~/.bashrc
    echo "✓ 已添加到 ~/.bashrc"
    shell_updated=true
fi

if [ "$shell_updated" = false ]; then
    echo "ℹ️  Shell 配置文件已包含代理脚本引用"
fi

echo ""
echo "🎉 Clash 配置完成!"
echo ""
echo "📋 使用说明:"
echo "   重新加载 Shell 配置: source ~/.zshrc 或 source ~/.bashrc"
echo "   开启代理: on"
echo "   关闭代理: off"
echo "   查看代理状态: status"
echo ""
echo "🔗 相关信息:"
echo "   HTTP 代理端口: 7890"
echo "   SOCKS5 代理端口: 7891"
echo "   Dashboard: http://<ip>:9090/ui"
echo "   配置文件: $Conf_Dir/config.yaml"
echo "   日志文件: $Log_Dir/clash.log"