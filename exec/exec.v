module exec

import os

import utils

pub fn try_exec_alias(cmd string, aliases map[string]string) ?bool{
	if alias_key_exists(cmd, aliases) {
		utils.debug('found alias ${cmd}')
		response := os.execute(aliases[cmd])
		if response.exit_code == 0 {
			print(response.output)
		} else {
			return error('error in executing ${aliases[cmd]}. errco: response.exit_code')
		}
		return true
	}
	return false
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
	return error('could not exec "$cmd"')
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
