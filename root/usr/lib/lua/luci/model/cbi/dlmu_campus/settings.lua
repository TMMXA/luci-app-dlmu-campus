local m, s, o

m = Map("dlmu_campus", translate("DLMU 校园网自动登录"),
	translate("用独立的 HTTP 响应指纹判断在线/认证页/检测异常；仅在连续确认认证页后重登，Portal 个人信息低频刷新且不参与在线判定。"))

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
o.default = "http://223.5.5.5"
o.rmempty = false
o.description = translate("建议使用不依赖 DNS 的稳定 HTTP 地址；当前地址在线时固定返回 404 text/plain，离线时会被校园认证页接管。")

o = s:option(Value, "online_http_status", translate("在线响应 HTTP 状态"))
o.datatype = "uinteger"
o.default = "404"
o.rmempty = false

o = s:option(Value, "online_content_type", translate("在线响应 Content-Type 前缀"))
o.default = "text/plain"
o.rmempty = false
o.description = translate("状态码与此前缀同时匹配才确认在线；不匹配但也未发现认证页时只显示检测异常，不会登录。")

o = s:option(Value, "captive_http_status", translate("离线响应 HTTP 状态"))
o.datatype = "uinteger"
o.default = "200"
o.rmempty = false

o = s:option(Value, "captive_content_type", translate("离线响应 Content-Type 前缀"))
o.default = "none"
o.rmempty = false
o.description = translate("填写 none 表示没有 Content-Type，* 表示任意类型。当前校园网手动下线后实测为 HTTP 200 且无 Content-Type。")

o = s:option(Value, "login_trigger_url", translate("登录触发 URL"))
o.default = "http://223.5.5.5"
o.rmempty = false
o.description = translate("仅在执行登录时访问，用于获取校园认证跳转；建议使用不依赖 DNS 的裸 IP。")

o = s:option(Value, "campus_dns", translate("校园网 DNS"))
o.default = "10.0.0.1"
o.rmempty = false
o.description = translate("登录触发使用裸 IP；进入认证流程后，直接用此 DNS 解析 Portal 和统一认证域名。")

o = s:option(Value, "portal_url", translate("Portal 状态页 URL"))
o.default = "http://portal.dlmu.edu.cn/"
o.rmempty = false

o = s:option(Value, "auth_base", translate("统一认证 URL"))
o.default = "https://id.dlmu.edu.cn"
o.rmempty = false

o = s:option(Value, "online_interval", translate("在线检测间隔"))
o.datatype = "uinteger"
o.default = "30"
o.description = translate("网络在线时，每隔多少秒进行一次轻量 HTTP 响应指纹检测。")

o = s:option(Value, "fast_interval", translate("离线快速检测间隔"))
o.datatype = "uinteger"
o.default = "3"
o.description = translate("检测到离线后，每隔多少秒快速复查。")

o = s:option(Value, "failure_threshold", translate("触发登录的连续认证页确认次数"))
o.datatype = "uinteger"
o.default = "3"
o.description = translate("仅计算明确进入校园认证页的次数；curl/DNS/响应指纹异常不会计入，也不会触发登录。")

o = s:option(Value, "max_login_retries", translate("冷却前登录重试次数"))
o.datatype = "uinteger"
o.default = "3"
o.description = translate("登录失败时连续重试该次数，全部失败后才进入冷却。")

o = s:option(Value, "login_cooldown", translate("登录失败冷却时间"))
o.datatype = "uinteger"
o.default = "120"
o.description = translate("达到登录重试上限后，至少等待多少秒再重试。")

o = s:option(Value, "portal_info_interval", translate("Portal 信息刷新间隔"))
o.datatype = "uinteger"
o.default = "900"
o.description = translate("单位为秒，仅在网络确认在线时读取姓名、余额和流量；失败不会改变在线状态。")

o = s:option(Value, "startup_delay", translate("开机启动延迟"))
o.datatype = "uinteger"
o.default = "10"

o = s:option(Value, "timeout", translate("HTTP 超时时间"))
o.datatype = "uinteger"
o.default = "5"

o = s:option(Flag, "verify_tls", translate("校验 TLS 证书"))
o.default = "1"
o.description = translate("认证密码提交到 HTTPS 统一认证主机；建议保持证书校验开启。")

function m.on_after_commit(self)
	luci.sys.call("chmod 600 /etc/config/dlmu_campus >/dev/null 2>&1")
	luci.sys.call("/etc/init.d/dlmu-campus-login enable >/dev/null 2>&1")
	luci.sys.call("/etc/init.d/dlmu-campus-login restart >/dev/null 2>&1 &")
end

return m
