export type Writer = {
	__code_marker: true,

	pos: number,
	buf: buffer,
}

local function alloc(writer: Writer): number
	local pos = writer.pos
	local size = buffer.len(writer.buf)

	if pos + 3 > size then
		local new_size = size + size / 2
		while new_size < pos + 3 do
			new_size += new_size / 2
		end

		local new = buffer.create(new_size)
		buffer.copy(new, 0, writer.buf, 0, pos)
		writer.buf = new
	end

	writer.pos += 3
	return pos
end

--- Push a constant to the stack from the given index in the data section.
local function emit_pushk(writer: Writer, index: number)
	local pos = alloc(writer)
	buffer.writeu8(writer.buf, pos, 1)
	buffer.writeu16(writer.buf, pos + 1, index)
end

--- Push a boolean onto the stack.
local function emit_pushb(writer: Writer, value: boolean)
	local pos = alloc(writer)
	buffer.writeu8(writer.buf, pos, 2)
	buffer.writeu8(writer.buf, pos + 1, if value then 1 else 0)
end

--- Push a global to the stack from the given index in the global section.
local function emit_pushg(writer: Writer, index: number)
	local pos = alloc(writer)
	buffer.writeu8(writer.buf, pos, 3)
	buffer.writeu16(writer.buf, pos + 1, index)
end

--- Push a function to the stack from the given index in the function section.
local function emit_pushf(writer: Writer, index: number)
	local pos = alloc(writer)
	buffer.writeu8(writer.buf, pos, 4)
	buffer.writeu16(writer.buf, pos + 1, index)
end

--- Push a local to the stack from the given index in the local frame.
local function emit_pushl(writer: Writer, index: number)
	local pos = alloc(writer)
	buffer.writeu8(writer.buf, pos, 4)
	buffer.writeu16(writer.buf, pos + 1, index)
end

--- Pop the top value from the stack and store it in the given local index.
local function emit_storl(writer: Writer, index: number)
	local pos = alloc(writer)
	buffer.writeu8(writer.buf, pos, 5)
	buffer.writeu16(writer.buf, pos + 1, index)
end

--- Pop the top two values from the stack, apply the first to the second, and
--- push the result back to the stack.
local function emit_apply(writer: Writer)
	local pos = alloc(writer)
	buffer.writeu8(writer.buf, pos, 6)
end

return {
	emit_pushk = emit_pushk,
	emit_pushb = emit_pushb,
	emit_pushg = emit_pushg,
	emit_pushf = emit_pushf,
	emit_pushl = emit_pushl,
	emit_storl = emit_storl,
	emit_apply = emit_apply,
}
