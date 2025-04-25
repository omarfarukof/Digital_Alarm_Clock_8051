    ORG 0
    MOV SP, #70H
    MOV PSW, #00H
    SJMP MAIN

    ; TIME_DELAY SETUP
        TIME_DELAY_L0_COUNT EQU 55H
        TIME_DELAY_L1_COUNT EQU 56H

        ; TIMER / COUNTER
        ORG 0BH     ; FOR TIMER_0
            LCALL TIMER_0_SUB
            RETI
        ORG 1BH     ; FOR TIMER_1
            LCALL TIMER_1_SUB
            RETI

    ; CLOCK SETUP
        CLOCK_HH     EQU 57H
        CLOCK_MM     EQU 58H
        CLOCK_SS     EQU 59H
        CLOCK_0E     EQU 60H

        CLOCK_HH_CHANGER BIT 00H
        CLOCK_MM_CHANGER BIT 01H
        CLOCK_SS_CHANGER BIT 02H
    
    ; ALARM
        ALARM_0     EQU 40H
        ALARM_COUNT EQU 50H

        ALARM_TEMP_HH   EQU 05H
        ALARM_TEMP_MM   EQU 06H

        ALARM_CHECK_INDICATOR   BIT 03H

    ; LCD DISPLAY SETUP
        LCD_P   EQU P2
        LCD_RS  EQU P1.4
        LCD_RW  EQU P1.5
        LCD_E   EQU P1.6
        ; LCD DELAY
        LCD_DELAY_L0_ADDRESS    EQU 6FH
        LCD_DELAY_L0_COUNT      EQU 22H
    
    ; KEYPAD SETUP
        ; bool ( BIT ADDRESSABLE )
        IS_KEY_SINGLE_PRESS  EQU     07H
        ; PORT CONNECTION ==>> C(4-1)->P(7-4) + R(4-1)->P(3-0)
        KEYPAD_PORT          EQU     P3



    



; ============== MAIN CODE START =====================
    ORG 30H
MAIN:   ; MAIN CODE START
    LCALL INTERUPT_ENABLE
    LCALL TIMER_0_ENABLE
    LCALL CLOCK_INIT
    LCALL LCD_INIT
    MOV ALARM_COUNT, #0

    LCALL LCD_CURSOR_LINE_1
    MOV DPTR, #CLOCK_STR
    LCALL LCD_STR_PRINT
    LCALL CLOCK_LCD_DISPLAY

    LCALL TIMER_0_INIT_MODE_1
    MOV TH0, #0
    MOV TL0, #0
    SETB TR0


    MAIN_HOLD:
        LCALL ALARM_SETUP

    SJMP MAIN_HOLD

    MAIN_END:   LJMP PROG_END;END
; ============== MAIN CODE END ========================



; ============== SUBROUTINE / FUNCTIONS ===============
; ALARM
ALARM_INIT:
    MOV ALARM_COUNT, #0
    RET

ALARM_CHECK:
    MOV A, ALARM_COUNT
    JZ ALARM_CHECK_END
    MOV R2, ALARM_COUNT
    ALARM_CHECK_AGAIN:
        

        MOV R1, #ALARM_0
        MOV A, @R1
        CJNE A, CLOCK_HH, ALARM_CHECK_END
        
        

        INC R1
        MOV A, @R1
        CJNE A, CLOCK_MM, ALARM_CHECK_END

        ; RUN ALARM -----------------
        LCALL LCD_CURSOR_LINE_2
        MOV DPTR, #ALARM_SETUP_STR
        LCALL LCD_STR_PRINT
        ; ---------------------------

        DJNZ R2, ALARM_CHECK_AGAIN
    ALARM_CHECK_END:
        RET

ALARM_SETUP:
    PUSH 0E0H
    PUSH 0F0H
    LCALL KEY_GET_ASCII
    CLR C
    SUBB A, #'C'
    JNZ ALARM_SETUP_END

    LCALL LCD_CURSOR_LINE_2
    MOV DPTR, #ALARM_SETUP_STR
    LCALL LCD_STR_PRINT

    LCALL ALARM_SETUP_TAKE_INPUT

    ALARM_SETUP_COMPLETE:
        LCALL KEY_GET_ASCII
        CLR C
        SUBB A, #'='
        JNZ ALARM_SETUP_COMPLETE
    INC ALARM_COUNT

    MOV R1, #16D
    LCALL LCD_CURSOR_LINE_2
    LCD_CLEAR_LINE_2:
        MOV A, #' '
        LCALL LCD_WRITE_DATA
        DJNZ R1, LCD_CLEAR_LINE_2

    ALARM_SETUP_END:
        POP 0F0H
        POP 0E0H
        RET

ALARM_SETUP_TAKE_INPUT:
    ;MOV R1, #ALARM_0
    MOV A, ALARM_COUNT
    RL A
    ADD A, #ALARM_0
    MOV R1, A

    MOV R2, #02H
    MOV R3, #6D
    MOV R4, #7D
    ALARM_TAKE_INPUT:
        LCALL KEY_GET_NUMBER
        MOV ALARM_TEMP_HH, A
        MOV A, R3
        LCALL LCD_CURSOR_LINE_2_POSITION_A
        MOV A, ALARM_TEMP_HH
        LCALL LCD_WRITE_NUMBER
        LCALL KEY_GET_NUMBER
        MOV ALARM_TEMP_MM, A
        MOV A, R4
        LCALL LCD_CURSOR_LINE_2_POSITION_A
        MOV A, ALARM_TEMP_MM
        LCALL LCD_WRITE_NUMBER
        MOV A, #0AH
        MOV B, ALARM_TEMP_HH
        MUL AB
        ADD A, ALARM_TEMP_MM
        MOV @R1, A
        INC R1
        INC R3
        INC R3
        INC R3
        INC R4
        INC R4
        INC R4
        DJNZ R2, ALARM_TAKE_INPUT
        RET

; CLOCK
; FOR f = 11.0592Hz 
;   => T = 12/f = 1.085us
;   => t = 1s
;   => MC = t / T = 921_658.986
;   => MC = 65536(FFFF) x 14.06(E)
CLOCK_INIT:
    MOV CLOCK_HH, #12D
    MOV CLOCK_MM, #30D
    MOV CLOCK_SS, #0D
    MOV CLOCK_0E, #0D

    SETB CLOCK_HH_CHANGER
    SETB CLOCK_MM_CHANGER
    SETB CLOCK_SS_CHANGER

    RET

CLOCK_LCD_DISPLAY:
    PUSH 0E0H
    PUSH 0F0H
    ; PRINT CLOCK_HH
    JNB CLOCK_HH_CHANGER, CLOCK_LCD_DISPLAY_MM
    CLR CLOCK_HH_CHANGER
    MOV A, #00D
    LCALL LCD_CURSOR_LINE_1_POSITION_A
    MOV A, CLOCK_HH
    MOV B, #10D
    DIV AB
    LCALL LCD_WRITE_NUMBER
    MOV A, B
    LCALL LCD_WRITE_NUMBER

    ; PRINT CLOCK_MM    
    CLOCK_LCD_DISPLAY_MM:
    JNB CLOCK_MM_CHANGER, CLOCK_LCD_DISPLAY_SS
    CLR CLOCK_MM_CHANGER
    MOV A, #03D
    LCALL LCD_CURSOR_LINE_1_POSITION_A
    MOV A, CLOCK_MM
    MOV B, #10D
    DIV AB
    LCALL LCD_WRITE_NUMBER
    MOV A, B
    LCALL LCD_WRITE_NUMBER
    
    ; PRINT CLOCK_SS
    CLOCK_LCD_DISPLAY_SS:
    JNB CLOCK_SS_CHANGER, CLOCK_LCD_DISPLAY_END
    CLR CLOCK_SS_CHANGER
    MOV A, #06D
    LCALL LCD_CURSOR_LINE_1_POSITION_A
    MOV A, CLOCK_SS
    MOV B, #10D
    DIV AB
    LCALL LCD_WRITE_NUMBER
    MOV A, B
    LCALL LCD_WRITE_NUMBER
    

    CLOCK_LCD_DISPLAY_END:
        POP 0F0H
        POP 0E0H
        RET

CLOCK_CHANGE:
    INC CLOCK_0E ; RUNNING CLOCK
    ; ROTATION
    MOV R0, #CLOCK_0E
    CJNE @R0, #14D, CLOCK_CHANGE_END
    MOV CLOCK_0E, #00H
    INC CLOCK_SS
    SETB CLOCK_SS_CHANGER

    ; SECOND ROTATION
    MOV R0, #CLOCK_SS
    CJNE @R0, #60D, CLOCK_CHANGE_END
    MOV CLOCK_SS, #00H
    INC CLOCK_MM
    SETB CLOCK_MM_CHANGER
    SETB ALARM_CHECK_INDICATOR

    ; MINUTE ROTATION
    MOV R0, #CLOCK_MM
    CJNE @R0, #60D, CLOCK_CHANGE_END
    MOV CLOCK_MM, #00H
    INC CLOCK_HH
    SETB CLOCK_HH_CHANGER

    ; HOUR ROTATION
    MOV R0, #CLOCK_HH
    CJNE @R0, #24D, CLOCK_CHANGE_END
    MOV CLOCK_HH, #00H

    CLOCK_CHANGE_END:
        RET



; TIME CALCULATED DELAY
TIMER_0_SUB:
    ; TIMER_0 = TH0_TL0
    ; START TIMER_0 => TR0 = 1
    ; END TIMER_0 => TF0 = 1
    ; ---- ---- ---- ---- ----
    ; WRITE CODE HERE
    LCALL CLOCK_CHANGE
    LCALL CLOCK_LCD_DISPLAY

    JNB ALARM_CHECK_INDICATOR, TIMER_0_SUB_END
        LCALL ALARM_CHECK
        CLR ALARM_CHECK_INDICATOR
    TIMER_0_SUB_END:
        RET

TIMER_1_SUB:
    ; TIMER_1 = TH1_TL1
    ; START TIMER_1 => TR1 = 1
    ; END TIMER_1 => TF1 = 1
    ; ---- ---- ---- ---- ----
    ; WRITE CODE HERE
    RET

TIMER_0_INIT_MODE_1:
    ; TH0_TL0 = (FFFF - MC)
    MOV A, TMOD
    ANL A, #0F0H
    ADD A, #01H ; MODE 1
    MOV TMOD, A
    RET

TIMER_1_INIT_MODE_1:
    ; TH0_TL0 = (FFFF - MC)
    MOV A, TMOD
    ANL A, #0FH
    SWAP A
    ADD A, #01H ; MODE 1
    SWAP A
    MOV TMOD, A
    RET

TIMER_0_INIT_MODE_2:
    ; TH0 = (FF - MC)
    MOV A, TMOD
    ANL A, #0F0H
    ADD A, #02H ; MODE 2
    MOV TMOD, A
    RET

TIMER_1_INIT_MODE_2:
    ; TH0 = (FF - MC)
    MOV A, TMOD
    ANL A, #0FH
    SWAP A
    ADD A, #02H ; MODE 2
    SWAP A
    MOV TMOD, A
    RET

INTERUPT_ENABLE:
    SETB IE.7
    RET
TIMER_0_ENABLE:
    SETB IE.1
    RET
TIMER_1_ENABLE:
    SETB IE.3
    RET
INTERUPT_DISABLE:
    CLR IE.7
    RET
TIMER_0_DISABLE:
    CLR IE.1
    RET
TIMER_1_DISABLE:
    CLR IE.3
    RET


TIME_DELAY_1MS:
        ; FOR f = 11Hz => T = 12/f = 1.09091us
        ; ==> n = 1ms/T = 916 = 3*L0.L1 + 3*L1 + 2 
        ; ==> L1 = (916 - 2) / ( 3*L0 + 3 )
        ; ==> L1 = 1 & L0 = 255
        MOV TIME_DELAY_L1_COUNT, #1
    TIME_DELAY_1MS_L1:
        MOV TIME_DELAY_L0_COUNT, #255
    TIME_DELAY_1MS_L0:
        DJNZ TIME_DELAY_L0_COUNT, TIME_DELAY_1MS_L0
        DJNZ TIME_DELAY_L1_COUNT, TIME_DELAY_1MS_L1
    RET

TIME_DELAY_20MS:
        ; FOR f = 11Hz => T = 1.09091us
        ; ==> n = 20ms/T = 18333 = 3*L0.L1 + 3*L1 + 2 
        ; ==> L1 = 23 & L0 = 255
        MOV TIME_DELAY_L1_COUNT, #23
    TIME_DELAY_20MS_L1:
        MOV TIME_DELAY_L0_COUNT, #255
    TIME_DELAY_20MS_L0:
        DJNZ TIME_DELAY_L0_COUNT, TIME_DELAY_20MS_L0
        DJNZ TIME_DELAY_L1_COUNT, TIME_DELAY_20MS_L1
    RET

; FOR LCD
LCD_STR_PRINT:  
        ;MOV DPTR, #LCD_STR
    LCD_STR_PRINT_AGAIN:
        CLR A           ;set A=0 (match found)
        MOVC A, @A+DPTR ;get ASCII code from table
        JZ LSP_END
        LCALL LCD_WRITE_DATA
        INC DPTR
        SJMP LCD_STR_PRINT_AGAIN
    LSP_END:    
        RET


LCD_DELAY:
        MOV LCD_DELAY_L0_ADDRESS, #LCD_DELAY_L0_COUNT
    LCD_DELAY_L0:
        DJNZ LCD_DELAY_L0_ADDRESS, LCD_DELAY_L0        
        RET

LCD_CMD:        
        LCALL LCD_READY     ;send command to LCD
        MOV LCD_P, A        ;copy reg A to port 1
        CLR LCD_RS          ;LCD_RS=0 for command
        CLR LCD_RW          ;R/W=0 for write
        SETB LCD_E          ;LCD_E=1 for high pulse
        LCALL LCD_DELAY     ;give LCD some time
        CLR LCD_E           ;LCD_E=0 for H-to-L pulse
        LCALL LCD_DELAY     ;give LCD some time
        RET


LCD_WRITE_DATA: 
        LCALL LCD_READY     ;write data to LCD
        MOV LCD_P, A        ;copy reg A to port1
        SETB LCD_RS         ;LCD_RS=1 for data
        CLR LCD_RW          ;R/W=0 for write
        SETB LCD_E          ;LCD_E=1 for high pulse
        LCALL LCD_DELAY     ;give LCD some time
        CLR LCD_E           ;LCD_E=0 for H-to-L pulse
        LCALL LCD_DELAY     ;give LCD some time
        RET

LCD_WRITE_NUMBER:  
        LCALL LCD_READY     ;write data to LCD
        ADD A, #30H         ;CONVERT ASCII NUM
        MOV LCD_P, A        ;copy reg A to port1
        SETB LCD_RS         ;LCD_RS=1 for data
        CLR LCD_RW          ;R/W=0 for write
        SETB LCD_E          ;LCD_E=1 for high pulse
        LCALL LCD_DELAY     ;give LCD some time
        CLR LCD_E           ;LCD_E=0 for H-to-L pulse
        LCALL LCD_DELAY     ;give LCD some time
        RET

LCD_READY:      
        SETB LCD_P.7
        CLR LCD_RS
        SETB LCD_RW

    LCD_WAIT:   
        CLR LCD_E
        LCALL LCD_DELAY
        SETB LCD_E
        JB LCD_P.7, LCD_WAIT
        RET

LCD_INIT:       
    MOV A, #38H         ;init. LCD 2 lines, 5x7 matrix
    ACALL LCD_CMD
    LCALL LCD_CURSOR_OFF      ;dispplay on, cursor on
    LCALL LCD_CMD
    RET

LCD_CURSOR_LINE_1:        
    MOV A, #80H         ; CURSOR AT BEGINNING OF LINE 1
    LCALL LCD_CMD
    RET

LCD_CURSOR_LINE_1_POSITION_A:
    ; MOV A, #3 ; FOR 3RD POSITION OF LINE 1
    ADD A, #80H         ; CURSOR AT A POSITION OF LINE 1
    LCALL LCD_CMD
    RET

LCD_CURSOR_LINE_2:        
    MOV A, #0C0H         ; CURSOR AT BEGINNING OF LINE 2
    LCALL LCD_CMD
    RET

LCD_CURSOR_LINE_2_POSITION_A:
    ; MOV A, #3 ; FOR 3RD POSITION OF LINE 2
    ADD A, #0C0H         ; CURSOR AT A POSITION OF LINE 2
    LCALL LCD_CMD
    RET


LCD_CURSOR_ON:        
    MOV A, #0FH         ; Display on, cursor blinking
    LCALL LCD_CMD
    RET

LCD_CURSOR_OFF:       
    MOV A, #0CH         ; Display on, cursor off
    LCALL LCD_CMD
    RET

LCD_CLEAR:        
    MOV A, #01H         ; Clear Display screen
    LCALL LCD_CMD
    RET

LCD_CURSOR_DEC:
    MOV A, #04H         ; Decrement cursor (shift cursor to left)
    LCALL LCD_CMD
    RET

LCD_CURSOR_INC:
    MOV A, #06H         ; Increment cursor (shift cursor to right)
    LCALL LCD_CMD
    RET

LCD_CURSOR_LEFT:
    MOV A, #10H         ; Shift cursor position to left
    LCALL LCD_CMD
    RET

LCD_CURSOR_RIGHT:
    MOV A, #14H         ; Shift cursor position to left
    LCALL LCD_CMD
    RET

; FOR KEYPAD
KEY_GET_ASCII:
    ; TAKE NUMBER INPUT FROM KEYPAD IN ASCII
    LCALL KEY_GET_DECODE
    RET

KEY_GET_NUMBER:
    ; TAKE NUMBER INPUT FROM KEYPAD
    LCALL KEY_GET_DECODE
    CLR C
    SUBB A, #30H
    RET

KEY_GET_DECODE:        
        ; TAKE ASCII VALUE INPUT FROM KEYPAD 
        MOV KEYPAD_PORT, #0F0H

        LCALL KEY_CHECK_COL     ; B = COLUMN INDEX
        ;MOV B, A
        LCALL KEY_CHECK_ROW     ; A = ROW INDEX
        PUSH 0F0H
        MOV B, #04H
        MUL AB
        POP 0F0H
        ADD A, B
        MOV DPTR, #KEYPAD_DATA
        MOVC A, @A+DPTR
        RET

KEY_IGNORE_NOISE:
        MOV A, KEYPAD_PORT
        ANL A, #0F0H
        CJNE A, #0F0H, KEY_IGNORE_NOISE_2
        LCALL TIME_DELAY_20MS; DELAY 20MS
    KEY_IGNORE_NOISE_2:
        MOV A, KEYPAD_PORT
        ANL A, #0F0H
        CJNE A, #0F0H, KEY_IGNORE_NOISE_RETURN
        SJMP KEY_IGNORE_NOISE
    KEY_IGNORE_NOISE_RETURN:
        RET

KEY_CHECK_COL:  
        MOV A, KEYPAD_PORT
        ANL A, #0F0H
        CJNE A, #0F0H, KEY_CHECK_SINGLE_PRESS_LABEL
        CLR IS_KEY_SINGLE_PRESS
        JMP KEY_CHECK_COL
    KEY_CHECK_SINGLE_PRESS_LABEL:
        JB IS_KEY_SINGLE_PRESS, KEY_CHECK_COL
    KEY_CHECK_COLUMN_0:  
        MOV B, #00H
        CJNE A, #0E0H, KEY_CHECK_COLUMN_1
        JMP KEY_CHECK_COLUMN_END
    KEY_CHECK_COLUMN_1:  
        INC B
        CJNE A, #0D0H, KEY_CHECK_COLUMN_2
        JMP KEY_CHECK_COLUMN_END
    KEY_CHECK_COLUMN_2:  
        INC B
        CJNE A, #0B0H, KEY_CHECK_COLUMN_3
        JMP KEY_CHECK_COLUMN_END
    KEY_CHECK_COLUMN_3:  
        INC B
        ;CJNE A, #0F7H, KEY_CHECK_COLUMN_END
        ;JMP KEY_CHECK_COLUMN_END
    KEY_CHECK_COLUMN_END:
        SETB IS_KEY_SINGLE_PRESS
        RET

KEY_CHECK_ROW: 
        PUSH 0F0H
    KEY_CHECK_ROW_0:
        MOV B, #00H
        SETB KEYPAD_PORT.0
        MOV A, KEYPAD_PORT
        ANL A, #0F0H
        CJNE A, #0F0H, KEY_CHECK_ROW_1
        JMP KEY_CHECK_ROW_END
    KEY_CHECK_ROW_1:
        INC B
        SETB KEYPAD_PORT.1
        MOV A, KEYPAD_PORT
        ANL A, #0F0H
        CJNE A, #0F0H, KEY_CHECK_ROW_2
        JMP KEY_CHECK_ROW_END
    KEY_CHECK_ROW_2:
        INC B
        SETB KEYPAD_PORT.2
        MOV A, KEYPAD_PORT
        ANL A, #0F0H
        CJNE A, #0F0H, KEY_CHECK_ROW_3
        JMP KEY_CHECK_ROW_END
    KEY_CHECK_ROW_3:
        INC B
        ; SETB KEYPAD_PORT.3
        ; MOV A, KEYPAD_PORT
        ; ANL A, #0F0H
        ; CJNE A, #0F0H, KEY_CHECK_ROW_END
    KEY_CHECK_ROW_END:
        MOV A, B
        POP 0F0H
        RET


; =================== DATA LOOK UP TABLE =============================
    ; END OF THE STRING HAS TO BE 0
    
    ; ---- ---- ----
    ; TABLE_LABEL:
        ; DB '1', '2' , ... ... , 0
    ; ---- ---- ----
    CLOCK_STR:
        DB "00:00:00",0
    KEYPAD_DATA:
        DB '7', '8', '9', '/', '4', '5', '6', '*', '1', '2', '3', '-', 'C', '0', '=', '+' , 0
        ;NOP
    ALARM_SETUP_STR:
        DB "ARMT: ",0

PROG_END:
    END