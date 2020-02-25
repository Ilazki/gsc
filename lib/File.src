//#open Error.src

File = {}

// Search for file in a list of paths given.
File.find = function(f,search)
	computer = get_shell.host_computer
	file = computer.File(f)
	if file then return file
	for i in search
		check = i + "/" + f
		if computer.File(check) then return computer.File(check)
	end for
	Error.error("File not found: " + f) and exit()
end function

File.write = function(f,s)
	computer = get_shell.host_computer
	pwd = computer.current_path
	// Join and re-split the path to make touch happy
	if f[0] == "/" then 
		file = f
	else
		file = pwd + "/" + f
	end if
	filename = file.split("/")[-1]
	filepath = file.split("/")[0:-1].join("/")
	err = computer.touch(filepath,filename)
	if typeof(err) == "string" then Error.warn("touch: " + err + " (" + f + ")") 	
	file = computer.File(f)
	file.set_content(s)
end function

File.delete = function(f)
	file = get_shell.host_computer.File(f)
	if file then file.delete
end function


// Strip file extension
strip_extension = function (s)
	file = s.split(".")
	if file.len == 1 then return s
	return file[0:-1].join(".")
end function






