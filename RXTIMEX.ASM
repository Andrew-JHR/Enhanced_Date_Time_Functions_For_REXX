//ANDREWJA JOB  CLASS=A,MSGCLASS=X,NOTIFY=&SYSUID,REGION=0M
//STEP1    EXEC ASMACL,PARM.C='FLAG(NOCONT)',PARM.L='MAP,LET,LIST'
//C.SYSLIB DD   DSN=SYS1.MACLIB,DISP=SHR
//SYSIN    DD   *
*-----------------------------------------------------------------*
* Program function :
*   This program provides a REXX function to complement the built-in
*   TIME function
* Only two formats are accepted:
* 1. Converting HH:MM:SS to seconds since 00:00:00
*   secs = TIMEX('S', hhmmss, 'N')
*   e.g. TIMEX('S','23:59:59','N') will be 86399
*
* 2. Converting the seconds to HH:MM:SS
*   hhmmss = TIMEX('N',secs, 'S')
*   e.g. TIMEX('S','86399','N') gives 23:59:59
*
*   The program pass on result back to the REXX caller, unless there
*   is no input passed from the caller. In that case, the result passed
*   back to the caller is a warning message
*
* Assember : High Level Assembler 1.2 or above
* Author :   Andrew Jan
* Completion Date : Jul 9, 2013
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
W_D      DS    D
INPUTLEN DS    F
INPUTTXT DS    CL16
HH       DS    F
MM       DS    F
SS       DS    F
HMS      DS    0CL8
H2       DS    CL2
         DC    C':'
M2       DS    CL2
         DC    C':'
S2       DS    CL2
W_S      DS    CL5
ARG1     DS    CL1
ARG3     DS    CL1
*
WORKLEN  EQU   *-WORKDATA

         IRXEFPL ,                efpl, external function parm list
         IRXARGTB ,               argument list map
         IRXEVALB ,               evaluation block map

TIMEX    CSECT
TIMEX    AMODE 31
TIMEX    RMODE ANY

         STM   R14,R12,12(R13)    save caller's reg values
         LR    R12,R15            set base reg
         USING TIMEX,R12          setup addressibility
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

         USING EFPL,R8            r8 was saved from r1 earlier

         L     R9,EFPLARG         argument list  addr

         USING ARGTABLE_ENTRY,R9  addressibility
*ARGTABLE_ARGSTRING_PTR    DS  A        Address of the argument string
*ARGTABLE_ARGSTRING_LENGTH DS  F        Length of the argument string
*ARGTABLE_NEXT             DS  0D       Next ARGTABLE entry
*ARGTABLE_END DC  XL8'FFFFFFFFFFFFFFFF' End of ARGTABLE marker

         L     R11,EFPLEVAL       addr of evaluation block addr
         L     R11,0(,R11)        evaluation blk for result to return
         USING EVALBLOCK,R11      addressibility
*EVALBLOCK_EVSIZE DS  F           Size of EVALBLK in double word
*EVALBLOCK_EVLEN  DS  F           Length of data
*EVALBLOCK_EVDATA DS  C           Result

* check if any arg provided ?
         CLC   ARGTABLE_ARGSTRING_PTR(8),=XL8'FFFFFFFFFFFFFFFF'
         BE    NO_ARGS            yes, gives the warning


* there should be 3 arguments
         L     R7,ARGTABLE_ARGSTRING_PTR     addr of arg 1
         L     R3,ARGTABLE_ARGSTRING_LENGTH  len of arg 1
         C     R3,=F'1'               valid in length?
         BH    ARG_ERRORS             not valid
         CLI   0(R7),C'S'             correct?
         BE    ARG_0                  yes
         CLI   0(R7),C's'             correct?
         BNE   ARG_1                  no, branch
ARG_0    EQU   *
         MVI   ARG1,C'S'              keep the value
         B     ARG_5                  branch
ARG_1    EQU   *
         CLI   0(R7),C'N'             correct?
         BE    ARG_2                  yes
         CLI   0(R7),C'n'             correct?
         BNE   ARG_3                  no, branch
ARG_2    EQU   *
         MVI   ARG1,C'N'              keep the value
         B     ARG_5                  branch
ARG_3    EQU   *
         B     ARG_ERRORS             not valid
ARG_5    EQU   *
         LA    R9,ARGTABLE_NEXT              next arg
         L     R7,ARGTABLE_ARGSTRING_PTR     addr of arg 2
         L     R3,ARGTABLE_ARGSTRING_LENGTH  len of arg 2

         ST    R3,INPUTLEN        save the length
         BCTR  R3,0               minus 1 for ex

EXMVC    MVC   INPUTTXT(0),0(R7)  mask for ex
         EX    R3,EXMVC           do the mvc according the length

* chk argument 3
         LA    R9,ARGTABLE_NEXT              next arg
         L     R7,ARGTABLE_ARGSTRING_PTR     addr of arg 3
         L     R3,ARGTABLE_ARGSTRING_LENGTH  len of arg 3
         C     R3,=F'1'               valid in length?
         BH    ARG_ERRORS             not valid
         CLI   0(R7),C'S'             correct?
         BE    ARG_50                 yes
         CLI   0(R7),C's'             correct?
         BNE   ARG_51                 no, branch
ARG_50   EQU   *
         MVI   ARG3,C'S'              keep the value
         B     ARG_55                 check further
ARG_51   EQU   *
         CLI   0(R7),C'N'             correct?
         BE    ARG_52                 yes
         CLI   0(R7),C'n'             correct?
         BNE   ARG_53                 no, branch
ARG_52   EQU   *
         MVI   ARG3,C'N'              keep the value
         B     ARG_55                 branch
ARG_53   EQU   *
         B     ARG_ERRORS             not valid

ARG_55   EQU   *
         XC    ARG1,ARG3              check if args 1 & 3 the same?
         BZ    ARG_ERRORS             yes, error

         L     R3,INPUTLEN        load the length of arg2
         CLI   ARG3,C'N'          request to convert into seconds?
         BE    ARG_6              yes, branch
         C     R3,=F'5'           input must be 5 bytes in secs
         BNE   ARG_ERRORS         not valid

         MVC   W_S,INPUTTXT       keep the value of argument 2
         B     SEC2HMS            go on

ARG_6    EQU   *
         C     R3,=F'8'           input must be 8 bytes in HH:MM:SS
         BNE   ARG_ERRORS         not valid
         MVC   HMS,INPUTTXT       keep the value of argument 2
         B     HMS2SEC            go on

SEC2HMS  EQU   *
         PACK  W_D,W_S            pack the input seconds
         CVB   R3,W_D             convert to binary in R3
         XR    R2,R2              clear r2
         D     R2,=F'60'          divided by 60
         CVD   R2,W_D             convert the remainder into pk-dec
         UNPK  S2,W_D+6(2)        unpack to zoned decimal
         OI    S2+1,X'F0'         make it readable
         XR    R2,R2              clear r2
         D     R2,=F'60'          divide again the minutes for hh
         CVD   R2,W_D             convert the remainder minutes
         UNPK  M2,W_D+6(2)        unpack to zoned decimal
         OI    M2+1,X'F0'         make it readable
         CVD   R3,W_D             convert the hours
         UNPK  H2,W_D+6(2)        unpack to zoned decimal
         OI    H2+1,X'F0'         make it readable

         MVI   H2+2,C':'          delimiter
         MVI   M2+2,C':'          delimiter

         MVC   EVALBLOCK_EVDATA(8),HMS  move the result
         LA    R1,8               length of the result
         ST    R1,EVALBLOCK_EVLEN save back
         B     GO_BACK            branch to return

HMS2SEC  EQU   *
         PACK  W_D,H2             pack the HH
         CVB   R2,W_D             convert to binary
         ST    R2,HH              save it
         PACK  W_D,M2             pack the MM
         CVB   R2,W_D             convert to binary
         ST    R2,MM              save it
         PACK  W_D,S2             pack the MM
         CVB   R2,W_D             convert to binary
         ST    R2,SS              save it
         XR    R2,R2              clear r2
         LA    R3,3600            1 hour = 60*60 secs
         M     R2,HH              how many secs of the hours
         XR    R4,R4              clear r4
         LA    R5,60              1 min = 60 secs
         M     R4,MM              how many secs of the minutes
         AR    R3,R5              secs of hours+ secs of mins
         A     R3,SS              plus seconds
         CVD   R3,W_D             convert to packed decimal
         UNPK  W_S,W_D+5(3)       convert to zoned decimal
         OI    W_S+4,X'F0'        make it readable

         MVC   EVALBLOCK_EVDATA(5),W_S  move the result
         LA    R1,5               length of the result
         ST    R1,EVALBLOCK_EVLEN save back
         B     GO_BACK            branch to return

NO_ARGS  EQU   *
         MVC   EVALBLOCK_EVDATA(L'NO_ARGS_MSG),NO_ARGS_MSG  warning msg
         L     R1,=A(L'NO_ARGS_MSG)  length of warning message
         ST    R1,EVALBLOCK_EVLEN   save back

NO_ARG2  EQU   *
         MVC   EVALBLOCK_EVDATA(L'NO_ARG2_MSG),NO_ARG2_MSG  warning msg
         L     R1,=A(L'NO_ARG2_MSG)  length of warning message
         ST    R1,EVALBLOCK_EVLEN   save back

NO_ARG3  EQU   *
         MVC   EVALBLOCK_EVDATA(L'NO_ARG3_MSG),NO_ARG3_MSG  warning msg
         L     R1,=A(L'NO_ARG3_MSG)  length of warning message
         ST    R1,EVALBLOCK_EVLEN   save back

ARG_ERRORS      EQU   *
         MVC   EVALBLOCK_EVDATA(L'INV_ARG_MSG),INV_ARG_MSG  warning msg
         L     R1,=A(L'INV_ARG_MSG)  length of warning message
         ST    R1,EVALBLOCK_EVLEN   save back

*--go back-------------------------------*
GO_BACK  EQU   *

         L     R13,4(,R13)        restore caller's save area
         L     R1,8(,R13)         our work area's addr in r1

         FREEMAIN RU,LV=WORKLEN,A=(1)   free out work area

         LM    R14,R12,12(R13)     restore caller's reg values
         SR    R15,R15             rc = 0
         BR    R14                 go back

         LTORG


NO_ARGS_MSG  DC  C'No Arguments Provided!'
NO_ARG2_MSG  DC  C'No Argument Two!'
NO_ARG3_MSG  DC  C'No Argument Three!'
INV_ARG_MSG  DC  C'Possible Argument Errors!'

*----------------------------------------*
         END
/*
//L.SYSLMOD  DD  DSN=ANDREWJ.SOURCE.LMD(TIMEX),DISP=SHR
//
