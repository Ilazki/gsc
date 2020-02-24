// Author:  Ilazki

// Automatically build and run for easier development workflow.
// Uses gsc if available, otherwise normal build.

// Function declarations
bold = function (s)
	return "<b>" + s + "</b>"
end function
italic = function (s)
	return "<i>" + s + "</i>"
end function
color = function (c,s)
	return "<color=" + c + ">" + s + "</color>"
end function

print_help = function ()
	bin_name = program_path.split("/")[-1]
	print(bold("Usage: " + bin_name + " <src> " + italic("[src args]")))
end function

error = function (s)
	print(bold(color("#FF2222","[ERROR] ") + s))
end function

get_file = function (s)
	pwd = get_shell.host_computer.current_path
	file = get_shell.host_computer.File(s)
	if not file then error("File not found: " + s) and exit()
	return file
end function

parse_argv = function ()
	if not params then 
		print_help and exit()
	else if (params[0] == "-h" or params[0] == "--help") then
		print_help and exit()
	end if	
	return [get_file(params[0]), params[1:]]
end function

strip_extension = function (s)
	file = s.split(".")
	if file.len == 1 then return s
	return file[0:-1].join(".")
end function

// Main logic

shell = get_shell
computer = shell.host_computer
pwd = computer.current_path
result = parse_argv
file = result[0]
args = result[1].join(" ")

// Only want source.  Fail on folders, binaries, and unreadable files.
if file.is_folder then error(file.name + " is a folder") and exit()
if file.is_binary then error(file.name + " is a binary file") and exit()
if not file.has_permission("r") then error(file.name + " is not readable") and exit()

// Determine name of output binary, abort if it exists already.
bin = [pwd, strip_extension(file.name)].join("/")
if computer.File(bin) then error(bin + " exists, not compiling.") and exit()

// Build file, abort on failure.  Default to /bin/gsc if exists.
gsc = "/bin/gsc"
if computer.File(gsc) then 
	err = shell.launch("/bin/gsc", file.path + " " + pwd)
else
	err = shell.build(file.path, pwd)
end if

if err then error(err) and exit("")

// Launch file and remove binary
shell.launch(bin,args)
computer.File(bin).delete




