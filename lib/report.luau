local ansi = require("./ansi")

export type Report = {
	kind: "syntax",
	message: string,
} | {
	kind: "compile",
	message: string,
} | {
	kind: "runtime",
	message: string,
}

local function display(report: Report): string
	if report.kind == "syntax" then
		return ansi.fmt("syntax error", ansi.FG_BRIGHT_RED) .. ": " .. report.message
	elseif report.kind == "compile" then
		return ansi.fmt("compile error", ansi.FG_BRIGHT_RED) .. ": " .. report.message
	elseif report.kind == "runtime" then
		return ansi.fmt("runtime error", ansi.FG_BRIGHT_RED) .. ": " .. report.message
	else
		error("unreachable")
	end
end

local function syntax(message: string): never
	error({ kind = "syntax", message = message })
end

local function runtime(message: string): never
	error({ kind = "runtime", message = message })
end

local function catch<U, T...>(f: (T...) -> U, ...: T...): { ok: true, value: U } | { ok: false, report: Report }
	local ok, ret = pcall(f, ...)
	if ok then
		return { ok = true, value = ret }
	else
		return { ok = false, report = ret :: any }
	end
end

return {
	display = display,

	syntax = syntax,
	runtime = runtime,

	catch = catch,
}
