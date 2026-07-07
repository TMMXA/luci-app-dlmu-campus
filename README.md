# luci-app-dlmu-campus

大连海事大学校园网自动登录 LuCI 小面板，适合放在 OpenWrt/ImmortalWrt 旁路由上做保活、断线重登和 Portal 在线信息看板。

## 功能

- LuCI 中文配置页和状态页
- 校园网 Portal 在线检测
- 断线后自动登录
- 登录失败重试，达到次数后冷却
- 显示姓名、学号、IP、MAC、余额、套餐、已用流量、在线时长
- 支持手动启动、停止、重启、立即登录、Portal 下线
- 服务配置存储在 `/etc/config/dlmu_campus`

## 安装

把仓库传到路由器后运行：

```sh
chmod +x install.sh
./install.sh
```

也可以手动复制：

```sh
cp -a root/. /
chmod 755 /usr/bin/dlmu-campus-login
chmod 755 /etc/init.d/dlmu-campus-login
chmod 600 /etc/config/dlmu_campus
/etc/init.d/dlmu-campus-login enable
/etc/init.d/uhttpd restart
```

依赖包：

```sh
apk add python3 python3-requests python3-cryptodome luci-compat
```

旧版 OpenWrt 如果使用 `opkg`：

```sh
opkg update
opkg install python3 python3-requests python3-cryptodome luci-compat
```

## 使用

安装完成后打开 LuCI：

```text
服务 -> DLMU 校园网
```

进入配置页填写学号和密码，启用服务并保存。状态页会显示守护进程、校园网在线状态、Portal 信息和最近日志。

## 命令行

```sh
/etc/init.d/dlmu-campus-login start
/etc/init.d/dlmu-campus-login stop
/etc/init.d/dlmu-campus-login restart
/etc/init.d/dlmu-campus-login login
/etc/init.d/dlmu-campus-login portal_logout
/etc/init.d/dlmu-campus-login status
```

## 配置文件

默认配置位于：

```text
/etc/config/dlmu_campus
```

其中 `username` 和 `password` 默认为空。仓库不会包含个人账号、密码或运行状态缓存。

## 说明

本项目基于 DLMU 统一认证当前的 AES-128 ECB + PKCS7 登录流程实现。校园网 Portal 页面或认证流程变化时，可能需要同步调整解析逻辑。

仅供学习交流和个人网络维护使用，请遵守校园网使用规定。
