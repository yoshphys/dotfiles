#!/usr/bin/env nu

# Place the following YAML files in $XDG_DATA_HOME/skk/ before running:
#   SKK-JISYO.L.yaml, SKK-JISYO.jinmei.yaml  (from skk-dict/jisyo)
#   SKK-JISYO.julia-latex.yaml, SKK-JISYO.julia-emoji.yaml  (from skk-jisyo-julia-unicode)

const JISYO_FILES = [
    "SKK-JISYO.L.yaml"
    "SKK-JISYO.julia-latex.yaml"
    "SKK-JISYO.geo.yaml"
    "SKK-JISYO.station.yaml"
    "SKK-JISYO.jinmei.yaml"
    "SKK-JISYO.fullname.yaml"
    "SKK-JISYO.propernoun.yaml"
    "SKK-JISYO.emoji.yaml"
    "SKK-JISYO.edict.yaml"
    "SKK-JISYO.pinyin.yaml"
    "SKK-JISYO.china_taiwan.yaml"
]

def yaml-to-skk [data: record] {
    let okuri_ari = try {
        $data.okuri_ari | transpose yomi candidates | each {|e|
            $"($e.yomi) /($e.candidates | str join '/')/"
        }
    } catch { [] }

    let okuri_nasi = try {
        $data.okuri_nasi | transpose yomi candidates | each {|e|
            $"($e.yomi) /($e.candidates | str join '/')/"
        }
    } catch { [] }

    [
        ";; -*- coding: utf-8 -*-"
        ";; okuri-ari entries."
        ...$okuri_ari
        ";; okuri-nasi entries."
        ...$okuri_nasi
    ] | str join "\n"
}

def main [] {
    let skk_dir = $env.XDG_DATA_HOME | path join "skk"
    let output = $skk_dir | path join "dictionary.yaskkserv2"
    let tmp_dir = (mktemp -d | str trim)

    let skk_files = $JISYO_FILES | each {|f|
        let src = $skk_dir | path join $f
        let dst = $tmp_dir | path join ($f | str replace ".yaml" "")
        print $"Converting ($f)..."
        yaml-to-skk (open $src) | save --force $dst
        $dst
    }

    print "Building yaskkserv2 dictionary..."
    run-external "yaskkserv2_make_dictionary" "--utf8" "--dictionary-filename" $output ...$skk_files

    rm -rf $tmp_dir
    print $"Done: ($output)"
}
