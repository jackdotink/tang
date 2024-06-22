type T<Kind, Extra = {}> = { kind: Kind } & Extra

export type Token =
	T<"eof">
	| T<"ident", { value: string }>
	-- keywords
	| T<"true">
	| T<"false">
	| T<"let">
	| T<"in">
	-- literals
	| T<"number", { value: number }>
	| T<"string", { value: string }>
	-- operators
	| T<".">
	| T<"+">
	| T<"-">
	| T<"*">
	| T<"/">
	| T<"%">
	| T<"^">
	| T<"=">
	-- delims
	| T<"|">
	| T<"(">
	| T<")">
	-- punctuation
	| T<",">

export type Kind = typeof((({} :: any) :: Token).kind)

local function display(tok: Token): string
	return tok.kind
end

return {
	display = display,
}
