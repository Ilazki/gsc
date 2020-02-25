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

String = {}
String.startswith = function (str,pred)
	return str.indexOf(pred) == 0
end function



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







PRAGMA = "//#"
VERSION = "1.0.5"

print_help = function()
	bold = @Text.bold
	bin_name = program_path.split("/")[-1]
	help = []
	help.push(bold("Usage: " + bin_name + " [switches] <source file> [output path]
"))
	help.push("

")
	help.push(bold("-h	--help		") + "Print this message and exit
")
	help.push(bold("-v	--version	") + "Print version information and exit
")
	help.push(bold("-o	--output		") + "Path of output file.  Current directory
")
	help.push(     "					"     + "used if omitted.
")
	help.push(bold("	--src			")    + "Generate source file and exit. Skips the 
")
	help.push(     "					"     + "compilation step.
")
	help.push(bold("-I	--include	") + "Comma-separated list of directories to
")
	help.push(     "					"     + "search for libs.  Example: -I=lib,src
")
	help.push(     "					"     + "Current directory and 'lib' are searched
")
	help.push(     "					"     + "even if no include switch provided.
")
	print(help.join(""))	
end function

print_version = function()
	color = @Text.color
	bold = @Text.bold
	blue = "#02A2FF"
	gold = "#FFBE4A"
	s = color(blue,bold("gsc")) + " version " + color(blue,bold(VERSION))
	s = s + ", a GreyScript compiler by " + color(gold,bold("Ilazki")) + "."
	print(s)
end function

// Take arguments: required input source and optional output path.
// 	use current_path if output is omitted.
check_help = function(sw)
	if sw.hasIndex("--help") or sw.hasIndex("-h") then 
		print_help
		exit()
	end if
end function

check_version = function(sw)
	if sw.hasIndex("--version") or sw.hasIndex("-v") then 
		print_version
		exit()
	end if
end function

get_output_dir = function(sw)
	// Fail on flag conflict.
	if sw.hasIndex("-o") and sw.hasIndex("--output") then 
		Error.error("Conflicting output switches specified") and exit()
	end if
	if sw.hasIndex("-o") then return sw["-o"]
	if sw.hasIndex("--output") then return sw["--output"]
	return null
end function

get_includes = function(sw)
	// Automatically add the common "lib" folder for convenience.
	inc = ["lib"]
	if sw.hasIndex("-I") then inc = inc + sw["-I"].split(",")
	if sw.hasIndex("--include") then inc = inc + sw["--include"].split(",")
	return inc
end function

get_args = function(lst)
	valid_switches = ["--output", "-o", "--include", "-I", "--version", "-v","--src"]
	valid_switches = valid_switches + ["--help", "-h"]
	switches = Params.parse(lst,valid_switches)

	args = {}
	args.compile = true
	
	check_help(switches)
	check_version(switches)

	// Input file
	if switches.extra.len < 1 then print_help and exit()
	args.input = switches.extra[0]
	
	// Output location
	out = get_output_dir(switches)
	// No explicit flag, try to match "build" behavior or fall back to curent_path.
	if not out and switches.extra.len > 1 then out = switches.extra[1]
	if not out then out = get_shell.host_computer.current_path
	args.output = out + "/"

	// Includes.  Automatically add the common ./lib for convenience.
	args.include = get_includes(switches)

	// Skip compiling if --src is set
	if switches.hasIndex("--src") then args.compile = false
	return args
end function

// Read file, return list of pragmas
read_pragmas = function (f)
	file = File.find(f,args.include)
	lines = file.content.split("
")
	pragmas = []
	// Accumulate pragmas, stopping on first non-pragma line for speed.
	for l in lines 
		split = l.split("\s")
		if not String.startswith(split[0], PRAGMA) then return pragmas
		pragmas.push(split)
	end for
end function

// Strip all pragmas from beginning of file and return rest of it.
strip_pragmas = function(f)
	file = File.find(f,args.include)
	lines = file.content.split("
")
	while 1
		if not String.startswith(lines[0], PRAGMA) then return lines.join("
")
		lines.pull()
	end while
	// File of only pragmas.  Return empty string.
	return "" 
end function

// Take a list of pragmas from read_pragmas and returns a list of
// files gathered from //#open pragmas
get_opens = function(pragmas)
	l = []
	pragma_open = PRAGMA + "open"
	for p in pragmas
		if p[0] == pragma_open then l.push(p[1])
	end for
	return l
end function

// Main logic begins here 

// args.input, args.output, args.include, args.compile
args = get_args(params)

// List of filenames to combine, starting with the original source
sources = [args.input]

// Open files recursively and check pragmas to build the list of 
// source files to merge.
opens = [args.input]
i = 0
while i < opens.len
	new_opens = get_opens(read_pragmas(opens[i]))
	new_opens.reverse
	for f in new_opens
		opens.push(f)
	end for
	i = i + 1
end while

// Walk the list in reverse, reading each file and adding it onto
// the concatenated file.  Once used, each filename is added to the 
// used_files list so it can be skipped if more than one file opens it.

generated_source = []
opens.reverse
used_files = []

for v in opens 
	used = false
	for f in used_files
		if v == f then used = true
	end for
	if not used then
		file = strip_pragmas(v)
		generated_source.push(file)
		used_files.push(v)
	end if
end for

// Create an actual on-disk file 
generated_source = generated_source.join("")
output_name = strip_extension(args.input)
temp_file = output_name + "_generated.gst"
File.write(temp_file,generated_source)

// Stop here if --src flag.
if not args.compile then exit()

// Compile
shell = get_shell
computer = shell.host_computer
temp_file_fullpath = computer.File(temp_file).path
temp_file_buildpath = temp_file_fullpath.split("/")[0:-1].join("/")

File.delete(strip_extension(temp_file_fullpath))
err = shell.build(temp_file_fullpath, temp_file_buildpath)

// If something goes wrong, print error and leave gst file to debug.
if err then 
	print(err)
	exit()
end if

// Cleanup
File.delete(temp_file_fullpath)
binfile = strip_extension(temp_file_fullpath)
outfile = strip_extension(args.input.split("/")[-1])
computer.File(binfile).move(args.output,outfile)




