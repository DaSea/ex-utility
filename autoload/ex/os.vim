" ex#os#is {{{1
" name: osx, windows, linux
function ex#os#is( name )
    if a:name ==# 'osx'
        return has('macunix')
    elseif a:name ==# 'windows'
        return  (has('win16') || has('win32') || has('win64'))
    elseif a:name ==# 'linux'
        return has('unix') && !has('macunix') && !has('win32unix')
    else
        call ex#warning( 'Invalide name ' . a:name . ", Please use 'osx', 'windows' or 'linux'" )
    endif

    return 0
endfunction
"}}}

" ex#os#open {{{1
function ex#os#open(path)
    if ex#os#is('osx')
        silent exec '!open ' . a:path
        call ex#hint('open ' . a:path)
    elseif ex#os#is('windows')
        let winpath = ex#path#translate(a:path,'windows')
        silent exec '!explorer /e,/select,' . winpath
        call ex#hint('explorer ' . winpath)
    else
        if executable("nautilus")
            call system('nautilus --select ' . a:path)
        elseif executable("dolphin")
            call system('dolphin --select' . a:path)
        elseif executable("dde-file-manager")
            call system('dde-file-manager -d --show-item ' . a:path)
        else
            call ex#warning( 'File borwser not support in Linux' )
        endif
endfunction
"}}}

" Judge operation system {{{
function! ex#os#is_windows() abort "{{{
    return  (has('win16') || has('win32') || has('win64'))
endfunction "}}}
function! ex#os#is_linux() abort "{{{
    return has('unix') && !has('macunix') && !has('win32unix')
endfunction "}}}
function! ex#os#is_osx() abort "{{{
    return has("macunix")
endfunction "}}}
function! ex#os#is_mingw() abort "{{{
    return has("win32unix")
endfunction "}}}
"}}}

" create dir{{{
" path: A:/c/d/e/ 或 /c/d/e/ 目录名
function! ex#os#new_folder(path) abort "{{{
    if isdirectory(a:path)
        return
    endif

    call mkdir(a:path, "p")
endfunction "}}}
"}}}

" delete folder {{{
function! ex#os#del_folder(path) abort
    if isdirectory(a:path)
        let rmcmd = ""
        let rmPath = ex#path#auto_translate(a:path)
        if ex#os#is_windows()
            let rmcmd = 'rd /s /q ' . rmPath
        else
            let rmcmd = 'rm -rf ' . rmPath
        endif
        call system(rmcmd)
    endif
endfunction " }}}

" create file {{{
function! ex#os#new_file(path) abort "{{{
    " Don't open again if current buffer is the file to be opened
    if fnamemodify(expand('%'),':p') != fnamemodify(a:path,':p')
        silent exec 'e '.a:path
    endif
endfunction "}}}
"}}}

" vim:ts=4:sw=4:sts=4 et fdm=marker:
