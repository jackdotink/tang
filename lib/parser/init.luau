local ast = require("../ast")
local state = require("./state")
local report = require("../report")
local lexer = require("./lexer")
local token = require("./token")

type State = state.State

local expr: (state: State) -> ast.Expr

local function atom(state: State): ast.Expr
	local tok = lexer.next(state)

	if tok.kind == "ident" then
		return { kind = "name", name = tok.value }
	elseif tok.kind == "number" then
		return { kind = "number", value = tok.value }
	elseif tok.kind == "string" then
		return { kind = "string", value = tok.value }
	elseif tok.kind == "(" then
		local expr = expr(state)

		local tok_close_paren = lexer.next(state)
		if tok_close_paren.kind ~= ")" then
			return report.syntax(`expected ')', found {token.display(tok_close_paren)}`)
		end

		return expr
	elseif tok.kind == "let" then
		local names = {}

		while true do
			local tok_name = lexer.next(state)
			if tok_name.kind == "ident" then
				table.insert(names, tok_name.value)
			else
				return report.syntax(`expected ident, found {token.display(tok_name)}`)
			end

			local tok_comma_equals = lexer.next(state)
			if tok_comma_equals.kind == "=" then
				break
			elseif tok_comma_equals.kind ~= "," then
				return report.syntax(`expected ',' or 'in', found {token.display(tok_comma_equals)}`)
			end
		end

		local vals = {}

		for i, name in names do
			vals[name] = expr(state)

			if i ~= #names then
				local tok_comma = lexer.next(state)
				if tok_comma.kind ~= "," then
					return report.syntax(`expected ',', found {token.display(tok_comma)}`)
				end
			end
		end

		local tok_in = lexer.next(state)
		if tok_in.kind ~= "in" then
			return report.syntax(`expected 'in', found {token.display(tok_in)}`)
		end

		local body = expr(state)

		return { kind = "let", vals = vals, body = body }
	elseif tok.kind == "|" then
		local args = {}

		repeat
			local tok_name = lexer.next(state)
			if tok_name.kind == "ident" then
				table.insert(args, tok_name.value)
			else
				return report.syntax(`expected ident, found {token.display(tok_name)}`)
			end
		until lexer.peek(state).kind == "|"
		lexer.next(state)

		local body = expr(state)

		return { kind = "lambda", args = args, body = body }
	else
		return report.syntax(`expected expr atom, found {token.display(tok)}`)
	end
end

local function into_prefix(tok: token.Token): ast.PrefixOp?
	if tok.kind == "+" then
		return "pos"
	elseif tok.kind == "-" then
		return "neg"
	else
		return nil
	end
end

local function into_infix(tok: token.Token): ast.InfixOp?
	if tok.kind == "." then
		return "index"
	elseif tok.kind == "+" then
		return "add"
	elseif tok.kind == "-" then
		return "sub"
	elseif tok.kind == "*" then
		return "mul"
	elseif tok.kind == "/" then
		return "div"
	elseif tok.kind == "%" then
		return "mod"
	elseif tok.kind == "^" then
		return "pow"
	else
		return nil
	end
end

local function bp_prefix(op: ast.PrefixOp): number
	if op == "neg" or op == "pos" then
		return 5
	else
		error("unreachable")
	end
end

local function bp_infix(op: ast.InfixOp): (number, number)
	if op == "add" or op == "sub" then
		return 1, 2
	elseif op == "mul" or op == "div" or op == "mod" then
		return 3, 4
	elseif op == "pow" then
		return 6, 5
	elseif op == "index" then
		return 7, 8
	else
		error("unreachable")
	end
end

local function expr_bp(state: State, min_bp: number): ast.Expr
	local lhs: ast.Expr

	do
		local tok = lexer.peek(state)
		local op: ast.PrefixOp? = into_prefix(tok)

		if op then
			lexer.next(state)
			lhs = { kind = "prefix", rhs = expr_bp(state, bp_prefix(op)), op = op }
		else
			lhs = atom(state)
		end
	end

	while true do
		local tok = lexer.peek(state)
		local op: ast.InfixOp? = into_infix(tok)

		if op == nil then
			break
		end

		local lbp, rbp = bp_infix(op)

		if lbp < min_bp then
			break
		end

		lexer.next(state)
		lhs = { kind = "infix", lhs = lhs, rhs = expr_bp(state, rbp), op = op }
	end

	return lhs
end

function expr(state: State): ast.Expr
	local lhs = expr_bp(state, 0)

	while true do
		local tok = lexer.peek(state)

		if tok.kind == "eof" or tok.kind == ")" or tok.kind == "," or tok.kind == "in" then
			break
		else
			lhs = { kind = "app", fn = lhs, arg = expr_bp(state, 0) }
		end
	end

	return lhs
end

return function(input: string): ast.Expr
	return expr({ pos = 0, buf = buffer.fromstring(input) })
end
