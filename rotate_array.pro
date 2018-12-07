; ##############################################################################################
; NAME: envi_header.pro
; LANGUAGE: ENVI + IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: Evaluating AWRA outputs (Activity 6, WRAA, WIRADA)
; DATE: 19/12/2012
; DLM: 19/12/2012
;
; DESCRIPTION: 
;
; INPUT:       Multiple single-band rasters.
;
; OUTPUT:      One ENVI header information file (.hdr) for each input.
;               
; PARAMETERS:  Via IDL widgets, set:
; 
;              1.  SELECT THE INPUT DATA: see INPUT
;
; NOTES:       The input data must have identical dimensions and data type. 
; 
;              An interactive ENVI session is needed to run this tool.
;              
;              For more information contact Garth.Warren@csiro.au
;
; ##############################################################################################


PRO rotate_array
  ;---------------------------------------------------------------------------------------------
  ; GET START TIME
  T_TIME = SYSTIME(1)
  ;--------------
  PRINT,''
  PRINT,'BEGIN PROCESSING: BATCH_DOIT_ENVI_Header'
  PRINT,''
  ;---------------------------------------------------------------------------------------------  
  ;*********************************************************************************************
  ; INPUT/OUTPUT: 
  ;*********************************************************************************************
  ;---------------------------------------------------------------------------------------------
  
  
   output_folder = 'C:\temp\PET\tmin_out_2\' 
  
  
  ; SELECT THE INPUT DATA
  PATH = 'C:\temp\PET\tmin_out\'
  FILTER=['*.img','*.flt','*.bin']
  TITLE='SELECT THE INPUT DATA'
  IN_FILES = DIALOG_PICKFILE(PATH=PATH, TITLE=TITLE, FILTER=FILTER, /MUST_EXIST, /MULTIPLE_FILES, /OVERWRITE_PROMPT)  
  ;--------------
  ; ERROR CHECK:
  IF IN_FILES[0] EQ '' THEN RETURN
  ;--------------
  ; SORT FILE LIST
  IN_FILES = IN_FILES[SORT(IN_FILES)]
  ;--------------
  ; GET FILENAME SHORT
  FNAME_START = STRPOS(IN_FILES, '\', /REVERSE_SEARCH)+1
  FNAME_LENGTH = (STRLEN(IN_FILES)-FNAME_START)-4
  ;--------------
  ; GET FILENAME ARRAY
  FNS = MAKE_ARRAY(1, N_ELEMENTS(IN_FILES), /STRING)
  FOR a=0, N_ELEMENTS(IN_FILES)-1 DO BEGIN
    ; GET THE a-TH FILE NAME 
    FNS[*,a] += STRMID(IN_FILES[a], FNAME_START[a], FNAME_LENGTH[a])
  ENDFOR
  ;--------------------------------------------------------------------------------------------- 
  ; QUERY THE FIRST FILE:
  ;--------------
  ; OPEN FILE
  ENVI_OPEN_FILE, IN_FILES[0], /NO_REALIZE, R_FID=FID_FIRST
  ;--------------
  ; QUERY FILE
  ENVI_FILE_QUERY, FID_FIRST, DIMS=DIMS_IN, NS=NS_IN, NL=NL_IN, NB=NB_IN, INTERLEAVE=INTERLEAVE_IN, $
    DATA_TYPE=DATATYPE_IN, XSTART=XSTART_IN, FILE_TYPE=FILE_TYPE_IN,YSTART=YSTART_IN, OFFSET=OFFSET_IN, $
    DATA_OFFSETS=DATA_OFFSETS_IN, DATA_IGNORE_VALUE=DATA_IGNORE_VALUE_IN
  ;--------------
  ; GET MAP INFORMATION
  MAPINFO_IN = ENVI_GET_MAP_INFO(FID=FID_FIRST)
  PROJ_FULL_IN = MAPINFO_IN.PROJ
  DATUM_IN = MAPINFO_IN.PROJ.DATUM
  PROJ_IN = MAPINFO_IN.PROJ.NAME
  UNITS_IN = MAPINFO_IN.PROJ.UNITS
  SIZEX_IN = FLOAT(MAPINFO_IN.PS[0])
  SIZEY_IN = FLOAT(MAPINFO_IN.PS[1])    
  CXUL_IN = FLOAT(MAPINFO_IN.MC[2])
  CYUL_IN = FLOAT(MAPINFO_IN.MC[3])
  LOCX_IN = FLOAT(MAPINFO_IN.MC[0])
  LOCY_IN = FLOAT(MAPINFO_IN.MC[1])
  ;---------------------------------------------------------------------------------------------
  ;*********************************************************************************************
  ; FILE LOOP:
  ;*********************************************************************************************
  ;---------------------------------------------------------------------------------------------
  FOR i=0, N_ELEMENTS(IN_FILES)-1 DO BEGIN
    ;-------------------------------------------------------------------------------------------
    ; GET START TIME:
    L_TIME = SYSTIME(1)
    ;-------------------------------------------------------------------------------------------
    ; GET THE i-TH INPUT FILE
    FILE_IN = IN_FILES[i] 
    FNSi = FNS[i] 
    
    
    
    
    envi_open_file, FILE_IN, r_fid=fid
    
    if (fid eq -1) then begin
       envi_batch_exit
       return
    endif
    
    
    envi_file_query, fid, dims=dims, nb=nb
    pos = lindgen(nb) 
    out_name = output_folder + FNSi + '.img' 
    
    ; Rotate the image.
    envi_doit, 'rotate_doit', $ 
       fid=fid, pos=pos, dims=dims, $ 
       rot_type=3, out_name=out_name, $ 
       r_fid=r_fid, /TRANSPOSE 
       
      
      
    ;-------------------------------------------------------------------------------------------
    ; PRINT LOOP INFORMATION:
    ;-----------------------------------   
    ; GET END TIME
    SECONDS = (SYSTIME(1)-L_TIME)
    ;--------------
    ; PRINT
    PRINT,'  PROCESSING TIME: ', STRTRIM(SECONDS, 2), ' SECONDS, FOR FILE ', STRTRIM(i+1, 2), ' OF ', $
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
  PRINT,'FINISHED PROCESSING: BATCH_DOIT_Temporal_Resample'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
END