module main

import os
import term
import readline { Readline }

import cmds
import exec
import utils

#include <signal.h>

const (
	history_file = [os.home_dir(), '.vlsh_history'].join('/')
	config_file  = [os.home_dir(), '.vlshrc'].join('/')
)

struct Cfg {
	mut:
	paths []string
	aliases map[string]string
}

enum KeyCode {
	null = 0
	tab = 9
	enter = 10
	escape = 27
	space = 32
	backspace = 127
	exclamation = 33
	double_quote = 34
	hashtag = 35
	dollar = 36
	percent = 37
	ampersand = 38
	single_quote = 39
	left_paren = 40
	right_paren = 41
	asterisk = 42
	plus = 43
	comma = 44
	minus = 45
	period = 46
	slash = 47
	_0 = 48
	_1 = 49
	_2 = 50
	_3 = 51
	_4 = 52
	_5 = 53
	_6 = 54
	_7 = 55
	_8 = 56
	_9 = 57
	colon = 58
	semicolon = 59
	less_than = 60
	equal = 61
	greater_than = 62
	question_mark = 63
	at = 64
	a = 97
	b = 98
	c = 99
	d = 100
	e = 101
	f = 102
	g = 103
	h = 104
	i = 105
	j = 106
	k = 107
	l = 108
	m = 109
	n = 110
	o = 111
	p = 112
	q = 113
	r = 114
	s = 115
	t = 116
	u = 117
	v = 118
	w = 119
	x = 120
	y = 121
	z = 122
	left_square_bracket = 91
	backslash = 92
	right_square_bracket = 93
	caret = 94
	underscore = 95
	backtick = 96
	left_curly_bracket = 123
	vertical_bar = 124
	right_curly_bracket = 125
	tilde = 126
	insert = 260
	delete = 261
	up = 262
	down = 263
	right = 264
	left = 265
	page_up = 266
	page_down = 267
	home = 268
	end = 269
	f1 = 290
	f2 = 291
	f3 = 292
	f4 = 293
	f5 = 294
	f6 = 295
	f7 = 296
	f8 = 297
	f9 = 298
	f10 = 299
	f11 = 300
	f12 = 301
	f13 = 302
	f14 = 303
	f15 = 304
	f16 = 305
	f17 = 306
	f18 = 307
	f19 = 308
	f20 = 309
	f21 = 310
	f22 = 311
	f23 = 312
	f24 = 313
}

fn handler() {
	println('')
	exit(0)
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
	r.enable_raw_mode_nosig()
	for {
		git_branch_name := os.execute('git rev-parse --abbrev-ref HEAD')
		mut git_branch_output := ''
		if git_branch_name.exit_code == 0 {
			git_branch_output = '\n𝌎 $git_branch_name.output.trim_space()'
		}

		git_branch_id := os.execute('git rev-parse --short HEAD')
		if git_branch_id.exit_code == 0 {
			git_branch_output = '$git_branch_output $git_branch_id.output.trim_space()'
		}
		git_branch_output = term.bg_rgb(232, 232, 232, git_branch_output)
		mut home_dir := term.colorize(term.bold, '$os.getwd() ')
		home_dir = home_dir.replace('($git_branch_output) $os.home_dir()', '~')
		println(git_branch_output)
		println(home_dir)
		cmd := r.read_line_utf8(term.red('->')) ?
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
		'echo' {
			println(args.join(' '))
		}
		else {
			alias_ok := exec.try_exec_alias(cmd, cfg.aliases) or {
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

fn unique_history_cmd(history []string, full_cmd string) bool {
	for line in history {
		if full_cmd == line {
			return false
		}
	}
	return true
}
