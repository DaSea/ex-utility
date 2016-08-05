" path: 根据不同的os对目录分割符进行操作{{{
" system: options { 'windows' 'unix' }
function ex#path#translate(path, system)
    if a:system == 'windows'
        return substitute( a:path, "\/", "\\", "g" )
    elseif a:system == 'unix'
        return substitute( a:path, "\\", "\/", "g" )
    else
        call ex#warning('unknown OS: ' . a:system)
        return a:path
    endif
endfunction
function ex#path#auto_translate(path)
    if ex#os#is_windows()
        return substitute( a:path, "\/", "\\", "g" )
    else
        return substitute( a:path, "\\", "\/", "g" )
    endif
endfunction
"}}}

" 检测路径的有效性 {{{ 
" Check the validity of path
" 1: valid; 0: invalid
function! ex#path#validity(checkPath) abort
    let ret = ""
    if ex#os#is_windows()
        let ret = matchstr(a:checkPath, '^[a-zA-Z]\{1}\:')
    else
        let ret = matchstr(a:checkPath, '^/\w\+')
    endif

    if "" == ret
        return 0
    endif

    return 1
endfunction " }}}

" 比较俩个路径是否相同 {{{
" Judge whether path1 is same as path2
function! ex#path#equal(path1, path2) abort
    if has("win16") || has("win32") || has("win64") || has("win95")
        return substitute(a:path1, "\/", "\\", "g") ==? substitute(a:path2, "\/", "\\", "g")
    else
        return a:path1 == a:path2
endfunction " }}}

" 查找一个根目录, 有可能是exvim工程目录, 有可能是.git目录, 有可能是.svn目录{{{
" Find the root path, exvim project path, or .git path, or .svn path
function! ex#path#root(path) abort
    let findDir = finddir(".exvim", a:path.";", 1)
    if "" == findDir
        let findDir = finddir(".git", a:path.";", 1)
        if "" == findDir
            let findDir = finddir(".svn", a:path.";", 1)
        endif
    endif

    if "" == findDir
        return findDir
    endif

    return fnamemodify(findDir, ":p:h:h")
endfunction " }}}

" 在filePath下面查找fileName文件 {{{
" find file in filePath
function! ex#path#find_file(filePath, fileName) abort
    if ex#os#is_windows()
        let exeCmd = "where /R " . a:filePath . " " . a:fileName
    else
        let exeCmd = "find " . a:filePath . " -name " . a:fileName
    endif

    let files = system(exeCmd)

    " If not find file, need remove error msg
    " let matchRet = matchstr(files, '^[a-zA-Z]\{1}:')
    let matchRet = ex#path#validity(files)
    if 0 == matchRet
        return []
    endif

    let filelist = []
    if ex#os#is_windows()
        let filelist = split(files, '[\x0]')
    else
        let filelist = split(fiiles, '\n')
    endif

    return filelist
endfunction " }}}

"}}}

" vim:ts=4:sw=4:sts=4 et fdm=marker:
