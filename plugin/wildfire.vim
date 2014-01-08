" =============================================================================
" File: wildfire.vim
" Description: Fast selection of the closest text object delimited any of ', ", ), ] or }
" Mantainer: Giacomo Comitti (https://github.com/gcmt)
" Url: https://github.com/gcmt/wildfire.vim
" License: MIT
" =============================================================================


" INIT
" =============================================================================

if exists("g:loaded_wildfire") || &cp
    finish
endif
let g:loaded_wildfire = 1


let g:wildfire_fuel_map =
    \ get(g:, "wildfire_fuel_map", "<ENTER>")

let g:wildfire_water_map =
    \ get(g:, "wildfire_water_map", "<BS>")


" FUNCTIONS
" =============================================================================

" variables that provide some sort of statefulness between function calls
let s:candidates = {}
let s:winners_history = []
let s:origin = []


fu! s:Wildfire(burning, water, repeat)

    if !a:burning || empty(s:origin)
        " init
        let s:origin = getpos(".")
        let s:candidates = {'"': 1, "'": 1, ")": 1, "]": 1, "}": 1}
        let s:winners_history = []
    endif

    cal setpos(".", s:origin)

    if a:water
        if len(s:winners_history) > 1
            let exwinner = remove(s:winners_history, -1)
            let s:candidates[strpart(exwinner[0], len(exwinner[0])-1, 1)] -= 1
            exe "norm! \<ESC>" . get(s:winners_history, -1)[0]
        endif
        return
    endif

    let winview = winsaveview()
    let [curline, curcol] = [s:origin[1], s:origin[2]]

    for i in range(1, a:repeat)

        exe "norm! \<ESC>"
        cal setpos(".", s:origin)

        let performances = {}
        for candidate in keys(s:candidates)

            let selection = "v" . s:candidates[candidate] . "i" . candidate
            exe "norm! v\<ESC>" . selection . "\<ESC>"
            let [startline, startcol] = [line("'<"), col("'<")]
            let [endline, endcol] = [line("'>"), col("'>")]

            if startline == endline
                if startcol != endcol && curcol >= startcol && curcol <= endcol
                    let size = strlen(strpart(getline("'<"), startcol, endcol-startcol+1))
                    let cond1 = !s:already_a_winner("v".(s:candidates[candidate]-1)."i".candidate, size-2)
                    let cond2 = !s:already_a_winner(selection, size)
                    if cond1 && cond2
                        let performances[size] = selection
                    endif
                endif
            endif

            cal winrestview(winview)

        endfor

        if len(performances)
            let minsize = min(keys(performances))
            let winner = performances[minsize]
            let s:winners_history = add(s:winners_history, [winner, minsize])
            let s:candidates[strpart(winner, len(winner)-1, 1)] += 1
            exe "norm! \<ESC>" . winner
        elseif len(s:winners_history)
            exe "norm! \<ESC>" . get(s:winners_history, -1)[0]
        endif

    endfor

endfu

fu! s:already_a_winner(selection, size)
    for winner in s:winners_history
        if winner[0] == a:selection && winner[1] == a:size
            return 1
        endif
    endfor
    return 0
endfu


" COMMANDS & MAPPINGS
" =============================================================================

command! -nargs=0 -range WildfireStart call s:Wildfire(0, 0, <line2> - <line1> + 1)
command! -nargs=0 -range WildfireFuel call s:Wildfire(1, 0, 1)
command! -nargs=0 -range WildfireWater call s:Wildfire(1, 1, 1)

exec "nnoremap <silent> " . g:wildfire_fuel_map . " :WildfireStart<CR>"
exec "vnoremap <silent> " . g:wildfire_fuel_map . " :WildfireFuel<CR>"
exec "vnoremap <silent> " . g:wildfire_water_map . " :WildfireWater<CR>"
