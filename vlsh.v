module main

import os
import term

import exec
import utils
import cmds

#include <signal.h>
#include <termios.h>
#include <sys/ioctl.h>

const (
	history_file = [os.home_dir(), '.vlsh_history'].join('/')
	config_file  = [os.home_dir(), '.vlshrc'].join('/')
	
	ctx_ptr = &Context(0)
)

struct App {
	mut:
	evnt &Context = 0
}

struct Cfg {
	mut:
	paths []string
	aliases map[string]string
}

struct Context {
	ExtraContext
	pub:
	cfg 		  EventConfig
	mut:
	print_buf  []byte
	read_buf []byte
}

struct Event {
	pub:
	typ EventType

	code      KeyCode
	ascii     byte
	utf8      string
}

pub struct EventConfig {
	user_data            voidptr
	init_fn              fn(voidptr)
	event_fn             fn(&Event, voidptr, chan Event)
	fail_fn              fn(string)

	buffer_size          int = 256

	capture_events       bool
	use_alternate_buffer bool = true
	skip_init_checks     bool
	// All kill signals to set up exit listeners on
	reset                []int = [1, 2, 3, 4, 6, 7, 8, 9, 11, 13, 14, 15, 19]
}

struct ExtraContext {
	mut:
	read_buf []byte
}

enum EventType {
	unknown
	key_down
}

enum KeyCode {
	null = 0
	tab = 9
	enter = 10
	escape = 27
	space = 32
	backspace = 127
	exclamation = 33
	double_quote = 34
	hashtag = 35
	dollar = 36
	percent = 37
	ampersand = 38
	single_quote = 39
	left_paren = 40
	right_paren = 41
	asterisk = 42
	plus = 43
	comma = 44
	minus = 45
	period = 46
	slash = 47
	_0 = 48
	_1 = 49
	_2 = 50
	_3 = 51
	_4 = 52
	_5 = 53
	_6 = 54
	_7 = 55
	_8 = 56
	_9 = 57
	colon = 58
	semicolon = 59
	less_than = 60
	equal = 61
	greater_than = 62
	question_mark = 63
	at = 64
	a = 97
	b = 98
	c = 99
	d = 100
	e = 101
	f = 102
	g = 103
	h = 104
	i = 105
	j = 106
	k = 107
	l = 108
	m = 109
	n = 110
	o = 111
	p = 112
	q = 113
	r = 114
	s = 115
	t = 116
	u = 117
	v = 118
	w = 119
	x = 120
	y = 121
	z = 122
	left_square_bracket = 91
	backslash = 92
	right_square_bracket = 93
	caret = 94
	underscore = 95
	backtick = 96
	left_curly_bracket = 123
	vertical_bar = 124
	right_curly_bracket = 125
	tilde = 126
	insert = 260
	delete = 261
	up = 262
	down = 263
	right = 264
	left = 265
	page_up = 266
	page_down = 267
	home = 268
	end = 269
	f1 = 290
	f2 = 291
	f3 = 292
	f4 = 293
	f5 = 294
	f6 = 295
	f7 = 296
	f8 = 297
	f9 = 298
	f10 = 299
	f11 = 300
	f12 = 301
	f13 = 302
	f14 = 303
	f15 = 304
	f16 = 305
	f17 = 306
	f18 = 307
	f19 = 308
	f20 = 309
	f21 = 310
	f22 = 311
	f23 = 312
	f24 = 313
}

fn handler() {
	println('')
	exit(0)
}

fn read_cfg() ?Cfg {
	mut cfg := Cfg{}
	config_file_data := os.read_lines(config_file) ?
	// populate config struct with aliases found in .vlshrc.
	// duplicate aliases will be overwritten
	cfg.extract_aliases(config_file_data)
	// populate config struct with paths found in .vlshrc.
	cfg.extract_paths(config_file_data) or {
		utils.fail(err.msg)
	}
	utils.debug(cfg)

	return cfg
}

fn main() {
	os.signal(2, handler)
	os.signal(1, handler)
	mut history_writer := os.open_append(history_file) ?

	mut history := os.read_lines(history_file) ?

	// reading in configuration file to handle paths and aliases
	mut cfg := read_cfg() ?

	// @todo : Need to handle events here somehow?!?!
	//ch := chan Event{}
	//mut app := &App{}
	//app.evnt = init(
	//user_data: app
	//event_fn: event
	//)
	//println(app)
	//e := go app.evnt.run(ch)
	//e.wait() ?
	//f := go test(ch)
	//f.wait()

	for {

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

		prompt := term.colorize(term.bold, '$os.getwd()').replace('$os.home_dir()', '~')
		mut stdin := (os.input_opt('$git_branch_output\n$prompt\n☣ ') or {
			exit(1)
			utils.fail('exiting: $err')
			''
		}).split(' ')

		// a command is always expected
		cmd := stdin[0]
		full_cmd := stdin.join(' ')
		if unique_history_cmd(history, full_cmd) {
			history_writer.write_string(stdin.join(' ') + '\n') ? //@todo: only write unique
			history << full_cmd
			utils.debug('wrote unique cmd to history: ${full_cmd}')
		}

		// handle possible arguments
		mut args := []string{}
		if stdin.len > 1 {
			args << stdin[1..]
		}

		match cmd {
			'aliases' {
				for alias_name, alias_cmd in cfg.aliases {
					print('${term.bold(alias_name)} : ${term.italic(alias_cmd)}\n')
				}
			}
			'cd' {
				cmds.cd(args)
			}
			'clear' {
				term.clear()
			}
			'chmod' {
				cmds.chmod(args) or {
					utils.fail(err.msg)
				}
			}
			'cp' {
				cmds.cp(args) or {
					utils.fail(err.msg)
				}
			}
			'ocp' {
				cmds.ocp(args) or {
					utils.fail(err.msg)
				}
			}
			'exit' {
				exit(0)
			}
			'help' {
				cmds.help()
			}
			'ls' {
				cmds.ls(args) ?
			}
			'mkdir' {
				os.mkdir_all(args[0]) ?
			}
			'pwd' {
				println(os.getwd())
			}
			'rm' {
				cmds.rm(args) or {
					utils.fail(err.msg)
				}
			}
			'rmdir' {
				cmds.rmdir(args) or {
					utils.fail(err.msg)
				}
			}
			'source' {
				cfg = read_cfg() ?
			}
			'echo' {
				stdin.delete(0)
				println(stdin.join(' '))
			}
			else {
				alias_ok := exec.try_exec_alias(cmd, cfg.aliases) or {
					utils.fail(err.msg)
					return
				}
				if !alias_ok {
					exec.try_exec_cmd(cmd, args, cfg.paths) or {
						utils.fail(err.msg)
					}
				}
			}
		}
	}
	history_writer.close()
	exit(0)
}

fn (mut cfg Cfg) extract_aliases(config []string) {
	for ent in config {
		if ent[0..5].trim_space() == 'alias' {
			split_alias := ent.replace('alias', '').trim_space().split('=')
			cfg.aliases[split_alias[0]] = split_alias[1]
		}
	}
}

fn (mut cfg Cfg) extract_paths(config []string) ? {
	for ent in config {
		if ent[0..4].trim_space() == 'path' {
			cleaned_ent := ent.replace('path', '').replace('=', '')
			mut split_paths := cleaned_ent.trim_space().split(';')
			for mut path in split_paths {
				path = path.trim_right('/')
				if os.exists(os.real_path(path)) {
					cfg.paths << path
				} else {
					real_path := os.real_path(path)
					return error('could not find ${real_path}')
				}
			}
		}
	}
}

fn unique_history_cmd(history []string, full_cmd string) bool {
	for line in history {
		if full_cmd == line {
			return false
		}
	}
	return true
}

fn (mut ctx Context) termios_loop(ch chan Event) {
	mut init_called := false
	for {
		if !init_called {
			ctx.init()
			init_called = true
		}
		if ctx.cfg.event_fn != voidptr(0) {
			unsafe {
				len := C.read(C.STDIN_FILENO, byteptr(ctx.read_buf.data) + ctx.read_buf.len,
				ctx.read_buf.cap - ctx.read_buf.len)
				ctx.resize_arr(ctx.read_buf.len + len)
			}
			if ctx.read_buf.len > 0 {
				ctx.parse_events(ch)
			}
		}
	}
}

fn (mut ctx Context) parse_events(ch chan Event) {
	// Stop this from getting stuck in rare cases where something isn't parsed correctly
	mut nr_iters := 0
	for ctx.read_buf.len > 0 {
		nr_iters++
		if nr_iters > 100 {
			ctx.shift(1)
		}
		mut event := &Event(0)
		if ctx.read_buf[0] == 0x1b {
			e, len := escape_sequence(ctx.read_buf.bytestr())
			event = e
			ctx.shift(len)
		} else {
			event = single_char(ctx.read_buf.bytestr())
			ctx.shift(1)
		}
		if event != 0 {
			ctx.event(event, ch)
			nr_iters = 0
		}
	}
}

[inline]
fn (mut ctx Context) shift(len int) {
	unsafe {
		C.memmove(ctx.read_buf.data, &byte(ctx.read_buf.data) + len, ctx.read_buf.cap - len)
		ctx.resize_arr(ctx.read_buf.len - len)
	}
}

[inline]
fn (mut ctx Context) resize_arr(size int) {
	mut l := unsafe { &ctx.read_buf.len }
	unsafe {
		*l = size
		_ = l
	}
}

fn single_char(buf string) &Event {
	ch := buf[0]

	mut event := &Event{
		typ: .key_down
		ascii: ch
		code: KeyCode(ch)
		utf8: buf
	}

	return event
}

fn escape_end(buf string) int {
	mut i := 0
	for {
		if i + 1 == buf.len {
			return buf.len
		}

		if buf[i].is_letter() || buf[i] == `~` {
			if buf[i] == `O` && i + 2 <= buf.len {
				n := buf[i + 1]
				if (n >= `A` && n <= `D`) || (n >= `P` && n <= `S`) || n == `F` || n == `H` {
					return i + 2
				}
			}
			return i + 1
			// escape hatch to avoid potential issues/crashes, although ideally this should never eval to true
		} else if buf[i + 1] == 0x1b {
			return i + 1
		}
		i++
	}
	// this point should be unreachable
	assert false
	return 0
}

fn escape_sequence(buf_ string) (&Event, int) {
	end := escape_end(buf_)
	single := buf_[..end] // read until the end of the sequence
	buf := single[1..] // skip the escape character

	if buf.len == 0 {
		return &Event{
			typ: .key_down
			ascii: 27
			code: .escape
			utf8: single
		}, 1
	}
	// ----------------------------
	//   Special key combinations
	// ----------------------------

	mut code := KeyCode.null
	match buf {
		'[A', 'OA' { code = .up }
		'[B', 'OB' { code = .down }
		'[C', 'OC' { code = .right }
		'[D', 'OD' { code = .left }
		'[5~', '[[5~' { code = .page_up }
		'[6~', '[[6~' { code = .page_down }
		'[F', 'OF', '[4~', '[[8~' { code = .end }
		'[H', 'OH', '[1~', '[[7~' { code = .home }
		'[2~' { code = .insert }
		'[3~' { code = .delete }
		'OP', '[11~' { code = .f1 }
		'OQ', '[12~' { code = .f2 }
		'OR', '[13~' { code = .f3 }
		'OS', '[14~' { code = .f4 }
		'[15~' { code = .f5 }
		'[17~' { code = .f6 }
		'[18~' { code = .f7 }
		'[19~' { code = .f8 }
		'[20~' { code = .f9 }
		'[21~' { code = .f10 }
		'[23~' { code = .f11 }
		'[24~' { code = .f12 }
		else {}
	}

	if buf.len == 5 && buf[0] == `[` && buf[1].is_digit() && buf[2] == `;` {
		if buf[1] == `1` {
			match buf[4] {
				`A` { code = KeyCode.up }
				`B` { code = KeyCode.down }
				`C` { code = KeyCode.right }
				`D` { code = KeyCode.left }
				`F` { code = KeyCode.end }
				`H` { code = KeyCode.home }
				`P` { code = KeyCode.f1 }
				`Q` { code = KeyCode.f2 }
				`R` { code = KeyCode.f3 }
				`S` { code = KeyCode.f4 }
				else {}
			}
		} else if buf[1] == `5` {
			code = KeyCode.page_up
		} else if buf[1] == `6` {
			code = KeyCode.page_down
		}
	}

	return &Event{
		typ: .key_down
		code: code
		utf8: single
	}, end
}

pub fn (mut ctx Context) run(ch chan Event) ? {
	ctx.termios_loop(ch)
}

pub fn init(cfg EventConfig) &Context {
	mut ctx := &Context{
		cfg: cfg
	}
	ctx.read_buf = []byte{cap: cfg.buffer_size}
	return ctx
}

[inline]
fn (ctx &Context) init() {
	if ctx.cfg.init_fn != voidptr(0) {
		ctx.cfg.init_fn(ctx.cfg.user_data)
	}
}

[inline]
fn (ctx &Context) event(event &Event, ch chan Event) {
	if ctx.cfg.event_fn != voidptr(0) {
		ctx.cfg.event_fn(event, ctx.cfg.user_data, ch)
	}
}

fn event(e &Event, x voidptr, ch chan Event) {
	ch.try_push(event)
	if e.typ == .key_down && e.code == .escape {
		exit(0)
	}
}
