
" ex#buffer#navigate {{{2
" the cmd must be 'bn', 'bp', ....
function ex#buffer#navigate(cmd)
    " if we are in plugin window, go back to edit window
    if ex#window#is_plugin_window(winnr())
        call ex#window#goto_edit_window()
    endif

    try
        silent exec a:cmd."!"
    catch /E85:/
        call ex#warning( 'There is no listed buffer' )
    endtry
endfunction
" }}}

" ex#buffer#record {{{2
let s:alt_edit_bufnr = -1
let s:alt_edit_bufpos = []
function ex#buffer#record()
    let bufnr = bufnr('%')
    if buflisted(bufnr)
                \ && bufloaded(bufnr)
                \ && !ex#is_registered_plugin(bufnr('%'))
        let s:alt_edit_bufnr = bufnr
        let s:alt_edit_bufpos = getpos('.')
    endif
endfunction
" }}}

" Function : ex#buffer#find_or_create "{{{
" Purpose  :中文: 看fileName对应的buffer是否已经存在, 如果存在着打开, 否则创建
"           English: searches the buffer list (:ls) for the specified filename. If
"            found, checks the window list for the buffer. If the buffer is in
"            an already open window, it switches to the window. If the buffer
"            was not in a window, it switches to that buffer. If the buffer did
"            not exist, it creates it.
" Args     : filename (IN):文件名, the name of the file
"            doSplit (IN):窗口切割方式, indicates whether the window should be split
"                            ("v", "h", "n", "v!", "h!", "n!", "t", "t!")
"                        n, n!: edit; v, v!: vsplit; h, h!: split; t,t!: tab split
"            findSimilar (IN):是否优先判断buffer是否存在, indicate whether existing buffers should be
"                                prefered
function! ex#buffer#find_or_create(fileName, doSplit, findSimilar)
    " Check to see if the buffer is already open before re-opening it.
    let FILENAME = escape(a:fileName, ' ')
    let bufNr = -1
    let lastBuffer = bufnr("$")
    let i = 1
    if (a:findSimilar)
        while i <= lastBuffer
            if ex#path#equal(expand("#".i.":p"), a:fileName)
                let bufNr = i
                break
            endif
            let i = i + 1
        endwhile

        if (bufNr == -1)
            let bufName = bufname(a:fileName)
            let bufFilename = fnamemodify(a:fileName,":t")

            if (bufName == "")
                let bufName = bufname(bufFilename)
            endif

            if (bufName != "")
                let tail = fnamemodify(bufName, ":t")
                if (tail != bufFilename)
                    let bufName = ""
                endif
            endif
            if (bufName != "")
                let bufNr = bufnr(bufName)
                let FILENAME = bufName
            endif
        endif
    endif

    let FILENAME = fnamemodify(FILENAME, ":p:.")

    let splitType = a:doSplit[0]
    let bang = a:doSplit[1]
    if (bufNr == -1)
        " Buffer did not exist....create it
        let v:errmsg=""
        if (splitType == "h")
            silent! execute ":split".bang." " . FILENAME
        elseif (splitType == "v")
            silent! execute ":vsplit".bang." " . FILENAME
        elseif (splitType == "t")
            silent! execute ":tab split".bang." " . FILENAME
        else
            silent! execute ":e".bang." " . FILENAME
        endif
        if (v:errmsg != "")
            echo v:errmsg
        endif
    else
        " Find the correct tab corresponding to the existing buffer
        let tabNr = -1
        " iterate tab pages
        for i in range(tabpagenr('$'))
            " get the list of buffers in the tab
            let tabList =  tabpagebuflist(i + 1)
            let idx = 0
            " iterate each buffer in the list
            while idx < len(tabList)
                " if it matches the buffer we are looking for...
                if (tabList[idx] == bufNr)
                    " ... save the number
                    let tabNr = i + 1
                    break
                endif
                let idx = idx + 1
            endwhile
            if (tabNr != -1)
                break
            endif
        endfor
        " switch the the tab containing the buffer
        if (tabNr != -1)
            execute "tabn ".tabNr
        endif

        " Buffer was already open......check to see if it is in a window
        let bufWindow = bufwinnr(bufNr)
        if (bufWindow == -1)
            " Buffer was not in a window so open one
            let v:errmsg=""
            if (splitType == "h")
                silent! execute ":sbuffer".bang." " . FILENAME
            elseif (splitType == "v")
                silent! execute ":vert sbuffer " . FILENAME
            elseif (splitType == "t")
                silent! execute ":tab sbuffer " . FILENAME
            else
                silent! execute ":buffer".bang." " . FILENAME
            endif
            if (v:errmsg != "")
                echo v:errmsg
            endif
        else
            " Buffer is already in a window so switch to the window
            execute bufWindow."wincmd w"
            if (bufWindow != winnr())
                " something wierd happened...open the buffer
                let v:errmsg=""
                if (splitType == "h")
                    silent! execute ":split".bang." " . FILENAME
                elseif (splitType == "v")
                    silent! execute ":vsplit".bang." " . FILENAME
                elseif (splitType == "t")
                    silent! execute ":tab split".bang." " . FILENAME
                else
                    silent! execute ":e".bang." " . FILENAME
                endif
                if (v:errmsg != "")
                    echo v:errmsg
                endif
            endif
        endif
    endif
endfunction
"}}}

" ex#buffer#to_alternate_edit_buf() {{{2
" this function will swap current buffer with alternate buffer ('aka. #')
" it will prevent swap in plugin window, and will restore the cursor position
" after swap.
function ex#buffer#to_alternate_edit_buf()
    " check if current buffer can use swap
    if ex#window#is_plugin_window(winnr())
        call ex#warning('Swap buffer in plugin window is not allowed!')
        return
    endif

    " check if we can use alternate buffer '#' for swap
    let alt_bufnr = bufnr('#')
    if bufexists(alt_bufnr)
                \ && buflisted(alt_bufnr)
                \ && bufloaded(alt_bufnr)
                \ && !ex#is_registered_plugin(bufnr(alt_bufnr))
        " NOTE: because s:alt_edit_bufnr.'b!' will invoke BufLeave event
        " and that will overwrite s:alt_edit_bufpos
        let record_alt_bufpos = deepcopy(s:alt_edit_bufpos)
        let record_alt_bufnr = s:alt_edit_bufnr
        silent exec alt_bufnr.'b!'

        " only recover the pos when we record the write alt buffer pos
        if alt_bufnr == record_alt_bufnr
            silent call setpos('.',record_alt_bufpos)
        endif

        return
    endif

    " if we don't have alt buf, go for search next
    let cur_bufnr = bufnr('%')
    let buflistedLeft = 0
    let nBufs = bufnr('$')
    let i = cur_bufnr+1
    while i <= nBufs
        if buflisted(i)
            silent exec i.'b!'
            return
        endif
        let i = i + 1
    endwhile
    let i = 0
    while i < cur_bufnr
        if buflisted(i)
            silent exec i.'b!'
            return
        endif
        let i = i + 1
    endwhile

    call ex#warning ( "Can't swap to buffer " . fnamemodify(bufname(alt_bufnr),":p:t") . ", buffer not listed."  )
endfunction
"}}}

" ex#buffer#keep_window_bd {{{1
" Delete the buffer; keep windows; create a scratch buffer if no buffers left
" Reference: VimTip #1119: How to use Vim like an IDE
function ex#buffer#keep_window_bd()
    " don't do anything, if we are in plugin window
    if ex#window#is_plugin_window(winnr())
        call ex#warning("Can't close plugin window by <Leader>bd")
        " DISABLE:
        " silent exec 'close'
        " call ex#window#goto_edit_window()
        return
    endif

    " if this our scratch buffer, do nothing
    if !bufname('%') && &bufhidden=='delete' && &buftype=='nofile'
        return
    endif

    " if the buffer didn't saved, warning it and return
    if getbufvar('%','&mod')
        call ex#warning("Can not close: The buffer is unsaved.")
        return
    endif

    " get current buffer and window
    let bd_bufnr = bufnr('%')
    let cur_winnr = winnr()

    " count how manay buffer listed left
    let buflistedLeft = 0
    let nBufs = bufnr('$')
    let i = 1
    while i <= nBufs
        if i != bd_bufnr
            if buflisted(i)
                let buflistedLeft = buflistedLeft + 1
            endif
        endif
        let i = i + 1
    endwhile

    if !buflistedLeft
        silent exec 'enew'
        let newBuf = bufnr('%')
        set buflisted
        set bufhidden=delete
        set buftype=nofile
        setlocal noswapfile
        normal athis is the scratch buffer

        " windo if buflisted(winbufnr(0)) | execute 'b! ' . newBuf | endif
        let i = 1
        let winCounts = winnr('$')
        while i <= winCounts
            if !ex#window#is_plugin_window(i)
                exe i . 'wincmd w'
                exec 'b! ' . newBuf
            endif
            let i = i + 1
        endwhile
    else
        " search all edit window, if the window is using the buffer, try to
        " use alternate buffer
        let i = 1
        let winCounts = winnr('$')
        while i <= winCounts
            if !ex#window#is_plugin_window(i)
                if winbufnr(i) == bd_bufnr
                    exe i . 'wincmd w'
                    let prevbufvar = bufnr('#')
                    if prevbufvar > 0 && buflisted(prevbufvar) && prevbufvar != bd_bufnr
                        b #
                    else
                        bn
                    endif
                endif
            endif
            let i = i + 1
        endwhile
    endif
    exe cur_winnr . 'wincmd w'

    " now delete the bd_bufnr
    execute 'bd! ' . bd_bufnr
endfunction
" }}}

" 中文:在文件末尾添加modeline {{{
" English: add modeline to buffer end
function! ex#buffer#add_mode_line() abort
    let l:modeline = printf("vim: set ts=%d sw=%d tw=%d:",
                \ &tabstop, &shiftwidth, &textwidth)
    let l:modeline = substitute(&commentstring, "%s", l:modeline, "")
    call append(line('$'), l:modeline)
endfunction
"}}}

" vim:ts=4:sw=4:sts=4 et fdm=marker:
