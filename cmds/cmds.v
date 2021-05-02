module cmds

import os
import term

import utils

struct Ent {
	mut:
	fullpath string
	name string
	output string
	len int
}

pub fn ls(args []string) ? { 
	x, _ := term.get_terminal_size()
	size := x / 3
	utils.debug('column size: ${size}')
	output := ls_cmd(args)?
	mut c := 0
	for ent in output {
		mut pad := 0
		mut pad_string := ''
		if pad < ent.len {
			pad = size - ent.len
		}
		for i := 0; i < pad; i += 1 {
			pad_string += ' '
		}
		print(ent.output + pad_string)
		c += 1
		if c == 3 {
			print('\n')
			c = 0
		}
	}
}

fn ls_cmd(args []string) ?[]Ent {
	mut target := '.'
	mut ents := []Ent{}
	mut show_hidden := false
	if args.len > 0 {
		mut target_arg := args[0].replace('~', os.home_dir())
		if args[0] == 'la' || args[0] == '-la' {
			show_hidden = true
		}
		if args.len > 1 {
			target_arg = args[1].replace('~', os.home_dir())
		}
		utils.debug('target_arg: ', target_arg)
		if os.exists(target_arg) {
			target = target_arg.trim_right('/')
		}
	}
	utils.debug('target: ', target)
	mut ls := os.ls([target, '/'].join('')) ?
	ls.sort()
	for mut ent in ls {
		if !show_hidden && ent.starts_with('.') {
			continue
		}
		full_ent := os.real_path([target, ent].join('/'))
		mut output := ['??', ent, 'unknown'].join('    ')
		if os.is_dir(full_ent) {
			output = term.colorize(term.blue, ent)
			output = term.colorize(term.bold, output)
		} else if os.is_executable(full_ent) {
			output = term.colorize(term.bright_red, ent)
		} else if os.is_link(full_ent) {
			output = term.italic(ent)
			output = term.bold(output)
			output = term.bright_magenta(output)
		} else if os.is_file(full_ent) {
			output = term.colorize(term.bright_black, ent)
		}
		ent_obj := Ent{
		 fullpath: full_ent,
		 name: ent,
		 output: output,
		 len: ent.len
	 }
	 ents << ent_obj
	}
	return ents 
}

pub fn help() {
				println('aliases			Shows a list of all declared aliases.
cd			Change to provided directory.
chmod			Change file/dir access attributes and permissions.
clear			Clears the screen.
cp			Copy source file/dir to destination.
echo			Print entered message.
exit			Exit the shell.
help			Displays this message.
ls			List all files and subdirectories in current directory.
mkdir			Creates new directory.
ocp			Override existing destination for cp.
pwd			Displays the full path of current directory.
rm			Removes file.
rmd			Removes directory.
source			Reloads the config file.')
}