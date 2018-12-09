; ##############################################################################################
; NAME: MODIS_DOIT_HDF_gzip_to_img.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: NA
; DATE: 11/11/2010
; DLM: 11/11/2010
;
; DESCRIPTION:  This tool extracts compressed (g-zip) HDF files. The tool was written to extract 
;               MODIS data from: '\\File-wron\RemoteSensing\MODIS\L2\LPDAAC\data\aust' - although 
;               it may be used to extract any compressed HDF data.
;               
;               The uncompressed HDF data is written to the user selected output directory as a
;               flat binary (ENVI Standard) '.img' file. The output data does not include any 
;               metadata; such as an ENVI .hdr file. Header files may be produced using the IDL 
;               tool: BATCH_DOIT_ENVI_Header.pro
;               
; INPUT:        One or more compressed HDF files (.hdf.gz). 
; 
;               Rather that select the actual files to be extracted you must select the parent 
;               directory of the sub-directory which contains the input files. 
;               
;               For example, to extract: 'MOD09A1.2000.049.aust.005.b01.500m_0620_0670nm_refl.hdf.gz' 
;               from '\\File-wron\RemoteSensing\MODIS\L2\LPDAAC\data\aust\MOD09A1.005\2000.02.18' 
;               you must select '\\File-wron\RemoteSensing\MODIS\L2\LPDAAC\data\aust\MOD09A1.005' 
;               as the input parent directory. Note that the program was coded in this way to extract 
;               MODIS data from the archive on 'file-wron'. By setting the input parent directory as 
;               above, the program will extract (and convert to .img) all MODIS hdf files in the 
;               MOD09A1.005 time-series.
;                
; OUTPUT:       One flat binary (.img) file per input.
;               
; PARAMETERS:   Via IDL widgets, set:  
;           
;               1.  SELECT THE INPUT PARENT DIRECTORY: see INPUT
;               
;               2.  SELECT THE OUTPUT DIRECTORY: The output data is saved to this location.
;                
; NOTES:        To identify the file dimensions, data-type and coordinate system, add a break-point 
;               to the function FUNCTION_Extract_HDF_gzip (after line 66) to pause the operation. 
;               You may then print the associated HDF information (see line 66 in 
;               FUNCTION_Extract_HDF_gzip for the variable names).
;
;               This program uses gzip.exe to extract the input HDF data. See: 'http://www.gzip.org/'
;               You will need to save the execution file gzip.exe to the current IDL working 
;               directory. To identify the CWD run the following from the IDL command line: 
;               CD, CURRENT=CWD & PRINT, CWD
;               
;               FUNCTIONS:
;               
;               This program calls one or more external functions. You will need to compile the  
;               necessary functions in IDL, or save the functions to the current IDL workspace  
;               prior to running this tool. To open a different workspace, select Switch  
;               Workspace from the File menu.
;               
;               Functions used in this program include:
;               
;               FUNCTION_Extract_HDF_gzip
;
;               For more information contact Garth.Warren@csiro.au
;    
; ##############################################################################################


PRO MODIS_DOIT_HDF_gzip_to_img
  ;---------------------------------------------------------------------------------------------
  ; GET START TIME
  T_TIME = SYSTIME(1)
  ;--------------
  PRINT,''
  PRINT,'BEGIN PROCESSING: MODIS_DOIT_HDF_gzip_to_img'
  PRINT,''
  ;---------------------------------------------------------------------------------------------  
  ;*********************************************************************************************
  ; INPUT/OUTPUT:
  ;*********************************************************************************************
  ;---------------------------------------------------------------------------------------------
  ; SET THE INPUT PARENT DIRECTORY
  PATH='\\File-wron\RemoteSensing\MODIS\L2\LPDAAC\data\aust'
  IN_DIRECTORY = DIALOG_PICKFILE(PATH=PATH, TITLE='SELECT THE INPUT PARENT DIRECTORY', /DIRECTORY)
  ;--------------
  ; ERROR CHECK
  IF IN_DIRECTORY EQ '' THEN RETURN
  ;---------------------------------------------------------------------------------------------
  ; SET THE OUTPUT DIRECTORY
  PATH='C:\WorkSpace\Guy\MODIS'
  OUT_DIRECTORY = DIALOG_PICKFILE(PATH=PATH, TITLE='SELECT THE OUTPUT DIRECTORY', /DIRECTORY, /OVERWRITE_PROMPT)
  ;-------------- 
  ; ERROR CHECK
  IF OUT_DIRECTORY EQ '' THEN RETURN
  ;---------------------------------------------------------------------------------------------
  ; GET THE SUB-DIRECTORY LIST:
  ;-----------------------------------
  CD, IN_DIRECTORY, CURRENT=OWD ; CHANGE THE CURRENT-WORKING-DIRECTORY TO THE INPUT DIRECTORY
  IN_SUB = FILE_SEARCH(/TEST_DIRECTORY) ; GET LIST OF SUB-FOLDERS IN THE NEW INPUT DIRECTORY
  CD, OWD ; RESET THE CURRENT-WORKING-DIRECTORY
  IN_SUB = IN_SUB[SORT(IN_SUB)] ; SORT SUB-DIRECTORY LIST
  COUNT_SUB = N_ELEMENTS(IN_SUB) ; SET SUB-DIRECTORY COUNT
  ;---------------------------------------------------------------------------------------------
  ;*********************************************************************************************
  ; SUB-DIRECTORY LOOP:
  ;*********************************************************************************************
  ;---------------------------------------------------------------------------------------------
  FOR i=0, COUNT_SUB-1 DO BEGIN ; FOR i
    ;-------------------------------------------------------------------------------------------
    ; GET START TIME: FILE LOOP
    L_TIME = SYSTIME(1)
    ;-------------------------------------------------------------------------------------------
    ; SET THE iTH SUB-DIRECTORY
    SUB_IN = IN_DIRECTORY + IN_SUB[i]
    ;--------------
    ; CHANGE THE CURRENT-WORKING-DIRECTORY
    CD, SUB_IN, CURRENT=OWD
    ;--------------
    ; GET THE LIST OF FILES IN THE CURRENT-WORKING-DIRECTORY
    IN_FILES = FILE_SEARCH('*hdf.gz')
    ;--------------
    ; RESET THE CURRENT-WORKING-DIRECTORY
    CD, OWD
    ;-------------------------------------------------------------------------------------------
    ;*******************************************************************************************
    ; FILE LOOP:
    ;*******************************************************************************************
    ;-------------------------------------------------------------------------------------------
    FOR j=0, N_ELEMENTS(IN_FILES)-1 DO BEGIN ; FOR j
      ;-----------------------------------------------------------------------------------------
      ; SET THE j-TH FILE
      FNS = IN_FILES[j]
      ;--------------
      ; SET THE FULL INPUT FILE NAME
      FILE_IN = SUB_IN + '\' + FNS
      ;-----------------------------------------------------------------------------------------
      ; EXTRACT THE HDF DATA
      DATA = FUNCTION_Extract_HDF_gzip(FILE_IN, OUT_DIRECTORY)
      ;-----------------------------------------------------------------------------------------
      ; DATA CHECK
      IF DATA[0] EQ -1 THEN CONTINUE ; START NEXT FILE LOOP ITERATION
      ;-----------------------------------------------------------------------------------------      
      ; WRITE DATA TO OUTPUT
      ;-----------------------------------
      ; BUILD THE OUTPUT FILENAME
      LENGTH = STRLEN(FNS)-7 ; GET FILENAME LENGTH
      FNS = STRMID(FNS, 0, LENGTH) ; TRIM THE FILE EXTENSION
      FILE_OUT = OUT_DIRECTORY + '\' + FNS + '.img' ; SET THE OUTPUT FILENAME
      ;--------------
      ; CREATE THE OUTPUT FILE
      OPENW, UNIT_OUT, FILE_OUT, /GET_LUN
      ;--------------
      ; CLOSE THE NEW FILES
      FREE_LUN, UNIT_OUT
      ;--------------
      ; OPEN THE OUTPUT FILE
      OPENU, UNIT_OUT, FILE_OUT, /GET_LUN, /APPEND
      ;--------------
      ; APPEND DATA TO THE OUTPUT FILES
      WRITEU, UNIT_OUT, DATA
      ;--------------
      ; CLOSE THE OUTPUT FILES
      FREE_LUN, UNIT_OUT
      ;-----------------------------------------------------------------------------------------
      ; PRINT LOOP INFORMATION
      PRINT, '  FILE ', STRTRIM(j+1, 2), ' OF ', STRTRIM(N_ELEMENTS(IN_FILES), 2), '; FOLDER ', $
        STRTRIM(i+1, 2), ' OF ', STRTRIM(COUNT_SUB, 2)  
      ;-----------------------------------------------------------------------------------------  
    ENDFOR  ; FOR j
    ;-------------------------------------------------------------------------------------------
    ; PRINT LOOP INFORMATION:
    ;-----------------------------------  
    ; GET END TIME
    MINUTES = (SYSTIME(1)-L_TIME)/60    
    ;--------------
    ; PRINT
    PRINT, '  PROCESSING TIME: ', STRTRIM(MINUTES, 2), ' MINUTES, FOR FOLDER ', STRTRIM(i+1, 2), ' OF ', STRTRIM(COUNT_SUB, 2)
    PRINT, ''
    ;-------------------------------------------------------------------------------------------
  ENDFOR  ; FOR i
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
  PRINT,'FINISHED PROCESSING: MODIS_DOIT_HDF_gzip_to_img'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
END