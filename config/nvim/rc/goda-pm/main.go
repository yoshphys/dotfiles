import (
	"context"
	"path/filepath"

	"github.com/Shougo/goda-pm-ext-lazy.vim/ext/lazy"
	"github.com/Shougo/goda-pm-ext/ext/installer"
	"github.com/Shougo/goda-pm-ext/ext/protocol/git"
	"github.com/Shougo/goda-pm-ext/ext/toml"
	"github.com/Shougo/goda-pm.vim/pm"
)

func main() {
	b := pm.New()
	b.AddProtocol(git.New())
	b.AddExt(installer.New())
	b.SetConfig(config)
	b.Main()
}

func config(ctx context.Context, c *pm.ConfigArgs) (*pm.ConfigReturn, error) {
	c.Options.InlineVimrcs = []string{"$BASE_DIR/options.rc.vim"}
	c.Options.Protocols = []string{"git"}
	c.Options.ExtParams["installer"] = pm.Params{
		"checkDiff":     true,
	  "logFilePath":   "$GODA_PM_CACHE_PATH/installer-log.txt",
		"minCommitDays": 1,
	}

	var plugins []pm.Plugin
	for _, f := range []struct {
		path    string
		options pm.Plugin
	}{
		{"$VIM_CONFIG_PATH/toml/dpp.toml", pm.Plugin{"lazy": false}},
		{"$VIM_CONFIG_PATH/toml/lazy.toml", pm.Plugin{"lazy": true}},
		{"$VIM_CONFIG_PATH/toml/goda.toml", pm.Plugin{"lazy": true, "depends": "goda.vim"}},
	} {
		t, err := toml.Load(ctx, c.Host, f.path, f.options)
		if err != nil {
			return nil, err
		}
		plugins = append(plugins, t.Plugins...)
	}

	r, err := lazy.MakeState(ctx, c.Host, plugins)
	if err != nil {
		return nil, err
	}

	baseDir, err := c.Expand(ctx, "$VIM_CONFIG_PATH")
	if err != nil {
		return nil, err
	}
	checkFiles, err := filepath.Glob(filepath.Join(baseDir, "*"))
	if err != nil {
		return nil, err
	}

	return &pm.ConfigReturn{
		CheckFiles: checkFiles,
		Plugins:    r.Plugins,
		StateLines: r.StateLines,
	}, nil
}
