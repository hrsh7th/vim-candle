let s:root_dir = expand('<sfile>:p:h:h')

let s:download_path = 'https://github.com/hrsh7th/vim-candle/releases/download/%s/candle-server_%s_%s'

"
" candle#install#do
"
function! candle#install#do() abort
  if !filereadable(candle#install#get_binary_path())
    call s:download(
    \   candle#install#get_download_path(),
    \   candle#install#get_binary_path(),
    \ )
  endif
endfunction

"
" candle#install#get_download_path
"
function! candle#install#get_download_path() abort
  let l:platform = candle#install#get_platform()
  return printf(s:download_path,
  \   candle#version(),
  \   l:platform.os,
  \   l:platform.arch
  \ )
endfunction

"
" candle#install#get_binary_path
"
function! candle#install#get_binary_path() abort
  let l:platform = candle#install#get_platform()
  return printf('%s/bin/candle/candle-server_%s_%s_%s',
  \   s:root_dir,
  \   l:platform.os,
  \   l:platform.arch,
  \   candle#version(),
  \ )
endfunction

"
" candle#install#get_platform
"
function! candle#install#get_platform() abort
  if has('linux')
    let l:os = 'linux'
    if trim(system('uname -m')) ==# 'x86_64'
      let l:arch = 'amd64'
    else
      let l:arch = '386'
    endif
  elseif has('mac')
    let l:os = 'darwin'
    if trim(system('uname -m')) ==# 'x86_64'
      let l:arch = 'adm64'
    else
      let l:arch = '386'
    endif
  elseif has('win32')
    let l:os = 'windows'
    let l:arch = '386'
  elseif has('win64')
    let l:os = 'windows'
    let l:arch = 'amd64'
  endif

  return {
  \   'os': l:os,
  \   'arch': l:arch
  \ }
endfunction

"
" download
"
function! s:download(uri, path) abort
  if executable('curl')
    call system('curl %s > %s', shellescape(a:uri), shellescape(a:path))
  endif
  if executable('wget')
    call system('wget %s > %s', shellescape(a:uri), shellescape(a:path))
  endif

  if executable('chmod')
    call system('chmod 700 %s', shellescape(a:path))
  endif
endfunction

