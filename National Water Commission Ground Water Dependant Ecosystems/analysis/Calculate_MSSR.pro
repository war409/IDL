; ##############################################################################################
; NAME: Calculate_MSSR.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: NWC Groundwater Dependent Ecosystems Atlas.
; DATE: 10/03/2011
; DLM: 14/05/2011
;
; DESCRIPTION:  This program calculates the mean seasonal storage range (MSSR).
; 
;               MSSR is calculated as the difference between the largest and smallest monthly mean 
;               seasonal storage (as calculated using Calculate_Mean_Monthly_Storage.pro).
;
; INPUT:        Ideally, the 12 (one per month of year) mean monthly storage grids as calculated 
;               using Calculate_Mean_Monthly_Storage.pro     
;
; OUTPUT:       One single band flat binary raster; MSSR.
;
; PARAMETERS:   Via pop-up dialog widgets.
;   
; NOTES:        This program calls one or more external functions. You will need to compile the  
;               necessary functions in IDL, or save the functions to the current IDL workspace  
;               prior to running this tool.
;               
;               To identify the workspace (CWD) run the following from the IDL command line: 
;               
;               CD, CURRENT=CWD & PRINT, CWD
;               
;               Functions used in this program include:
;               
;               FUNCTION_WIDGET_Droplist
;               FUNCTION_WIDGET_No_Data
;               FUNCTION_WIDGET_Checklist
;               
;               For more information contact Garth.Warren@csiro.au
;
; ##############################################################################################


;-----------------------------------------------------------------------------------------------
FUNCTION FUNCTION_Segment, Elements, Segment
  Segment_Length = ROUND((Elements)*Segment) ; Using the segment value get the segment length.
  Count_S_TMP = CEIL((Elements) / Segment_LENGTH) ; Get the count of segments based on the input grid size.
  Count_S = Count_S_TMP[0]
  Segment_Start = 0 ; Set the initial segment start position.
  Segment_End = FLOAT(Segment_LENGTH) ; Set the initial segment end position.
  RETURN, [Segment, Count_S, Segment_Start, Segment_End, Segment_Length] ; Return values to main program.
END
;-----------------------------------------------------------------------------------------------


PRO Calculate_MSSR
  ;---------------------------------------------------------------------------------------------
  StartTime = SYSTIME(1) ; Get the current system time.
  PRINT,''
  PRINT,'Begin Processing: Calculate_MSSR'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
  ; Input/Output:
  ;---------------------------------------------------------------------------------------------
  Prefix = 'MOD09Q1.MOD09A1.CMRSET.20010101.20091231' ; Set a string prefix for the output file names.
  ;---------------------------------------------------------------------------------------------
  In_Mask = '\\File-wron\Working\work\NWC_Groundwater_Dependent_Ecosystems\Data\Raster\SILO\MODIS.Land.Mask.aust.005.250m.img'
  Mask = READ_BINARY(In_Mask, DATA_TYPE=1)
  ;---------------------------------------------------------------------------------------------
  ; Select the input data:
  Path='\\Powerapp5-wron\scratch\war409\gamma\'
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
  ; Set the output folder:
  Path='\\Powerapp5-wron\scratch\war409\gamma\'
  Out_Directory = DIALOG_PICKFILE(PATH=Path, TITLE='Select The Output Folder', /DIRECTORY, /OVERWRITE_PROMPT)
  IF Out_Directory EQ '' THEN RETURN ; Error check.
  ;---------------------------------------------------------------------------------------------
  ; Build output:
  File_MSSR = Out_Directory + Prefix + '.MSSR' + '.img' ; Set the output file name
  OPENW, UNIT_MSSR, File_MSSR, /GET_LUN ; Create the output file.
  FREE_LUN, UNIT_MSSR ; Close the output file.
  ;---------------------------------------------------------------------------------------------
  ; Segment loop:
  ;---------------------------------------------------------------------------------------------
  In_First = READ_BINARY(In_Files[0], DATA_TYPE=In_DataType) ; Open the first input file.
  Elements = (N_ELEMENTS(In_First)-1) ; Get the number of grid elements (cells).  
  Result = FUNCTION_Segment(Elements, 0.1000) ; Call the segment function.
  ;-------------- ; Set segment parameters:
  Segment = Result[0]
  Count_S = LONG(Result[1])
  Segment_Start = LONG(Result[2]) 
  Segment_End = LONG(Result[3])
  Segment_Length = LONG(Result[4])
  ;-------------- ; Segment loop:
  FOR s=0, Count_S-1 DO BEGIN
    LoopStart = SYSTIME(1) ;  Get loop start time.
    ;-------------------------------------------------------------------------------------------
    ; Update segment loop parameters and build arrays:
    ;-------------------------------------------------------------------------------------------
    IF s GE 1 THEN BEGIN ; Update the segment parameters:
      Segment_Start = LONG(Segment_Start + Segment_Size) ; Update segment start position.
      Segment_End = LONG((s+1)*Segment_Size) ; Update segment end position.
    ENDIF
    ;-------------- ; In the final loop fix the end position if segment length is not a round integer.
    IF s EQ Count_S-1 THEN Segment_End = LONG(Elements) ; Update end position.
    ;-------------- ; Get the current segment size:
    Segment_Size = LONG(Segment_End - Segment_Start)+1 ; Get the current segment size.
    ;-------------- ; Create empty arrays to hold analysis data:
    Matrix_Data = MAKE_ARRAY(N_ELEMENTS(In_Files), Segment_Size, /FLOAT)
    ;-------------------------------------------------------------------------------------------
    ; File loop (get data and fill arrays):
    ;-------------------------------------------------------------------------------------------
    FOR i=0, N_ELEMENTS(In_Files)-1 DO BEGIN ; Loop through each input file:
      Data = READ_BINARY(In_Files[i], DATA_TYPE=In_DataType) ; Open the i-th file.
      Data_Segment = Data(Segment_Start:Segment_End) ; Get data slice (segment).
      Matrix_Data[i,*] = Data_Segment ; Fill data array.   
    ENDFOR
    ;-------------------------------------------------------------------------------------------
    ; Calculate Statistics:
    ;-------------------------------------------------------------------------------------------
    ; Set mask:
    Land = WHERE(Mask(Segment_Start:Segment_End) EQ 1, Count_Land)
    ;-------------- ; Calculate the Minimum:
    Data_Min = MIN(Matrix_Data, DIMENSION=1, /NAN)
    ;-------------- ; Calculate the Maximum:
    Data_Max = MAX(Matrix_Data, DIMENSION=1, /NAN)
    ;-------------- ; Calculate MSSR:
    Data_MSSR = Data_Max[Land] - Data_Min[Land]
    ;-------------- ; Use land mask to build output:
    Data_MSSR_Out = MAKE_ARRAY(Segment_Size, VALUE=-999, /FLOAT)
    Data_MSSR_Out[Land] = Data_MSSR
    ;-------------- ; Write to file:
    IF (Out_DataType EQ 1) THEN Data_MSSR_Out = BYTE(Data_MSSR_Out) ; Convert to Byte.
    IF (Out_DataType EQ 2) THEN Data_MSSR_Out = FIX(Data_MSSR_Out + 0.5) ; Convert to Integer.
    IF (Out_DataType EQ 3) THEN Data_MSSR_Out = LONG(Data_MSSR_Out + 0.5) ; Convert to LONG
    IF (Out_DataType EQ 5) THEN Data_MSSR_Out = DOUBLE(Data_MSSR_Out) ; Convert to DOUBLE
    IF (Out_DataType EQ 12) THEN Data_MSSR_Out = UINT(Data_MSSR_Out + 0.5) ; Convert to unsigned Integer.
    OPENU, UNIT_MSSR, File_MSSR, /APPEND, /GET_LUN
    WRITEU, UNIT_MSSR, Data_MSSR_Out 
    FREE_LUN, UNIT_MSSR
    ;-------------------------------------------------------------------------------------------
    Minutes = (SYSTIME(1)-LoopStart)/60 ; Get the file loop end time
    PRINT, '  Processing Time: ', STRTRIM(Minutes, 2), ' minutes, for segment ', STRTRIM(s+1, 2), $
      ' of ', STRTRIM(Count_S, 2)
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

