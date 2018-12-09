; ##############################################################################################
; NAME: Time_Series_Map_Proportion_By_Relational_Operators_Contiguous_LANDMASK.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: NWC Groundwater Dependent Ecosystems Atlas.
; DATE: 22/09/2010
; DLM: 21/05/2011
;
; DESCRIPTION: This tool identifies cells that conform to the user selected relational statement 
;              for a selected length of time. Where time is the count of inputs. For example, 
;              say each individual input raster contains values from 0.0 to 1.0, and each input 
;              is a daily snapshot of the phenomena of interest. Say the user is only interested 
;              in values that are greater than 0.5. The user also wants to identify cells that  
;              have had a value of more than 0.5 for at least 7 days in a row. By defining the  
;              relational statement as ‘Event GT 0.5’ and the length of the contiguous period as 
;              ‘7’ the tool will identify those cells where the criterion is satisfied in the 
;              input time series. 
;          
;              The output grid contains the count of times the criteria was satisfied during 
;              the time-series; a value of 0 indicates that the criteria was never satisfied.
;          
; INPUT:       One or more single band raster files.
;
; OUTPUT:      One output flat binary file (.img) of the user selected datatype per time-series. 
;              (See description for more details)
;               
; PARAMETERS:  Via IDL widgets, set:
; 
;              1.  SELECT THE INPUT DATA: see INPUT
;              
;              3.  SELECT THE INPUT DATATYPE: The datatype of the input rasters e.g. byte, integer, 
;                  float etc.
;              
;              4.  DEFINE AN INPUT NODATA VALUE: If the input data contains a 'fill' or 'nodata'   
;                  value that you want to exclude from the processing select YES.
;              
;              4.1   DEFINE THE INPUT NODATA VALUE (optional; if YES in 3.): The input nodata value.
;              
;              5.  SET THE RELATIONAL STATEMENT: see DESCRIPTION
;              
;              6.  SET THE LENGTH OF THE CONTIGUOUS PERIOD: see DESCRIPTION
;              
;              7.  SELECT THE OUTPUT DATATYPE: The datatype of the output raster.
;              
;              8.  DEFINE THE OUTPUT FILE: The output raster name and location. 
;              
; NOTES:       The input data must have identical dimensions.
; 
;              Per cell; if a single date within a contiguous period has a no-data value, but  
;              the selected criteria was satisfied on the previous and subsequent dates, the  
;              no-data date is recorded as satisfying the criteria for the purpose of 
;              identifying contiguous periods.
;               
;              This program calls one or more external functions. You will need to compile the  
;              necessary functions in IDL, or save the functions to the current IDL workspace  
;              prior to running this tool.
;              
;              For more information contact Garth.Warren@csiro.au
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


PRO Time_Series_Map_Proportion_By_Relational_Operators_Contiguous_LANDMASK
  ;---------------------------------------------------------------------------------------------
  StartTime = SYSTIME(1) ; Get the current system time.
  PRINT,''
  PRINT,'Begin Processing: Time_Series_Map_Proportion_By_Relational_Operators_Contiguous_LANDMASK'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
  ; Input/Output:
  ;---------------------------------------------------------------------------------------------
  ;In_Mask_250 = '\\File-wron\Working\work\NWC_Groundwater_Dependent_Ecosystems\Data\Raster\SILO\MODIS.Land.Mask.aust.005.250m.img'
  In_Mask_500 = '\\File-wron\Working\work\NWC_Groundwater_Dependent_Ecosystems\Data\Raster\SILO\MODIS.Land.Mask.aust.005.500m.img'
  Mask = READ_BINARY(In_Mask_500, DATA_TYPE=1)
  ;---------------------------------------------------------------------------------------------
  ; Select the input data:
  Path='\\file-wron\Working\work\Juan_Pablo\Open_Water_mapping\'
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
  ;-------------- ; Get the input dates:
  In_Dates = FUNCTION_WIDGET_Date(IN_FILES=FNS, /JULIAN) ; Get the input file name dates.
  IF In_Dates[0] NE -1 THEN BEGIN ; Check for valid dates.
    In_Files = In_Files[SORT(In_Dates)] ; Sort file name by date.
    FNS = FNS[SORT(In_Dates)] ; Sort file name by date.
    Dates_Unique = In_Dates[UNIQ(In_Dates)] ; Get unique input dates.
    Dates_Unique = Dates_Unique[SORT(Dates_Unique)] ; Sort the unique dates.   
    Dates_Unique = Dates_Unique[UNIQ(Dates_Unique)] ; Get unique input dates.
  ENDIF ELSE BEGIN
    PRINT,'** Invalid Date Selection **'
    RETURN ; Quit program
  ENDELSE
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
  ; Define no-data: (if In_NaN[0] EQ -1 then NO no-data was set.
  In_NaN = FUNCTION_WIDGET_No_Data(TITLE='Provide Input: No Data', DEFAULT='255', /INTEGER) ; 
  ;---------------------------------------------------------------------------------------------
  ; Set the relational operation parameters:
  Statement = FUNCTION_WIDGET_Set_Single_Relational_Statement(TITLE='Relational Statement', DEFAULT='25')
  IF Statement[0] EQ -1 THEN BEGIN
    PRINT,'** Invalid Selection **'
    RETURN ; Quit program.
  ENDIF
  ;-------------- ; Set widget results:
  Operators = ['EQ','LE','LT','GE','GT','NE']
  Operator_A = Operators[Statement[0]]
  Value_A = Statement[1]
  PRINT,'Statement: (Event ', Operator_A, ' ', STRTRIM(Value_A, 2),')'
  ;---------------------------------------------------------------------------------------------
  ; Set the contiguous period:
  IF In_Operation EQ 2 THEN BEGIN
    Contiguous = FUNCTION_WIDGET_Map_By_Frequency(TITLE='Contiguous Period:', DEFAULT='25')
    IF Contiguous[0] EQ -1 THEN BEGIN
      PRINT,'** Invalid Selection **'
      RETURN ; Quit program.
    ENDIF
    Contiguous_A = Operators[Contiguous[0]]
    Contiguous_Value = Contiguous[1]
    PRINT,'Statement: (Contiguous Period: ', Contiguous_A, ' ', STRTRIM(Contiguous_Value, 2), ')'
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
  ; Set the output file:
  Path='C:\WorkSpace\OWL\'
  Out_File = DIALOG_PICKFILE(PATH=Path, TITLE='Define The Output File', /OVERWRITE_PROMPT)
  IF Out_File EQ '' THEN RETURN ; Error check.
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
    Matrix_Duration = MAKE_ARRAY(Segment_Size, VALUE=0, /DOUBLE)
    Matrix_Contiguous = MAKE_ARRAY(Segment_Size, VALUE=0, /DOUBLE)
    ;-------------------------------------------------------------------------------------------
    ; File loop (get data and fill arrays):
    ;-------------------------------------------------------------------------------------------  
    FOR i=0, N_ELEMENTS(In_Files)-1 DO BEGIN ; Loop through each input file.
      FileLoopStart = SYSTIME(1) ;  Get loop start time.
      Data = READ_BINARY(In_Files[i], DATA_TYPE=In_DataType) ; Open the i-th file.
      Data_Segment = Data(Segment_Start:Segment_End) ; Get data slice (segment).
      ;-------------- ; Set mask:
      Land = WHERE(Mask(Segment_Start:Segment_End) EQ 1, Count_Land)
      Data_Segment = Data_Segment[Land] ; Apply land mask.
      ;-------------- ; Get data from the previous date:
      IF i GT 0 THEN BEGIN
        Data_P = READ_BINARY(In_Files[i-1], DATA_TYPE=In_DataType) ; Open file i-1. 
        Data_Segment_P = Data_P(Segment_Start:Segment_End) ; Get data slice (segment).
        Data_Segment_P = Data_Segment_P[Land] ; Apply land mask.
      ENDIF
      ;-------------- ; Get data from the following date:
      IF i EQ 0 THEN BEGIN
        Data_F = READ_BINARY(In_Files[i+1], DATA_TYPE=In_DataType) ; Open file i+1. 
        Data_Segment_F = Data_F(Segment_Start:Segment_End) ; Get data slice (segment).
        Data_Segment_F = Data_Segment_F[Land] ; Apply land mask.
      ENDIF
      ;-----------------------------------------------------------------------------------------
      ; Apply relational operation:
      IF i GT 0 THEN BEGIN
        IF In_NaN[0] NE -1 THEN BEGIN  ; No-data is set.
          IF Operator_A EQ 0 THEN Matrix_Duration += (((Data_Segment EQ Value_A) AND (Data_Segment NE In_NaN[1])) $
            AND ((Data_Segment_P EQ Value_A) AND (Data_Segment_P NE In_NaN[1])))
          IF Operator_A EQ 1 THEN Matrix_Duration += (((Data_Segment LE Value_A) AND (Data_Segment NE In_NaN[1])) $
            AND ((Data_Segment_P LE Value_A) AND (Data_Segment_P NE In_NaN[1])))
          IF Operator_A EQ 2 THEN Matrix_Duration += (((Data_Segment LT Value_A) AND (Data_Segment NE In_NaN[1])) $
            AND ((Data_Segment_P LT Value_A) AND (Data_Segment_P NE In_NaN[1])))
          IF Operator_A EQ 3 THEN Matrix_Duration += (((Data_Segment GE Value_A) AND (Data_Segment NE In_NaN[1])) $
            AND ((Data_Segment_P GE Value_A) AND (Data_Segment_P NE In_NaN[1])))
          IF Operator_A EQ 4 THEN Matrix_Duration += (((Data_Segment GT Value_A) AND (Data_Segment NE In_NaN[1])) $
            AND ((Data_Segment_P GT Value_A) AND (Data_Segment_P NE In_NaN[1])))
          IF Operator_A EQ 5 THEN Matrix_Duration += (((Data_Segment NE Value_A) AND (Data_Segment NE In_NaN[1])) $
            AND ((Data_Segment_P NE Value_A) AND (Data_Segment_P NE In_NaN[1])))
        ENDIF ELSE BEGIN
          IF Operator_A EQ 0 THEN Matrix_Duration += ((Data_Segment EQ Value_A) AND (Data_Segment_P EQ Value_A))
          IF Operator_A EQ 1 THEN Matrix_Duration += ((Data_Segment LE Value_A) AND (Data_Segment_P LE Value_A))
          IF Operator_A EQ 2 THEN Matrix_Duration += ((Data_Segment LT Value_A) AND (Data_Segment_P LT Value_A))
          IF Operator_A EQ 3 THEN Matrix_Duration += ((Data_Segment GE Value_A) AND (Data_Segment_P GE Value_A))
          IF Operator_A EQ 4 THEN Matrix_Duration += ((Data_Segment GT Value_A) AND (Data_Segment_P GT Value_A))
          IF Operator_A EQ 5 THEN Matrix_Duration += ((Data_Segment NE Value_A) AND (Data_Segment_P NE Value_A))
        ENDELSE
      ENDIF
      ;-----------------------------------------------------------------------------------------
      ; Apply relational operation: i = 0
      IF i EQ 0 THEN BEGIN
        IF In_NaN[0] NE -1 THEN BEGIN  ; No-data is set.
          IF Operator_A EQ 0 THEN Matrix_Duration += (((Data_Segment EQ Value_A) AND (Data_Segment NE In_NaN[1])) $
            AND ((Data_Segment_F EQ Value_A) AND (Data_Segment_F NE In_NaN[1])))
          IF Operator_A EQ 1 THEN Matrix_Duration += (((Data_Segment LE Value_A) AND (Data_Segment NE In_NaN[1])) $
            AND ((Data_Segment_F LE Value_A) AND (Data_Segment_F NE In_NaN[1])))
          IF Operator_A EQ 2 THEN Matrix_Duration += (((Data_Segment LT Value_A) AND (Data_Segment NE In_NaN[1])) $
            AND ((Data_Segment_F LT Value_A) AND (Data_Segment_F NE In_NaN[1])))
          IF Operator_A EQ 3 THEN Matrix_Duration += (((Data_Segment GE Value_A) AND (Data_Segment NE In_NaN[1])) $
            AND ((Data_Segment_F GE Value_A) AND (Data_Segment_F NE In_NaN[1])))
          IF Operator_A EQ 4 THEN Matrix_Duration += (((Data_Segment GT Value_A) AND (Data_Segment NE In_NaN[1])) $
            AND ((Data_Segment_F GT Value_A) AND (Data_Segment_F NE In_NaN[1])))
          IF Operator_A EQ 5 THEN Matrix_Duration += (((Data_Segment NE Value_A) AND (Data_Segment NE In_NaN[1])) $
            AND ((Data_Segment_F NE Value_A) AND (Data_Segment_F NE In_NaN[1])))
        ENDIF ELSE BEGIN
          IF Operator_A EQ 0 THEN Matrix_Duration += ((Data_Segment EQ Value_A) AND (Data_Segment_F EQ Value_A))
          IF Operator_A EQ 1 THEN Matrix_Duration += ((Data_Segment LE Value_A) AND (Data_Segment_F LE Value_A))
          IF Operator_A EQ 2 THEN Matrix_Duration += ((Data_Segment LT Value_A) AND (Data_Segment_F LT Value_A))
          IF Operator_A EQ 3 THEN Matrix_Duration += ((Data_Segment GE Value_A) AND (Data_Segment_F GE Value_A))
          IF Operator_A EQ 4 THEN Matrix_Duration += ((Data_Segment GT Value_A) AND (Data_Segment_F GT Value_A))
          IF Operator_A EQ 5 THEN Matrix_Duration += ((Data_Segment NE Value_A) AND (Data_Segment_F NE Value_A))
        ENDELSE
      ENDIF
      ;-----------------------------------------------------------------------------------------
      ; Set Matrix_Contiguous. Return '1' if the contiguous period satisfies the selected statement:
      IF Contiguous_A EQ 0 THEN Matrix_Contiguous += (Matrix_Duration EQ Contiguous_Value)
      IF Contiguous_A EQ 1 THEN Matrix_Contiguous += (Matrix_Duration LE Contiguous_Value)
      IF Contiguous_A EQ 2 THEN Matrix_Contiguous += (Matrix_Duration LT Contiguous_Value)
      IF Contiguous_A EQ 3 THEN Matrix_Contiguous += (Matrix_Duration GE Contiguous_Value)
      IF Contiguous_A EQ 4 THEN Matrix_Contiguous += (Matrix_Duration GT Contiguous_Value)
      IF Contiguous_A EQ 5 THEN Matrix_Contiguous += (Matrix_Duration NE Contiguous_Value)
      ;-----------------------------------------------------------------------------------------
    ENDFOR
    ;-------------------------------------------------------------------------------------------
    ; Set output:
    IF (Out_DataType EQ 1) THEN Contiguous_Out = BYTE(Matrix_Contiguous) ; Convert to Byte.
    IF (Out_DataType EQ 2) THEN Contiguous_Out = FIX(Matrix_Contiguous + 0.5) ; Convert to Integer.
    IF (Out_DataType EQ 3) THEN Contiguous_Out = LONG(Matrix_Contiguous + 0.5) ; Convert to LONG
    IF (Out_DataType EQ 4) THEN Contiguous_Out = FLOAT(Matrix_Contiguous) ; Convert to FLOAT
    IF (Out_DataType EQ 5) THEN Contiguous_Out = DOUBLE(Matrix_Contiguous) ; Convert to DOUBLE
    IF (Out_DataType EQ 12) THEN Contiguous_Out = UINT(Matrix_Contiguous + 0.5) ; Convert to unsigned Integer.
    ; Write output:
    IF s EQ 0 THEN BEGIN
      OPENW, Unit_Out, Out_File, /GET_LUN ; Create the output file.
      FREE_LUN, Unit_Out ; Close the output file.
    ENDIF
    OPENU, Unit_Out, Out_File, /APPEND, /GET_LUN
    WRITEU, Unit_Out, Contiguous_Out 
    FREE_LUN, Unit_Out
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

