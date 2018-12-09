; ##############################################################################################
; NAME: CMRSET_Bias_Correction.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: NWC Groundwater Dependent Ecosystems Atlas.
; DATE: 11/05/2011
; DLM: 27/12/2012
; DESCRIPTION:  This tool applys the CMRSET bias correction equation to the 'raw' 8-day CMRSET
;               time series.
; 
; INPUT:        One or more single band flat binary raster.
; 
; OUTPUT:       One single band flat binary raster.
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
;               FUNCTION_WIDGET_Set_Value_Conditional
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


PRO CMRSET_Bias_Correction
  ;---------------------------------------------------------------------------------------------
  StartTime = SYSTIME(1) ; Get the current system time.
  PRINT,''
  PRINT,'Begin Processing: CMRSET_Bias_Correction'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
  ; Input/Output:
  ;---------------------------------------------------------------------------------------------
  In_Mask = 'C:\Users\war409\CMRSET\land_mask_australia_MOD13Q1.img'
  Mask = READ_BINARY(In_Mask, DATA_TYPE=1)
  ;---------------------------------------------------------------------------------------------
  ; Select the input data:
  Path='C:\Users\war409\CMRSET\cmrset\'
  Filter=['*.tif','*.img','*.flt','*.bin']
  In_Files = DIALOG_PICKFILE(PATH=Path, TITLE='Select The Input Data', FILTER=Filter, /MUST_EXIST, /MULTIPLE_FILES)
  IF In_Files[0] EQ '' THEN RETURN ; Error check.
  In_Files = In_Files[SORT(In_Files)] ; Sort the input file list.
  ;-------------- ; Remove the file path from the input file names.
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
  IF (Out_DataType EQ 0) OR (Out_DataType EQ 1) OR (Out_DataType EQ 7) OR (Out_DataType EQ 8) OR (Out_DataType EQ 9) OR (Out_DataType EQ 10) OR (Out_DataType EQ 11) THEN BEGIN
    PRINT,'** Invalid Data Type **'
    RETURN ; Quit program.
  ENDIF
  ;---------------------------------------------------------------------------------------------
  ; Set an output scaling factor:
  IF (Out_DataType EQ 1) OR (Out_DataType EQ 2) OR (Out_DataType EQ 3) THEN BEGIN
    Scaling = FUNCTION_WIDGET_Set_Value_Conditional(TITLE='Provide Input: Scaling', ACCEPT_STRING='Set a Scaling Value', $
      DECLINE_STRING='Do Not Set a Scaling Value', DEFAULT='1000.00', /FLOAT)
  ENDIF ELSE Scaling = -1
  ;---------------------------------------------------------------------------------------------
  ; Set the output folder:
  Path='C:\Users\war409\CMRSET\cmrset.bias.correct\'
  Out_Directory = DIALOG_PICKFILE(PATH=Path, TITLE='Select The Output Folder', /DIRECTORY, /OVERWRITE_PROMPT)
  IF Out_Directory EQ '' THEN RETURN ; Error check.
  ;---------------------------------------------------------------------------------------------
  ; File Loop:
  ;---------------------------------------------------------------------------------------------
  FOR i=0, N_ELEMENTS(In_Files)-1 DO BEGIN
    FileLoopStart = SYSTIME(1) ;  Get file loop start time.
    ;-------------- ; Set file:
    File_In = In_Files[i] ; Get the ith filename and path.
    FNS_In = FNS[i] ; Get the ith filename (not inc. file extension).
    ;-------------- ; Create output file:
    ; File_Out = Out_Directory + Prefix + Date_String + '.img' ; Set the output file name
    File_Out = Out_Directory + FNS_In + 'Bias.Correct.img'
    OPENW, UNIT_Out, File_Out, /GET_LUN ; Create the output file.
    FREE_LUN, UNIT_Out ; Close the output file.
    ;-------------------------------------------------------------------------------------------
    ; Segment loop:
    ;-------------------------------------------------------------------------------------------    
    Data_In = READ_BINARY(File_In, DATA_TYPE=In_DataType) ; Open the input file.
    Elements = (N_ELEMENTS(Data_In)-1) ; Get the number of grid elements (cells).
    Result = FUNCTION_Segment(Elements, 0.1000) ; Call the segment function.
    ;-------------- ; Set segment parameters:
    Segment = Result[0]
    Count_S = LONG(Result[1])
    Segment_Start = LONG(Result[2]) 
    Segment_End = LONG(Result[3])
    Segment_Length = LONG(Result[4])
    ;-------------- ; Segment loop:
    FOR s=0, Count_S-1 DO BEGIN
      SegmentLoopStart = SYSTIME(1) ; Get the segment loop start time.
      ;-------------- ; Update segment loop parameters: 
      IF s GE 1 THEN BEGIN
        Segment_Start = LONG(Segment_Start + Segment_Size) ; Update the segment start position.
        Segment_End = LONG((s+1)*Segment_Size) ; Update the segment end position.
      ENDIF
      ;-------------- ; In the final loop fix the end position if the segment length is not a round integer.
      IF s EQ Count_S-1 THEN Segment_End = LONG(Elements) ; Update the segment end position.
      ;-------------- ; Get the current segment size:
      Segment_Size = LONG(Segment_End - Segment_Start)+1 ; Get the current segment size.
      ;-------------- ; Set mask:
      Land = WHERE(Mask(Segment_Start:Segment_End) EQ 1, Count_Land)
      ;-------------- ; Get data:
      Data_Segment = Data_In(Segment_Start:Segment_End) ; Get data slice.
      ;-------------- ; Set no-data mask:
      NaN = WHERE(Data_Segment EQ -999, NaN_Count)
      ;-------------- ; Apply the CMRSET scaling factor:
      Data_Segment = (Data_Segment * 0.001)
      ;-------------- ; Apply bias correction:
      BC_Data = (0.853 * Data_Segment[Land]) + 0.293
      ;-------------- ; Use the land mask to build the output array.
      IF (Out_DataType EQ 2) THEN BEGIN ; Signed Integer:
        BC_Data_Out = MAKE_ARRAY(Segment_Size, VALUE=-999, /INTEGER)
        IF (Scaling[0] NE -1) THEN BC_Data_Out[Land] = FIX((BC_Data * Scaling[1]) + 0.5) ELSE BC_Data_Out[Land] = FIX(BC_Data + 0.5)
        BC_Data_Out[NaN] = -999
      ENDIF
      IF (Out_DataType EQ 3) THEN BEGIN ; Long Integer:
        BC_Data_Out = MAKE_ARRAY(Segment_Size, VALUE=-999, /LONG)
        IF (Scaling[0] NE -1) THEN BC_Data_Out[Land] = LONG((BC_Data * Scaling[1]) + 0.5) ELSE BC_Data_Out[Land] = LONG(BC_Data + 0.5)
        BC_Data_Out[NaN] = -999
      ENDIF
      IF (Out_DataType EQ 4) THEN BEGIN ; Float:
        BC_Data_Out = MAKE_ARRAY(Segment_Size, VALUE=-999.00, /FLOAT)
        BC_Data_Out[Land] = BC_Data
        BC_Data_Out[NaN] = -999
      ENDIF
      IF (Out_DataType EQ 5) THEN BEGIN ; Double:
        BC_Data_Out = MAKE_ARRAY(Segment_Size, VALUE=-999.00, /DOUBLE)
        BC_Data_Out[Land] = DOUBLE(BC_Data)
        BC_Data_Out[NaN] = -999
      ENDIF
      IF (Out_DataType EQ 12) THEN BEGIN ; Unsigned Integer:
        BC_Data_Out = MAKE_ARRAY(Segment_Size, VALUE=0, /UINT)
        IF (Scaling[0] NE -1) THEN BC_Data_Out[Land] = UINT((BC_Data * Scaling[1]) + 0.5) ELSE BC_Data_Out[Land] = UINT(BC_Data + 0.5)
        BC_Data_Out[NaN] = -999
      ENDIF
      ;-------------- ; Write the output data:
      OPENU, UNIT_Out, File_Out, /APPEND, /GET_LUN
      WRITEU, UNIT_Out, BC_Data_Out
      FREE_LUN, UNIT_Out
      ;-----------------------------------------------------------------------------------------
      Seconds = (SYSTIME(1)-SegmentLoopStart)/60
      PRINT, '  Processing Time: ', STRTRIM(Seconds, 2), ' seconds, for segment ', STRTRIM(s+1, 2), $
        ' of ', STRTRIM(Count_S, 2)
      ;-----------------------------------------------------------------------------------------
    ENDFOR
    ;-------------------------------------------------------------------------------------------
    Minutes = (SYSTIME(1)-FileLoopStart)/60
    PRINT, 'Processing Time: ', STRTRIM(Minutes, 2), ' minutes, for file ', STRTRIM(i+1, 2), $
      ' of ', STRTRIM(N_ELEMENTS(In_Files), 2)
    ;-------------------------------------------------------------------------------------------
  ENDFOR
  ;---------------------------------------------------------------------------------------------
  Minutes = (SYSTIME(1)-StartTime)/60
  Hours = Minutes/60 ; Convert minutes to hours.
  PRINT,''
  PRINT,'Total Processing Time: ', STRTRIM(Minutes, 2), ' minutes (', STRTRIM(Hours, 2),   ' hours).'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
END

  