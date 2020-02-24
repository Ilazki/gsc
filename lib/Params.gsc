//#open String.src

Params = {}

// Parses a list of strings (ARGV), usually `params`, for any 
// command line switches in LST.  Returns a map of any matched
// switches and their arguments, with an extra key named "extra"
// that contains all extra arguments.
Params.parse = function (argv,lst)
	table = { }
	table.extra = []
	
	check_flags = function (arg,lst)
		for v in lst
			if String.startswith(arg,v) then return v
		end for
		return false
	end function
	
	for arg in argv
		match = check_flags(arg,lst)
		if match then 
			table[match] = arg.split("=")[1:].join("=")
		else 
			table.extra.push(arg)
		end if
	end for	

	return table
end function




