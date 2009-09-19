set tags+=~/luatags

" Vim file type plug-in
" Language: Lua 5.1
" Maintainer: Peter Odding <xolox@home.nl>
" Last Change: 2008/08/20
" URL: http://xolox.ath.cx/vim/ftplugin/lua.vim
" License:	Pick your favorite from the Vim and Lua licenses

if exists('b:did_ftplugin')
 finish
else
 let b:did_ftplugin = 1
endif

" Plug-in configuration defaults {{{1

" Check the syntax of Lua scripts when they are saved? This assumes that 'luac'
" is in your $PATH or you have set the global 'lua_compiler_name' to an
" appropriate path. If what you're writing isn't plain Lua source code (e.g.
" your using token filters) then this probably won't work unless you have a
" wrapper for 'luac' that first transforms the source code to plain Lua.

if !exists('lua_check_syntax')
 let lua_check_syntax = 1
endif

" The name of the Lua compiler used to check for syntax errors. You shouldn't
" need to change this unless the Lua compiler isn't in your $PATH or the caveat
" above about token filters applies to you.

if !exists('lua_compiler_name')
 let lua_compiler_name = 'luac'
endif

" The format of error messages produced by the Lua compiler. You shouldn't need
" to change this unless I haven't updated this plug-in since 'luac' changed its
" error message format :) or you've set 'lua_compiler_name' yourself and the
" error messages printed by that program don't match those of 'luac'.

if !exists('lua_error_format')
 let lua_error_format = 'luac: %f:%l: %m'
endif

" Whether to complete keywords using <C-x><C-u>

if !exists('lua_complete_keywords')
 let lua_complete_keywords = 1
endif

" Whether to complete global variables using <C-x><C-u>

if !exists('lua_complete_globals')
 let lua_complete_globals = 1
endif

" Whether to complete library members using <C-x><C-u>

if !exists('lua_complete_library')
 let lua_complete_library = 1
endif

" Whether to complete automatically when typing the '.' operator in insert
" mode. This doesn't work quite like I want it to (yet), which is why it's
" disabled by default.

if !exists('lua_complete_dynamic')
 let lua_complete_dynamic = 0
endif

" }}}

" List of commands to undo buffer local changes made by this file type plug-in
let s:undo_ftplugin = []

" Comment (formatting) related options
setlocal fo-=t fo+=c fo+=r fo+=o fo+=q fo+=l
setlocal cms=--%s com=s:--[[,m:\ ,e:]],:--
call add(s:undo_ftplugin, 'setlocal fo< cms< com<')

" Teaching Vim to follow dofile(), loadfile() and require() calls
let &l:include = '\v<((do|load)file|require)[^''"]*[''"]\zs[^''"]+'
let &l:includeexpr = 'LuaIncludeExpr(v:fname)'
call add(s:undo_ftplugin, 'setlocal inc< inex<')

" Completion of Lua keywords, globals and standard library identifiers
setlocal completefunc=LuaUserComplete
call add(s:undo_ftplugin, 'setlocal completefunc<')

" Filename filter for the Windows file open/save dialogs
if has('gui_win32') && !exists('b:browsefilter')
 let b:browsefilter = "Lua Files (*.lua)\t*.lua\nAll Files (*.*)\t*.*\n"
 call add(s:undo_ftplugin, 'unlet! b:browsefilter')
endif

" Automatic command that checks for syntax errors when saving buffers
augroup PluginFileTypeLua
 autocmd! BufWritePost <buffer> call s:SyntaxCheck()
 call add(s:undo_ftplugin, 'autocmd! PluginFileTypeLua BufWritePost <buffer>')
augroup END

" Mappings for context-sensitive help that use the Lua Reference for Vim
imap <buffer> <F1> <C-o>:call <Sid>Help()<Cr>
nmap <buffer> <F1>      :call <Sid>Help()<Cr>
call add(s:undo_ftplugin, 'iunmap <buffer> <F1>')
call add(s:undo_ftplugin, 'nunmap <buffer> <F1>')

" Custom text objects to navigate Lua source code
noremap <buffer> <silent> [{ m':call <Sid>JumpBlock(0)<Cr>
noremap <buffer> <silent> ]} m':call <Sid>JumpBlock(1)<Cr>
noremap <buffer> <silent> [[ m':call <Sid>JumpThisFunction(0)<Cr>
noremap <buffer> <silent> ][ m':call <Sid>JumpThisFunction(1)<Cr>
noremap <buffer> <silent> [] m':call <Sid>JumpOtherFunction(0)<Cr>
noremap <buffer> <silent> ]] m':call <Sid>JumpOtherFunction(1)<Cr>
call add(s:undo_ftplugin, 'unmap <buffer> [{')
call add(s:undo_ftplugin, 'unmap <buffer> ]}')
call add(s:undo_ftplugin, 'unmap <buffer> [[')
call add(s:undo_ftplugin, 'unmap <buffer> ][')
call add(s:undo_ftplugin, 'unmap <buffer> []')
call add(s:undo_ftplugin, 'unmap <buffer> ]]')

" Extended matching with % using the 'matchit' plug-in
if exists('loaded_matchit')
 let b:match_ignorecase = 0
 let b:match_words = 'LuaMatchWords()'
 call add(s:undo_ftplugin, 'unlet! b:match_ignorecase b:match_words b:match_skip')
endif

" Dynamic completion on typing the '.' operator
imap <buffer> <silent> <expr> . <Sid>CompleteDynamic()
call add(s:undo_ftplugin, 'iunmap <buffer> .')

" Join the commands that undo the changes to the buffer made above
call map(s:undo_ftplugin, "'execute ' . string(v:val)")
let b:undo_ftplugin = join(s:undo_ftplugin, ' | ')
unlet s:undo_ftplugin

" Finish sourcing the plug-in when it's already been sourced before
if exists('*LuaIncludeExpr')
 finish
endif

" Resolve Lua module names to absolute file paths {{{1

function LuaIncludeExpr(fname)

 " automatically get the Lua module path from $LUA_PATH or package.path.
 " this initialization is done here so that the below error message isn't
 " shown unless the user actually needs this functionality...
 if !exists('g:lua_path')
  let g:lua_path = $LUA_PATH
  if empty(g:lua_path)
   let g:lua_path = system('lua -e "io.write(package.path)"')
   if g:lua_path == '' || v:shell_error
    let error = "Lua file type plug-in: I couldn't find the module search path!"
    let error .= " If you want to resolve Lua module names then please set the"
    let error .= " global variable 'lua_path' to the value of package.path."
    echoerr error
    return
   endif
  endif
 endif

 " search the module path for matching Lua scripts
 let module = substitute(a:fname, '\.', '/', 'g')
 for path in split(g:lua_path, ';')
  let path = substitute(path, '?', module, 'g')
  if filereadable(path)
   return path
  endif
 endfor

 return a:fname

endfunction

" Check for syntax errors when saving buffers {{{1

function s:SyntaxCheck()
 if g:lua_check_syntax
  let mp_save = &makeprg
  let efm_save = &errorformat
  try
   let &makeprg = g:lua_compiler_name
   let &errorformat = g:lua_error_format
   let winnr = winnr()
   silent make -p %:p
   cwindow
   execute winnr . 'wincmd w'
  finally
   let &makeprg = mp_save
   let &errorformat = efm_save
  endtry
 endif
endfunction

" Lookup context-sensitive documentation using the Lua Reference for Vim {{{1

function s:Help()
 let isk_save = &isk
 set iskeyword+=.,:
 let e = expand('<cword>')
 let &isk = isk_save
 if e != ''
  " some extra trouble to recognize method calls on strings and file userdata
  let m = matchstr(e, '\v<(byte|char|dump|g?find|format|len|lower|g?match|rep|reverse|g?sub|upper)>')
  if m == '' || !s:LookUp('lrv-string.' . m)
   let m = matchstr(e, '\v<(close|flush|lines|read|seek|setvbuf|write)>')
   if m == '' || !s:LookUp('lrv-file:' . m)
    if !s:LookUp('lrv-' . e)
     " fall back to Vim's default behavior (not very useful IMHO :)
     help
    endif
   endif
  endif
 endif
endfunction

function s:LookUp(topic)
 let v:errmsg = ''
 silent! execute 'help' escape(a:topic, ' []*?')
 return v:errmsg !~ '^E149'
endfunction

" Support for text objects (outer block, current function, other functions) {{{1

" Note that I've decided to ignore 'do' / 'end' statements
" because the 'do' keyword is kind of overloaded in Lua...

" Jump to the start or end of a block (i.e. scope)

function s:JumpBlock(forward)
 let start = '\<\%(for\|function\|if\|repeat\|while\)\>'
 let middle = '\<\%(elseif\|else\)\>'
 let end = '\<\%(end\|until\)\>'
 let flags = a:forward ? '' : 'b'
 return searchpair(start, middle, end, flags, '!LuaTokenIsCode()')
endfunction

" Jump to the start or end of the current function

function s:JumpThisFunction(forward)
 let view = winsaveview()
 while s:JumpBlock(0)
  if expand('<cword>') == 'function'
   break
  endif
 endwhile
 if expand('<cword>') == 'function'
  if a:forward
   call s:JumpBlock(1)
  endif
  return 1
 endif
 call winrestview(view)
endfunction

" Jump to the previous/next function

function s:JumpOtherFunction(forward)
 let view = winsaveview()
 " jump to the start/end of the function
 call s:JumpThisFunction(a:forward)
 " search for the previous/next function
 while search('\<function\>', a:forward ? 'W' : 'bW')
  " ignore strings and comments containing 'function'
  if LuaTokenIsCode()
   return 1
  endif
 endwhile
 call winrestview(view)
endfunction

function LuaTokenIsCode()
 return s:GetSyntaxType(0) !~? 'string\|comment'
endfunction

function s:GetSyntaxType(transparent)
 let id = synID(line('.'), col('.'), 1)
 if a:transparent
  let id = synIDtrans(id)
 endif
 return synIDattr(id, 'name')
endfunction

" Supporting code for extended matching with % using the 'matchit' plug-in {{{1

if exists('loaded_matchit')

 " The following callback function is really pushing the 'matchit' plug-in to
 " its limits and one might wonder whether it's even worth it. Since I've
 " already written the code I'm keeping it in for the moment :)

 function LuaMatchWords()
  let cword = expand('<cword>')
  if cword == 'end'
   let s = ['function', 'if', 'for', 'while']
   let e = ['end']
   unlet! b:match_skip
  elseif cword =~ '^\(function\|return\)$'
   let s = ['function']
   let m = ['return']
   let e = ['end']
   let b:match_skip = "LuaMatchIgnore('^luaCond$')"
   let b:match_skip .= " || (expand('<cword>') == 'end' && LuaMatchIgnore('^luaStatement$'))"
  elseif cword =~ '^\(for\|in\|while\|do\|repeat\|until\|break\)$'
   let s = ['for', 'repeat', 'while']
   let m = ['break']
   let e = ['end', 'until']
   let b:match_skip = "LuaMatchIgnore('^\\(luaCond\\|luaFunction\\)$')"
  elseif cword =~ '\(if\|then\|elseif\|else\)$'
   let s = ['if']
   let m = ['elseif', 'else']
   let e = ['end']
   let b:match_skip = "LuaMatchIgnore('^\\(luaFunction\\|luaStatement\\)$')"
  else
   let s = ['for', 'function', 'if', 'repeat', 'while']
   let m = ['break', 'elseif', 'else', 'return']
   let e = ['eend', 'until']
   unlet! b:match_skip
  endif
  let p = '\<\(' . join(s, '\|') . '\)\>'
  if exists('m')
   let p .=  ':\<\(' . join(m, '\|') . '\)\>'
  endif
  return p . ':\<\(' . join(e, '\|') . '\)\>'
 endfunction

 function LuaMatchIgnore(ignored)
  let word = expand('<cword>')
  let type = s:GetSyntaxType(0)
  return type =~? a:ignored || type =~? 'string\|comment'
 endfunction

endif

" Completion of Lua keywords and identifiers from the standard libraries {{{1

function LuaUserComplete(init, base)
 if a:init
  let prefix = strpart(getline('.'), 0, col('.') - 2)
  return match(prefix, '\w\+\.\?\w*$')
 else
  let items = []
  if g:lua_complete_keywords
   call extend(items, s:keywords)
  endif
  if g:lua_complete_globals
   call extend(items, s:globals)
  endif
  if g:lua_complete_library
   call extend(items, s:library)
  endif
  let regex = string('\V' . escape(a:base, '\'))
  return filter(items, 'v:val.word =~ ' . regex)
 endif
endfunction

function s:CompleteDynamic()
 if g:lua_complete_dynamic
  if s:GetSyntaxType(1) !~? 'string\|comment\|keyword'
   let column = col('.') - 1
   " gotcha: even though '.' is remapped it counts as a column?
   if column && getline('.')[column - 1] =~ '\w'
    " this results in 'Pattern not found' when no completion items matched, which is
    " kind of annoying. But I don't know an alternative to :silent that can be used
    " inside of <expr> mappings?!
    return ".\<C-x>\<C-u>"
   endif
  endif
 endif
 return '.'
endfunction

" These lists were generated automatically by a Lua script which is
" available online at http://xolox.ath.cx/vim/ftplugin/complete.lua

" enable line continuation
let s:cpo_save = &cpo
set cpoptions-=C

let s:keywords = [
   \ { 'word': "and", 'kind': 'k' },
   \ { 'word': "break", 'kind': 'k' },
   \ { 'word': "do", 'kind': 'k' },
   \ { 'word': "else", 'kind': 'k' },
   \ { 'word': "elseif", 'kind': 'k' },
   \ { 'word': "end", 'kind': 'k' },
   \ { 'word': "false", 'kind': 'k' },
   \ { 'word': "for", 'kind': 'k' },
   \ { 'word': "function", 'kind': 'k' },
   \ { 'word': "if", 'kind': 'k' },
   \ { 'word': "in", 'kind': 'k' },
   \ { 'word': "local", 'kind': 'k' },
   \ { 'word': "nil", 'kind': 'k' },
   \ { 'word': "not", 'kind': 'k' },
   \ { 'word': "or", 'kind': 'k' },
   \ { 'word': "repeat", 'kind': 'k' },
   \ { 'word': "return", 'kind': 'k' },
   \ { 'word': "then", 'kind': 'k' },
   \ { 'word': "true", 'kind': 'k' },
   \ { 'word': "until", 'kind': 'k' },
   \ { 'word': "while", 'kind': 'k' }]

let s:globals = [
   \ { 'word': "_G", 'kind': 'v' },
   \ { 'word': "_VERSION", 'kind': 'v' },
   \ { 'word': "arg", 'kind': 'v' },
   \ { 'word': "assert", 'kind': 'f' },
   \ { 'word': "collectgarbage", 'kind': 'f' },
   \ { 'word': "coroutine", 'kind': 'v' },
   \ { 'word': "debug", 'kind': 'v' },
   \ { 'word': "dofile", 'kind': 'f' },
   \ { 'word': "error", 'kind': 'f' },
   \ { 'word': "gcinfo", 'kind': 'f' },
   \ { 'word': "getfenv", 'kind': 'f' },
   \ { 'word': "getmetatable", 'kind': 'f' },
   \ { 'word': "io", 'kind': 'v' },
   \ { 'word': "ipairs", 'kind': 'f' },
   \ { 'word': "load", 'kind': 'f' },
   \ { 'word': "loadfile", 'kind': 'f' },
   \ { 'word': "loadstring", 'kind': 'f' },
   \ { 'word': "math", 'kind': 'v' },
   \ { 'word': "module", 'kind': 'f' },
   \ { 'word': "newproxy", 'kind': 'f' },
   \ { 'word': "next", 'kind': 'f' },
   \ { 'word': "os", 'kind': 'v' },
   \ { 'word': "package", 'kind': 'v' },
   \ { 'word': "pairs", 'kind': 'f' },
   \ { 'word': "pcall", 'kind': 'f' },
   \ { 'word': "print", 'kind': 'f' },
   \ { 'word': "rawequal", 'kind': 'f' },
   \ { 'word': "rawget", 'kind': 'f' },
   \ { 'word': "rawset", 'kind': 'f' },
   \ { 'word': "require", 'kind': 'f' },
   \ { 'word': "select", 'kind': 'f' },
   \ { 'word': "setfenv", 'kind': 'f' },
   \ { 'word': "setmetatable", 'kind': 'f' },
   \ { 'word': "string", 'kind': 'v' },
   \ { 'word': "table", 'kind': 'v' },
   \ { 'word': "tonumber", 'kind': 'f' },
   \ { 'word': "tostring", 'kind': 'f' },
   \ { 'word': "type", 'kind': 'f' },
   \ { 'word': "unpack", 'kind': 'f' },
   \ { 'word': "xpcall", 'kind': 'f' }]

let s:library = [
   \ { 'word': "coroutine.create", 'kind': 'f' },
   \ { 'word': "coroutine.resume", 'kind': 'f' },
   \ { 'word': "coroutine.running", 'kind': 'f' },
   \ { 'word': "coroutine.status", 'kind': 'f' },
   \ { 'word': "coroutine.wrap", 'kind': 'f' },
   \ { 'word': "coroutine.yield", 'kind': 'f' },
   \ { 'word': "debug.debug", 'kind': 'f' },
   \ { 'word': "debug.getfenv", 'kind': 'f' },
   \ { 'word': "debug.gethook", 'kind': 'f' },
   \ { 'word': "debug.getinfo", 'kind': 'f' },
   \ { 'word': "debug.getlocal", 'kind': 'f' },
   \ { 'word': "debug.getmetatable", 'kind': 'f' },
   \ { 'word': "debug.getregistry", 'kind': 'f' },
   \ { 'word': "debug.getupvalue", 'kind': 'f' },
   \ { 'word': "debug.setfenv", 'kind': 'f' },
   \ { 'word': "debug.sethook", 'kind': 'f' },
   \ { 'word': "debug.setlocal", 'kind': 'f' },
   \ { 'word': "debug.setmetatable", 'kind': 'f' },
   \ { 'word': "debug.setupvalue", 'kind': 'f' },
   \ { 'word': "debug.traceback", 'kind': 'f' },
   \ { 'word': "io.close", 'kind': 'f' },
   \ { 'word': "io.flush", 'kind': 'f' },
   \ { 'word': "io.input", 'kind': 'f' },
   \ { 'word': "io.lines", 'kind': 'f' },
   \ { 'word': "io.open", 'kind': 'f' },
   \ { 'word': "io.output", 'kind': 'f' },
   \ { 'word': "io.popen", 'kind': 'f' },
   \ { 'word': "io.read", 'kind': 'f' },
   \ { 'word': "io.stderr", 'kind': 'm' },
   \ { 'word': "io.stdin", 'kind': 'm' },
   \ { 'word': "io.stdout", 'kind': 'm' },
   \ { 'word': "io.tmpfile", 'kind': 'f' },
   \ { 'word': "io.type", 'kind': 'f' },
   \ { 'word': "io.write", 'kind': 'f' },
   \ { 'word': "math.abs", 'kind': 'f' },
   \ { 'word': "math.acos", 'kind': 'f' },
   \ { 'word': "math.asin", 'kind': 'f' },
   \ { 'word': "math.atan", 'kind': 'f' },
   \ { 'word': "math.atan2", 'kind': 'f' },
   \ { 'word': "math.ceil", 'kind': 'f' },
   \ { 'word': "math.cos", 'kind': 'f' },
   \ { 'word': "math.cosh", 'kind': 'f' },
   \ { 'word': "math.deg", 'kind': 'f' },
   \ { 'word': "math.exp", 'kind': 'f' },
   \ { 'word': "math.floor", 'kind': 'f' },
   \ { 'word': "math.fmod", 'kind': 'f' },
   \ { 'word': "math.frexp", 'kind': 'f' },
   \ { 'word': "math.huge", 'kind': 'm' },
   \ { 'word': "math.ldexp", 'kind': 'f' },
   \ { 'word': "math.log", 'kind': 'f' },
   \ { 'word': "math.log10", 'kind': 'f' },
   \ { 'word': "math.max", 'kind': 'f' },
   \ { 'word': "math.min", 'kind': 'f' },
   \ { 'word': "math.mod", 'kind': 'f' },
   \ { 'word': "math.modf", 'kind': 'f' },
   \ { 'word': "math.pi", 'kind': 'm' },
   \ { 'word': "math.pow", 'kind': 'f' },
   \ { 'word': "math.rad", 'kind': 'f' },
   \ { 'word': "math.random", 'kind': 'f' },
   \ { 'word': "math.randomseed", 'kind': 'f' },
   \ { 'word': "math.sin", 'kind': 'f' },
   \ { 'word': "math.sinh", 'kind': 'f' },
   \ { 'word': "math.sqrt", 'kind': 'f' },
   \ { 'word': "math.tan", 'kind': 'f' },
   \ { 'word': "math.tanh", 'kind': 'f' },
   \ { 'word': "os.clock", 'kind': 'f' },
   \ { 'word': "os.date", 'kind': 'f' },
   \ { 'word': "os.difftime", 'kind': 'f' },
   \ { 'word': "os.execute", 'kind': 'f' },
   \ { 'word': "os.exit", 'kind': 'f' },
   \ { 'word': "os.getenv", 'kind': 'f' },
   \ { 'word': "os.remove", 'kind': 'f' },
   \ { 'word': "os.rename", 'kind': 'f' },
   \ { 'word': "os.setlocale", 'kind': 'f' },
   \ { 'word': "os.time", 'kind': 'f' },
   \ { 'word': "os.tmpname", 'kind': 'f' },
   \ { 'word': "package.config", 'kind': 'm' },
   \ { 'word': "package.cpath", 'kind': 'm' },
   \ { 'word': "package.loaded", 'kind': 'm' },
   \ { 'word': "package.loaders", 'kind': 'm' },
   \ { 'word': "package.loadlib", 'kind': 'f' },
   \ { 'word': "package.path", 'kind': 'm' },
   \ { 'word': "package.preload", 'kind': 'm' },
   \ { 'word': "package.seeall", 'kind': 'f' },
   \ { 'word': "string.byte", 'kind': 'f' },
   \ { 'word': "string.char", 'kind': 'f' },
   \ { 'word': "string.dump", 'kind': 'f' },
   \ { 'word': "string.find", 'kind': 'f' },
   \ { 'word': "string.format", 'kind': 'f' },
   \ { 'word': "string.gfind", 'kind': 'f' },
   \ { 'word': "string.gmatch", 'kind': 'f' },
   \ { 'word': "string.gsub", 'kind': 'f' },
   \ { 'word': "string.len", 'kind': 'f' },
   \ { 'word': "string.lower", 'kind': 'f' },
   \ { 'word': "string.match", 'kind': 'f' },
   \ { 'word': "string.rep", 'kind': 'f' },
   \ { 'word': "string.reverse", 'kind': 'f' },
   \ { 'word': "string.sub", 'kind': 'f' },
   \ { 'word': "string.upper", 'kind': 'f' },
   \ { 'word': "table.concat", 'kind': 'f' },
   \ { 'word': "table.foreach", 'kind': 'f' },
   \ { 'word': "table.foreachi", 'kind': 'f' },
   \ { 'word': "table.getn", 'kind': 'f' },
   \ { 'word': "table.insert", 'kind': 'f' },
   \ { 'word': "table.maxn", 'kind': 'f' },
   \ { 'word': "table.remove", 'kind': 'f' },
   \ { 'word': "table.setn", 'kind': 'f' },
   \ { 'word': "table.sort", 'kind': 'f' }]

" restore compatibility options
let &cpo = s:cpo_save
unlet s:cpo_save
