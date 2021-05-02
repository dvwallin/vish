module cmds

import os

pub fn rm(args []string) ? {
	if os.exists(args[0]) {
		if os.is_dir(args[0]) {
			os.rmdir(args[0]) ?
		} else {
			os.rm(args[0]) ?
		}
	} else {
		return error('cannot remove "${args[0]}". path does not exist')
	}
}

pub fn rmdir(args []string) ? {
	if os.exists(args[0]) {
		os.rmdir(args[0]) ?
	} else {
		return error('cannot remove "${args[0]}". path does not exist')
	}
}
