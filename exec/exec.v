module exec

import os

import utils

pub fn try_exec_alias(alias string, aliases map[string]string, paths []string) ?bool{
	if alias_key_exists(alias, aliases) {
		alias_split := aliases[alias].split(' ')
		cmd := alias_split[0]
		args := alias_split[1..]
		utils.debug('found $alias in $aliases')
		return try_exec_cmd(cmd, args, paths)
	}
	return error('could not execute ${aliases[alias]}')
}

pub fn try_exec_cmd(cmd string, args []string, paths []string) ?bool {
	ok, path := find_exe(cmd, paths)
	if ok {
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

fn find_exe(needle string, paths []string) (bool, string) {
	for path in paths {
		if os.exists([path, needle].join('/')) {
			return true, [path, needle].join('/') // will return on first hit 
		}
	}

	return false, ''
}
