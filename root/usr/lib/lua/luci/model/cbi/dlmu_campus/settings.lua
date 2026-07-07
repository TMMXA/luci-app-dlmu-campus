local m, s, o

m = Map("dlmu_campus", translate("DLMU 校园网自动登录"),
	translate("在旁路由上运行校园网保活守护进程，掉线后自动重登，并在状态页展示 portal 在线信息。"))

s = m:section(NamedSection, "main", "service", translate("基础设置"))
s.addremove = false
s.anonymous = true

o = s:option(Flag, "enabled", translate("启用服务"))
o.rmempty = false

o = s:option(Value, "username", translate("学号/用户名"))
o.placeholder = "student id"
o.rmempty = true

o = s:option(Value, "password", translate("密码"))
o.password = true
o.rmempty = true

o = s:option(Value, "test_url", translate("连通性检测 URL"))
o.default = "http://www.baidu.com"
o.rmempty = false

o = s:option(Value, "portal_url", translate("Portal 状态页 URL"))
o.default = "http://portal.dlmu.edu.cn/"
o.rmempty = false

o = s:option(Value, "auth_base", translate("统一认证 URL"))
o.default = "https://id.dlmu.edu.cn"
o.rmempty = false

o = s:option(Value, "online_interval", translate("在线检测间隔"))
o.datatype = "uinteger"
o.default = "10"
o.description = translate("网络在线时，每隔多少秒检测一次。")

o = s:option(Value, "fast_interval", translate("离线快速检测间隔"))
o.datatype = "uinteger"
o.default = "3"
o.description = translate("检测到离线后，每隔多少秒快速复查。")

o = s:option(Value, "failure_threshold", translate("触发登录的连续失败次数"))
o.datatype = "uinteger"
o.default = "2"
o.description = translate("连通性检测连续失败达到该次数后，开始登录。")

o = s:option(Value, "max_login_retries", translate("冷却前登录重试次数"))
o.datatype = "uinteger"
o.default = "3"
o.description = translate("登录失败时连续重试该次数，全部失败后才进入冷却。")

o = s:option(Value, "login_cooldown", translate("登录失败冷却时间"))
o.datatype = "uinteger"
o.default = "60"
o.description = translate("Minimum seconds between login attempts.")

o = s:option(Value, "portal_info_interval", translate("Portal 信息刷新间隔"))
o.datatype = "uinteger"
o.default = "60"

o = s:option(Value, "startup_delay", translate("开机启动延迟"))
o.datatype = "uinteger"
o.default = "10"

o = s:option(Value, "timeout", translate("HTTP 超时时间"))
o.datatype = "uinteger"
o.default = "5"

o = s:option(Flag, "verify_tls", translate("校验 TLS 证书"))
o.default = "0"
o.description = translate("校园网劫持门户通常建议关闭，以提高兼容性。")

function m.on_after_commit(self)
	luci.sys.call("chmod 600 /etc/config/dlmu_campus >/dev/null 2>&1")
	luci.sys.call("/etc/init.d/dlmu-campus-login enable >/dev/null 2>&1")
	luci.sys.call("/etc/init.d/dlmu-campus-login restart >/dev/null 2>&1 &")
end

return m
