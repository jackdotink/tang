local token = require("./token")
local state = require("./state")

type State = state.State

local function char(c: string): number
	return string.byte(c)
end

local function first(state: State): number
	if state.pos == buffer.len(state.buf) then
		return 0
	else
		return buffer.readu8(state.buf, state.pos)
	end
end

local function bump(state: State)
	if state.pos ~= buffer.len(state.buf) then
		state.pos = state.pos + 1
	end
end

local function is_space(c: number): boolean
	return c == char(" ") or c == char("\t") or c == char("\n") or c == char("\r")
end

local function is_numeric(c: number): boolean
	return char("0") <= c and c <= char("9")
end

local function is_alpha(c: number): boolean
	return (c >= char("a") and c <= char("z")) or (c >= char("A") and c <= char("Z"))
end

local function is_alphanumeric(c: number): boolean
	return is_alpha(c) or is_numeric(c)
end

local function next(state: State): token.Token
	if state.peek ~= nil then
		local token = state.peek
		state.peek = nil

		return token
	end

	local c = first(state)

	while is_space(c) do
		bump(state)
		c = first(state)
	end

	if c == 0 then
		bump(state)
		return { kind = "eof" :: "eof" }
	elseif is_alpha(c) or c == char("_") then
		local start = state.pos

		while is_alphanumeric(first(state)) or first(state) == char("_") do
			bump(state)
		end

		local ident = buffer.readstring(state.buf, start, state.pos - start)

		if ident == "let" then
			return { kind = "let" :: "let" }
		elseif ident == "in" then
			return { kind = "in" :: "in" }
		else
			return { kind = "ident" :: "ident", value = ident }
		end
	elseif is_numeric(c) then
		local value = 0

		while is_numeric(first(state)) do
			value = value * 10 + first(state) - char("0")
			bump(state)
		end

		return { kind = "number" :: "number", value = value }
	elseif c == char('"') or c == char("'") then
		bump(state)

		local value = ""
		local quote = c

		local backslash = false
		while first(state) ~= quote or backslash do
			if backslash then
				backslash = false

				if first(state) == char("n") then
					value = value .. "\n"
				elseif first(state) == char("r") then
					value = value .. "\r"
				elseif first(state) == char("t") then
					value = value .. "\t"
				elseif first(state) == char("\\") then
					value = value .. "\\"
				elseif first(state) == char('"') then
					value = value .. '"'
				elseif first(state) == char("'") then
					value = value .. "'"
				else
					error(`unknown escape sequence \\{string.char(first(state))}`)
				end
			elseif first(state) == char("\\") then
				backslash = true
			else
				value = value .. string.char(first(state))
			end
		end

		bump(state)

		return { kind = "string" :: "string", value = value }
	elseif c == char(".") then
		bump(state)
		return { kind = "." :: "." }
	elseif c == char("+") then
		bump(state)
		return { kind = "+" :: "+" }
	elseif c == char("-") then
		bump(state)
		return { kind = "-" :: "-" }
	elseif c == char("*") then
		bump(state)
		return { kind = "*" :: "*" }
	elseif c == char("/") then
		bump(state)
		return { kind = "/" :: "/" }
	elseif c == char("%") then
		bump(state)
		return { kind = "%" :: "%" }
	elseif c == char("^") then
		bump(state)
		return { kind = "^" :: "^" }
	elseif c == char("=") then
		bump(state)
		return { kind = "=" :: "=" }
	elseif c == char("|") then
		bump(state)
		return { kind = "|" :: "|" }
	elseif c == char("(") then
		bump(state)
		return { kind = "(" :: "(" }
	elseif c == char(")") then
		bump(state)
		return { kind = ")" :: ")" }
	elseif c == char(",") then
		bump(state)
		return { kind = "," :: "," }
	else
		error(`unknown character {string.char(c)}`)
	end
end

local function peek(state: State): token.Token
	if state.peek == nil then
		state.peek = next(state)
	end

	return state.peek :: any
end

return {
	next = next,
	peek = peek,
}
