//ANDREWJA JOB  CLASS=A,MSGCLASS=X,NOTIFY=&SYSUID,REGION=0M
//STEP1    EXEC ASMACL,PARM.C='FLAG(NOCONT)'
//C.SYSLIB DD   DSN=SYS1.MACLIB,DISP=SHR
//SYSIN    DD   *
*-----------------------------------------------------------------*
* Program function :
*    This program is called by a REXX exec to convert a string of
*    date time values into a 4-byte calendar time value ( UTC or
*    Universal Time Coordinates) which counts how many seconds
*    accumulated since January 1st 1970 midnight.
*
* Accepted forms of arguments:
*    1. if no argument :
*          Gets the current time
*    2. 1 argument of 14 bytes:
*          Treats the argument as YYYYMMDDhhmmss
*    3. 1 argument of 13 bytes:
*          Treats the argument as YYYYDDDhhmmss
*    4. 1 argument of 11 bytes:
*          Treats the argument as YYDDDhhmmss
*    5. 1 argument of  4 bytes:
*          The input is a UTC value and this is xlated
*          into YYYYMMDDhhmmss as the output
*    Any other length is treated invalid
*
* Result is a 4-byte binary field
*
* Examples :
*   say c2x(rxutc())
*     returns the Calendar time like : 412DAB12
*
*   say c2x(rxutc(20040826114845)) /* YYYYMMDDhhmmss */
*   datetime= 20040826114845
*   say c2x(rxutc(datetime))
*   say c2x(rxutc(2004239114845))  /* YYYYDDDhhmmss*/
*   say c2x(rxutc(04239114845))    /* YYDDDhhmmss */
*     all have the result : 412D5D9D
*
*   utc = '412DAB12'X
*   say rxutc(utc)   will be 20040826114845
*
* Assember : High Level Assembler 1.2 or above
* Author :   Andrew Jan
* Completion Date : 26/Aug/2004
* Update     Date : 20/Dec/2004
*
*-----------------------------------------------------------------*
         PRINT NOGEN
*------------------------------------------------*

         PRINT OFF
         LCLA  &REG
.LOOP    ANOP                     generate reg equates
R&REG    EQU   &REG
&REG     SETA  &REG+1
         AIF   (&REG LE 15).LOOP
         PRINT ON


*------------------------------------------------*

*------------------------------------------------*
WORKDATA DSECT ,
REGSAVE  DS    18F
TOD_WK   DS    D              work of a double-word field
WK_16    DS    0CL16          fullword boundary
P_HHMMSS DS    CL3            packed hhmmss
P_TH     DS    CL3            packed thijuu0000
         DS    CL2            reserved
P_Y4MMDD DS    CL4            packed yyyy
         DS    CL4            reserved
         ORG   P_Y4MMDD
P_Y4DDD  DS    CL4
         ORG   P_Y4MMDD
P_Y2K    DS    CL1
P_YYDDD  DS    CL3
         ORG
WK_8     DS    CL8
         DS    CL1

CONVTODL CONVTOD MF=L
STCKCONL STCKCONV MF=L

WORKLEN  EQU   *-WORKDATA

         IRXEFPL ,                efpl, external function parm list
         IRXARGTB ,               argument list map
         IRXEVALB ,               evaluation block map

RXUTC    CSECT
RXUTC    AMODE 31
RXUTC    RMODE ANY

         STM   R14,R12,12(R13)    save caller's reg values
         LR    R12,R15            set base reg
         USING RXUTC,R12          setup addressibility
         LR    R8,R1              save parmlist addr
         B     CMNTTAIL           skip over the remarks

CMNTHEAD EQU   *
         PRINT GEN                print out remarks
         DC    CL8'&SYSDATE'      compiling date
         DC    C' '
         DC    CL5'&SYSTIME'      compiling time
         DC    C'ANDREW JAN'      author
         CNOP  2,4                ensure half word boundary
         PRINT NOGEN              disable macro expansion
CMNTTAIL EQU   *

*-start code ----------------------------*

         GETMAIN RU,LV=WORKLEN,LOC=BELOW  blk addr returned in r1
         ST    R13,4(,R1)         chain save areas
         ST    R1,8(,R13)         save ours to caller's area
         LR    R13,R1             set our save addr
         USING WORKDATA,R13       addressibility for data

         USING EFPL,R8            addressibility

         L     R9,EFPLARG         argument list  addr

         USING ARGTABLE_ENTRY,R9  addressibility

*ARGTABLE_ARGSTRING_PTR    DS  A        Address of the argument string
*ARGTABLE_ARGSTRING_LENGTH DS  F        Length of the argument string
*ARGTABLE_NEXT             DS  0D       Next ARGTABLE entry
*ARGTABLE_END DC  XL8'FFFFFFFFFFFFFFFF' End of ARGTABLE marker

* check if any arg provided ?
         CLC   ARGTABLE_ARGSTRING_PTR(8),=XL8'FFFFFFFFFFFFFFFF'
         BZ    NO_ARG                   No, get current tod

* init. the work area
         MVC   WK_16,LOWVALUEX    init the field

* if there is arguments we need only the 1st argument
         L     R10,ARGTABLE_ARGSTRING_PTR     addr of arg 1
         L     R11,ARGTABLE_ARGSTRING_LENGTH  len of arg 1

         C     R11,=F'14'         YYYYMMDDhhmmss ?
         BNL   ARG_14             yes
         C     R11,=F'13'         YYYYDDDhhmmss ?
         BNL   ARG_13             yes
         C     R11,=F'11'         YYDDDhhmmss ?
         BNL   ARG_11             yes
         C     R11,=F'4'          a UTC ?
         BE    ARG_04             yes

         B     NO_ARG             others just treated as no argument

ARG_14   EQU   *
         PACK  WK_8,0(15,R10)     pack the value
         MVC   P_Y4MMDD,WK_8      move packed yyyymmdd
         MVC   P_HHMMSS,WK_8+4    move packed hhmmss

         CONVTOD CONVVAL=WK_16,TODVAL=TOD_WK,TIMETYPE=DEC,             X
               DATETYPE=YYYYMMDD,OFFSET=LOCALDIF,MF=(E,CONVTODL)
         B     COMMON
*
ARG_13   EQU   *
         PACK  WK_8,0(14,R10)     pack the date
         MVC   P_Y4DDD,WK_8       move packed yyyymmdd
         MVC   P_HHMMSS,WK_8+4    move packed hhmmss

         CONVTOD CONVVAL=WK_16,TODVAL=TOD_WK,TIMETYPE=DEC,             X
               DATETYPE=YYYYDDD,OFFSET=LOCALDIF,MF=(E,CONVTODL)
         B     COMMON
*
ARG_11   EQU   *
         PACK  P_YYDDD,0(5,R10)   pack the date
         PACK  WK_8(4),5(7,R10)   pack the time
         MVC   P_HHMMSS,WK_8      move packed hhmmss
         MVI   P_Y2K,X'01'        ind. not 19xx

         CONVTOD CONVVAL=WK_16,TODVAL=TOD_WK,TIMETYPE=DEC,             X
               DATETYPE=YYDDD,OFFSET=LOCALDIF,MF=(E,CONVTODL)
         B     COMMON
*
ARG_04   EQU   *                  expand the utc
         XR    R14,R14            tod value for 1 second
         L     R15,TOD_1SEC       tod value for 1 second
         SRDL  R14,1              divided by 2 1st
         M     R14,0(R10)         the tod for seconds since 1970
         SLDL  R14,1              divided by 2 1st
         LA    R1,TOD_1970        locate the footing
         BAL   R7,DBL_ADD         add the footing
         LA    R1,TOD_GMT         locate the gmt diff. for local time
         BAL   R7,DBL_ADD         add the footing
         ST    R14,TOD_WK           ore back - higher bytes
         ST    R15,TOD_WK+4       store back - lower bytes

         L     R7,EFPLEVAL        addr of evaluation block addr
         L     R7,0(,R7)          evaluation blk for result to return

         USING EVALBLOCK,R7       addressibility

*EVALBLOCK_EVSIZE DS  F           Size of EVALBLK in double word
*EVALBLOCK_EVLEN  DS  F           Length of data
*EVALBLOCK_EVDATA DS  C           Result

         STCKCONV STCKVAL=TOD_WK,CONVVAL=WK_16,DATETYPE=YYYYMMDD,      X
               MF=(E,STCKCONL)

         UNPK  WK_8(9),P_Y4MMDD(5)         unpack the decimal value
         MVC   EVALBLOCK_EVDATA(8),WK_8    move yyyymmdd
         UNPK  WK_8(7),P_HHMMSS(4)         unpack the decimal value
         MVC   EVALBLOCK_EVDATA+8(6),WK_8  move hhmmss
         LA    R1,14                       length of data
         ST    R1,EVALBLOCK_EVLEN          save back
         B     GO_BACK                     return

*
NO_ARG   EQU   *
         STCK  TOD_WK             current time

COMMON   EQU   *
         L     R14,TOD_WK        load into reg pair - higher bytes
         L     R15,TOD_WK+4      load into reg pair - lower bytes
         LA    R1,TOD_1970       tod for the start of 1970
         BAL   R7,DBL_SUBTRACT   get diff.
         SRDL  R14,1             divided by 2 1st
         L     R3,TOD_1SEC       how many seconds since 1970 ?
         SRL   R3,1              divided by 2 to remove the sign bit
         DR    R14,R3            how many seconds since start of 1970

         L     R7,EFPLEVAL        addr of evaluation block addr
         L     R7,0(,R7)          evaluation blk for result to return


         ST    R15,EVALBLOCK_EVDATA save result
         LA    R1,4                 length of data
         ST    R1,EVALBLOCK_EVLEN   save back

*--go back-------------------------------*
GO_BACK  EQU   *

         L     R13,4(,R13)        restore caller's save area
         L     R1,8(,R13)         our work area's addr in r1

         FREEMAIN RU,LV=WORKLEN,A=(1)   free out work area

         LM    R14,R12,12(R13)     restore caller's reg values
         SR    R15,R15             rc = 0
         BR    R14                 go back

*-----subroutine--------------------------*                             03961090
DBL_SUBTRACT EQU   *
         SL    R15,4(,R1)          subtract low order words             03984850
         BC    2+1,DBLSUB1         branch if carry                      03985840
         SL    R14,=A(1)           subtract carry fm high order word    03987820
DBLSUB1  EQU   *                                                        03989800
         SL    R14,0(,R1)          subtract high order words            03990790
         BR    R7                                                       03991780

*-----------------------------------------*                             03961090
DBL_ADD      EQU   *
         AL    R15,4(,R1)          add low order words
         BC    8+4,DBLADD1         branch if no carry
         AL    R14,=A(1)           add carry into high order word
DBLADD1  EQU   *
         AL    R14,0(,R1)          add high order words
         BR    R7                                                       03991780
*-----subroutine--------------------------*                             03961090

         LTORG

TOD_1970 DS   0D
         DC   X'7D91048BCA000000'  tod for Jan 1st 1970 midnight
TOD_GMT  DS   0D
         DC   X'00006B49D2000000'  tod value for 8 hours
TOD_1SEC DC   0F
         DC   X'F4240000'          tod for 1 second


LOWVALUEX DS   0CL16
         DC    16X'00'

LOCALDIF DC  X'0000800D'             -8 hours local time diff.

         END
/*
//L.SYSLMOD  DD  DSN=SYS1.SS.LINKLIB(RXUTC),DISP=SHR
//
