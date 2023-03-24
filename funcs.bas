
' Waits for any keypress.
sub WaitAnyKey() static shared
    wait 197,64: wait 197,64,64
end sub

SUB WaitRasterLine256() SHARED STATIC
    ASM
wait1:  bit $d011
        bmi wait1
wait2:  bit $d011
        bpl wait2
    END ASM
END SUB

