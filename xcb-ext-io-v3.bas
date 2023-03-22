rem ******************************
rem * File IO extension
rem * by Thraka
rem * namespace: io_
rem * GitHub: https://github.com/Thraka/xcb-ext-io
rem *
rem * version: 1.1 Aug 6, 2020
rem * - Added io_WriteByte and io_WriteBytes
rem *
rem * version: 1.0 Aug 4, 2020
rem * - Initial release
rem ******************************

const _KERNAL_SETLFS = $FFBA 
const _KERNAL_SETNAM = $FFBD
const _KERNAL_OPEN   = $FFC0
const _KERNAL_CLOSE  = $FFC3
const _KERNAL_CHKIN  = $FFC6
const _KERNAL_CHKOUT = $FFC9
const _KERNAL_CLRCHN = $FFCC
const _KERNAL_CHRIN  = $FFCF
const _KERNAL_CHROUT = $FFD2
const _KERNAL_LOAD   = $FFD5
const _KERNAL_READST = $FE07

sub io_PrintError() shared static
    asm
    pha
    jsr _KERNAL_CLRCHN
    pla
    cmp #$02
    beq .error_file_open
    cmp #$03
    beq .error_file_not_open
    cmp #$05
    beq .error_device_not_ready
    jmp .error_unknown
.error_file_open
    lda #<.string_error_file_already_open
    pha
    lda #>.string_error_file_already_open
    pha
    jmp RUNTIME_ERROR
.error_file_not_open
    lda #<.string_error_file_not_open
    pha
    lda #>.string_error_file_not_open
    pha
    jmp RUNTIME_ERROR
.error_device_not_ready
    lda #<.string_error_device_not_ready
    pha
    lda #>.string_error_device_not_ready
    pha
    jmp RUNTIME_ERROR
.error_unknown
    sta .string_error_unknown+13
    lda #<.string_error_unknown
    pha
    lda #>.string_error_unknown
    pha
    jmp RUNTIME_ERROR
.string_error_file_already_open     HEX 45 52 52 3A 20 46 49 4C 45 20 4F 50 45 4E 00
.string_error_file_not_open         HEX 45 52 52 3A 20 46 49 4C 45 20 4E 4F 54 20 4F 50 45 4E 00
.string_error_device_not_ready      HEX 45 52 52 3A 20 44 45 56 49 43 45 20 4D 49 53 53 49 4E 47 00
.string_error_unknown               HEX 45 52 52 3A 20 55 4E 4B 4E 4F 57 4E 20 20 00
    end asm
end sub

rem ******************************
rem * Command:
rem * io_Open   
rem * 
rem * Arguments:
rem * logicalFile! - Logical file number.
rem * device!      - Device to open.
rem * channel!     - Secondary address.
rem * 
rem * Summary:
rem * Opens a logical file targeting the specified device and channel.
rem * Doesn't open a specific file.
rem * 
rem * Calls the kernal routines SETNAM, SETLFS, and OPEN.
rem ******************************

sub io_Open(logicalFile as byte, device as byte, channel as byte) shared static 
    asm 
    lda #0
    jsr _KERNAL_SETNAM
    lda {logicalFile}
    ldx {device}
    ldy {channel}
    jsr _KERNAL_SETLFS
    jsr _KERNAL_OPEN
    bcs .error
    jmp .end
.error
    jmp _Pio_PrintError
.end
    end asm
end sub

rem ******************************
rem * Command:
rem * io_OpenName
rem * 
rem * Arguments:
rem * logicalFile! - Logical file number.
rem * device!      - Device to open.
rem * channel!     - Secondary address.
rem * filename$    - The file name to open.
rem * 
rem * Summary:
rem * Opens a logical file targeting the specified device and channel.
rem * Sends the file name to the device to open.
rem * 
rem * Calls the kernal routines SETNAM, SETLFS, and OPEN.
rem ******************************

sub io_OpenName(logicalFile as byte, device as byte, channel as byte, _
    filename as string * 40) shared static
    
    dim length as byte
    length = len(filename)
    asm 
    lda {length}
    ldx {filename}
    ldy {filename}+1
    jsr _KERNAL_SETNAM
    lda {logicalFile}
    ldx {device}
    ldy {channel}
    jsr _KERNAL_SETLFS
    jsr _KERNAL_OPEN
    bcs .error
    jmp .end
.error
    jmp _Pio_PrintError
.end
;.error
    ;investigate READST from kernal
    ;kernal print error
    ; Value of A:
    ;$05 device not present
    ;$04 file not found
    ;$1D load error
    ;$00 break run/stop pressed during loading
    end asm
end sub

rem ******************************
rem * Command:
rem * io_Close
rem * 
rem * Arguments:
rem * logicalFile! - Logical file number.
rem * 
rem * Summary:
rem * Closes a logical file that has been opened with either
rem * io_Open or io_OpenName.
rem * 
rem * Calls the kernal routine CLOSE.
rem ******************************

sub io_Close(logicalFile as byte) shared static
    asm 
    lda {logicalFile}
    jsr _KERNAL_CLOSE
    end asm
end sub

rem ******************************
rem * Command:
rem * io_ReadByte
rem * 
rem * Arguments:
rem * logicalFile!  - Logical file number.
rem * 
rem * Returns:
rem * The byte read from the logical file.
rem * 
rem * Summary:
rem * Reads a byte from a logical file that has been opened
rem * with either io_Open or io_OpenName.
rem * 
rem * Calls the kernal routines CHKIN, CHRIN, and CLRCHN.
rem ******************************
function io_ReadByte as byte (logicalFile as byte) shared static
    dim result as byte : result = 0
    asm 
    jsr _KERNAL_CLRCHN
    ldx {logicalFile}
    jsr _KERNAL_CHKIN
    bcs .error
    jsr _KERNAL_CHRIN
    ; - do readst 
    ; - destroys A so that needs to be saved
    ; - if A is 00 then all is good
    ; - restore A 
    tax
    jsr _KERNAL_READST
    cmp #$00
    bne .error
    stx {result}
    jsr _KERNAL_CLRCHN
    jmp .end
.error
    jmp _Pio_PrintError
.end
    end asm
    return result
end function

rem ******************************
rem * Command:
rem * io_ReadBytes
rem * 
rem * Arguments:
rem * logicalFile!  - Logical file number.
rem * bufferAddress - The address of a byte array.
rem * byteCount!    - The count of bytes to read.
rem * 
rem * Summary:
rem * Reads the total bytes specified by the byteCount!
rem * parameter and stores them in the byte array specified by
rem * the bufferAddress parameter.
rem * 
rem * Operates on a logical file that has been opened
rem * with either io_Open or io_OpenName.
rem * 
rem * Calls the kernal routines CHKIN, CHRIN, and CLRCHN.
rem ******************************

sub io_ReadBytes(logicalFile as byte, bufferAddress as int, _
    byteCount as byte) shared static
    
    asm 
    ldx {logicalFile}
    jsr _KERNAL_CHKIN
    ;readst
    ldy #$00
    lda {bufferAddress}
    sta .buff+1
    lda {bufferAddress}+1
    sta .buff+2
.start
    jsr _KERNAL_CHRIN
.buff
    sta {bufferAddress},Y
    ;readst
    iny
    cpy {byteCount}
    bne .start
    jsr _KERNAL_CLRCHN
    end asm
end sub

rem ******************************
rem * Command:
rem * io_WriteByte
rem * 
rem * Arguments:
rem * logicalFile!  - Logical file number.
rem * byte!         - The byte to write.
rem * 
rem * Summary:
rem * Writes the specified byte to a logical file that has been opened
rem * with either io_Open or io_OpenName.
rem * 
rem * Calls the kernal routines CHKOUT, CHROUT, and CLRCHN.
rem ******************************

sub  io_WriteByte(logicalFile as byte, _byte as byte) shared static
    asm 
    ldx {logicalFile}
    jsr _KERNAL_CHKOUT
    ;readst
    lda {_byte}
    jsr _KERNAL_CHROUT
    ;readst
    jsr _KERNAL_CLRCHN
    end asm
end sub


rem ******************************
rem * Command:
rem * io_WriteBytes
rem * 
rem * Arguments:
rem * logicalFile!  - Logical file number.
rem * bufferAddress - The address of a byte array.
rem * byteCount!    - The count of bytes to write.
rem * 
rem * Summary:
rem * Writes the total bytes specified by the byteCount!
rem * parameter to the logical file.
rem * 
rem * The bufferAddress parameter is the address of the byte
rem * array to store.
rem * 
rem * Calls the kernal routines CHKOUT, CHROUT, and CLRCHN.
rem ******************************

sub io_WriteBytes(logicalFile as byte, bufferAddress as int, _
    byteCount as byte) shared static
    
    asm 
    ldx {logicalFile}
    jsr _KERNAL_CHKOUT
    ;readst
    ldy #$00
    lda {bufferAddress}
    sta .buff+1
    lda {bufferAddress}+1
    sta .buff+2
.start
.buff
    lda {bufferAddress},Y
    jsr _KERNAL_CHROUT
    ;readst
    iny
    cpy {byteCount}
    bne .start
    jsr _KERNAL_CLRCHN
    end asm
end sub

rem ******************************
rem * Command:
rem * io_WriteString
rem * 
rem * Arguments:
rem * logicalFile! - Logical file number.
rem * text$        - The string to print to the logical file.
rem * 
rem * Summary:
rem * Writes the string prived to the logical file that has been
rem * opened with either io_Open or io_OpenName.
rem * 
rem * Calls the kernal routines CHKOUT, CHROUT, and CLRCHN.
rem ******************************

sub io_WriteString(logicalFile as byte, text as string * 40) shared static
    asm 
    ldx {logicalFile}
    jsr _KERNAL_CHKOUT
    ;readst
    ldy #$00
    lda {text}
    sta .buff+1
    lda {text}+1
    sta .buff+2
.start
.buff
    lda {text},Y
    beq .end
    jsr _KERNAL_CHROUT
    ;readst
    iny
    jmp .start
.end
    jsr _KERNAL_CLRCHN
    end asm
end sub
