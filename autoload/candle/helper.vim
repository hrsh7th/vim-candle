let s:Job = vital#candle#import('VS.System.Job')

"
" candle#helper#foreach
"
function! candle#helper#foreach(items, ctx) abort
  let l:ctx = {}
  let l:ctx.items = a:items
  let l:ctx.on_item = get(a:ctx, 'on_item', { -> {} })
  let l:ctx.on_done = get(a:ctx, 'on_done', { -> {} })
  let l:ctx.index = 0
  let l:ctx.timer = 0
  function! l:ctx.callback() abort
    let l:index = self.index
    let self.index = min([l:index + 100, len(self.items) - 1])
    call map(self.items[l:index : self.index], 'self.on_item(v:val)')
    if self.index < len(self.items) - 1
      let self.timer = timer_start(10, { -> self.callback() })
    else
      call self.on_done()
    endif
  endfunction
  call l:ctx.callback()
  return { -> timer_stop(l:ctx.timer) }
endfunction

"
" candle#helper#process
"
function! candle#helper#process(command, ctx) abort
  let l:ctx = {}
  let l:ctx.on_item = get(a:ctx, 'on_item', { -> {} })
  let l:ctx.on_done = get(a:ctx, 'on_done', { -> {} })
  let l:ctx.job = s:Job.new()
  let l:ctx.job.on_stdout({ data -> add(l:ctx.lines, data) })
  let l:ctx.job.start({ 'cmd': a:command })
  let l:ctx.lines = []
  let l:ctx.timer = timer_start(10, { -> l:ctx.callback() }, { 'repeat': -1 })
  function! l:ctx.callback() abort
    if empty(self.lines) && !self.job.is_running()
      call timer_stop(self.timer)
      call self.on_done()
      return
    endif
    if !empty(self.lines)
      call map(remove(self.lines, 0, min([100, len(self.lines) - 1])), 'self.on_item(v:val)')
    endif
  endfunction
  return { -> [l:ctx.job.stop(), timer_stop(l:ctx.timer)] }
endfunction

