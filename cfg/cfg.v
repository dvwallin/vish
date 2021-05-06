module cfg

import os

const config_file = [os.home_dir(), '.vlshrc'].join('/')

pub struct Cfg {
	pub mut:
	paths     []string
	aliases   map[string]string
	style     map[string][]int
}

pub fn get() ?Cfg {
	mut cfg := Cfg{}
	config_file_data := os.read_lines(config_file) or {
		return error('could not read from $config_file')
	}
	cfg.extract_aliases(config_file_data)
	cfg.extract_paths(config_file_data) or {
		return err
	}
	cfg.extract_style(config_file_data) or {
		return err
	}

	return cfg
}

pub fn paths() ?[]string {
	cfg := get() or {
		return error('could not get paths from $config_file')
	}
	return cfg.paths
}

pub fn aliases() ?map[string]string {
	cfg := get() or {
		return error('could not get aliases from $config_file')
	}
	return cfg.aliases
}

pub fn style() ?map[string][]int {
	cfg := get() or {
		return error('could not get style from $config_file')
	}
	return cfg.style
}

fn (mut cfg Cfg) extract_style(cfd []string) ? {
	for ent in cfd {
		if ent == '' {
			continue
		}
		if ent[0..5].trim_space() == 'style' {
			split_style := ent.trim_space().split('=')
			if split_style.len < 2 {
				return error('style wasn\'t formatted correctly: $ent')
			}
			rgb_split := split_style[1].trim_space().split(',')
			if rgb_split.len != 3 {
				return error('not correct rgb definition: $ent')
			}

			mut style_int_slice := []int{}
			for v in rgb_split {
				style_int_slice << v.int()
			}
			cfg.style[split_style[0]] = style_int_slice
		}
	}
	mut default := map[string][]int{}
	default['style_git_bg'] = [44,59,71]
	default['style_git_fg'] = [251,255,234]
	default['style_debug_bg'] = [44,59,71]
	default['style_debug_fg'] = [251,255,234]

	for k, v in default {
		if k !in cfg.style {
			cfg.style[k] << v
		}
	}

}

fn (mut cfg Cfg) extract_aliases(cfd []string) {
	for ent in cfd {
		if ent == '' {
			continue
		}
		if ent[0..5].trim_space() == 'alias' {
			split_alias := ent.replace('alias', '').trim_space().split('=')
			cfg.aliases[split_alias[0]] = split_alias[1]
		}
	}
}

fn (mut cfg Cfg) extract_paths(cfd []string) ? {
	for ent in cfd {
		if ent == '' {
			continue
		}
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
