module main

import os
import term

#include <signal.h>

const (
	history_file = [os.home_dir(), '.vlsh_history'].join('/')
	config_file  = [os.home_dir(), '.vlshrc'].join('/')
	debug_mode	 = os.getenv('VLSHDEBUG')
)

struct Cfg {
	mut:
	paths []string
	aliases map[string]string
}

fn handler() {
	println('')
	exit(0)
}

fn main() {
	os.signal(2, handler)
	os.signal(1, handler)
	mut history := os.open_append(history_file) ?

	// reading in configuration file to handle paths and aliases
	mut cfg := Cfg{}
	config_file_data := os.read_lines(config_file) ?

	// populate config struct with aliases found in .vlshrc.
	// duplicate aliases will be overwritten
	cfg.extract_aliases(config_file_data)

	// populate config struct with paths found in .vlshrc.
	cfg.extract_paths(config_file_data)

	debug(cfg)

	for {
		prompt := term.colorize(term.bold, '$os.getwd()').replace('$os.home_dir()', '~')
		mut stdin := (os.input_opt('--\n$prompt\n☣ ') or {
			exit(1)
			panic('Exiting: $err')
			''
		}).split(' ')

		// a command is always expected
		cmd := stdin[0]

		// handle possible arguments
		mut args := []string{}
		if stdin.len > 1 {
			args << stdin[1..]
		}

		history.write_string(stdin.join(' ') + '\n') ? //@todo: only write unique
		match cmd {
			'cd' {
				mut target := os.home_dir()
				if args.len > 0 {
					target = args[0]
				}
				os.chdir(target)
			}
			'clear' {
				term.clear()
			}
			'chmod' {
				if os.exists(args[1]) {
					os.chmod(args[1], ('0o' + args[0]).int())
				} else {
					println('chmod: error: path does not exist')
				}
			}
			'cp' {
				if os.exists(args[0]) {
					if os.exists(args[1]) {
						println('cp: error: destination path exists, use ocp to override')
					} else {
						os.cp(args[0], args[1]) ?
					}
				} else {
					println('cp: error: source path does not exist')
				}
			}
			'ocp' {
				if os.exists(args[0]) {
					os.cp(args[0], args[1]) ?
				} else {
					println('ocp: error: source path does not exist')
				}
			}
			'exit' {
				exit(0)
			}
			'help' {
				println('cd			Change to provided directory.
				chmod			Change file/dir access attributes and permissions.
				clear			Clears the screen.
				cp			Copy source file/dir to destination.
				echo			Print entered message.
				exit			Exit the shell.
				help			Displays this message.
				ls			List all files and subdirectories in current directory.
				mkdir			Creates new directory.
				ocp			Override existing destination for cp.
				pwd			Displays the full path of current directory
				rm			Removes file.
				rmd			Removes directory.')
			}
			'ls' {
				output := ls_cmd(args)?
				println(output)
			}
			'mkdir' {
				os.mkdir_all(args[0]) ?
			}
			'pwd' {
				println(os.getwd())
			}
			'rm' {
				if os.exists(args[0]) {
					if os.is_dir(args[0]) {
						println("rm: error: cannot remove '" + args[0] + "': Is a directory")
					} else {
						os.rm(args[0]) ?
					}
				} else {
					println("rm: error: cannot remove'" + args[0] + "': Path does not exist")
				}
			}
			'rmdir' {
				if os.exists(args[0]) {
					os.rmdir(args[0]) ?
				} else {
					println("rm: error: cannot remove'" + args[0] + "': Path does not exist")
				}
			}
			'echo' {
				stdin.delete(0)
				println(stdin.join(' '))
			}
			else {
				ok, path := cfg.find_exe(cmd)
				if ok {
					if !os.is_executable(path) {
						println([path, 'is not executable'].join(' '))
						return
					}
					mut child := new_process(path)
					child.set_args(args[0..])
					child.run()
					child.wait()
				} else {
					println('command not found: ' + cmd)
				}
			}
		}
	}
	history.close()
	exit(0)
}

fn (cfg Cfg) find_exe(needle string) (bool, string) {
	for path in cfg.paths {
		if os.exists([path, needle].join('/')) {
			return true, [path, needle].join('/') // will return on first hit 
		}
	}

	return false, ''
}

fn (mut cfg Cfg) extract_aliases(config []string) {
	for ent in config {
		if ent[0..5].trim_space() == 'alias' {
			split_alias := ent.replace('alias', '').trim_space().split('=')
			cfg.aliases[split_alias[0]] = split_alias[1]
		}
	}
}

fn (mut cfg Cfg) extract_paths(config []string) {
	for ent in config {
		if ent[0..4].trim_space() == 'path' {
			cleaned_ent := ent.replace('path', '').replace('=', '')
			mut split_paths := cleaned_ent.trim_space().split(';')
			for mut path in split_paths {
				path = path.trim_right('/')
				if os.exists(os.real_path(path)) {
					cfg.paths << path
				} else {
					println(['could not find', os.real_path(path)].join(' '))
				}
			}
		}
	}
}

fn debug<T>(input T) {
	if debug_mode == 'true' {
		println(input)
	}
}

fn ls_cmd(args []string) ?string {
	mut target := '.'
	if args.len > 0 {
		first_arg := args[0].replace('~', os.home_dir())
		if os.exists(args[0]) {
			target = first_arg.trim_right('/')
		}
	}
	mut ls := os.ls([target, '/'].join('')) ?
	mut output_array := []string{}
	ls.sort()
	for mut ent in ls {
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
		output_array << output
	}
	return output_array.join('\t')
}
