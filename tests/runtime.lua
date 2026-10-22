-- Run on OpenWrt with the app's Lua dependencies: lua tests/runtime.lua
-- All UCI, filesystem, HTTP and daemon side effects below are mocked.
local path = arg[1] or "root/usr/bin/dlmu-campus-login"
local file = assert(io.open(path))
local source = file:read("*a")
file:close()
source = source:gsub("^#![^\n]*\n", "")
local tests = [=[
local function equal(actual, expected)
	assert(actual == expected, tostring(actual) .. " ~= " .. tostring(expected))
end

-- A fresh cursor per load observes changes without spawning UCI commands.
local values = { username = " test-user ", online_interval = "invalid" }
local cursors, closed = 0, 0
uci.cursor = function()
	cursors = cursors + 1
	return {
		get_all = function(_, config, section)
			equal(config, "dlmu_campus")
			equal(section, "main")
			return values
		end,
		close = function() closed = closed + 1 end,
	}
end
io.popen = function() error("unexpected subprocess while loading configuration") end
local cfg = load_config()
equal(cfg.username, "test-user")
equal(cfg.online_interval, 30)
equal(cfg.verify_tls, true)
values = { online_interval = "1", username = "changed" }
cfg = load_config()
equal(cfg.online_interval, 5)
equal(cfg.username, "changed")
equal(cursors, 2)
equal(closed, 2)

-- Cache positive checks, but retry commands that may be installed later.
local calls = 0
os.execute = function(command)
	calls = calls + 1
	return command:find("present", 1, true) and 0 or 1
end
assert(command_exists("audit-present"))
assert(command_exists("audit-present"))
equal(calls, 1)
assert(not command_exists("audit-missing"))
assert(not command_exists("audit-missing"))
equal(calls, 3)

-- Temporary auth files stay in the private directory; logs rotate at the limit.
local modes, renamed, unlinked = {}, {}, {}
fs.mkdirr = function(directory) equal(directory, STATUS_DIR) end
fs.chmod = function(name, mode) modes[name] = mode end
fs.stat = function(name) equal(name, LOG_FILE); return { size = MAX_LOG_BYTES } end
fs.rename = function(from, to) renamed[from] = to; return true end
fs.unlink = function(name) unlinked[name] = true; return true end
assert(tmp_path("plain"):sub(1, #STATUS_DIR + 1) == STATUS_DIR .. "/")
equal(modes[STATUS_DIR], "0700")
local written
io.open = function(name, mode)
	equal(name, LOG_FILE)
	equal(mode, "a")
	return { write = function(_, line) written = line end, close = function() end }
end
log("test rotation")
equal(renamed[LOG_FILE], LOG_FILE .. ".1")
assert(unlinked[LOG_FILE .. ".1"] and written:find("test rotation", 1, true))
equal(modes[LOG_FILE], "0600")

-- Reject credentials before encryption/POST when the auth target is unexpected.
http_request = function() error("unexpected HTTP request") end
aes_encrypt = function() error("unexpected credential encryption") end
cfg = load_config()
cfg.username, cfg.password = "dummy", "dummy"
for _, url in ipairs({ "http://id.dlmu.edu.cn/login", "https://example.com/login" }) do
	get_login_params = function() return url, "dummy-key", "dummy-execution" end
	local ok, err = pcall(do_login, {}, cfg)
	assert(not ok and tostring(err):find("非预期 HTTPS", 1, true), tostring(err))
end

-- Drive the actual daemon branches with deterministic probes and a fake clock.
cfg.startup_delay = 0
cfg.online_interval = 30
load_config = function() return cfg end
log = function() end
refresh_portal_info = function() return true end
local function scenario(states, expected_delays, expected_logins)
	local index, clock, logins = 0, 100000, 0
	local status, delays = {}, {}
	now = function() return clock end
	read_status = function() return status end
	save_status = function(updates)
		for key, value in pairs(updates) do status[key] = value end
	end
	probe_connectivity = function()
		index = index + 1
		assert(states[index], "unexpected extra probe")
		return { state = states[index], status = 404, exit_code = 0,
			content_type = "text/plain", final_host = "223.5.5.5", error = "" }
	end
	do_login = function() logins = logins + 1 end
	nixio.nanosleep = function(seconds)
		delays[#delays + 1] = seconds
		clock = clock + seconds
		if #delays == #expected_delays then error("TEST_STOP") end
	end
	local ok, err = pcall(daemon)
	assert(not ok and tostring(err):find("TEST_STOP", 1, true), tostring(err))
	equal(#delays, #expected_delays)
	for i, value in ipairs(expected_delays) do equal(delays[i], value) end
	equal(logins, expected_logins)
end
scenario({ "unknown", "unknown", "unknown", "unknown", "unknown", "unknown" },
	{ 3, 6, 12, 24, 30, 30 }, 0)
scenario({ "online" }, { 30 }, 0)
scenario({ "captive", "captive", "captive", "online" }, { 3, 3, 3, 30 }, 1)
print("runtime tests passed")
]=]
local count
source, count = source:gsub("os%.exit%(main%(arg%)%)%s*$", function() return tests end)
assert(count == 1, "could not replace CLI entry point")
assert(loadstring(source, "@" .. path))()
