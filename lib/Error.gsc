//#open Text.src

// Standard error and warning dumps
Error = {}
Error.error = function (s)
	bold = @Text.bold
	color = @Text.color
	print(bold(color("#FF2222","[ERROR] ") + s))
end function

Error.warn = function (s)
		bold = @Text.bold
		color = @Text.color
	print(bold(color("#FFA402","[WARNING] ") + s))
end function


