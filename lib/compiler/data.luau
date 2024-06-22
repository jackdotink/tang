export type Writer = {
	__data_marker: true,

	pos: number,
	buf: buffer,
}

local function alloc(writer: Writer, bytes: number): number
	local pos = writer.pos
	local size = buffer.len(writer.buf)

	if pos + bytes > size then
		local new_size = size + size / 2
		while new_size < pos + bytes do
			new_size += new_size / 2
		end

		local new = buffer.create(new_size)
		buffer.copy(new, 0, writer.buf, 0, pos)
		writer.buf = new
	end

	writer.pos += bytes
	return pos
end

local function emit_number(writer: Writer, value: number): number
	local pos = alloc(writer, 9)
	buffer.writeu8(writer.buf, pos, 0)
	buffer.writef64(writer.buf, pos + 1, value)
	return pos
end

local function emit_string(writer: Writer, value: string): number
	local pos = alloc(writer, #value + 5)
	buffer.writeu8(writer.buf, pos, 1)
	buffer.writeu16(writer.buf, pos + 1, #value)
	buffer.writestring(writer.buf, pos + 3, value, #value)
	return pos
end

return {
	emit_number = emit_number,
	emit_string = emit_string,
}
