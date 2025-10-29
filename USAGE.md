# Clash Linux 服务器使用说明

## 功能特性

- ✅ 支持从 URL 下载配置文件
- ✅ 支持手动指定本地配置文件
- ✅ 详细的中间输出信息
- ✅ 错误检查和状态反馈
- ✅ 自动生成代理控制脚本

## 使用方法

### 方法一：使用本地配置文件

```bash
# 使用相对路径
./start.sh ./test_clash.yaml

# 使用绝对路径
./start.sh /path/to/your/clash.yaml
```

### 方法二：从 URL 下载配置文件

1. 在 `env.sh` 中设置 URL：
```bash
URL="https://your-subscription-url/clash.yaml"
```

2. 运行脚本：
```bash
./start.sh
```

## 输出信息说明

脚本运行时会显示详细的进度信息：

- 📁 目录创建状态
- 🔧 文件权限设置
- 📥 配置文件下载/复制状态
- ⚙️ 配置文件处理进度
- 🎛️ Dashboard 配置
- 🔐 API 密钥设置
- 🚀 服务启动状态
- 📋 使用说明

## 代理控制

脚本会自动生成 `~/clash.sh` 文件，包含以下功能：

```bash
# 开启代理
on

# 关闭代理
off

# 查看代理状态
status
```

## 端口配置

- HTTP 代理端口: 7890
- SOCKS5 代理端口: 7891
- Dashboard 端口: 9090

## 文件位置

- 配置文件: `./conf/config.yaml`
- 日志文件: `./logs/clash.log`
- 代理脚本: `~/clash.sh`

## 错误处理

脚本包含完善的错误检查：

- 配置文件存在性检查
- 下载状态验证
- 服务启动状态确认
- 进程运行状态检查

如果遇到错误，请检查相应的日志文件获取详细信息。