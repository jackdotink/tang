local token = require("./token")

export type State = {
	buf: buffer,
	pos: number,

	peek: token.Token?,
}

return {}
