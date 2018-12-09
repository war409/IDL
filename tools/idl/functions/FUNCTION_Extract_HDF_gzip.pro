; ##############################################################################################
; NAME: FUNCTION_Extract_HDF_gzip.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: NA
; DATE: 11/11/2010
; DLM: 11/11/2010
;
; DESCRIPTION:  This function extracts the input compressed (g-zipped) HDF file.
;
; INPUT:        FILE_IN: a scalar string containing the full filename and path of the selected 
;               HDF (.hdf.gz) file.
; 
;               TEMP_DIRECTORY: a scalar string containing a directory name; the data is 
;               extracted to this location. The uncompressed HDF file will be deleted at the 
;               end of the function.
;
; OUTPUT:       The data contained in the HDF file will be returned to the program that called 
;               the function. 
;               
;               RETURN = The gridded data.
;               
;               If the file is missing, or if the file is corrupt, '-1' is returned.
;               
; NOTES:        
;
; ##############################################################################################


;***********************************************************************************************
; ##############################################################################################
FUNCTION FUNCTION_Extract_HDF_gzip, FILE_IN, TEMP_DIRECTORY
  COMPILE_OPT IDL2, HIDDEN
  ON_ERROR, 2
  ;---------------------------------------------------------------------------------------------
  ; CHECK FILE EXISTS
  FILE_INFO = FILE_INFO(FILE_IN)
  IF FILE_INFO.EXISTS EQ 1 THEN BEGIN
    ;------------------------------------------------------------------------------------------
    ; SET THE TEMPORARY FILE:
    ;-----------------------------------
    ; GET FILENAME SHORT
    FNAME_START = STRPOS(FILE_IN, '\', /REVERSE_SEARCH)+1
    FNAME_LENGTH = (STRLEN(FILE_IN)-FNAME_START)-7
    FNS = STRMID(FILE_IN, FNAME_START, FNAME_LENGTH)
    ;--------------
    ; SET TEMP FILE
    FILE_TEMP = TEMP_DIRECTORY + '\' + FNS + '.hdf'
    ;------------------------------------------------------------------------------------------
    ; UNZIP THE INPUT FILE TO THE TEMP FILE
    SPAWN, 'gzip -d -c ' + FILE_IN + ' > ' + FILE_TEMP , Result, ErrResult, /HIDE 
    ;--------------
    ; ERROR CHECK
    IF (N_ELEMENTS(ErrResult) EQ 1) AND (ErrResult[0] EQ '') THEN BEGIN
      ;----------------------------------------------------------------------------------------
      ; READ HDF:
      ;-----------------------------------
      ; GET HDF ID
      SDFILEID = HDF_SD_START(FILE_TEMP, /Read)
      ;--------------
      ; SET ID
      SDSID = HDF_SD_SELECT(SDFILEID, 0)
      ;--------------
      ; GET FILE INFORMATION
      HDF_SD_FILEINFO, SDFILEID, DATASETS, ATTRIBUTES
      HDF_SD_GETINFO, SDSID, NAME=SDSNAME, COORDSYS=COORDSYS, DIMS=DIMS, FILL=FILL, HDF_TYPE=HDF_TYPE
      ;--------------
      ; GET FILE DATA
      HDF_SD_GETDATA, SDSID, DATA
      ;--------------
      ; CLOSE THE SD FILE
      HDF_SD_END, SDFILEID
      ;--------------
      ; DELETE THE UNCOMPRESSED HDF FILE
      FILE_DELETE, FILE_TEMP
      ;-----------------------------------------------------------------------------------------
    ENDIF ELSE BEGIN ; BAD FILE
      PRINT, 'FILE CORRUPT, RETURNING -1'
      DATA = -1
    ENDELSE
    ;-------------------------------------------------------------------------------------------
  ENDIF ELSE BEGIN ; BAD FILENAME
    PRINT, 'FILE NOT FOUND, RETURNING -1'
    DATA = -1
  ENDELSE
  ;---------------------------------------------------------------------------------------------
  ; RETURN TO MAIN PROGRAM LEVEL
  RETURN, DATA
  ;---------------------------------------------------------------------------------------------
END
; ##############################################################################################
;***********************************************************************************************

