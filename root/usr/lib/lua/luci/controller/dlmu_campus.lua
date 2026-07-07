module("luci.controller.dlmu_campus", package.seeall)

local fs = require "nixio.fs"

function index()
	if not fs.access("/etc/config/dlmu_campus") then
		return
	end

	entry({"admin", "services", "dlmu-campus"}, firstchild(), _("DLMU 校园网"), 65).dependent = false
	entry({"admin", "services", "dlmu-campus", "status"}, template("dlmu_campus/status"), _("状态"), 10).leaf = true
	entry({"admin", "services", "dlmu-campus", "settings"}, cbi("dlmu_campus/settings"), _("配置"), 20).leaf = true
	entry({"admin", "services", "dlmu-campus", "start"}, call("action_start")).leaf = true
	entry({"admin", "services", "dlmu-campus", "stop"}, call("action_stop")).leaf = true
	entry({"admin", "services", "dlmu-campus", "restart"}, call("action_restart")).leaf = true
	entry({"admin", "services", "dlmu-campus", "login"}, call("action_login")).leaf = true
	entry({"admin", "services", "dlmu-campus", "portal_logout"}, call("action_portal_logout")).leaf = true
end

local function redirect_status()
	luci.http.redirect(luci.dispatcher.build_url("admin", "services", "dlmu-campus", "status"))
end

function action_start()
	luci.sys.call("uci set dlmu_campus.main.enabled='1'; uci commit dlmu_campus; /etc/init.d/dlmu-campus-login enable; /etc/init.d/dlmu-campus-login restart >/dev/null 2>&1 &")
	redirect_status()
end

function action_stop()
	luci.sys.call("uci set dlmu_campus.main.enabled='0'; uci commit dlmu_campus; /etc/init.d/dlmu-campus-login stop >/dev/null 2>&1")
	redirect_status()
end

function action_restart()
	luci.sys.call("/etc/init.d/dlmu-campus-login restart >/dev/null 2>&1 &")
	redirect_status()
end

function action_login()
	luci.sys.call("/etc/init.d/dlmu-campus-login login >/dev/null 2>&1")
	redirect_status()
end

function action_portal_logout()
	luci.sys.call("/etc/init.d/dlmu-campus-login stop >/dev/null 2>&1; uci set dlmu_campus.main.enabled='0'; uci commit dlmu_campus; /etc/init.d/dlmu-campus-login portal_logout >/dev/null 2>&1")
	redirect_status()
end
