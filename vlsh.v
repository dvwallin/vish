module main

import os
import term
import readline { Readline }

import cmds
import exec
import utils

#include <signal.h>

const (
	config_file  = [os.home_dir(), '.vlshrc'].join('/')
)

struct Cfg {
	mut:
	paths []string
	aliases map[string]string
}

fn read_cfg() ?Cfg {
	mut cfg := Cfg{}
	config_file_data := os.read_lines(config_file) ?
	cfg.extract_aliases(config_file_data)
	cfg.extract_paths(config_file_data) or {
		utils.fail(err.msg)
	}
	utils.debug(cfg)

	return cfg
}

fn main() {
	mut r := Readline{}
	r.enable_raw_mode()
	for {
		mut home_dir := term.colorize(term.bold, '$os.getwd() ')
		home_dir = home_dir.replace('$os.home_dir()', '~')
		git_branch_output := utils.get_git_info()
		println('\n$git_branch_output\n$home_dir')
		cmd := r.read_line_utf8(term.red(':=')) ?
		main_loop(cmd.str().trim_space())
	}
	r.disable_raw_mode()
}

fn main_loop(input string) {

	input_split := input.split(' ')
	cmd := input_split[0]
	mut args := []string{}
	if input_split.len > 1 {
		args << input_split[1..]
	}

	// reading in configuration file to handle paths and aliases
	mut cfg := read_cfg() or {
		utils.fail('could not read $config_file')
		return
	}

	match cmd {
		'aliases' {
			for alias_name, alias_cmd in cfg.aliases {
				print('${term.bold(alias_name)} : ${term.italic(alias_cmd)}\n')
			}
		}
		'cd' {
			cmds.cd(args)
		}
		'clear' {
			term.clear()
		}
		'chmod' {
			cmds.chmod(args) or {
				utils.fail(err.msg)
			}
		}
		'cp' {
			cmds.cp(args) or {
				utils.fail(err.msg)
			}
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
			cmds.help()
		}
		'ls' {
			cmds.ls(args) or {
				utils.fail('could not read directory')
				return
			}
		}
		'mkdir' {
			os.mkdir_all(args[0]) or {
				utils.fail('could not create ${args[0]}')
				return
			}
		}
		'pwd' {
			println(os.getwd())
		}
		'rm' {
			cmds.rm(args) or {
				utils.fail(err.msg)
			}
		}
		'rmdir' {
			cmds.rmdir(args) or {
				utils.fail(err.msg)
			}
		}
		'source' {
			cfg = read_cfg() or {
				utils.fail('could not read $config_file')
				return
			}
		}
		else {
			alias_ok := exec.try_exec_alias(cmd, cfg.aliases, cfg.paths) or {
				utils.fail(err.msg)
				return
			}
			if !alias_ok {
				exec.try_exec_cmd(cmd, args, cfg.paths) or {
					utils.fail(err.msg)
				}
			}
		}
	}
}

fn (mut cfg Cfg) extract_aliases(config []string) {
	for ent in config {
		if ent[0..5].trim_space() == 'alias' {
			split_alias := ent.replace('alias', '').trim_space().split('=')
			cfg.aliases[split_alias[0]] = split_alias[1]
		}
	}
}

fn (mut cfg Cfg) extract_paths(config []string) ? {
	for ent in config {
		if ent[0..4].trim_space() == 'path' {
			cleaned_ent := ent.replace('path', '').replace('=', '')
			mut split_paths := cleaned_ent.trim_space().split(';')
			for mut path in split_paths {
				path = path.trim_right('/')
				if os.exists(os.real_path(path)) {
					cfg.paths << path
				} else {
					real_path := os.real_path(path)
					return error('could not find ${real_path}')
				}
			}
		}
	}
}
