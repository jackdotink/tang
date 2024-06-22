local ansi = require("./ansi")

export type PrefixOp = "neg" | "pos"
export type InfixOp = "index" | "add" | "sub" | "mul" | "div" | "mod" | "pow"

export type Expr =
	-- literals
	{ kind: "number", value: number }
	| { kind: "string", value: string }
	| { kind: "boolean", value: boolean }
	-- operator exprs
	| { kind: "prefix", op: PrefixOp, rhs: Expr }
	| { kind: "infix", op: InfixOp, lhs: Expr, rhs: Expr }
	-- bindings
	| { kind: "let", vals: { [string]: Expr }, body: Expr }
	| { kind: "name", name: string }
	-- functions
	| { kind: "app", fn: Expr, arg: Expr }
	| { kind: "lambda", args: { string }, body: Expr }

local function display_expr(expr: Expr): string
	local fmt = ansi.fmt

	local function node(text: string)
		return fmt(text, ansi.FG_BRIGHT_GREEN)
	end

	local function user(text: string)
		return fmt(text, ansi.ITALIC, ansi.FG_BRIGHT_CYAN)
	end

	local function op(text: string)
		return fmt(text, ansi.BOLD, ansi.FG_BRIGHT_RED)
	end

	if expr.kind == "number" then
		return `{node("number")}({user(tostring(expr.value))})`
	elseif expr.kind == "string" then
		return `{node("string")}({user(expr.value)})`
	elseif expr.kind == "boolean" then
		return `{node("boolean")}({user(tostring(expr.value))})`
	elseif expr.kind == "prefix" then
		return `{node("prefix")}({op(expr.op)} {display_expr(expr.rhs)})`
	elseif expr.kind == "infix" then
		return `{node("infix")}({op(expr.op)} {display_expr(expr.lhs)} {display_expr(expr.rhs)})`
	elseif expr.kind == "let" then
		local vals = {}

		for name, expr in expr.vals do
			table.insert(vals, `{user(name)} = {display_expr(expr)}`)
		end

		return `{node("let")}({table.concat(vals, ", ")} {op("in")} {display_expr(expr.body)})`
	elseif expr.kind == "name" then
		return `{node("name")}({user(expr.name)})`
	elseif expr.kind == "app" then
		return `{node("app")}({display_expr(expr.fn)} {display_expr(expr.arg)})`
	elseif expr.kind == "lambda" then
		local args = {}

		for _, name in expr.args do
			table.insert(args, user(name))
		end

		return `{node("lambda")}({table.concat(args, " ")} {op("|")} {display_expr(expr.body)})`
	else
		error("unreachable")
	end
end

return {
	display_expr = display_expr,
}
