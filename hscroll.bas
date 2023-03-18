' https://github.com/AlanPBourke/trse-scroller/blob/main/x_scroll.ras
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

                
dim offset          as int
dim map_column      as int
dim current_screen  as byte
dim i               as byte
dim row             as byte
dim col             as byte
dim numlines        as byte
dim this_colour     as byte
dim this_char       as byte
dim startline       as byte
dim scroll          as byte

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

    if current_screen = 0 then
        poke vic_ctrl, (peek(vic_ctrl) and %00001111) or %11000000
    else
        poke vic_ctrl, (peek(vic_ctrl) and %00001111) or %11010000
    end if

end sub

start:

    vmode text multi
    border 0    
    background 0
    
    scroll = 7
    
    current_screen = 0
    call SetScreenLocation()
    
    
    
    on raster start_colorcopy_line gosub line_65
    system interrupt off
    raster interrupt on
    
    do : loop while 1

line_65:

    on raster begin_vblank_line gosub begin_vblank
    
    return
    
begin_vblank:

    scroll = scroll - 1
    return