' https://github.com/AlanPBourke/trse-scroller/blob/main/x_scroll.ras
include "consts.bas"
include "funcs.bas"

const start_colorcopy_line      = 65
const begin_vblank_line         = 245

const vic_colour_base           = $d800
const charset_base              = $2000
const screen_base               = $3000
const screen_backbuffer_base    = $3400
const vic_ctrl                  = $d018
const map_base                  = $5000
const map_height                = 17
const map_width                 = 512

dim current_screen          as byte
dim i                       as byte
dim row                     as byte
dim col                     as byte
dim numlines                as byte
dim this_colour             as byte
dim this_char               as byte
dim startline               as byte
dim scroll                  as byte

dim from_ptr                as word
dim to_ptr                  as word
dim screen_base_ptr         as word
dim backbuffer_base_ptr     as word
dim map_ptr                 as word
dim offset                  as word
dim map_column              as word

goto start

origin charset_base
incbin "UridiumChars.bin"
origin map_base
incbin "UridiumMap.bin"

sub SetScreenLocation() static

    ' SEE https://oldskoolcoder.co.uk/the-vic-ii-addressing-system/
    ' We are using Bank 0. Screen location is $D018 bits 4-7 = 16 possible locations
    '
    ' if current_screen = 0 then set the VIC II character screen to screen_base = $3000
    ' so register shoulf be %1100xxxx
    '
    ' otherwise set to screen_backbuffer_base = $3400
    ' so register shoulf be %1101xxxx
         call WaitAnyKey()

    if current_screen = 0 then
        poke vic_ctrl, (peek(vic_ctrl) and %00001111) or %11000000
    else
        poke vic_ctrl, (peek(vic_ctrl) and %00001111) or %11010000
    end if

end sub

sub DrawColumn39FromMap() static

    if current_screen = 0 then
        to_ptr = screen_backbuffer_base
    else
        to_ptr = screen_base 
    end if    

    to_ptr = to_ptr + 160       ' Screen row 4
    map_ptr = map_base + map_column
    
    for i = 1 to 17
        poke to_ptr + 39, peek(map_ptr)
        to_ptr = to_ptr + 40
        map_ptr = map_ptr + map_width
    next i
    
    map_column = map_column + 1
    if map_column = 254 then map_column = 0
    
end sub

sub swap_screens() static

    border green
    call WaitAnyKey()
    
    call DrawColumn39FromMap()
    scroll = 7
    hscroll scroll
    
    if current_screen = 0 then
        current_screen = 1
    else
        current_screen = 0
    end if    
    
    call SetScreenLocation()
    
end sub    

sub copy_and_shift() static
    
    border RED
    call WaitAnyKey()
    if current_screen = 0 then
        from_ptr = screen_base
        to_ptr = screen_backbuffer_base
    else
        from_ptr = screen_backbuffer_base
        to_ptr = screen_base 
    end if
    
    to_ptr = startline * 40
    from_ptr = 1 + to_ptr
    
    row = 0
    
    do while row < numlines 
    
        memcpy from_ptr, to_ptr, 39
        row = row + 1
        from_ptr = from_ptr + 40
        to_ptr = to_ptr + 40
        
    loop
    
end sub    


sub begin_vblank() static

    scroll = scroll - 1

    if scroll = 255 then 
        border BLACK
        call WaitAnyKey()
        call swap_screens()
    else
        
        hscroll scroll

        select case scroll
        
            ' Copy top half of char screen to back buffer.
            case 4
            
                startline = 4
                numlines = 8
                call copy_and_shift()
        
            ' Copy bottom half of char screen to back buffer.
            case 2 
            
                startline = 12
                numlines = 8
                call copy_and_shift()
       
        end select
        ' TODO expand border
    
    end if
    
end sub


start:

    vmode text multi
    charset ram 4           ' $2000
    memset screen_base, 1000, 32
    memset screen_backbuffer_base, 1000, 32

    background BLACK
    border MIDGREY
    
    scroll = 7
    
    screen_base_ptr = screen_base
    backbuffer_base_ptr = screen_backbuffer_base
    
    current_screen = 0
    call SetScreenLocation()
    
    'on raster start_colorcopy_line gosub line_65
    ''on raster begin_vblank_line gosub begin_vblank
    ''system interrupt off
    ''raster interrupt on

mainloop:    
    do : loop while scan() < begin_vblank_line
    call begin_vblank()
    goto mainloop
    
