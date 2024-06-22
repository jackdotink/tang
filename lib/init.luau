local parser = require("./parser")
local ast = require("./ast")
local report = require("./report")
local compiler = require("./compiler")

local input = "let a, b = 1, 2 in a + b"

--- |a| |b| a + b
--- |a| (|a b| a + b) a

print(input)

local result = report.catch(parser, input)

if result.ok then
	print(ast.display_expr(result.value))
	print(ast.display_expr(compiler.pass_let_into_lambda(result.value)))
else
	print(report.display(result.report))
end
