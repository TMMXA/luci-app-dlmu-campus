#!/bin/sh
set -eu

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLI_ONLY=0
case "$*" in
	"") ;;
	--cli-only) CLI_ONLY=1 ;;
	*) echo "Usage: sh install.sh [--cli-only]"; exit 2 ;;
esac

if ! command -v opkg >/dev/null 2>&1 && ! command -v apk >/dev/null 2>&1; then
	echo "未检测到 opkg 或 apk，请在 OpenWrt/ImmortalWrt 上运行。"
	exit 1
fi

if command -v apk >/dev/null 2>&1; then
	apk update
	apk add lua curl openssl-util libuci-lua luci-lib-nixio luci-lib-jsonc
	if [ "$CLI_ONLY" = 0 ]; then
		apk add luci-compat
	fi
else
	opkg update
	opkg install lua curl openssl-util libuci-lua luci-lib-nixio luci-lib-jsonc
	if [ "$CLI_ONLY" = 0 ]; then
		opkg install luci-compat
	fi
fi

mkdir -p /etc/config /etc/init.d /usr/bin
if [ ! -f /etc/config/dlmu_campus ]; then
	cp "$ROOT_DIR/root/etc/config/dlmu_campus" /etc/config/dlmu_campus
fi
cp "$ROOT_DIR/root/etc/init.d/dlmu-campus-login" /etc/init.d/dlmu-campus-login
if [ "$CLI_ONLY" = 1 ]; then
	cp "$ROOT_DIR/root/usr/bin/dlmu-campus-login" /usr/bin/dlmu-campus-login
else
	cp -a "$ROOT_DIR/root/usr/." /usr/
fi
chmod 755 /usr/bin/dlmu-campus-login
chmod 755 /etc/init.d/dlmu-campus-login
chmod 600 /etc/config/dlmu_campus

/etc/init.d/dlmu-campus-login enable
if [ "$CLI_ONLY" = 0 ]; then
	/etc/init.d/uhttpd restart >/dev/null 2>&1 || true
fi

if [ "$CLI_ONLY" = 1 ]; then
	echo "命令行版安装完成。请编辑 /etc/config/dlmu_campus，填写校园网账号密码后启用服务。"
else
	echo "安装完成。请到 LuCI：服务 -> DLMU 校园网，填写学号和密码后启用。"
fi
