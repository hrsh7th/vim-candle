let s:dirname = expand('<sfile>:p:h')

"
" candle#source#grep#source#definition
"
function! candle#source#grep#source#definition() abort
  return {
        \   'name': 'grep',
        \   'create': function('s:create', ['grep'])
        \ }
endfunction

"
" create
"
function! s:create(name, args) abort
  if strlen(a:args.pattern) == 0
    throw '[grep] `pattern` is required.'
  endif

  return {
  \   'name': a:name,
  \   'script': {
  \     'path': s:dirname . '/source.go',
  \     'args': {
  \       'root_path': get(a:args, 'root_path', getcwd()),
  \       'pattern': get(a:args, 'pattern', ''),
  \       'command': get(a:args, 'command', s:default_command()),
  \     }
  \   },
  \   'action': {
  \     'default': 'edit'
  \   }
  \ }
endfunction

"
" default_command
"
function! s:default_command() abort
  if executable('rg')
    return ['rg', '-i', '--vimgrep', '--no-heading', '%PATTERN%', '%ROOT_PATH%']
  endif
  if executable('ag')
    return ['ag', '-i', '--vimgrep', '%PATTERN%', '%ROOT_PATH%']
  endif
  if executable('pt')
    return ['pt', '-i', '--nogroup', '--nocolor', '%PATTERN%', '%ROOT_PATH%']
  endif
  if executable('jvgrep')
    return ['jvgrep', '-iR', '%PATTERN%', '%ROOT_PATH%']
  endif
  return ['grep', '-rin', '%PATTERN%', '%ROOT_PATH%']
endfunction

