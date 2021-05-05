module exec

import os

import utils

pub struct Cmd_object{
	mut:
	cmd						string
	fullcmd					string
	args					[]string
	path					string
	paths					[]string
	aliases					map[string]string
	input					string
	set_redirect_stdio		bool
	intercept_stdio			bool
	next_pipe_index			int
}

pub struct Task {
	mut:
	cmd			Cmd_object
	pipe_string	string
	pipe_cmds	[]Cmd_object
}

pub fn (mut t Task) prepare_task() ?string {
	/*
		prase possible pipes first.
	*/
	t.parse_pipe()

	t.exec() or {

		return err
	}

	return ''
}

fn (mut t Task) parse_pipe() {
	t.pipe_string = norm_pipe([t.cmd.cmd, t.cmd.args.join(' ')].join(' '))
	t.walk_pipes()
}

fn norm_pipe(i string) string {
	mut r := []string{}
	m := i.split('|')
	for s in m {
		mut p := s
		p = p.trim_space()
		if p != '' {
			r << p
		}
	}

	return r.join('|')
}

fn (mut t Task) walk_pipes() {
	split_pipe_string := t.pipe_string.split('|')
	len := split_pipe_string.len
	for index, pipe_string in split_pipe_string {
		split_pipe := pipe_string.split(' ')
		cmd := split_pipe[0]
		mut args := []string{}
		if split_pipe.len > 1 {
			args << split_pipe[1..]
		}
		mut intercept := true
		mut next_index := index
		if next_index + 1 == len {
			intercept = false
			next_index = -1
		}
		obj := Cmd_object{
			cmd: cmd,
			args: args,
			paths: t.cmd.paths,
			aliases: t.cmd.aliases,
			intercept_stdio: intercept,
			set_redirect_stdio: intercept,
			next_pipe_index: next_index
		}
		if index == 0 {
			t.cmd = obj
		} else {
			t.pipe_cmds << obj
		}
	}
}

fn (mut t Task) exec() ?bool {

	/*
		checking if we have any aliases defined first that we should
		overwrite any actual given command with.
	*/
	t.handle_aliases()

	/*
		locate the given command in specifide paths.

		@todo: should set some standard paths in the code..?
	*/
	t.cmd.find_exe() or {

		return err
	}

	/*
		also find_exec for each pipe cmd following.
	*/
	if t.pipe_cmds.len > 0 {
		for i := 0; i < t.pipe_cmds.len; i++ {
			t.pipe_cmds[i].find_exe() or {

				return err
			}
		}
	}

	/*
		apply certain flags to specific commands if they aren't set manually.
	*/
	t.cmd.internal_cmd_modifiers()

	/*
		also find internal_cmd_modifiers for each pipe cmd following.
	*/
	if t.pipe_cmds.len > 0 {
		for i := 0; i < t.pipe_cmds.len; i++ {
			t.pipe_cmds[i].internal_cmd_modifiers()
		}
	}

	//utils.debug('Task: $t')

	/*
		actually run the process.
	*/
	mut index := -1
	index = t.run(t.cmd)

	if index >= 0 && t.pipe_cmds.len > 0 {
		for {
			index = t.run(t.pipe_cmds[index])
			if index < 0 {
				utils.debug('breaking')
				break
			}
		}
	}

	return true
}

fn (mut t Task) run(c Cmd_object) (int) {
	mut output := ''
	mut child := os.new_process('$c.fullcmd')
	if c.args.len > 0 {
		child.set_args(c.args[0..])
	}
	if c.next_pipe_index >= 0 || c.input != '' {
			child.set_redirect_stdio()
	}

	if c.next_pipe_index < 0 {
		child.run()
	}

	child.wait()
	if c.input != '' {
		child.stdin_write(c.input)
	}
	if c.intercept_stdio {
		/*
			set intercepted stdout for next
			pipe cmd in chain.
		*/
		if c.next_pipe_index >= 0 {
			output = child.stdout_slurp().trim_space()
			t.pipe_cmds[c.next_pipe_index].input = output
		}

	}

	return c.next_pipe_index
}

pub fn (mut t Task) handle_aliases() {
	if alias_key_exists(t.cmd.cmd, t.cmd.aliases) {
		alias_split := t.cmd.aliases[t.cmd.cmd].split(' ')
		t.cmd.cmd = alias_split[0]
		t.cmd.args << alias_split[1..]
		utils.debug('found $t.cmd.cmd in $t.cmd.aliases')
		utils.debug('will try to run $t.cmd.cmd with $t.cmd.args')
	}
}

fn alias_key_exists(key string, aliases map[string]string) bool {
	for i, _ in aliases {
		if i == key {

			return true
		}
	}

	return false
}

fn (mut c Cmd_object) find_exe() ? {
	mut trimmed_needle := ''
	for path in c.paths {
		trimmed_needle = c.cmd.replace(path, '').trim_left('/')
		utils.debug('looking for $c.cmd in $path')
		if os.exists([path, trimmed_needle].join('/')) {
			utils.debug('found $trimmed_needle in $path')
			c.fullcmd = [path, trimmed_needle].join('/')
			c.path = path
			c.cmd = trimmed_needle

			return
		}
	}

	return error('could not find and/or execute $trimmed_needle in $c.paths')
}

fn (mut c Cmd_object) internal_cmd_modifiers() {
	utils.debug('matching $c.cmd in built in modifiers')
	match c.cmd {
		'ls' {
			if !c.args.join(' ').contains('--color') {
				c.args << '--color=auto'
			}
		}
		else {}
	}
}
