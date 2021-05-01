module utils

import os

const (
	debug_mode = os.getenv('VLSHDEBUG')
)

pub fn debug<T>(input ...T) {
	if debug_mode == 'true' {
		print('debug::\t\t')
		for i in input {
			print(i)
		}
		print('\n')
	}
}

