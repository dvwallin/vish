module cmds

import os

pub fn help(version string) {
				println('
vlsh - V Lang SHell v$version
---------------------------------------
Copyright (c) 2021 David Satime Wallin <david@dwall.in>
https://vlsh.ti-l.de


aliases			Shows a list of all declared aliases.
cd			Change to provided directory.
exit			Exit the shell.
help			Displays this message.
ocp			Override existing destination for cp.
version 		Prints the version of vlsh.
source			Reloads the config file.

')
}

pub fn cd(args []string) {
	mut target := os.home_dir()
	if args.len > 0 {
		target = args[0]
	}
	os.chdir(target)
}
