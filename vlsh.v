module main

import os
import term
import readline { Readline }

import cfg
import cmds
import exec
import utils

const version = '0.1.2'

fn main() {

	if !os.exists(cfg.config_file) {
		cfg.create_default_config_file() or {
			panic(err.msg)
		}
	}

	term.clear()
	mut r := Readline{}
	for {
		mut current_dir := term.colorize(term.bold, '$os.getwd() ')
		current_dir = current_dir.replace('$os.home_dir()', '~')
		git_branch_output := utils.get_git_info()
		println('\n$git_branch_output\n$current_dir')
		cmd := r.read_line(term.rgb(255, 112, 112, '- ')) or {
			utils.fail(err.msg)
			return
		}
		main_loop(cmd.str().trim_space())
	}
}

fn main_loop(input string) {

	input_split := input.split(' ')
	cmd := input_split[0]
	mut args := []string{}
	if input_split.len > 1 {
		args << input_split[1..]
	}

	match cmd {
		'aliases' {
			aliases := cfg.aliases() or {
				utils.fail(err.msg)
				return
			}
			for alias_name, alias_cmd in aliases {
				print('${term.bold(alias_name)} : ${term.italic(alias_cmd)}\n')
			}
		}
		'cd' {
			cmds.cd(args)
		}
		'ocp' {
			cmds.ocp(args) or {
				utils.fail(err.msg)
			}
		}
		'exit' {
			exit(0)
		}
		'help' {
			cmds.help(version)
		}
		'version' {
			println('version $version')
		}
		//'source' {
			//cfg = read_cfg() or {
				//utils.fail('could not read $config_file')
				//return
			//}
		//}
		'share' {
			link := cmds.share(args) or {
				utils.fail(err.msg)
				return
			}
			println(link)
		}
		else {
			cfg := cfg.get() or {
				utils.fail(err.msg)
				return
			}
			mut t := exec.Task{
				cmd: exec.Cmd_object{
					cmd: cmd,
					args: args,
					cfg: cfg
				}
			}
			t.prepare_task() or {
				utils.fail(err.msg)
			}
		}
	}
}
