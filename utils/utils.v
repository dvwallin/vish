module utils

import os
import term

const (
	debug_mode = os.getenv('VLSHDEBUG')
)

pub fn fail(input string) {
	println(term.fail_message('ERR| ${input}'))
}

pub fn debug<T>(input ...T) {
	if debug_mode == 'true' {
		print(term.bg_rgb(252, 251, 239, 'debug::\t\t'))
		for i in input {
			print(term.bg_rgb(252, 251, 239, i.str()))
		}
		print('\n')
	}
}
