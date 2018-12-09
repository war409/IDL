; ##########################################################################
; NAME: Time_Series_Analysis_DOIT_Convert_HDF_To_IMG.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: Evaluating AWRA outputs (Activity 6, WRAA, WIRADA)
; DATE: 01/03/2010
; DLM: 01/03/2010
;
; DESCRIPTION: This tool converts compressed HDF SD data to flat binary
;              format.
;
; INPUT:       One of more compressed HDF files (*.hdf.gz). This script works by
;              searching sub-directories (of the input directory) for compressed
;              HDF data.
;
; OUTPUT:      One flat binary file (.img) per input. The output date is written
;              to the output directory.
;
; PARAMETERS:  Via IDL widgets, set:
;
;              'SELECT THE INPUT DIRECTORY'
;              'SELECT THE OUTPUT DIRECTORY'
;
; NOTES:       Before running this tool you must install 7-zip see:
;
;              '\\File-wron\Working\work\war409\Work\General\software\7z\7z465.exe'
;
;              After installing the above software use the SPAWN command to
;              identify the current working directory and copy '7z.exe' into
;              this location. See:
;
;              '\\File-wron\Working\work\war409\Work\General\software\7z\7z.exe'
;
;              See line 77: define the file search filter.
;
; ##########################################################################
;
PRO Time_Series_Analysis_DOIT_Convert_HDF_To_IMG
  ;-------------------------------------------------------------------------
  ; GET START TIME
  T_TIME = SYSTIME(1)
  PRINT,''
  PRINT,'BEGIN PROCESSING: Time_Series_Analysis_DOIT_Convert_HDF_To_IMG'
  PRINT,''
  ;-------------------------------------------------------------------------
  ;*************************************************************************
  ; INPUT/OUTPUT:
  ;*************************************************************************
  ; SELECT THE INPUT DIRECTORY  '\\File-wron\RemoteSensing\MODIS\L2\LPDAAC\data\aust'
  IN_DIR = DIALOG_PICKFILE(PATH='C:\Modis',$
  	TITLE='SELECT THE INPUT DIRECTORY', /DIRECTORY, /OVERWRITE_PROMPT)
  ;-------------------------------------------------------------------------
  ; SELECT THE OUTPUT DIRECTORY:
  OUT_DIR = DIALOG_PICKFILE(PATH='C:\Modis',$
  	TITLE='SELECT THE OUTPUT DIRECTORY', /DIRECTORY, /OVERWRITE_PROMPT)
  ;-------------------------------------------------------------------------
  ; GET SUB-DIRECTORY LIST:
  ;-------------------------------------------------------------------------
  ; CHANGE CWD TO THE INPUT DIRECTORY
  CD, IN_DIR, CURRENT=OWD
  ; GET LIST OF FOLDERS IN THE NEW CWD
  IN_SUBDIR = FILE_SEARCH(/TEST_DIRECTORY)
  ; RESET THE WORKING DIRECTORY
  CD, OWD
  ; SORT SUB-DIRECTORY LIST
  IN_SUBDIR = IN_SUBDIR[SORT(IN_SUBDIR)]
  ; SET SUB-DIRECTORY COUNT
  COUNT_SD = N_ELEMENTS(IN_SUBDIR)
  ;*************************************************************************
  ; SUB-DIRECTORY LOOP:
  ;*************************************************************************
  FOR i=0, COUNT_SD-1 DO BEGIN ; START 'FOR i'
    ;-----------------------------------------------------------------------
    ; GET START TIME: LOOP
    L_TIME = SYSTIME(1)
    ;-----------------------------------------------------------------------
    ; GET THE CURRENT DIRECTORY
    C_SUBDIR = IN_DIR + IN_SUBDIR[i]
    ;-----------------------------------------------------------------------
    ; CHANGE THE WORKING DIRECTORY
    CD, C_SUBDIR, CURRENT=OWD
    ; GET LIST OF FILES IN THE WORKING DIRECTORY                ** DEFINE **
    IN_FILES = FILE_SEARCH('*hdf.gz')
    ; RESET THE WORKING DIRECTORY
    CD, OWD
    ;-----------------------------------------------------------------------
    ; SET FILE COUNT
    COUNT_F = N_ELEMENTS(IN_FILES)
    ;-----------------------------------------------------------------------
    ;***********************************************************************
    ; FILE LOOP:
    ;***********************************************************************
    FOR j=0, COUNT_F-1 DO BEGIN ; START 'FOR i'
      ;---------------------------------------------------------------------
      ; GET THE CURRENT FILE
      FNAME = IN_FILES[j]
      ;---------------------------------------------------------------------
      ; BUILD THE COMPRESSED INPUT FILE NAME
      FNAME_FULL = C_SUBDIR + '\' + FNAME
      ;---------------------------------------------------------------------
      ; UNCOMPRESS THE CURRENT INPUT FILE (UNZIP WITH 7-ZIP VIA MS DOS)
      SPAWN, '7z x ' + FNAME_FULL + ' -o' + OUT_DIR, /NOSHELL
      ;---------------------------------------------------------------------
      ; BUILD THE HDF FILE NAME:
      ;---------------------------------------------------------------------
      ; MANIPULATE FILE NAME TO GET FILE NAME SHORT
      FNAME_LENGTH = (STRLEN(FNAME)-0)-7
      FNAME_SHORT = STRMID(FNAME, 0, FNAME_LENGTH[0])
      ; SET HDF FILE NAME
      HDF_IN = OUT_DIR + FNAME_SHORT + '.hdf'
      ;---------------------------------------------------------------------
      ; CREATE THE OUTPUT FILE:
      ;---------------------------------------------------------------------
      ; BUILD THE OUTPUT NAME
      OUTNAME = OUT_DIR + FNAME_SHORT + '.img'
      ; CREATE THE FILE
      OPENW, UNIT_OUT, OUTNAME, /GET_LUN
      ; CLOSE THE NEW FILE
      FREE_LUN, UNIT_OUT
      ;---------------------------------------------------------------------
      ;*********************************************************************
      ; GET HDF DATA:
      ;*********************************************************************
      ; OPEN THE HDF FILE
      SD_FILEID = HDF_SD_START(HDF_IN, /READ)
      ;---------------------------------------------------------------------
      ; SET THE SD DATASET ID
      SDSID = HDF_SD_SELECT(SD_FILEID, 0)
      ;---------------------------------------------------------------------
      ; GET FILE INFORMATION
      HDF_SD_FILEINFO, SD_FILEID, DATASETS, ATTRIBUTES
      HDF_SD_GETINFO, SDSID, NAME=SDSNAME
      ;---------------------------------------------------------------------
      ; GET FILE DATA
      HDF_SD_GETDATA, SDSID, DATA
      ;---------------------------------------------------------------------
      ; CLOSE THE SD FILE
      HDF_SD_END, SD_FILEID
      ;---------------------------------------------------------------------
      ; DELETE THE UNCOMPRESSED HDF FILE
      FILE_DELETE, HDF_IN
      ;---------------------------------------------------------------------
      ; WRITE DATA TO FILE:
      ;---------------------------------------------------------------------
      ; OPEN THE OUTPUT FILE
      OPENU, UNIT_OUT, OUTNAME, /APPEND, /GET_LUN
      ; APPEND DATA TO THE OUTPUT FILE
      WRITEU, UNIT_OUT, DATA
      ; CLOSE THE OUTPUT FILES
      FREE_LUN, UNIT_OUT
      ;---------------------------------------------------------------------
    ENDFOR ; END 'FOR j'
    ;-----------------------------------------------------------------------
    ; GET END TIME
    SECONDS = (SYSTIME(1)-L_TIME)
    ; PRINT LOOP INFORMATION
    PRINT,'  PROCESSING TIME: ', STRTRIM(SECONDS, 2), ' SECONDS, FOR SUB-DIRECTORY ', $
      STRTRIM(i+1, 2), ' OF ', STRTRIM(COUNT_SD, 2)
    PRINT,''
    ;-----------------------------------------------------------------------
  ENDFOR ; END 'FOR i'
  ;-------------------------------------------------------------------------
  ; PRINT END TIME
  MINUTES = (SYSTIME(1)-T_TIME)/60
  HOURS = MINUTES/60
  PRINT,''
  PRINT,'TOTAL PROCESSING TIME: ', STRTRIM(MINUTES, 2), ' MINUTES (', STRTRIM(HOURS, 2),   ' HOURS)'
  PRINT,''
  PRINT,'FINISHED PROCESSING: Time_Series_Analysis_DOIT_Convert_HDF_To_IMG'
  PRINT,''
  ;-------------------------------------------------------------------------
END