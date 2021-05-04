module exec

import os

import utils

pub fn try_exec_alias(
	alias string,
	args []string,
	aliases map[string]string,
	paths []string
) ?bool{
	if alias_key_exists(alias, aliases) {
		alias_split := aliases[alias].split(' ')
		cmd := alias_split[0]
		mut combined_args := []string{}
		combined_args << args
		split_args := alias_split[1..]
		combined_args << split_args
		utils.debug('found $alias in $aliases')
		utils.debug('will try to run $cmd with $combined_args')
		return try_exec_cmd(cmd, combined_args, paths)
	}
	return false
}

pub fn try_exec_cmd(raw_cmd string, pre_args []string, paths []string) ?bool {
	mut args_string := pre_args.join(' ')
	args_string = '$raw_cmd $args_string'
	has_pipe := args_string.contains('|')

	if has_pipe {

		pipe_split := args_string.split('|')
		for pipe in pipe_split {
			utils.debug('running pipe $pipe')
			pipe_sec_split := pipe.split(' ')
			sub_cmd := pipe_sec_split[0]
			sub_args := pipe_sec_split[1..]
			try_exec_cmd(sub_cmd, sub_args, paths) ?
		}

		return true
	}

	ok, path, cmd := find_exe(raw_cmd, paths) or {
		return err
	}
	if ok {
		args := built_in_cmd_modifiers(cmd, pre_args)
		if !os.is_executable(path) {
			return error('"$path" is not executable')
		}
		mut child := os.new_process(path)
		utils.debug('args: ', args.join(' '))
		child.set_args(args[0..])
		child.run()
		child.wait()
		return true
	}
	return error('could not execute "$cmd"')
}

fn alias_key_exists(key string, aliases map[string]string) bool {
	for i, _ in aliases {
		if i == key {
			return true
		}
	}

	return false
}

fn find_exe(needle string, paths []string) ?(bool, string, string) {
	mut trimmed_needle := ''
	for path in paths {
		trimmed_needle = needle.replace(path, '').trim_left('/')
		utils.debug('looking for $needle in $path')
		if os.exists([path, trimmed_needle].join('/')) {
			utils.debug('found $trimmed_needle in $path')
			return true, [path, trimmed_needle].join('/'), trimmed_needle // will return on first hit 
		}
	}

	return error('could not find and/or execute $trimmed_needle in $paths')
}

fn built_in_cmd_modifiers(cmd string, args []string) []string {
	mut return_args := []string{}
	return_args << args
	utils.debug('matching $cmd in built in modifiers')
	match cmd {
		'ls' {
			if !args.join(' ').contains('--color') {
				return_args << '--color=auto'
			}
		}
		else {}
	}
	return return_args
}
