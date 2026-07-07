#!/bin/sh
set -eu

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

if ! command -v opkg >/dev/null 2>&1 && ! command -v apk >/dev/null 2>&1; then
	echo "未检测到 opkg 或 apk，请在 OpenWrt/ImmortalWrt 上运行。"
	exit 1
fi

if command -v apk >/dev/null 2>&1; then
	apk update || true
	apk add python3 python3-requests python3-cryptodome luci-compat || true
else
	opkg update || true
	opkg install python3 python3-requests python3-cryptodome luci-compat || true
fi

cp -a "$ROOT_DIR/root/." /
chmod 755 /usr/bin/dlmu-campus-login
chmod 755 /etc/init.d/dlmu-campus-login
chmod 600 /etc/config/dlmu_campus

/etc/init.d/dlmu-campus-login enable
/etc/init.d/uhttpd restart >/dev/null 2>&1 || true

echo "安装完成。请到 LuCI：服务 -> DLMU 校园网，填写学号和密码后启用。"
