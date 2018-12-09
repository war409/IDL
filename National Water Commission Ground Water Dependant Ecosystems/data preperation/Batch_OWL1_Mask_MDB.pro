; ##############################################################################################
; NAME: Batch_OWL1_Mask_MDB.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: MDB-FIM
; DLM: 11/07/2011
;
; DESCRIPTION:  This program applies a user selected mask to the user selected input data.
;               The user must define the "mask value": the value in the mask layer that show 
;               which cells in the input should be masked. The user must set a replacement 
;               value (Fill Value) for masked cells.
;
; INPUT:        One or more single band rasters. A single 'mask' layer with dimension 
;               identical to the input raster data.
;
; OUTPUT:       One single - masked - flat binary raster per input.
;
; PARAMETERS:   Via pop-up dialog widgets.
;   
; NOTES:        This program calls one or more external functions. You will need to compile the  
;               necessary functions in IDL, or save the functions to the current IDL workspace  
;               prior to running this tool.
;               
;               FUNCTION_WIDGET_Droplist
;               FUNCTION_WIDGET_Set_Value
;               
;               To identify the workspace (CWD) run the following from the IDL command line: 
;               
;               CD, CURRENT=CWD & PRINT, CWD
;               
;               For more information contact Garth.Warren@csiro.au
;
; ##############################################################################################


PRO Batch_OWL1_Mask_MDB
  ;---------------------------------------------------------------------------------------------
  StartTime = SYSTIME(1) ; Get the current system time.
  PRINT,''
  PRINT,'Begin Processing: Time_Series_Statistics'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
  ; Input/Output:
  ;---------------------------------------------------------------------------------------------
  ; Select the input data:
  Path='T:\gamma\rain\rain.monthly.sum\'
  Filter=['*.tif','*.img','*.flt','*.bin']
  In_Files = DIALOG_PICKFILE(PATH=Path, TITLE='Select The Input Data', FILTER=Filter, /MUST_EXIST, /MULTIPLE_FILES)
  IF In_Files[0] EQ '' THEN RETURN ; Error check.
  In_Files = In_Files[SORT(In_Files)] ; Sort the input file list.
  ;-------------- ; Remove the file path from the input file names:
  fname_Start = STRPOS(In_Files, '\', /REVERSE_SEARCH)+1 ; Get the position of the first file name character (after the file path).
  fname_Length = (STRLEN(In_Files)-fname_Start)-4 ; Get the length of each path-less file name.
  FNS = MAKE_ARRAY(N_ELEMENTS(In_Files), /STRING) ; Create an array to store the input file names.
  FOR a=0, N_ELEMENTS(In_Files)-1 DO BEGIN ; Fill the file name array:
    FNS[a] += STRMID(In_Files[a], fname_Start[a], fname_Length[a]) ; Get the a-the file name (trim away the file path).
  ENDFOR
  ;---------------------------------------------------------------------------------------------
  ; Select the input data type:
  In_DataType = FUNCTION_WIDGET_Droplist(TITLE='Select Input Datatype:', VALUE=['0 : UNDEFINED : Undefined', '1 : BYTE : Byte', $
    '2 : INT : Integer', '3 : LONG : Longword integer', '4 : FLOAT : Floating point', $
    '5 : DOUBLE : Double-precision floating', '6 : COMPLEX : Complex floating', $
    '7 : STRING : String', '8 : STRUCT : Structure', '9 : DCOMPLEX : Double-precision complex', $
    '10 : POINTER : Pointer', '11 : OBJREF : Object reference', '12 : UINT : Unsigned Integer', $
    '13 : ULONG : Unsigned Longword Integer', '14 : LONG64 : 64-bit Integer', $
    '15 : ULONG64 : Unsigned 64-bit Integer'])
  IF (In_DataType EQ 7) OR (In_DataType EQ 8) OR (In_DataType EQ 9) OR (In_DataType EQ 10) OR (In_DataType EQ 11) THEN BEGIN
    PRINT,'** Invalid Data Type **'
    RETURN ; Quit program.
  ENDIF
  ;---------------------------------------------------------------------------------------------
  ; Select the output data type:
  Out_DataType = FUNCTION_WIDGET_Droplist(TITLE='Select Output Datatype:', VALUE=['0 : UNDEFINED : Undefined', '1 : BYTE : Byte', $
    '2 : INT : Integer', '3 : LONG : Longword integer', '4 : FLOAT : Floating point', $
    '5 : DOUBLE : Double-precision floating', '6 : COMPLEX : Complex floating', $
    '7 : STRING : String', '8 : STRUCT : Structure', '9 : DCOMPLEX : Double-precision complex', $
    '10 : POINTER : Pointer', '11 : OBJREF : Object reference', '12 : UINT : Unsigned Integer', $
    '13 : ULONG : Unsigned Longword Integer', '14 : LONG64 : 64-bit Integer', $
    '15 : ULONG64 : Unsigned 64-bit Integer'])
  IF (Out_DataType EQ 7) OR (Out_DataType EQ 8) OR (Out_DataType EQ 9) OR (Out_DataType EQ 10) OR (Out_DataType EQ 11) THEN BEGIN
    PRINT,'** Invalid Data Type **'
    RETURN ; Quit program.
  ENDIF
  ;---------------------------------------------------------------------------------------------
  ; Select the input mask:
  Path='T:\gamma\rain\rain.monthly.sum\'
  Filter=['*.tif','*.img','*.flt','*.bin']
  In_Mask = DIALOG_PICKFILE(PATH=Path, TITLE='Select The Input Mask', FILTER=Filter, /MUST_EXIST, /MULTIPLE_FILES)
  IF In_Mask[0] EQ '' THEN RETURN ; Error check.
  ;---------------------------------------------------------------------------------------------
  ; Select the input data type:
  Mask_DataType = FUNCTION_WIDGET_Droplist(TITLE='Select The Mask Datatype:', VALUE=['0 : UNDEFINED : Undefined', '1 : BYTE : Byte', $
    '2 : INT : Integer', '3 : LONG : Longword integer', '4 : FLOAT : Floating point', $
    '5 : DOUBLE : Double-precision floating', '6 : COMPLEX : Complex floating', $
    '7 : STRING : String', '8 : STRUCT : Structure', '9 : DCOMPLEX : Double-precision complex', $
    '10 : POINTER : Pointer', '11 : OBJREF : Object reference', '12 : UINT : Unsigned Integer', $
    '13 : ULONG : Unsigned Longword Integer', '14 : LONG64 : 64-bit Integer', $
    '15 : ULONG64 : Unsigned 64-bit Integer'])
  IF (Mask_DataType EQ 7) OR (Mask_DataType EQ 8) OR (Mask_DataType EQ 9) OR (Mask_DataType EQ 10) OR (Mask_DataType EQ 11) THEN BEGIN
    PRINT,'** Invalid Data Type **'
    RETURN ; Quit program.
  ENDIF
  ;---------------------------------------------------------------------------------------------
  ; Set the mask value:
  Mask_Value = FUNCTION_WIDGET_Set_Value(TITLE='Mask Value:', VALUE='1.0', /FLOAT)
  ;---------------------------------------------------------------------------------------------
  ; Set the replacement value:
  Fill_Value = FUNCTION_WIDGET_Set_Value(TITLE='Fill Value:', VALUE='1.0', /INTEGER)
  ;---------------------------------------------------------------------------------------------
  ; Set the output folder:
  Path='T:\gamma\rain\rain.long.term\'
  Out_Directory = DIALOG_PICKFILE(PATH=Path, TITLE='Select The Output Folder', /DIRECTORY, /OVERWRITE_PROMPT)
  IF Out_Directory EQ '' THEN RETURN ; Error check.
  ;---------------------------------------------------------------------------------------------
  ; File loop:
  ;---------------------------------------------------------------------------------------------
  Mask_In = READ_BINARY(In_Mask, DATA_TYPE=Mask_DataType) ; Open mask.
  FOR i=0, N_ELEMENTS(In_Files)-1 DO BEGIN
    LoopStart = SYSTIME(1) ;  Get loop start time.
    Data = READ_BINARY(In_Files[i], DATA_TYPE=In_DataType) ; Open the i-th file.
    FNS_In = FNS[i] ; Set the i-th short filename.
    ;-------------------------------------------------------------------------------------------
    ; Apply mask:
    m = WHERE(Mask_In EQ Mask_Value, Mask_Count)
    IF (Mask_Count GT 0) THEN Data[m] = Fill_Value
    ;-------------------------------------------------------------------------------------------
    ; Write:
    File_Out = Out_Directory + FNS_In + '.Masked.img' ; Build the output filename.
    OPENW, UNIT_Out, File_Out, /GET_LUN ; Create the output file.
    FREE_LUN, UNIT_Out ; Close the output file. 
    OPENU, UNIT_Out, File_Out, /APPEND, /GET_LUN
    WRITEU, UNIT_Out, Data 
    FREE_LUN, UNIT_Out
    ;-------------------------------------------------------------------------------------------
    Minutes = (SYSTIME(1)-StartTime)/60 ; Get the file loop end time
    PRINT, '  Processing Time: ', STRTRIM(Minutes, 2), ' seconds, for file ', STRTRIM(i+1, 2), $
      ' of ', STRTRIM(N_ELEMENTS(In_Files), 2)
    ;-------------------------------------------------------------------------------------------
  ENDFOR
  ;---------------------------------------------------------------------------------------------
  Minutes = (SYSTIME(1)-StartTime)/60 ; Subtract End-Time from Start-Time.
  Hours = Minutes/60 ; Convert minutes to hours.
  PRINT,''
  PRINT,'Total Processing Time: ', STRTRIM(Minutes, 2), ' minutes (', STRTRIM(Hours, 2),   ' hours).'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
END

