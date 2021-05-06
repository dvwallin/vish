module utils

import os
import term

import cfg

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
	style := cfg.style() or {
		fail(err.msg)
		return
	}
	if debug_mode == 'true' {
		print(
			term.bg_rgb(
				style['style_debug_bg'][0],
				style['style_debug_bg'][1],
				style['style_debug_bg'][2],
				term.rgb(
					style['style_debug_fg'][0],
					style['style_debug_fg'][1],
					style['style_debug_fg'][2],
					'debug::\t\t'
				)
			)
		)
		for i in input {
			print(
				term.bg_rgb(
					style['style_git_bg'][0],
					style['style_git_bg'][1],
					style['style_git_bg'][2],
					term.rgb(
						style['style_git_fg'][0],
						style['style_git_fg'][1],
						style['style_git_fg'][2],
						i.str()
					)
				)
			)
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
		git_branch_output = term.bg_rgb(
			44, 59, 71,
			term.rgb(
				251, 255, 234,
				git_branch_output
			)
		)

		return git_branch_output
}
