package main

import (
	"context"
	"path/filepath"

	"github.com/Shougo/goda-pm-ext-lazy.vim/ext/lazy"
	"github.com/Shougo/goda-pm-ext/ext/installer"
	"github.com/Shougo/goda-pm-ext/ext/local"
	"github.com/Shougo/goda-pm-ext/ext/protocol/git"
	// "github.com/Shougo/goda-pm-ext/ext/protocol/http"
	"github.com/Shougo/goda-pm-ext/ext/toml"
	"github.com/Shougo/goda-pm.vim/pm"
)

func main() {
	b := pm.New()
	b.AddProtocol(git.New())
	// b.AddProtocol(http.New())
	b.AddExt(installer.New())
	b.SetConfig(config)
	b.Main()
}

func config(ctx context.Context, c *pm.ConfigArgs) (*pm.ConfigReturn, error) {
	hasNvim := c.IsNvim()
	hasWindows, err := c.Has(ctx, "win32")
	if err != nil {
		return nil, err
	}
	hasGui, err := c.Has(ctx, "gui_running")
	if err != nil {
		return nil, err
	}

	c.Options.InlineVimrcs = []string{
		"$VIM_CONFIG_PATH/rc/options.rc.vim",
	}
	if hasNvim {
		c.Options.InlineVimrcs = append(
			c.Options.InlineVimrcs,
			"$VIM_CONFIG_PATH/rc/neovim.rc.lua",
		)
	}
	if !hasNvim && hasGui {
		// c.Options.InlineVimrcs = append(
		// 	c.Options.InlineVimrcs,
		// 	"$VIM_CONFIG_PATH/rc/gui.rc.vim",
		// )
	}
	if hasWindows {
		// c.Options.InlineVimrcs = append(
		// 	c.Options.InlineVimrcs,
		// 	"$VIM_CONFIG_PATH/rc/windows.rc.vim",
		// )
	} else {
		c.Options.InlineVimrcs = append(
			c.Options.InlineVimrcs,
			"$VIM_CONFIG_PATH/rc/unix.rc.vim",
		)
	}
	c.Options.ExtParams["installer"] = pm.Params{
		"checkDiff":     true,
		"logFilePath":   "$GODA_PM_CACHE_PATH/installer-log.txt",
		"minCommitDays": 1,
	}
	c.Options.Protocols = []string{
		"git",
		// "http",
	}

	// The plugins by name: a later one replaces an earlier one.
	recordPlugins := map[string]pm.Plugin{}
	var names []string
	record := func(p pm.Plugin) {
		if _, ok := recordPlugins[p.Name()]; !ok {
			names = append(names, p.Name())
		}
		recordPlugins[p.Name()] = p
	}
	ftplugins := map[string]string{}
	var hooksFiles []string
	var multipleHooks []pm.MultipleHook

	vimTomlFile := "$VIM_CONFIG_PATH/rc/vim.toml"
	if hasNvim {
		vimTomlFile = "$VIM_CONFIG_PATH/rc/neovim.toml"
	}
	for _, f := range []struct {
		path    string
		options pm.Plugin
	}{
		{
			"$VIM_CONFIG_PATH/rc/merge.toml",
			pm.Plugin{"lazy": false},
		},
		{
			"$VIM_CONFIG_PATH/rc/lazy.toml",
			pm.Plugin{"lazy": true},
		},
		{
			"$VIM_CONFIG_PATH/rc/ddc.toml",
			pm.Plugin{"lazy": true},
		},
		{
			"$VIM_CONFIG_PATH/rc/ddu.toml",
			pm.Plugin{"lazy": true},
		},
		{
			"$VIM_CONFIG_PATH/rc/goda.toml",
			pm.Plugin{"lazy": true, "depends": "goda.vim"},
		},
		{
			vimTomlFile,
			pm.Plugin{"lazy": true},
		},
	} {
		t, err := toml.Load(ctx, c.Host, f.path, f.options)
		if err != nil {
			return nil, err
		}
		for _, p := range t.Plugins {
			record(p)
		}
		pm.MergeFtplugins(ftplugins, t.Ftplugins)
		multipleHooks = append(multipleHooks, t.MultipleHooks...)
		if t.HooksFile != "" {
			hooksFiles = append(hooksFiles, t.HooksFile)
		}
	}

	// The plugins in ~/work are used from there, instead of those of the
	// TOML files of the same name.
	localPlugins, err := local.Load(
		ctx,
		c.Host,
		"~/ghq/github.com/yoshphys",
		pm.Plugin{"frozen": true, "merged": false},
		[]string{"*.nvim", "*.vim", "nvim-*", "vim*"},
	)
	if err != nil {
		return nil, err
	}
	for _, p := range localPlugins {
		if old, ok := recordPlugins[p.Name()]; ok {
			url, err := c.URL(ctx, "git", old)
			if err != nil {
				return nil, err
			}
			p = pm.Merge(old, p, pm.Plugin{"url": url})
		}
		record(p)
	}

	plugins := make([]pm.Plugin, 0, len(names))
	for _, n := range names {
		plugins = append(plugins, recordPlugins[n])
	}
	lazyResult, err := lazy.MakeState(ctx, c.Host, plugins)
	if err != nil {
		return nil, err
	}

	baseDir, err := c.Expand(ctx, "$VIM_CONFIG_PATH/rc")
	if err != nil {
		return nil, err
	}
	checkFiles, err := filepath.Glob(filepath.Join(baseDir, "*"))
	if err != nil {
		return nil, err
	}

	return &pm.ConfigReturn{
		CheckFiles:    checkFiles,
		Ftplugins:     ftplugins,
		HooksFiles:    hooksFiles,
		MultipleHooks: multipleHooks,
		Plugins:       lazyResult.Plugins,
		StateLines:    lazyResult.StateLines,
	}, nil
}
