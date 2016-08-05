" 按splitChar分割字符串, 并获取第index个子串 {{{
" Split str by splitChar, and return the index number
function! ex#string#sub_by_index(str, splitChar, index) abort
    let itemStart = 0
    let itemEnd = -1
    let pos = 0
    let item = ""
    let i = 0
    while (i != a:index)
        let itemStart = itemEnd + 1
        let itemEnd = match(a:str, a:splitChar, itemStart)
        let i = i + 1
        if (itemEnd == -1)
            if (i == a:index)
                let itemEnd = strlen(a:str)
            endif
            break
        endif
    endwhile
    if (itemEnd != -1)
        let item = strpart(a:str, itemStart, itemEnd - itemStart)
    endif
    return item
endfunction " }}}
