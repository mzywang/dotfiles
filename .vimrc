" Use spaces instead of tabs
set expandtab

" Set the number of spaces for each indentation level
set shiftwidth=4

" Set the number of spaces for a tab character
set tabstop=4

" Set the number of spaces for a tab in insert mode
set softtabstop=4

" Enable auto-indentation
set autoindent

" Enable smart indentation (context-aware)
set smartindent

" Show absolute and relative line numbers
set number
set relativenumber

command! CopyRelPath let @+ = expand('%')

" eng_log: date header (# YYYYMMDD)
inoremap <expr> ,,d '# ' .. strftime('%Y%m%d')

" eng_log: time entry ( - HHMM: )
function! EngLogTime() abort
  let lnum = line('.')
  call setline(lnum, ' - ' .. strftime('%H%M') .. ': ')
  call cursor(lnum, col('$'))
  startinsert!
endfunction
inoremap ,,t <Esc>:call EngLogTime()<CR>
