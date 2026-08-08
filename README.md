# luci-app-dlmu-campus

大连海事大学校园网自动登录 LuCI 小面板，适合放在 OpenWrt/ImmortalWrt 旁路由上做保活、断线重登和 Portal 在线信息看板。

## 功能

- LuCI 中文配置页和状态页
- 独立 HTTP 响应指纹检测，区分在线、认证页和检测异常
- 仅在连续确认进入认证页后自动登录，普通超时或 DNS 故障不会误触发
- 登录失败重试，达到次数后冷却
- Portal 个人信息低频独立刷新，不参与在线判定
- 显示姓名、学号、IP、MAC、余额、套餐、已用流量、在线时长和探测详情
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

Lua 版依赖包：

```sh
apk add lua curl openssl-util luci-compat
```

旧版 OpenWrt 如果使用 `opkg`：

```sh
opkg update
opkg install lua curl openssl-util luci-compat
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
/etc/init.d/dlmu-campus-login probe
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

默认使用 `http://223.5.5.5` 做不依赖 DNS 的轻量检测，在线响应指纹为 `HTTP 404` 和 `Content-Type: text/plain`，离线响应指纹为 `HTTP 200` 且无 Content-Type。在线时每 10 秒检测一次，发现认证页或离线指纹后每 3 秒复查，连续 3 次确认后登录；姓名、余额和流量等 Portal 信息每 300 秒刷新一次。若检测目标的响应发生变化，可在 LuCI 中调整状态码和 Content-Type 前缀。

自动登录使用单独的 `login_trigger_url` 获取校园认证跳转，默认同样访问裸 IP `http://223.5.5.5`，不依赖 DNS。进入认证流程后，Portal 和统一认证域名通过 `campus_dns` 直接解析，避免离线时公共 DNS 或 Fake-IP 阻断登录。命令行 `login` 在检测状态不明确时仍会按用户意图强制尝试登录；守护进程则继续坚持只对明确离线指纹自动登录。

如果旁路由使用 OpenClash 的 Fake-IP DNS，建议把校园域名固定交给校园网 DNS，并排除 Fake-IP，否则离线时可能无法解析认证地址：

```yaml
dns:
  nameserver-policy:
    "+.dlmu.edu.cn": 10.0.0.1
  fake-ip-filter:
    - "+.dlmu.edu.cn"
```

## 说明

本项目基于 DLMU 统一认证当前的 AES-128 ECB + PKCS7 登录流程实现。后台守护脚本使用 Lua 编写，HTTP 请求调用 `curl`，AES 加密调用 `openssl`，避免引入完整 Python 运行环境。校园网 Portal 页面或认证流程变化时，可能需要同步调整解析逻辑。

仅供学习交流和个人网络维护使用，请遵守校园网使用规定。
