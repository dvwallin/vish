module main

import os
import term

#include <signal.h>

const (
	history_file = [os.home_dir(),'.vish_history'].join('/')
)

fn handler() {
	println('')
	exit(0)
}

fn main() {
	os.signal(2, handler)
	os.signal(1, handler)
	mut history := os.open_append(history_file) ?
	for {
		abvwd := term.colorize(term.bold, '$os.getwd()').replace('$os.home_dir()', '~')
		mut stdin := (os.input_opt('$abvwd\n➜ ') or {
			exit(1)
			panic('Exiting: $err')
			''
		}).split(' ')
		history.write_string(stdin.join(' ') + '\n') ?
		match stdin[0] {
			'cd' {
				os.chdir(stdin[1])
			}
			'clear' {
				term.clear()
			}
			'chmod' {
				if os.exists(stdin[2]) {
					os.chmod(stdin[2], ('0o' + stdin[1]).int())
				} else {
					println('chmod: error: path does not exist')
				}
			}
			'cp' {
				if os.exists(stdin[1]) {
					if os.exists(stdin[2]) {
						println('cp: error: destination path exists, use ocp to override')
					} else {
						os.cp(stdin[1], stdin[2]) ?
					}
				} else {
					println('cp: error: source path does not exist')
				}
			}
			'ocp' {
				if os.exists(stdin[1]) {
					os.cp(stdin[1], stdin[2]) ?
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
				mut target := '.'
				if stdin.len > 1 {
					stdin[1] = stdin[1].replace('~', os.home_dir())
					if os.exists(stdin[1]) {
						target = stdin[1].trim_right('/')
					}
				}
				mut ls := os.ls([target, '/'].join('')) ?
				println(target)
				ls.sort()
				for mut ent in ls {
					full_ent := os.real_path([target, ent].join('/'))
					mut output := ['??', ent, 'unknown'].join('    ')
					if os.is_dir(full_ent) {
						output = term.colorize(term.blue, ['{dir}', ent].join('  '))
						output = term.colorize(term.bold, output)
					} else if os.is_executable(full_ent) {
						output = term.colorize(term.bright_red, ['{exe}', ent].join('  '))
					} else if os.is_link(full_ent) {
						output = ['{lnk}', ent].join('  ')
						output = term.italic(output)
						output = term.bold(output)
						output = term.bright_magenta(output)
					} else if os.is_file(full_ent) {
						output = ['{fil}', ent].join('  ')
						output = term.colorize(term.bright_black, output)
					}
					println(output)
				}
			}
			'mkdir' {
				os.mkdir_all(stdin[1]) ?
			}
			'pwd' {
				println(os.getwd())
			}
			'rm' {
				if os.exists(stdin[1]) {
					if os.is_dir(stdin[1]) {
						println("rm: error: cannot remove '" + stdin[1] + "': Is a directory")
					} else {
						os.rm(stdin[1]) ?
					}
				} else {
					println("rm: error: cannot remove'" + stdin[1] + "': Path does not exist")
				}
			}
			'rmdir' {
				if os.exists(stdin[1]) {
					os.rmdir(stdin[1]) ?
				} else {
					println("rm: error: cannot remove'" + stdin[1] + "': Path does not exist")
				}
			}
			'echo' {
				stdin.delete(0)
				println(stdin.join(' '))
			}
			else {
				println('command not found: ' + stdin[0])
			}
		}
	}
	history.close()
	exit(0)
}
