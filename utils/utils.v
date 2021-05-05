module utils

import os
import term

const (
	debug_mode = os.getenv('VLSHDEBUG')
)

pub fn ok(input string) {
	println(term.ok_message('OKY| ${input}'))
}

pub fn fail(input string) {
	println(term.fail_message('ERR| ${input}'))
}

pub fn warn(input string) {
	println(term.warn_message('WRN| ${input}'))
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

pub fn get_git_info() string {
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

		return git_branch_output
}
