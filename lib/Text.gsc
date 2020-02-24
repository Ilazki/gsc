Text = {}

// TODO:  add helpers for common colour names,
// reverse text and bgcolor if I find a way, etc.

// Basic formatting
Text.bold = function (s)
	return "<b>" + s + "</b>"
end function
Text.italic = function (s)
	return "<i>" + s + "</i>"
end function
Text.color = function (c,s)
	return "<color=" + c + ">" + s + "</color>"
end function

