let s:root_dir = resolve(expand('<sfile>:p:h:h:h'))

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
  \ ) . (l:platform.os ==# 'windows' ? '.exe' : '')
endfunction

"
" candle#install#get_binary_path
"
function! candle#install#get_binary_path() abort
  let l:platform = candle#install#get_platform()
  return printf('%s/bin/candle-server/candle-server_%s_%s_%s',
  \   s:root_dir,
  \   l:platform.os,
  \   l:platform.arch,
  \   candle#version(),
  \ ) . (l:platform.os ==# 'windows' ? '.exe' : '')
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
      let l:arch = 'amd64'
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
function! s:download(download_path, binary_path) abort
  if !candle#yesno(['You have no binary.', 'Download?'])
    throw 'Cancel.'
  endif

  call mkdir(fnamemodify(a:binary_path, ':p:h'), 'p')

  if executable('curl')
    call candle#echo(printf('Downloading binary from %s (using curl)', a:download_path))
    echomsg system(printf('curl -L %s > %s', shellescape(a:download_path), shellescape(a:binary_path)))
  elseif executable('wget')
    call candle#echo(printf('Downloading binary from %s (using wget)', a:download_path))
    echomsg system(printf('wget -O - %s > %s', shellescape(a:download_path), shellescape(a:binary_path)))
  elseif has('win32') || has('win64')
    try
      let l:saved_shell = &shell
      let l:saved_shellcmdflag = &shellcmdflag
      set shell=powershell
      set shellcmdflag=-c
      call candle#echo(printf('Downloading binary from %s (using powershell)', a:download_path))
      echomsg system(printf('iwr -outf %s %s', shellescape(a:binary_path), shellescape(a:download_path)))
    finally
      let &shell = l:saved_shell
      let &shellcmdflag = l:saved_shellcmdflag
    endtry
  endif

  if executable('chmod')
    echomsg system(printf('chmod 700 %s', shellescape(a:binary_path)))
  endif

  if !filereadable(a:binary_path)
    throw 'Can''t download binary. Please create new issue.'
  endif
endfunction

