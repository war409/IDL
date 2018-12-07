; ##########################################################################
; NAME: URLGET_FAO_versionB.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: NA
; DATE: 04/02/2010
; DLM: 30/03/2010
; 
; DESCRIPTION: This tool downloads all Australian Landsat data from the 
;              Global Forest Resources Assessment Portal...
;              http://geonetwork4.fao.org/geonetwork/
;              
; INPUT:       Define the output directory, the input name file and the base
;              URL. 
; 
; OUTPUT:      Compressed Landsat data.
; 
; PARAMETERS:  See script for details.
;                          
; NOTES:       Version B uses MS DOS WGET to connect to, and download data.
;              The WGET execusion file must be placed in the output file.
;              See: http://users.ugent.be/~bpuype/wget/
; 
; ##########################################################################
;
PRO URLGET_FAO_versionB
  ;-------------------------------------------------------------------------
  ; GET START TIME
  T_TIME = SYSTIME(1)
  PRINT,''
  PRINT,'BEGIN PROCESSING: URLGET_FAO_versionB'
  PRINT,''
  ;-------------------------------------------------------------------------
  ;*************************************************************************
  ; INPUT/OUTPUT:
  ;*************************************************************************
  ;-------------------------------------------------------------------------
  ; SET INPUT FILE - CONTAINING THE URL FILE NAMES
  INFILE = 'C:\Landsat\In\glsXXXX.txt'
  ;-------------------------------------------------------------------------
  ; SET OUTPUT DIRECTORY - TO CONTAIN THE DOWNLOADED FILES
  OUTPATH = 'C:/Landsat/Out/'
  ;-------------------------------------------------------------------------
  ; SET URL PATH
  INURL = 'http://globalmonitoring.sdstate.edu/projects/fao/'
  ;-------------------------------------------------------------------------
  ; OPEN INPUT FILE
  OPENR, INFILElun, INFILE, /GET_LUN
  ; GET THE FILE COUNT
  FILEC = FILE_LINES(INFILE)
  ;PRINT INFORMATION
  PRINT, 'FILE COUNT: ', FILEC
  ;-------------------------------------------------------------------------
  ;*************************************************************************
  ; GET DATA:
  ;*************************************************************************
  ;-------------------------------------------------------------------------
  ; SET COUNTER
  i = 0
  ;-------------------------------------------------------------------------
  ; CHANGE THE WORKING DIRECTORY
  CD, OUTPATH, CURRENT=OWD
  ;-------------------------------------------------------------------------
  ; READ INFILE, ONE LINE AT A TIME
  WHILE NOT EOF(INFILElun) DO BEGIN ; START 'WHILE 1'
    LINE = ''
    ;-----------------------------------------------------------------------
    ; UPDATE COUNTER
    i = (i+1)
    ;-----------------------------------------------------------------------
    ; GET LOOP START TIME
    L_TIME = SYSTIME(1)
    ;-----------------------------------------------------------------------
    ; READ INFILE
    READF, INFILElun, LINE
    ;-----------------------------------------------------------------------
    ; SET INFILE ROW AS FNAME1
    FNAME1 = LINE[0]
    ;-----------------------------------------------------------------------
    ; SET OUT FILE
    START = STRPOS(FNAME1, '/', /REVERSE_SEARCH)+1
    LENGTH = (STRLEN(FNAME1)-START)
    OUTFILE = OUTPATH + STRMID(FNAME1, START, LENGTH)
    ;----------------------------------------------------------------------- 
    ; SET URL FILENAME
    FNAME2 = INURL + FNAME1
    ;-----------------------------------------------------------------------
    ;***********************************************************************
    ; DOWNLOAD DATA:
    ;***********************************************************************
    ;-----------------------------------------------------------------------
    ; DOWNLOAD THE CURRENT FILE (WITH WGET VIA MS DOS)
    SPAWN, 'wget ' + FNAME2, /NOSHELL
    ;-----------------------------------------------------------------------
    ; GET LOOP END TIME
    SECONDS = (SYSTIME(1)-L_TIME)
    PRINT,''
    PRINT, STRTRIM(SECONDS, 2), ' SECONDS FOR ', STRMID(FNAME1, START, LENGTH), $
      ', FILE ', STRTRIM(i, 2), ' OF ', STRTRIM(FILEC, 2)
    ;-----------------------------------------------------------------------
  ENDWHILE ; END 'WHILE 1'
  ;-------------------------------------------------------------------------
  ; FREE LUN
  FREE_LUN, INFILElun
  ;-------------------------------------------------------------------------
  ; RESET THE WORKING DIRECTORY
  CD, OWD
  ;-------------------------------------------------------------------------
  ; PRINT END TIME
  MINUTES = (SYSTIME(1)-T_TIME)/60
  HOURS = MINUTES/60
  PRINT,''
  PRINT,'TOTAL PROCESSING TIME: ', STRTRIM(MINUTES, 2), ' MINUTES (', STRTRIM(HOURS, 2),   ' HOURS)'
  PRINT,''
  PRINT,'FINISHED PROCESSING: URLGET_FAO_versionB'
  PRINT,''
  ;-------------------------------------------------------------------------
END