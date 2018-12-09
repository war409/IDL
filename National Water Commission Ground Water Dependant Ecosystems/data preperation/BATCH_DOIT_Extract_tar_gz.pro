; ##############################################################################################
; NAME: BATCH_DOIT_Extract_tar_gz.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: NA
; DATE: 01/12/2010
; DLM: 01/12/2010
;
; DESCRIPTION:  This tool extracts tarred (.tar) and g-zip (.gz) compressed data files.
;               
; INPUT:        One or more compressed and tarred (.tar.gz) files.
;                
; OUTPUT:       Untarred and unzipped input files.
;               
; PARAMETERS:   Via IDL widgets, set:  
;           
;               1.  Select the Input Directory: The location of the input '.tar.gz' files.
;               
;               2.  Select the Output Directory: The uncompressed data files will be saved to 
;                   this location 
;                
; NOTES:        This program uses gzip.exe to extract the input .gz data. 
; 
;               See: 'http://www.gzip.org/'
;               
;               You will need to save the execution file gzip.exe to the current working directory. 
;               The program uses 7zip to un-tar the .tar file. See:
;               
;               '\\File-wron\Working\work\war409\Work\General\software\7z\7z465.exe'
;
;               After installing the above software use must copy '7z.exe' to the current working 
;               directory. See:
;
;               '\\File-wron\Working\work\war409\Work\General\software\7z\7z.exe'    
;               
;               To identify the CWD run the following from the IDL command line: 
;               CD, CURRENT=CWD & PRINT, CWD
;    
; ##############################################################################################


PRO BATCH_DOIT_Extract_tar_gz
  ;---------------------------------------------------------------------------------------------
  ; GET START TIME
  T_TIME = SYSTIME(1)
  ;--------------
  PRINT,''
  PRINT,'BEGIN PROCESSING: BATCH_DOIT_Extract_tar_gz'
  PRINT,''
  ;---------------------------------------------------------------------------------------------  
  ;*********************************************************************************************
  ; INPUT/OUTPUT:
  ;*********************************************************************************************
  ;---------------------------------------------------------------------------------------------  
  ; SELECT THE INPUT DATA:
  PATH = '\\File-wron\Working\work\NWC_Groundwater_Dependent_Ecosystems\Data\Imagery\Landsat\Howard East'
  IN_DIRECTORY = DIALOG_PICKFILE(PATH=PATH, TITLE='Select the Input Directory', /DIRECTORY)
  ;--------------
  ; ERROR CHECK:
  IF IN_DIRECTORY[0] EQ '' THEN RETURN
  ;---------------------------------------------------------------------------------------------
  ; CHANGE THE CURRENT-WORKING-DIRECTORY
  CD, IN_DIRECTORY, CURRENT=OWD
  ;--------------
  ; GET THE LIST OF FILES IN THE CURRENT-WORKING-DIRECTORY
  IN_FILES = FILE_SEARCH('*tar.gz')
  ;--------------
  ; ERROR CHECK:
  IF IN_FILES[0] EQ '' THEN RETURN
  ;--------------  
  ; RESET THE CURRENT-WORKING-DIRECTORY
  CD, OWD 
  ;---------------------------------------------------------------------------------------------
  ; SET THE OUTPUT DIRECTORY
  PATH='\\File-wron\Working\work\NWC_Groundwater_Dependent_Ecosystems\Data\Imagery\Landsat\Howard East'
  OUT_DIRECTORY = DIALOG_PICKFILE(PATH=PATH, TITLE='Select the Output Directory', /DIRECTORY, /OVERWRITE_PROMPT)
  ;-------------- 
  ; ERROR CHECK
  IF OUT_DIRECTORY EQ '' THEN RETURN
  ;---------------------------------------------------------------------------------------------  
  ;*********************************************************************************************
  ; FILE LOOP:
  ;*********************************************************************************************
  ;---------------------------------------------------------------------------------------------
  FOR i=0, N_ELEMENTS(IN_FILES)-1 DO BEGIN ; FOR i
    ;-------------------------------------------------------------------------------------------
    ; GET START TIME: DATE LOOP
    L_TIME = SYSTIME(1)
    ;-------------------------------------------------------------------------------------------
    ; SET THE j-TH FILE
    FNAME = IN_FILES[i]
    ;--------------
    ; SET THE FULL INPUT FILE NAME
    FILE_IN = IN_DIRECTORY + FNAME
    ;-------------- 
    ; CHECK FILE EXISTS
    FILE_INFO = FILE_INFO(FILE_IN)
    IF FILE_INFO.EXISTS EQ 1 THEN BEGIN
      ;--------------
      ; GET FILENAME SHORT:
      FNAME_START = STRPOS(FILE_IN, '\', /REVERSE_SEARCH)+1
      FNAME_LENGTH = (STRLEN(FILE_IN)-FNAME_START)-7
      FNS = STRMID(FILE_IN, FNAME_START, FNAME_LENGTH)
      ;--------------
      ; SET TEMP FILE
      FILE_TEMP =  OUT_DIRECTORY + FNS + '.tar' 
      ;--------------
      ; UNZIP THE INPUT FILE TO THE TEMP FILE
      SPAWN, 'gzip -d -c ' + '"' +  FILE_IN + '"' + ' > ' + '"' + FILE_TEMP + '"', Result, ErrResult, /HIDE 
      ;--------------
      ; ERROR CHECK
      IF (N_ELEMENTS(ErrResult) EQ 1) AND (ErrResult[0] EQ '') THEN BEGIN
      ;--------------
      ENDIF ELSE BEGIN ; BAD FILE
        PRINT, 'FILE CORRUPT, RETURNING -1'
        DATA = -1
      ENDELSE
      ;-----------------------------------------------------------------------------------------
    ENDIF ELSE BEGIN ; BAD FILENAME
      PRINT, 'FILE NOT FOUND, RETURNING -1'
      DATA = -1
    ENDELSE
    ;-------------------------------------------------------------------------------------------
    ; CHECK FILE:
    FILE_INFO = FILE_INFO(FILE_TEMP)
    IF FILE_INFO.EXISTS EQ 1 THEN BEGIN
      ;--------------
      ; UNTAR THE UNCOMPRESSED GZIP FILE
      SPAWN, '7z x ' + '"' +  FILE_TEMP + '"' + ' -o' + '"' + OUT_DIRECTORY + '"', /NOSHELL, Result, ErrResult, /HIDE
      ;--------------
      ; DELETE THE UNCOMPRESSED TAR FILE
      FILE_DELETE, FILE_TEMP
      ;--------------
    ENDIF ELSE BEGIN ; BAD FILENAME
      PRINT, 'FILE NOT FOUND, RETURNING -1'
      DATA = -1
    ENDELSE  
    ;-------------------------------------------------------------------------------------------
    ; PRINT LOOP INFORMATION:
    ;-----------------------------------   
    ; GET END TIME
    SECONDS = (SYSTIME(1)-L_TIME)
    ;--------------
    PRINT, '  PROCESSING TIME: ', STRTRIM(SECONDS, 2), ' SECONDS, FOR FILE ', STRTRIM(i+1, 2), ' OF ', $
      STRTRIM(N_ELEMENTS(IN_FILES), 2)
    ;-------------------------------------------------------------------------------------------
  ENDFOR
  ;---------------------------------------------------------------------------------------------
  ; PRINT SCRIPT INFORMATION:
  ;-----------------------------------
  ; GET END TIME
  MINUTES = (SYSTIME(1)-T_TIME)/60
  HOURS = MINUTES/60
  ;--------------
  PRINT,''
  PRINT,'TOTAL PROCESSING TIME: ', STRTRIM(MINUTES, 2), ' MINUTES (', STRTRIM(HOURS, 2),   ' HOURS)'
  PRINT,''
  PRINT,'FINISHED PROCESSING: BATCH_DOIT_Extract_tar_gz'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
END

