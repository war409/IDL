; ######################################################################
; NAME: RENAME_ASAR_GM.pro
; LANGUAGE: ENVI IDL
; AUTHOR: Garth Warren 
; DATE: 13/01/2010
; DLM: 13/01/2010
; 
; DESCRIPTION: This tool re-names the ASARGM files.
; 
; INPUT: Source directory and destination directory.
; 
; OUTPUT: No new files are created, the input files are simply re-named.
; 
; SET PARAMETERS: Via widgets.
; 
; NOTES: This tool can be used to re-name and move files.
; ######################################################################
;
PRO RENAME_ASAR_GM
  ; GET START TIME
  T_TIME = SYSTIME(1)
  PRINT,''
  PRINT,'BEGIN PROCESSING: RENAME_ASAR_GM'
  ;---------------------------------------------------------------------
  ; SET INPUT OUTPUT:
  ;---------------------------------------------------------------------  
  ; SET INPUT DIRECTORY
  INDIR = DIALOG_PICKFILE(/DIRECTORY, TITLE='SELECT INPUT DIRECTORY', $
    PATH='\\File-wron\RemoteSensing\ASAR_GM\ENVI_daily\Australia_BINARY_8DAY\')
  ;---------------------------------------------------------------------
  ; SET OUTPUT DIRECTORY
  OUTDIR = DIALOG_PICKFILE(/DIRECTORY, TITLE='SELECT OUTPUT DIRECTORY', $
    PATH='\\File-wron\RemoteSensing\ASAR_GM\ENVI_daily\Australia_BINARY_8DAY\')
  ;---------------------------------------------------------------------
  ; GET INPUT DIRECTORY FILE LIST                                
  FILELIST = FILE_SEARCH(INDIR, "*.bin", COUNT=FCOUNT)
  ;---------------------------------------------------------------------  
  ; FILELIST LOOP:
  ;---------------------------------------------------------------------
  FOR i=0, FCOUNT-1 DO BEGIN ; START 'FOR i'
    ;-------------------------------------------------------------------
    ; GET START TIME
    L_TIME = SYSTIME(1)
    ;-------------------------------------------------------------------
    ; GET FILENAME
    INFILE = FILELIST[i]
    ;-------------------------------------------------------------------
    ; MANIPULATE FILENAME TO GET FILENAME SHORT    
    STARTPOS = STRPOS(INFILE, '\', /REVERSE_SEARCH)+1
    FNAMEL = STRLEN(INFILE)-STARTPOS
    FNAME = STRMID(INFILE, STARTPOS, FNAMEL)
    ;-------------------------------------------------------------------
    ; MANIPULATE FILENAME TO GET DATE
    ;-------------------------------------------------------------------
    ; GET START DATE FROM FILENAME
    SYYYY = STRMID(FNAME, 27, 4)
    SMM = STRMID(FNAME, 25, 2)
    SDD = STRMID(FNAME, 23, 2)
    ; GET DAY OF YEAR AND JULIAN DATE 
    SDOY = JULDAY(SMM, SDD, SYYYY) - JULDAY(1, 0, SYYYY)
    SDMY = JULDAY(SMM, SDD, SYYYY)
    ; GET END DATE FROM FILENAME 
    EYYYY = STRMID(FNAME, 39, 4)
    EMM = STRMID(FNAME, 37, 2)
    EDD = STRMID(FNAME, 35, 2)
    ;-------------------------------------------------------------------
    IF SDOY LE 9 THEN SDOY = '00' + STRING(STRTRIM(SDOY,2))
    IF (SDOY LE 99) AND (SDOY GT 9) THEN SDOY = '0' + STRING(STRTRIM(SDOY,2))
    ;-------------------------------------------------------------------
    ; BUILD NEW NAME
    NEWNAMEA = 'TUW.ASAGW.SSM.002.8DAY.500M.'
    NEWNAMEB = STRTRIM(SYYYY, 2) + STRTRIM(SDOY, 2) + '.bin'
    NEWNAME = NEWNAMEA + NEWNAMEB
    OUTFILE = OUTDIR + NEWNAME
    ; MOVE/RENAME FILE
    FILE_MOVE, INFILE, OUTFILE, /NOEXPAND_PATH
    ;-------------------------------------------------------------------
    ; PRINT LOOP TIME
    SECONDS = (SYSTIME(1)-L_TIME)
    PRINT, ''
    PRINT, '  ', STRTRIM(SECONDS, 2), ' SECONDS. FILE NO. ', STRTRIM(i+1, 2), $
      ' OF ', STRTRIM(FCOUNT, 2)
    ;-------------------------------------------------------------------   
  ENDFOR ; END 'FOR i'
  ;---------------------------------------------------------------------  
  PRINT,''
  MINUTES = (SYSTIME(1)-T_TIME)/60
  PRINT,'TOTAL PROCESSING TIME: ', STRTRIM(MINUTES, 2), '  MINUTES'
  PRINT,''
  PRINT,'FINISHED PROCESSING: RENAME_ASAR_GM'
  PRINT,'' 
END 