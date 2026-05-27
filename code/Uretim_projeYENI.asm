      ;========================================================
; ODEV 2 - PIC16F628A
; Paketleme sisteminde bayan ve erkek forma sayimi
; RA0 : kapasite artirma butonu
; RA1 : baslatma butonu
; RA2 : bayan sensoru
; RA3 : erkek sensoru
; RB0 : bayan motoru
; RB1 : erkek motoru
; RA5/MCLR : reset
;========================================================

        LIST      P=16F628A
        #INCLUDE <P16F628A.INC>

;========================================================
; KONFIGURASYON BITLERI
;========================================================
        __CONFIG   _INTOSC_OSC_NOCLKOUT & _WDT_OFF & _PWRTE_ON & _MCLRE_ON & _BODEN_ON & _LVP_OFF & _CP_OFF & _CPD_OFF

;========================================================
; DEGISKENLER
;========================================================
        CBLOCK 0x20
            KAPASITE
            BAYAN_SAY
            ERKEK_SAY
            D1
            D2
        ENDC

;========================================================
; RESET VEKTORU
;========================================================
        ORG     0x0000
        GOTO    BASLA

;========================================================
; ANA PROGRAM
;========================================================
BASLA:
        ; Comparator kapat
        MOVLW   0x07
        MOVWF   CMCON

        ; PORT ayarlari
        BSF     STATUS, RP0

        MOVLW   b'00001111'     ; RA0-RA3 giris
        MOVWF   TRISA

        MOVLW   b'00000000'     ; PORTB cikis
        MOVWF   TRISB

        BCF     STATUS, RP0

        ; Portlari temizle
        CLRF    PORTA
        CLRF    PORTB

        ; Baslangic degerleri
        CLRF    KAPASITE
        CLRF    BAYAN_SAY
        CLRF    ERKEK_SAY

;========================================================
; KAPASITE BELIRLEME ASAMASI
; RA0: kapasite artir
; RA1: baslat
;========================================================
KAPASITE_BEKLE:

        ;----------------------------------------
        ; RA0 basildi mi? (kapasite arttir)
        ; Eski mantigi koruyoruz:
        ; aktif durum PORTA,0 = 1 kabul edilmis
        ;----------------------------------------
        BTFSS   PORTA, 0
        GOTO    BASLAT_KONTROL

        CALL    DELAY
        BTFSS   PORTA, 0
        GOTO    BASLAT_KONTROL

        INCF    KAPASITE, F

RA0_BIRAK:
        BTFSC   PORTA, 0
        GOTO    RA0_BIRAK

        CALL    DELAY

;----------------------------------------
; RA1 basildi mi? (baslat)
;----------------------------------------
BASLAT_KONTROL:
        BTFSS   PORTA, 1
        GOTO    KAPASITE_BEKLE

        CALL    DELAY
        BTFSS   PORTA, 1
        GOTO    KAPASITE_BEKLE

        ; kapasite 0 ise baslatma yapma
        MOVF    KAPASITE, F
        BTFSC   STATUS, Z
        GOTO    RA1_BIRAK

        ; motorlari calistir
        BSF     PORTB, 0
        BSF     PORTB, 1

RA1_BIRAK:
        BTFSC   PORTA, 1
        GOTO    RA1_BIRAK

        CALL    DELAY

        MOVF    KAPASITE, F
        BTFSS   STATUS, Z
        GOTO    URETIM_DONGUSU

        GOTO    KAPASITE_BEKLE

;========================================================
; URETIM ASAMASI
;========================================================
URETIM_DONGUSU:

;----------------------------------------
; Bayan sayisi kapasiteye ulastiysa motoru durdur
;----------------------------------------
        MOVF    KAPASITE, W
        SUBWF   BAYAN_SAY, W
        BTFSC   STATUS, Z
        BCF     PORTB, 0

;----------------------------------------
; Erkek sayisi kapasiteye ulastiysa motoru durdur
;----------------------------------------
        MOVF    KAPASITE, W
        SUBWF   ERKEK_SAY, W
        BTFSC   STATUS, Z
        BCF     PORTB, 1

;----------------------------------------
; Bayan sensor kontrolu
; aktif durum eski koddaki gibi 1 kabul edildi
;----------------------------------------
        BTFSS   PORTA, 2
        GOTO    ERKEK_KONTROL

        CALL    DELAY
        BTFSS   PORTA, 2
        GOTO    ERKEK_KONTROL

        ; kapasite doluysa artirma yapma
        MOVF    KAPASITE, W
        SUBWF   BAYAN_SAY, W
        BTFSC   STATUS, Z
        GOTO    BAYAN_BIRAK

        INCF    BAYAN_SAY, F

BAYAN_BIRAK:
        BTFSC   PORTA, 2
        GOTO    BAYAN_BIRAK

        CALL    DELAY

;----------------------------------------
; Erkek sensor kontrolu
;----------------------------------------
ERKEK_KONTROL:
        BTFSS   PORTA, 3
        GOTO    URETIM_DONGUSU

        CALL    DELAY
        BTFSS   PORTA, 3
        GOTO    URETIM_DONGUSU

        ; kapasite doluysa artirma yapma
        MOVF    KAPASITE, W
        SUBWF   ERKEK_SAY, W
        BTFSC   STATUS, Z
        GOTO    ERKEK_BIRAK

        INCF    ERKEK_SAY, F

ERKEK_BIRAK:
        BTFSC   PORTA, 3
        GOTO    ERKEK_BIRAK

        CALL    DELAY
        GOTO    URETIM_DONGUSU

;========================================================
; DAHA KISA VE DAHA RAHAT DELAY
;========================================================
DELAY:
        MOVLW   D'30'
        MOVWF   D1
DLY1:
        MOVLW   D'100'
        MOVWF   D2
DLY2:
        DECFSZ  D2, F
        GOTO    DLY2
        DECFSZ  D1, F
        GOTO    DLY1
        RETURN

        END
