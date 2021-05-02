module cmds

import os

pub fn cp(args []string) ? {
	if os.exists(args[0]) {
		if os.exists(args[1]) {
			return error('"${args[1]}" already exists, use ocp to override')
		} else {
			os.cp(args[0], args[1]) ?
		}
	} else {
		return error('"${args[0]}" does not exist')
	}
}

pub fn ocp(args []string) ? {
	if os.exists(args[0]) {
		os.cp(args[0], args[1]) ?
	} else {
		return error('"${args[0]}" does not exist')
	}
}
