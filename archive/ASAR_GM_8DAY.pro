; ###################################################################### 
; NAME: ASAR_GM_8DAY.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren 
; DATE: 22/09/2009
; DLM: 29/10/2009*
; DESCRIPTION: Create 8-day ASAR GM SSM composite binary files.
; INPUT: Daily ASAR GM SSM binary data.
; OUTPUT: 8-day median ASAR GM SSM flat binary data.
; SET PARAMETERS:
;   MANIPULATE FILE: YYY, MMM, DDD
;   DATE LOOP: SA (Start Date), EA (End Date)
;   MAKE ARRAY LOOP: Number of loops (currently set to 10), COLVALUE (original
;       array size divided by the number of loops
;   FILL LOOP: File manipulation (NAME, ROOT, PATH)  247.0),
;       OUTPATH, OUTNAMEA, SUBDIRECTORY
; NOTES: *MAJOR UPDATE: implemented to avoid upper array size limit crash 
; ######################################################################
;
PRO ASAR_GM_8DAY
  F_DATE = SYSTIME(1)
  PRINT,''
  PRINT,'BEGIN PROCESSING: ASAR_GM_8DAY'
  PRINT,'GET FULL FILE NAME LIST'
  ; GET FILE NAMES
  ALLFILENAME = FILE_SEARCH("R:/ASAR_GM/ENVI_daily/Australia_BINARY_TransponseB4Saving/", "*.bin", COUNT=COUNT)
  ;
  ; MANIPULATE FILE NAMES TO GET DATE
  YYY = STRMID(ALLFILENAME, 76, 4)
  MMM = STRMID(ALLFILENAME, 80, 2)
  DDD = STRMID(ALLFILENAME, 82, 2)
  DMY = JULDAY(MMM, DDD, YYY)
  ;
  ; SETUP DATE LOOP
  SA = JULDAY(4, 7, 2006) ; (M,D,YYYY)
  DA = 8
  EA = JULDAY(4, 14, 2006) ; (M,D,YYYY)
  VA = SA
  ;
  ; DATE LOOP
  WHILE (VA = VA + DA) LE EA DO BEGIN
    T_DATE = SYSTIME(1)
    DRS = (VA - DA)
    PRINT,''
    PRINT,'  DATE LOOP: START'  
    ; RELATIONAL STATEMENT TO GET DATE RANGE
    INDEX = WHERE(((DMY LE VA) AND (DMY GE DRS)), COUNT)
    ; SET COUNT VARIABLE
    COUNTSPLIT = COUNT
    ; OUTPUT NAME PART 2 FILL NAME WITH DATE RANGE - PRECURSIVE TO PART 1
    OUTNAMEBa = STRTRIM(DRS, 2)
    CALDAT, OUTNAMEBa, Month, Day, Year
    IF Day LE 9 THEN Day = (STRING(0) + STRING(STRTRIM(Day, 2))) ELSE Day = Day
    IF Month LE 9 THEN Month = (STRING(0) + STRING(STRTRIM(Month, 2))) ELSE Month = Month  
    OUTNAMEB = STRTRIM(Day, 2) + STRTRIM(Month, 2) + STRTRIM(Year, 2)
    PRINT, '  START DATE: ', OUTNAMEB
    ;
    OUTNAMECa = STRTRIM((VA-1), 2)
    CALDAT, OUTNAMECa, Month, Day, Year
    IF Day LE 9 THEN Day = (STRING(0) + STRING(STRTRIM(Day, 2))) ELSE Day = Day
    IF Month LE 9 THEN Month = (STRING(0) + STRING(STRTRIM(Month, 2))) ELSE Month = Month 
    OUTNAMEC = STRTRIM(Day, 2) + STRTRIM(Month, 2) + STRTRIM(Year, 2)
    PRINT, '  END DATE: ', OUTNAMEC
    IF (COUNTSPLIT EQ 0) THEN BEGIN
      PRINT,'' 
      PRINT, '  NO FILES IN DATE RANGE! ...GO TO NEXT DATE RANGE'
    ENDIF ELSE BEGIN
      ; GET FILES IN DATE RANGE
      FILENAME = ALLFILENAME[INDEX]
      PRINT,''
      PRINT, FILENAME
      PRINT,'' 
      PRINT, '  NO. OF FILES: ', COUNT
      IF COUNT LE 13 THEN BEGIN
        ;---------------------------------------------------------------------------------
        ; WRITE NEW EMPTY OUTPUT FILE
        PRINT, '  WRITE NEW EMPTY OUTPUT FILE'
        ; SET THE OUTPUT FILE PATH AND NAME
        ; OUTPUT PATH
        OUTPATH = 'R:/ASAR_GM/ENVI_daily/Australia_BINARY_8DAY/2006/'
        ; OUTPUT NAME PART 1
        OUTNAMEA = 'TUW_ASAGW_SSM_002_8DAY_'
        ; BUILD NAME
        OUTNAME = OUTNAMEA + OUTNAMEB + '_TO_' + OUTNAMEC + '.bin'
        ; BUILD NAME WITH PATH
        OUTPATHOUTNAME = OUTPATH + OUTNAMEA + OUTNAMEB + OUTNAMEC + '.bin'
        ; SET FUNCTION 'FILEPATH'
        OUTFILE = FILEPATH(OUTNAME, ROOT_DIR='R:\', SUBDIRECTORY='ASAR_GM\ENVI_daily\Australia_BINARY_8DAY\2006')
        PRINT, '  OUTPUT: ', OUTNAME
        ; CREATE THE FILE 
        OPENW, UNIT, OUTFILE, /GET_LUN
        ; CLOSE THE FILE
        FREE_LUN, UNIT
        ;
        PRINT,''
        PRINT,'  DATE LOOP: END'
        ;
        ; MAKE ARRAY LOOP
        FOR i=0, 10-1 DO BEGIN
          PRINT,''
          PRINT,'    MASTER ARRAY LOOP: START SPLIT MATRIX', i+1, ' OF 10'
          ; SET ARRAY COLUMN VALUE (71380580/10)=7138058
          COLVALUE = 7138058
          ; SET FILL ARRAY POSITION VALUES
          ENDPOSa = (i+1)*COLVALUE
          ONE = 1   
          STARTPOS = ENDPOSa-COLVALUE
          ENDPOS = ENDPOSa-ONE
          PRINT, '    START POSITION: ', STARTPOS
          PRINT, '    END POSITION: ', ENDPOS
          ; CREATE ARRAY
          MATRIX = MAKE_ARRAY(COLVALUE, COUNTSPLIT, /INTEGER)
          ;
          ; FILL ARRAY LOOP  
          FOR k=0, COUNTSPLIT-1 DO BEGIN
            PRINT,'      FILL ARRAY LOOP: START FILE', k+1
            ; SET THE INPUT FILE PATH AND NAME      
            NAME = STRMID(FILENAME[k], 58, 44)
            ROOT = 'R:\'
            PATH = STRMID(FILENAME[k], 3, 55)
            PRINT,'      OPEN FILE AND INSERT DATA: ', NAME
            FILEOPEN = FILEPATH(NAME, ROOT_DIR=ROOT, SUBDIRECTORY=PATH)
            OUT = READ_BINARY(FILEOPEN, DATA_TYPE=1)
            ; FILL ARRAY       
            MATRIX[*,k] = OUT(STARTPOS:ENDPOS)
            PRINT,'      FILL ARRAY LOOP: END FILE', k+1
          ENDFOR
          ; CALCULATE & WRITE
          PRINT,''
          PRINT, '    CALCULATE ARRAY MEDIAN & WRITE'
          ; SET NODATA VALUES TO NaN IN MATRIX
          MATRIX = FLOAT(MATRIX)
          j = WHERE(MATRIX EQ 247.00, COUNT)
          IF (COUNT GT 0) THEN MATRIX[j] = !VALUES.F_NAN
          ; IF ONLY ONE FILE FOR THE UNIQUE DATE THEN...
          IF COUNTSPLIT GE 2 THEN BEGIN
            ; GET MEDIAN
            OUTMEDIAN = MEDIAN(MATRIX, DIMENSION=2, /EVEN)
            ; SET OUTMEDIAN NaN TO 247
            k= WHERE(FINITE(OUTMEDIAN, /NAN), COUNT)
            IF (COUNT GT 0) THEN OUTMEDIAN[k] = 247.00
            ; CONVERT MEDIAN ARRAY TO BYTE
            OUTMEDIANBYTE = BYTE(OUTMEDIAN) 
          ENDIF ELSE BEGIN
            PRINT,''
            PRINT,'      ***ONLY 1 FILE IN DATE RANGE ',OUTNAMEB
            PRINT,''
            ; SET OUTMEDIAN NaN TO 247
            k= WHERE(FINITE(MATRIX, /NAN), COUNT)
            IF (COUNT GT 0) THEN MATRIX[k] = 247.00
            ; CONVERT MEDIAN ARRAY TO BYTE
            OUTMEDIANBYTE = BYTE(MATRIX)
          ENDELSE
          ; OPEN OUTPUT FILE
          OPENU, UNIT, OUTFILE, /APPEND, /GET_LUN
          ; WRITE TO THE OUTPUT FILE
          WRITEU, UNIT, OUTMEDIANBYTE
          ; CLOSE THE OUTPUT FILE
          FREE_LUN, UNIT
          PRINT,'    MASTER ARRAY LOOP: END; SPLIT MATRIX', i+1, ' OF 10'
        ENDFOR
        ; PRINT PROCESSING TIME
        MINUTES = (SYSTIME(1)-T_DATE)/60
        PRINT, MINUTES,'  MINUTES FOR MAKE COMPOSITE: ', OUTNAME
        ;---------------------------------------------------------------------------------
      ENDIF ELSE BEGIN
        ;
        ;
        ; IF COUNT GREATER THAN 15 FILES PROCESS EACH SINGLE DATE INDIVIDUALLY
        ; DATE LOOP SPECIAL 1 ------------------------------------------
        ; MANIPULATE FILE NAMES TO GET DATE
        YYY2 = STRMID(FILENAME, 76, 4)
        MMM2 = STRMID(FILENAME, 80, 2)
        DDD2 = STRMID(FILENAME, 82, 2)
        DMY2 = JULDAY(MMM2, DDD2, YYY2)
        ; GET UNIQUE DATES
        UDMY = DMY2[UNIQ(DMY2, SORT(DMY2))]
        ; GET COUNT OF UNIQUE DATES
        z = WHERE(UDMY, COUNT)
        UNIQC = COUNT
        ; LOOP FOR EACH UNIQUE DATE
        FOR l=0, UNIQC-1 DO BEGIN
            ; RELATIONAL STATEMENT TO GET FILES FOR UNIQUE DATE
            INDEX = WHERE(((DMY2 EQ UDMY[l])), COUNT)
            ; FILES IN UNIQUE DATE RANGE
            FILENAME2 = FILENAME[INDEX]
            PRINT,''
            PRINT, FILENAME2
            PRINT,'' 
            PRINT, '  NO. OF FILES IN UNIQUE: ', COUNT
            ; SET COUNT VARIABLE
            COUNTSPLIT = COUNT
            ;
            ; OUTPUT NAME PART 2(SPECIAL) FILL NAME WITH DATE RANGE - PRECURSIVE TO PART 1(SPECIAL)
            OUTNAMEBa = STRTRIM(UDMY[l], 2)
            CALDAT, OUTNAMEBa, Month, Day, Year
            IF Day LE 9 THEN Day = (STRING(0) + STRING(STRTRIM(Day, 2))) ELSE Day = Day
            IF Month LE 9 THEN Month = (STRING(0) + STRING(STRTRIM(Month, 2))) ELSE Month = Month  
            OUTNAMEB = STRTRIM(Day, 2) + STRTRIM(Month, 2) + STRTRIM(Year, 2)
            PRINT, '  UNIQUE START DATE: ', OUTNAMEB
            ;
            OUTNAMEC = OUTNAMEB
            ; 
            ; WRITE NEW EMPTY OUTPUT FILE
            PRINT, '  WRITE NEW EMPTY TEMP OUTPUT FILE'
            ; SET THE OUTPUT FILE PATH AND NAME
            ; OUTPUT PATH
            OUTPATH = 'R:/ASAR_GM/ENVI_daily/Australia_BINARY_8DAY/2006/TEMP/'
            ; OUTPUT NAME PART 1
            OUTNAMEA = 'TUW_ASAGW_SSM_002_8DAY_'
            ; BUILD NAME
            OUTNAME = OUTNAMEA + OUTNAMEB + '_TO_' + OUTNAMEC + '.bin'
            ; BUILD NAME WITH PATH
            OUTPATHOUTNAME = OUTPATH + OUTNAMEA + OUTNAMEB + OUTNAMEC + '.bin'
            ; SET FUNCTION 'FILEPATH'
            OUTFILE = FILEPATH(OUTNAME, ROOT_DIR='R:\', SUBDIRECTORY='ASAR_GM\ENVI_daily\Australia_BINARY_8DAY\2006\TEMP')
            PRINT, '  TEMP OUTPUT: ', OUTPATHOUTNAME
            ; CREATE THE FILE 
            OPENW, UNIT, OUTFILE, /GET_LUN
            ; CLOSE THE FILE
            FREE_LUN, UNIT
            ;
            PRINT,''
            PRINT,'  UNIQUE DATE LOOP: END'
            ;
            ; MAKE ARRAY LOOP
            FOR i=0, 10-1 DO BEGIN
              PRINT,''
              PRINT,'    MASTER ARRAY LOOP (UNIQUE): START SPLIT MATRIX', i+1, ' OF 10'
              ; SET ARRAY COLUMN VALUE (71380580/10)=7138058
              COLVALUE = 7138058
              ; SET FILL ARRAY POSITION VALUES
              ENDPOSa = (i+1)*COLVALUE
              ONE = 1   
              STARTPOS = ENDPOSa-COLVALUE
              ENDPOS = ENDPOSa-ONE
              PRINT, '    START POSITION: ', STARTPOS
              PRINT, '    END POSITION: ', ENDPOS
              ; CREATE ARRAY
              MATRIX = MAKE_ARRAY(COLVALUE, COUNTSPLIT, /INTEGER)
              ;
              ; FILL ARRAY LOOP
              FOR k=0, COUNTSPLIT-1 DO BEGIN
                PRINT,'      FILL ARRAY LOOP: START FILE', k+1
                ; SET THE INPUT FILE PATH AND NAME      
                NAME = STRMID(FILENAME2[k], 58, 44)
                ROOT = 'R:\'
                PATH = STRMID(FILENAME2[k], 3, 55)
                PRINT,'      OPEN FILE AND INSERT DATA: ', NAME
                FILEOPEN = FILEPATH(NAME, ROOT_DIR=ROOT, SUBDIRECTORY=PATH)
                OUT = READ_BINARY(FILEOPEN, DATA_TYPE=1)
                ; FILL ARRAY       
                MATRIX[*,k] = OUT(STARTPOS:ENDPOS)
                PRINT,'      FILL ARRAY LOOP: END FILE', k+1
              ENDFOR
              ; CALCULATE & WRITE
              PRINT,''
              PRINT, '    CALCULATE ARRAY MEDIAN & WRITE'
              ; SET NODATA VALUES TO NaN IN MATRIX
              MATRIX = FLOAT(MATRIX)
              j = WHERE(MATRIX EQ 247.00, COUNT)
              IF (COUNT GT 0) THEN MATRIX[j] = !VALUES.F_NAN
              ; IF ONLY ONE FILE FOR THE UNIQUE DATE THEN...
              IF COUNTSPLIT GE 2 THEN BEGIN
                ; GET MEDIAN
                OUTMEDIAN = MEDIAN(MATRIX, DIMENSION=2, /EVEN)
                ; SET OUTMEDIAN NaN TO 247
                k= WHERE(FINITE(OUTMEDIAN, /NAN), COUNT)
                IF (COUNT GT 0) THEN OUTMEDIAN[k] = 247.00
                ; CONVERT MEDIAN ARRAY TO BYTE
                OUTMEDIANBYTE = BYTE(OUTMEDIAN)
              ENDIF ELSE BEGIN
                PRINT,''
                PRINT,'      ***ONLY 1 FILE IN UNIQUE DATE RANGE ',OUTNAMEB
                PRINT,''
                ; SET OUTMEDIAN NaN TO 247
                k= WHERE(FINITE(MATRIX, /NAN), COUNT)
                IF (COUNT GT 0) THEN MATRIX[k] = 247.00
                ; CONVERT MEDIAN ARRAY TO BYTE
                OUTMEDIANBYTE = BYTE(MATRIX)
              ENDELSE
              ; OPEN OUTPUT FILE
              OPENU, UNIT, OUTFILE, /APPEND, /GET_LUN
              ; WRITE TO THE OUTPUT FILE
              WRITEU, UNIT, OUTMEDIANBYTE
              ; CLOSE THE OUTPUT FILE
              FREE_LUN, UNIT
              PRINT,'    MASTER ARRAY LOOP (UNIQUE): END; SPLIT MATRIX', i+1, ' OF 10'
            ENDFOR
        ENDFOR
        ;
        ;
        ; DATE LOOP SPECIAL 2 ------------------------------------------
        PRINT,'GET FULL FILE NAME LIST'
        ; GET FILE NAMES
        ALLFILENAME2 = FILE_SEARCH("R:/ASAR_GM/ENVI_daily/Australia_BINARY_8DAY/2006/TEMP/", "*.bin", COUNT=COUNT)
        ;
        ; MANIPULATE FILE NAMES TO GET DATE
        YYY3 = STRMID(ALLFILENAME2, 81, 4)
        MMM3 = STRMID(ALLFILENAME2, 79, 2)
        DDD3 = STRMID(ALLFILENAME2, 77, 2)
        DMY3 = JULDAY(MMM3, DDD3, YYY3)
        ;
        ; SETUP DATE LOOP
        SA2 = SA
        DA2 = DA
        EA2 = EA
        VA2 = SA2
        ;
        ; DATE LOOP
        WHILE (VA2 = VA2 + DA2) LE EA DO BEGIN
          T_DATE = SYSTIME(1)
          DRS2 = (VA2 - DA2)
          PRINT,''
          PRINT,'  DATE LOOP: START'  
          ; RELATIONAL STATEMENT TO GET DATE RANGE
          INDEX = WHERE(((DMY3 LE VA2) AND (DMY3 GE DRS2)), COUNT)
          ; SET COUNT VARIABLE
          COUNTSPLIT = COUNT
          ; OUTPUT NAME PART 2 FILL NAME WITH DATE RANGE - PRECURSIVE TO PART 1
          OUTNAMEBa = STRTRIM(DRS2, 2)
          CALDAT, OUTNAMEBa, Month, Day, Year
          IF Day LE 9 THEN Day = (STRING(0) + STRING(STRTRIM(Day, 2))) ELSE Day = Day
          IF Month LE 9 THEN Month = (STRING(0) + STRING(STRTRIM(Month, 2))) ELSE Month = Month
          OUTNAMEB = STRTRIM(Day, 2) + STRTRIM(Month, 2) + STRTRIM(Year, 2)
          PRINT, '  START DATE: ', OUTNAMEB
          ;
          OUTNAMECa = STRTRIM((VA2-1), 2)
          CALDAT, OUTNAMECa, Month, Day, Year
          IF Day LE 9 THEN Day = (STRING(0) + STRING(STRTRIM(Day, 2))) ELSE Day = Day
          IF Month LE 9 THEN Month = (STRING(0) + STRING(STRTRIM(Month, 2))) ELSE Month = Month
          OUTNAMEC = STRTRIM(Day, 2) + STRTRIM(Month, 2) + STRTRIM(Year, 2)
          PRINT, '  END DATE: ', OUTNAMEC
          IF (COUNTSPLIT EQ 0) THEN BEGIN
            PRINT,'' 
            PRINT, '  NO FILES IN DATE RANGE! ...GO TO NEXT DATE RANGE'
          ENDIF ELSE BEGIN
          ; GET FILES IN DATE RANGE
          FILENAME = ALLFILENAME2[INDEX]
          PRINT,''
          PRINT, FILENAME
          PRINT,'' 
          PRINT, '  NO. OF FILES: ', COUNT
          ; WRITE NEW EMPTY OUTPUT FILE
          PRINT, '  WRITE NEW EMPTY OUTPUT FILE'
          ; SET THE OUTPUT FILE PATH AND NAME
          ; OUTPUT PATH
          OUTPATH = 'R:/ASAR_GM/ENVI_daily/Australia_BINARY_8DAY/2006/'
          ; OUTPUT NAME PART 1
          OUTNAMEA = 'TUW_ASAGW_SSM_002_8DAY_'
          ; BUILD NAME
          OUTNAME = OUTNAMEA + OUTNAMEB + '_TO_' + OUTNAMEC + '.bin'
          ; BUILD NAME WITH PATH
          OUTPATHOUTNAME = OUTPATH + OUTNAMEA + OUTNAMEB + OUTNAMEC + '.bin'
          ; SET FUNCTION 'FILEPATH'
          OUTFILE = FILEPATH(OUTNAME, ROOT_DIR='R:\', SUBDIRECTORY='ASAR_GM\ENVI_daily\Australia_BINARY_8DAY\2006')
          PRINT, '  OUTPUT: ', OUTPATHOUTNAME
          ; CREATE THE FILE 
          OPENW, UNIT, OUTFILE, /GET_LUN
          ; CLOSE THE FILE
          FREE_LUN, UNIT
          ;
          PRINT,''
          PRINT,'  DATE LOOP: END'
          ;
          ; MAKE ARRAY LOOP
          FOR i=0, 10-1 DO BEGIN
            PRINT,''
            PRINT,'    MASTER ARRAY LOOP: START SPLIT MATRIX', i+1, ' OF 10'
            ; SET ARRAY COLUMN VALUE (71380580/10)=7138058
            COLVALUE = 7138058
            ; SET FILL ARRAY POSITION VALUES
            ENDPOSa = (i+1)*COLVALUE
            ONE = 1   
            STARTPOS = ENDPOSa-COLVALUE
            ENDPOS = ENDPOSa-ONE
            PRINT, '    START POSITION: ', STARTPOS
            PRINT, '    END POSITION: ', ENDPOS
            ; CREATE ARRAY
            MATRIX = MAKE_ARRAY(COLVALUE, COUNTSPLIT, /INTEGER)
            ;
            ; FILL ARRAY LOOP  
            FOR k=0, COUNTSPLIT-1 DO BEGIN
                PRINT,'      FILL ARRAY LOOP: START FILE', k+1
                ; SET THE INPUT FILE PATH AND NAME      
                NAME = STRMID(FILENAME[k], 54, 48)
                ROOT = 'R:\'
                PATH = STRMID(FILENAME[k], 3, 50)
                PRINT,'      OPEN FILE AND INSERT DATA: ', NAME
                FILEOPEN = FILEPATH(NAME, ROOT_DIR=ROOT, SUBDIRECTORY=PATH)
                OUT = READ_BINARY(FILEOPEN, DATA_TYPE=1)
                ; FILL ARRAY       
                MATRIX[*,k] = OUT(STARTPOS:ENDPOS)
                PRINT,'      FILL ARRAY LOOP: END FILE', k+1
            ENDFOR
            ; CALCULATE & WRITE
            PRINT,''
            PRINT, '    CALCULATE ARRAY MEDIAN & WRITE'
            ; SET NODATA VALUES TO NaN IN MATRIX
            MATRIX = FLOAT(MATRIX)
            j = WHERE(MATRIX EQ 247.00, COUNT)
            IF (COUNT GT 0) THEN MATRIX[j] = !VALUES.F_NAN
            ; GET MEDIAN
            OUTMEDIAN = MEDIAN(MATRIX, DIMENSION=2, /EVEN)
            ; SET OUTMEDIAN NaN TO 247
            k= WHERE(FINITE(OUTMEDIAN, /NAN), COUNT)
            IF (COUNT GT 0) THEN OUTMEDIAN[k] = 247.00
            ; CONVERT MEDIAN ARRAY TO BYTE
            OUTMEDIANBYTE = BYTE(OUTMEDIAN)
            ; OPEN OUTPUT FILE
            OPENU, UNIT, OUTFILE, /APPEND, /GET_LUN
            ; WRITE TO THE OUTPUT FILE
            WRITEU, UNIT, OUTMEDIANBYTE
            ; CLOSE THE OUTPUT FILE
            FREE_LUN, UNIT
            PRINT,'    MASTER ARRAY LOOP: END; SPLIT MATRIX', i+1, ' OF 10'
          ENDFOR
          ; PRINT PROCESSING TIME
          MINUTES = (SYSTIME(1)-T_DATE)/60
          PRINT, MINUTES,'  MINUTES FOR MAKE COMPOSITE: ', OUTNAME
          ENDELSE
        ENDWHILE
      ENDELSE
    ENDELSE    
  ENDWHILE
  PRINT,''
  ; PRINT FULL PROCESSING TIME
  MINUTES = (SYSTIME(1)-F_DATE)/60
  PRINT, MINUTES,'  MINUTES TOTAL'
  PRINT,''
  PRINT, 'FINISHED PROCESSING: ASAR_GM_8DAY'
END
