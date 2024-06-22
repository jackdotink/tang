local ast = require("../ast")
local data = require("./data")
local code = require("./code")

-- |a b| if a then |c| b + c else |c| b - c
-- |a b| if a then (|b c| b + c) b else (|b c| b - c) b

local function pass_let_into_lambda(expr: ast.Expr): ast.Expr
	if expr.kind == "prefix" then
		expr.rhs = pass_let_into_lambda(expr.rhs)
	elseif expr.kind == "infix" then
		expr.lhs = pass_let_into_lambda(expr.lhs)
		expr.rhs = pass_let_into_lambda(expr.rhs)
	elseif expr.kind == "app" then
		expr.fn = pass_let_into_lambda(expr.fn)
		expr.arg = pass_let_into_lambda(expr.arg)
	elseif expr.kind == "lambda" then
		expr.body = pass_let_into_lambda(expr.body)
	elseif expr.kind == "let" then
		local args = {}

		local fn: ast.Expr = {
			kind = "lambda",
			args = args,
			body = pass_let_into_lambda(expr.body),
		}

		for name, expr in expr.vals do
			table.insert(args, name)

			fn = {
				kind = "app",
				fn = fn,
				arg = pass_let_into_lambda(expr),
			}
		end

		return fn
	end

	return expr
end

local function pass_closure_conversion(expr: ast.Expr) end

return {
	pass_let_into_lambda = pass_let_into_lambda,
}
