# Clash For Linux Server

一个功能增强的 Clash Linux 服务器配置脚本，支持多种配置方式和详细的运行状态输出。

## 新增功能

- ✅ **详细的中间输出**: 显示每个步骤的执行状态和结果
- ✅ **手动指定配置文件**: 支持使用本地 clash.yaml 文件
- ✅ **智能错误检查**: 完善的错误处理和状态验证
- ✅ **增强的代理控制**: 新增代理状态查看功能

## 快速开始

### 使用本地配置文件
```bash
./start.sh /path/to/your/clash.yaml
```

### 使用 URL 下载配置
```bash
# 1. 在 env.sh 中设置 URL
# 2. 运行脚本
./start.sh
```

## 详细使用说明

请查看 [USAGE.md](USAGE.md) 获取完整的使用指南。

## 项目结构

```
clash/
├── start.sh              # 主启动脚本（已增强）
├── env.sh                # 环境变量配置
├── template_config.yaml  # 配置模板
├── USAGE.md              # 详细使用说明
├── conf/                 # 配置文件目录
├── logs/                 # 日志文件目录
├── dashboard/            # Web 控制面板
└── tools/                # 工具目录
```

## 参考链接

- 原始参考: https://blog.iswiftai.com/posts/clash-linux/#dashboard-%E5%A4%96%E9%83%A8%E6%8E%A7%E5%88%B6