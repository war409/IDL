; ##############################################################################################
; NAME: BATCH_DOIT_Spatial_Resample_SILO_to_modis250.pro
; LANGUAGE: ENVI + IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: NA
; DATE: 18/02/2010
; DLM: 03/03/2011
;
; DESCRIPTION: This tool alters the proportions of a raster dataset by changing the cell size. 
;              The extent of the output raster will remain the same unless the user selects the 
;              'ALIGN CELLS WITH THE EXISTING FILE' option, in which case the extents will move 
;              the minimum distance to ensure that the cell alignment of the output matches the 
;              existing file.
;
; INPUT:       One or more single-band or multi-band image files.
;
; OUTPUT:      One new raster file per input.
;
; PARAMETERS:  Via widgets. The user may choose whether to use the cell size of an existing file, 
;              or enter the new cell size manually. If the user opts to use the cell size of an
;              existing file the user may also select whether or not to align (snap cells) the 
;              output with the existing file.
;
;              1.  SELECT THE INPUT DATA: see INPUT
;              
;              2.  RESAMPLE-BY: see PARAMETERS above
;              
;              2.1  SET THE NEW CELL SIZE (optional): enter the cell size for the output raster 
;                   dataset.
;              
;              2.2  SELECT AN EXISTING FILE (optional): select an example dataset; the output 
;                   raster will use the cell size of the example file. 
;              
;              3.  SELECT THE ALIGNMENT TYPE: select whether the output grid cells should align
;                  with the example 'EXISTING' grid.
;              
;              4.  SELECT THE RESAMPLE METHOD: see NOTES
;              
;              5.  SELECT THE OUTPUT DIRECTORY: The output data is saved to this location.
;
; NOTES:       The input data must have identical dimensions. If the input is a flat binary file,
;              or an ENVI standard file it must have an associated ENVI header file (.hdr). 
;
;              An interactive ENVI session is needed to run this tool.
;              
;              RESAMPLING METHODS;
;
;              The user may select one of four interpolation methods. When 'down' sampling data 
;              it is recommended to use either the NEAREST NEIGHBOUR or PIXEL AGGREGATE method.
;              
;              NEAREST NEIGHBOUR assignment will determine the location of the closest cell 
;              centre on the input raster and assign the value of that cell to the cell on the 
;              output.
;                
;              BILINEAR INTERPOLATION uses the value of the four nearest input cell centers to 
;              determine the value on the output.
;                
;              CUBIC CONVOLUTION is similar to bilinear interpolation except the weighted average 
;              is calculated from the 16 nearest input cell centres and their values.
;                
;              PIXEL AGGREGATE uses the average of the surrounding pixels to determine the output 
;              value.
;              
;              For more information contact Garth.Warren@csiro.au
;
; ##############################################################################################


function Resample_SILO_to_modis250, array
  size_array = Size(Array)
  if size_array[0] ne 2 then begin
      print, 'array must have 2 dimensions'
      return, 0
  endif
   if size_array[1] ne 841 or size_array[2] ne 681 then begin
      print, 'array must be of size 841 * 681' 
      return, 0
  endif
  
  ; fills array with 40 columns left, 20 right and 20 bottom
  new_Array = FltArr(901, 701)
  new_Array[40:40+840, 0:680] = Array
 
  ; resize new array to MODIS 250m dimensions
  new_Array_MCD43_Size = Congrid(new_Array, 19182, 14924)
  ; gets rid of left, top 5 pixels , bottom , right 6 pixels
  new_array_final = new_Array_MCD43_Size[10:19169, 10:14911]
 
  return, new_array_final
end


PRO BATCH_DOIT_Spatial_Resample_SILO_to_modis250
  ;---------------------------------------------------------------------------------------------
  ; GET START TIME
  T_TIME = SYSTIME(1)
  ;--------------
  PRINT,''
  PRINT,'BEGIN PROCESSING: BATCH_DOIT_Spatial_Resample_SILO_to_modis250'
  PRINT,''
  ;---------------------------------------------------------------------------------------------  
  ;*********************************************************************************************
  ; INPUT/OUTPUT:
  ;*********************************************************************************************
  ;--------------------------------------------------------------------------------------------- 
  ; SELECT THE INPUT DATA
  PATH='\\File-wron\Working\work\NWC_Groundwater_Dependent_Ecosystems\Data\Raster\SILO\'
  FILTER=['*.tif','*.img','*.flt','*.bin']
  IN_FILES = DIALOG_PICKFILE(PATH=PATH, TITLE='SELECT THE INPUT DATA', FILTER=FILTER, /MUST_EXIST, $
    /MULTIPLE_FILES, /OVERWRITE_PROMPT)
  ;--------------
  ; ERROR CHECK:
  IF IN_FILES[0] EQ '' THEN RETURN
  ;--------------
  ; SORT FILE LIST
  IN_FILES = IN_FILES[SORT(IN_FILES)]
  ;--------------
  ; MANIPULATE FILENAME TO GET FILENAME SHORT:
  ;--------------
  ; GET FNAME_SHORT
  FNAME_START = STRPOS(IN_FILES, '\', /REVERSE_SEARCH)+1
  FNAME_LENGTH = (STRLEN(IN_FILES)-FNAME_START)-4
  ;--------------
  ; GET FILENAME ARRAY
  IN_FSHORT = MAKE_ARRAY(1, N_ELEMENTS(IN_FILES), /STRING)
  FOR a=0, N_ELEMENTS(IN_FILES)-1 DO BEGIN
    ; ADD THE a-TH FILENAME TO THE FILENAME ARRAY
    IN_FSHORT[*,a] += STRMID(IN_FILES[a], FNAME_START[a], FNAME_LENGTH[a])
  ENDFOR
  ;---------------------------------------------------------------------------------------------
  ; SELECT THE RESAMPLE METHOD
  VALUES = ['NEAREST NEIGHBOUR', 'BILINEAR INTERPOLATION', 'CUBIC CONVOLUTION', 'PIXEL AGGREGATE']
  TYPE_RESAMPLE = 0
  ;---------------------------------------------------------------------------------------------
  ; SELECT THE OUTPUT DIRECTORY:
  TITLE='SELECT THE OUTPUT DIRECTORY'
  PATH = '\\Tidalwave-bu\war409_one$\rain.8Day.250\'
  ;--------------  
  OUT_DIRECTORY = DIALOG_PICKFILE(PATH=PATH, TITLE=TITLE, /DIRECTORY, /OVERWRITE_PROMPT)
  ;-------------- 
  ; ERROR CHECK
  IF OUT_DIRECTORY EQ '' THEN RETURN
  ;---------------------------------------------------------------------------------------------
  ;*********************************************************************************************
  ; FILE LOOP:
  ;*********************************************************************************************
  ;---------------------------------------------------------------------------------------------
  FOR i=0, N_ELEMENTS(IN_FILES)-1 DO BEGIN ; START 'FOR i'
    ;-------------------------------------------------------------------------------------------
    ; GET START TIME: DATE LOOP
    L_TIME = SYSTIME(1)
    ;-------------------------------------------------------------------------------------------
    ; GET DATA:
    ;------------------------------------------------------------------------------------------- 
    FILE_IN = IN_FILES[i] ; GET THE i-TH INPUT FILENAME
    FSHORT_IN = IN_FSHORT[i] ; GET THE i-TH INPUT FILENAME SHORT
    ;--------------
    ; BUILD THE OUTPUT FILENAME
    SUFFIX = '.250.img'
    FILE_OUT = OUT_DIRECTORY + FSHORT_IN + SUFFIX
    ;--------------------------------------
    ; OPEN THE i-TH INPUT FILE
    ENVI_OPEN_FILE, FILE_IN, R_FID=FID_IN, /NO_REALIZE
    ;--------------
    ; QUERY THE i-TH INPUT FILE
    ENVI_FILE_QUERY, FID_IN, DIMS=DIMS_IN, DATA_TYPE=DATATYPE_IN, NS=NS_IN, NL=NL_IN
    ;--------------
    ; GET MAP INFORMATION
    MAPINFO_IN = ENVI_GET_MAP_INFO(FID=FID_IN)
    PROJ_IN = MAPINFO_IN.PROJ
    DATUM_IN = MAPINFO_IN.PROJ.DATUM
    PROJNAME_IN = MAPINFO_IN.PROJ.NAME
    UNITS_IN = MAPINFO_IN.PROJ.UNITS
    XSIZE_IN = DOUBLE(MAPINFO_IN.PS[0])
    YSIZE_IN = DOUBLE(MAPINFO_IN.PS[1])
    XUL_IN = DOUBLE(MAPINFO_IN.MC[2])
    YUL_IN = DOUBLE(MAPINFO_IN.MC[3])
    XO_IN = DOUBLE(MAPINFO_IN.MC[0])
    YO_IN = DOUBLE(MAPINFO_IN.MC[1])
    ;--------------------------------------
    ; GET DATA
    DATA_IN = ENVI_GET_DATA(FID=FID_IN, DIMS=DIMS_IN, POS=0)
    
    ;-------------------------------------------------------------------------------------------
    ; RESAMPLE DATA:
    ;-------------------------------------------------------------------------------------------
    
    DATA_OUT = resample_SILO_to_modis250(DATA_IN)
    
    DATA_OUT_INT = FIX(DATA_OUT*1000)
    
    OPENW, UNIT_OUT, FILE_OUT, /GET_LUN ; Create the output file.
    FREE_LUN, UNIT_OUT ; Close the output file.
    OPENU, UNIT_OUT, FILE_OUT, /APPEND, /GET_LUN
    WRITEU, UNIT_OUT, DATA_OUT_INT 
    FREE_LUN, UNIT_OUT    
    ;-------------------------------------------------------------------------------------------    
    ; PRINT LOOP INFORMATION:
    ;-----------------------------------   
    ; GET END TIME
    SECONDS = (SYSTIME(1)-L_TIME)
    ;--------------
    ; PRINT
    PRINT,'  PROCESSING TIME: ', STRTRIM(SECONDS, 2), ' SECONDS, FOR FILE ', STRTRIM(i+1, 2), $
      ' OF ', STRTRIM(N_ELEMENTS(IN_FILES), 2)
    ;-------------------------------------------------------------------------------------------    
  ENDFOR ; FOR i
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
  PRINT,'FINISHED PROCESSING: BATCH_DOIT_Spatial_Resample_SILO_to_modis250'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
END  
