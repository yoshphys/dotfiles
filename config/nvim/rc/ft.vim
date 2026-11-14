" Plugin-independent per-filetype settings. Parsed by goda-pm's hooks_file
" mechanism: each block below becomes an [ftplugin] entry for that
" filetype (sourced automatically via Vim's own ftplugin on FileType),
" not something this file runs itself. See `:help goda-pm-plugin-option-ftplugin`.

" julia {{{
setlocal shiftwidth=4 softtabstop=4
" }}}

" python {{{
" PEP8
setlocal shiftwidth=4 softtabstop=4
" }}}

" go {{{
" gofmt always rewrites to tabs, so stay in tabs to avoid noisy diffs.
setlocal noexpandtab tabstop=4 shiftwidth=4
" }}}

" rust {{{
" rustfmt's default.
setlocal shiftwidth=4 softtabstop=4
" }}}
