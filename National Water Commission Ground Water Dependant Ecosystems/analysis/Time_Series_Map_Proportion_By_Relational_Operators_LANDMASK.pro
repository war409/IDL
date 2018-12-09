; ##############################################################################################
; NAME: Time_Series_Map_Proportion_By_Relational_Operators_LANDMASK.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: NWC Groundwater Dependent Ecosystems Atlas.
; DATE: 22/09/2010
; DLM: 08/04/2011
;
; DESCRIPTION:  This tool produces three types of output:
; 
;               1.  Map the percentage of:
; 
;               The per-cell proportion of the input time series that conforms   
;               to the user defined relational statement. Cell values that: DO and DO NOT, conform  
;               to the user statement are identified in each input. The per-cell percentage of 
;               inputs in the time series that DO conform to the selected statement is calculated  
;               and returned.
;              
;               For example, say each individual input contains values from 0.0 to 1.0 however the  
;               user is only interested in values (or spatial location) that are greater than 0.5.  
;               By defining the relational statement as ‘Event GT 0.5’ the tool will identify those 
;               cells that satisfy the criteria in each input grid. The output grid can contain 
;               values from 0 to 100. Where a cell value of 100 indicates that for each input that 
;               cell location has a value greater than 0.5.
;              
;               The statement may contain up to two user-selected operators; e.g. the relational 
;               statement ‘Event GT 0.5’ AND ‘Event LE 0.75’ will identify those values in the 
;               input that have a cell value of more than 0.5 but less than or equal to 0.75.
;
;               Similarly, ‘Event GT 0.5’ OR ‘Event LE 0.25’ identifies values greater than 50 
;               and values less than or equal to 0.25.
;              
;               2.  Map the count of:
;              
;               Similar to above. Rather than the output containing the proportion of the time series
;               that conforms to the selected statement it contains the per cell count of times the 
;               statement was satisfied.
;              
;               3.  Map by frequency:
;              
;               This output type identifies cells that have meet the selected statement EQ, NE, 
;               LT, LE, GE, GT a user selected proportion of time.
;              
;               For example, this option could identify cells that have had a cell value GE 0.95 for
;               95% of the time series. Cells that satisfy the criteria are given a value of 1 in the
;               output, cells that do not satisfy the criteria are given a value of 0.
;          
; INPUT:        One or more single band raster files.
;
; OUTPUT:       One output flat binary file (.img) of the user selected datatype per time series. 
;               (See description for more details)
;               
; PARAMETERS:   Via pop-up dialog widgets.
;              
; NOTES:        For more information contact Garth.Warren@csiro.au
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


PRO Time_Series_Map_Proportion_By_Relational_Operators_LANDMASK
  ;---------------------------------------------------------------------------------------------
  StartTime = SYSTIME(1) ; Get the current system time.
  PRINT,''
  PRINT,'Begin Processing: Time_Series_Map_Proportion_By_Relational_Operators_LANDMASK'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
  ; Input/Output:
  ;---------------------------------------------------------------------------------------------
  ;In_Mask_250 = '\\File-wron\Working\work\NWC_Groundwater_Dependent_Ecosystems\Data\Raster\SILO\MODIS.Land.Mask.aust.005.250m.img'
  In_Mask_500 = '\\File-wron\Working\work\NWC_Groundwater_Dependent_Ecosystems\Data\Raster\SILO\MODIS.Land.Mask.aust.005.500m.img'
  Mask = READ_BINARY(In_Mask_500, DATA_TYPE=1)
  ;---------------------------------------------------------------------------------------------
  ; Select the mapping type:
  In_Operation = FUNCTION_WIDGET_Droplist(TITLE='Select Mapping Operation:', VALUE=['1.  Map the percentage of', $
    '2.  Map the count of','3.  Map by frequency'])
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
  Statement = FUNCTION_WIDGET_Set_Relational_Statement(TITLE='Set: Relational Statement', DEFAULT_A='25', DEFAULT_B='75')
  IF Statement[0] EQ -1 THEN BEGIN
    PRINT,'** Invalid Selection **'
    RETURN ; Quit program.
  ENDIF
  ;-------------- ; Set widget results:
  Operators = ['EQ','LE','LT','GE','GT','NE']
  Options = ['---','AND','OR']
  Operator_A = Operators[Statement[0]]
  Value_A = Statement[1]
  IF Statement[2] NE -1 THEN Operator_B = Options[Statement[2]] ELSE Operator_B = -1
  IF Statement[2] NE -1 THEN Operator_C = Operators[Statement[3]] ELSE Operator_C = -1
  IF Statement[2] NE -1 THEN Value_B = Statement[4] ELSE Value_B = -1
  IF Statement[2] EQ -1 THEN PRINT,'Statement: (Event ', Operator_A, ' ', STRTRIM(Value_A, 2),')' ELSE PRINT, 'Statement:  (Event  ', $
    Operator_A, '  ', STRTRIM(Value_A, 2), ')  ', Operator_B, '  (Event  ', Operator_C, '  ', STRTRIM(Value_B, 2), ')'
  ;---------------------------------------------------------------------------------------------
  ; Set the frequency operator and value:
  IF In_Operation EQ 2 THEN BEGIN
    Frequency = FUNCTION_WIDGET_Map_By_Frequency(TITLE='Set: Mapping Freq.', DEFAULT='25')
    IF Frequency[0] EQ -1 THEN BEGIN
      PRINT,'** Invalid Selection **'
      RETURN ; Quit program.
    ENDIF
    Frequency_A = Operators[Frequency[0]]
    Frequency_Value = Frequency[1]
    PRINT,'Statement: (Frequency ', Frequency_A, ' ', STRTRIM(Frequency_Value, 2), '% of cases)'
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
    Matrix_Data = MAKE_ARRAY(Segment_Size, VALUE=0, /FLOAT) ; Create an array to hold grid data for all files.
    IF In_NaN[0] NE -1 THEN Matrix_Count = MAKE_ARRAY(Segment_Size, /FLOAT) ; Frequency of no-data values.
    IF In_NaN[0] EQ -1 THEN Matrix_Count = MAKE_ARRAY(Segment_Size, VALUE=N_ELEMENTS(In_Files), /FLOAT) ; Total count.
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
      ;-----------------------------------------------------------------------------------------
      ; Map the percentage of (single statement):
      IF Operator_B EQ -1 THEN BEGIN ; '---'      
        IF In_NaN[0] NE -1 THEN BEGIN  ; No-data is set.
          IF Operator_A EQ 'EQ' THEN Matrix_Data += ((Data_Segment EQ Value_A) AND (Data_Segment NE In_NaN[1]))
          IF Operator_A EQ 'LE' THEN Matrix_Data += ((Data_Segment LE Value_A) AND (Data_Segment NE In_NaN[1]))
          IF Operator_A EQ 'LT' THEN Matrix_Data += ((Data_Segment LT Value_A) AND (Data_Segment NE In_NaN[1]))
          IF Operator_A EQ 'GE' THEN Matrix_Data += ((Data_Segment GE Value_A) AND (Data_Segment NE In_NaN[1]))
          IF Operator_A EQ 'GT' THEN Matrix_Data += ((Data_Segment GT Value_A) AND (Data_Segment NE In_NaN[1]))
          IF Operator_A EQ 'NE' THEN Matrix_Data += ((Data_Segment NE Value_A) AND (Data_Segment NE In_NaN[1]))
          Matrix_Count += (Data_Segment NE In_NaN[1]) ; Non-no-data values.
        ENDIF ELSE BEGIN ; No-data is NOT set.
          IF Operator_A EQ 'EQ' THEN Matrix_Data += (Data_Segment EQ Value_A)
          IF Operator_A EQ 'LE' THEN Matrix_Data += (Data_Segment LE Value_A) 
          IF Operator_A EQ 'LT' THEN Matrix_Data += (Data_Segment LT Value_A)
          IF Operator_A EQ 'GE' THEN Matrix_Data += (Data_Segment GE Value_A)
          IF Operator_A EQ 'GT' THEN Matrix_Data += (Data_Segment GT Value_A)
          IF Operator_A EQ 'NE' THEN Matrix_Data += (Data_Segment NE Value_A)
        ENDELSE
      ENDIF
      ;----------------------------------------------------------------------------------------- 
      ; Map the percentage of (double statement AND):
      IF Operator_B EQ 1 THEN BEGIN ; 'AND'
        IF In_NaN[0] NE -1 THEN BEGIN  ; No-data is set.
          IF Operator_A EQ 'EQ' THEN BEGIN 
            IF Operator_C EQ 'EQ' THEN Matrix_Data += (((Data_Segment EQ Value_A) AND (Data_Segment EQ Value_B)) AND (Data_Segment NE In_NaN[1])) 
            IF Operator_C EQ 'LE' THEN Matrix_Data += (((Data_Segment EQ Value_A) AND (Data_Segment LE Value_B)) AND (Data_Segment NE In_NaN[1]))
            IF Operator_C EQ 'LT' THEN Matrix_Data += (((Data_Segment EQ Value_A) AND (Data_Segment LT Value_B)) AND (Data_Segment NE In_NaN[1]))
            IF Operator_C EQ 'GE' THEN Matrix_Data += (((Data_Segment EQ Value_A) AND (Data_Segment GE Value_B)) AND (Data_Segment NE In_NaN[1]))
            IF Operator_C EQ 'GT' THEN Matrix_Data += (((Data_Segment EQ Value_A) AND (Data_Segment GT Value_B)) AND (Data_Segment NE In_NaN[1]))
            IF Operator_C EQ 'NE' THEN Matrix_Data += (((Data_Segment EQ Value_A) AND (Data_Segment NE Value_B)) AND (Data_Segment NE In_NaN[1]))   
          ENDIF
          IF Operator_A EQ 'LE' THEN BEGIN 
            IF Operator_C EQ 'EQ' THEN Matrix_Data += (((Data_Segment LE Value_A) AND (Data_Segment EQ Value_B)) AND (Data_Segment NE In_NaN[1])) 
            IF Operator_C EQ 'LE' THEN Matrix_Data += (((Data_Segment LE Value_A) AND (Data_Segment LE Value_B)) AND (Data_Segment NE In_NaN[1]))
            IF Operator_C EQ 'LT' THEN Matrix_Data += (((Data_Segment LE Value_A) AND (Data_Segment LT Value_B)) AND (Data_Segment NE In_NaN[1]))
            IF Operator_C EQ 'GE' THEN Matrix_Data += (((Data_Segment LE Value_A) AND (Data_Segment GE Value_B)) AND (Data_Segment NE In_NaN[1]))
            IF Operator_C EQ 'GT' THEN Matrix_Data += (((Data_Segment LE Value_A) AND (Data_Segment GT Value_B)) AND (Data_Segment NE In_NaN[1]))
            IF Operator_C EQ 'NE' THEN Matrix_Data += (((Data_Segment LE Value_A) AND (Data_Segment NE Value_B)) AND (Data_Segment NE In_NaN[1]))   
          ENDIF
          IF Operator_A EQ 'LT' THEN BEGIN 
            IF Operator_C EQ 'EQ' THEN Matrix_Data += (((Data_Segment LT Value_A) AND (Data_Segment EQ Value_B)) AND (Data_Segment NE In_NaN[1])) 
            IF Operator_C EQ 'LE' THEN Matrix_Data += (((Data_Segment LT Value_A) AND (Data_Segment LE Value_B)) AND (Data_Segment NE In_NaN[1]))
            IF Operator_C EQ 'LT' THEN Matrix_Data += (((Data_Segment LT Value_A) AND (Data_Segment LT Value_B)) AND (Data_Segment NE In_NaN[1]))
            IF Operator_C EQ 'GE' THEN Matrix_Data += (((Data_Segment LT Value_A) AND (Data_Segment GE Value_B)) AND (Data_Segment NE In_NaN[1]))
            IF Operator_C EQ 'GT' THEN Matrix_Data += (((Data_Segment LT Value_A) AND (Data_Segment GT Value_B)) AND (Data_Segment NE In_NaN[1]))
            IF Operator_C EQ 'NE' THEN Matrix_Data += (((Data_Segment LT Value_A) AND (Data_Segment NE Value_B)) AND (Data_Segment NE In_NaN[1]))   
          ENDIF
          IF Operator_A EQ 'GE' THEN BEGIN 
            IF Operator_C EQ 'EQ' THEN Matrix_Data += (((Data_Segment GE Value_A) AND (Data_Segment EQ Value_B)) AND (Data_Segment NE In_NaN[1])) 
            IF Operator_C EQ 'LE' THEN Matrix_Data += (((Data_Segment GE Value_A) AND (Data_Segment LE Value_B)) AND (Data_Segment NE In_NaN[1]))
            IF Operator_C EQ 'LT' THEN Matrix_Data += (((Data_Segment GE Value_A) AND (Data_Segment LT Value_B)) AND (Data_Segment NE In_NaN[1]))
            IF Operator_C EQ 'GE' THEN Matrix_Data += (((Data_Segment GE Value_A) AND (Data_Segment GE Value_B)) AND (Data_Segment NE In_NaN[1]))
            IF Operator_C EQ 'GT' THEN Matrix_Data += (((Data_Segment GE Value_A) AND (Data_Segment GT Value_B)) AND (Data_Segment NE In_NaN[1]))
            IF Operator_C EQ 'NE' THEN Matrix_Data += (((Data_Segment GE Value_A) AND (Data_Segment NE Value_B)) AND (Data_Segment NE In_NaN[1]))   
          ENDIF
          IF Operator_A EQ 'GT' THEN BEGIN 
            IF Operator_C EQ 'EQ' THEN Matrix_Data += (((Data_Segment GT Value_A) AND (Data_Segment EQ Value_B)) AND (Data_Segment NE In_NaN[1])) 
            IF Operator_C EQ 'LE' THEN Matrix_Data += (((Data_Segment GT Value_A) AND (Data_Segment LE Value_B)) AND (Data_Segment NE In_NaN[1]))
            IF Operator_C EQ 'LT' THEN Matrix_Data += (((Data_Segment GT Value_A) AND (Data_Segment LT Value_B)) AND (Data_Segment NE In_NaN[1]))
            IF Operator_C EQ 'GE' THEN Matrix_Data += (((Data_Segment GT Value_A) AND (Data_Segment GE Value_B)) AND (Data_Segment NE In_NaN[1]))
            IF Operator_C EQ 'GT' THEN Matrix_Data += (((Data_Segment GT Value_A) AND (Data_Segment GT Value_B)) AND (Data_Segment NE In_NaN[1]))
            IF Operator_C EQ 'NE' THEN Matrix_Data += (((Data_Segment GT Value_A) AND (Data_Segment NE Value_B)) AND (Data_Segment NE In_NaN[1]))   
          ENDIF
          IF Operator_A EQ 'NE' THEN BEGIN 
            IF Operator_C EQ 'EQ' THEN Matrix_Data += (((Data_Segment NE Value_A) AND (Data_Segment EQ Value_B)) AND (Data_Segment NE In_NaN[1])) 
            IF Operator_C EQ 'LE' THEN Matrix_Data += (((Data_Segment NE Value_A) AND (Data_Segment LE Value_B)) AND (Data_Segment NE In_NaN[1]))
            IF Operator_C EQ 'LT' THEN Matrix_Data += (((Data_Segment NE Value_A) AND (Data_Segment LT Value_B)) AND (Data_Segment NE In_NaN[1]))
            IF Operator_C EQ 'GE' THEN Matrix_Data += (((Data_Segment NE Value_A) AND (Data_Segment GE Value_B)) AND (Data_Segment NE In_NaN[1]))
            IF Operator_C EQ 'GT' THEN Matrix_Data += (((Data_Segment NE Value_A) AND (Data_Segment GT Value_B)) AND (Data_Segment NE In_NaN[1]))
            IF Operator_C EQ 'NE' THEN Matrix_Data += (((Data_Segment NE Value_A) AND (Data_Segment NE Value_B)) AND (Data_Segment NE In_NaN[1]))   
          ENDIF
          Matrix_Count += (Data_Segment NE In_NaN[1]) ; Non-no-data values.
          ;--------------
        ENDIF ELSE BEGIN ; No-data is NOT set.
          IF Operator_A EQ 'EQ' THEN BEGIN 
            IF Operator_C EQ 'EQ' THEN Matrix_Data += ((Data_Segment EQ Value_A) AND (Data_Segment EQ Value_B)) 
            IF Operator_C EQ 'LE' THEN Matrix_Data += ((Data_Segment EQ Value_A) AND (Data_Segment LE Value_B))
            IF Operator_C EQ 'LT' THEN Matrix_Data += ((Data_Segment EQ Value_A) AND (Data_Segment LT Value_B))
            IF Operator_C EQ 'GE' THEN Matrix_Data += ((Data_Segment EQ Value_A) AND (Data_Segment GE Value_B))
            IF Operator_C EQ 'GT' THEN Matrix_Data += ((Data_Segment EQ Value_A) AND (Data_Segment GT Value_B))
            IF Operator_C EQ 'NE' THEN Matrix_Data += ((Data_Segment EQ Value_A) AND (Data_Segment NE Value_B))  
          ENDIF
          IF Operator_A EQ 'LE' THEN BEGIN 
            IF Operator_C EQ 'EQ' THEN Matrix_Data += ((Data_Segment LE Value_A) AND (Data_Segment EQ Value_B)) 
            IF Operator_C EQ 'LE' THEN Matrix_Data += ((Data_Segment LE Value_A) AND (Data_Segment LE Value_B))
            IF Operator_C EQ 'LT' THEN Matrix_Data += ((Data_Segment LE Value_A) AND (Data_Segment LT Value_B))
            IF Operator_C EQ 'GE' THEN Matrix_Data += ((Data_Segment LE Value_A) AND (Data_Segment GE Value_B))
            IF Operator_C EQ 'GT' THEN Matrix_Data += ((Data_Segment LE Value_A) AND (Data_Segment GT Value_B))
            IF Operator_C EQ 'NE' THEN Matrix_Data += ((Data_Segment LE Value_A) AND (Data_Segment NE Value_B))   
          ENDIF
          IF Operator_A EQ 'LT' THEN BEGIN 
            IF Operator_C EQ 'EQ' THEN Matrix_Data += ((Data_Segment LT Value_A) AND (Data_Segment EQ Value_B)) 
            IF Operator_C EQ 'LE' THEN Matrix_Data += ((Data_Segment LT Value_A) AND (Data_Segment LE Value_B))
            IF Operator_C EQ 'LT' THEN Matrix_Data += ((Data_Segment LT Value_A) AND (Data_Segment LT Value_B))
            IF Operator_C EQ 'GE' THEN Matrix_Data += ((Data_Segment LT Value_A) AND (Data_Segment GE Value_B))
            IF Operator_C EQ 'GT' THEN Matrix_Data += ((Data_Segment LT Value_A) AND (Data_Segment GT Value_B))
            IF Operator_C EQ 'NE' THEN Matrix_Data += ((Data_Segment LT Value_A) AND (Data_Segment NE Value_B))  
          ENDIF
          IF Operator_A EQ 'GE' THEN BEGIN 
            IF Operator_C EQ 'EQ' THEN Matrix_Data += ((Data_Segment GE Value_A) AND (Data_Segment EQ Value_B))
            IF Operator_C EQ 'LE' THEN Matrix_Data += ((Data_Segment GE Value_A) AND (Data_Segment LE Value_B))
            IF Operator_C EQ 'LT' THEN Matrix_Data += ((Data_Segment GE Value_A) AND (Data_Segment LT Value_B))
            IF Operator_C EQ 'GE' THEN Matrix_Data += ((Data_Segment GE Value_A) AND (Data_Segment GE Value_B))
            IF Operator_C EQ 'GT' THEN Matrix_Data += ((Data_Segment GE Value_A) AND (Data_Segment GT Value_B))
            IF Operator_C EQ 'NE' THEN Matrix_Data += ((Data_Segment GE Value_A) AND (Data_Segment NE Value_B))   
          ENDIF
          IF Operator_A EQ 'GT' THEN BEGIN 
            IF Operator_C EQ 'EQ' THEN Matrix_Data += ((Data_Segment GT Value_A) AND (Data_Segment EQ Value_B)) 
            IF Operator_C EQ 'LE' THEN Matrix_Data += ((Data_Segment GT Value_A) AND (Data_Segment LE Value_B))
            IF Operator_C EQ 'LT' THEN Matrix_Data += ((Data_Segment GT Value_A) AND (Data_Segment LT Value_B))
            IF Operator_C EQ 'GE' THEN Matrix_Data += ((Data_Segment GT Value_A) AND (Data_Segment GE Value_B))
            IF Operator_C EQ 'GT' THEN Matrix_Data += ((Data_Segment GT Value_A) AND (Data_Segment GT Value_B))
            IF Operator_C EQ 'NE' THEN Matrix_Data += ((Data_Segment GT Value_A) AND (Data_Segment NE Value_B))   
          ENDIF
          IF Operator_A EQ 'NE' THEN BEGIN 
            IF Operator_C EQ 'EQ' THEN Matrix_Data += ((Data_Segment NE Value_A) AND (Data_Segment EQ Value_B)) 
            IF Operator_C EQ 'LE' THEN Matrix_Data += ((Data_Segment NE Value_A) AND (Data_Segment LE Value_B))
            IF Operator_C EQ 'LT' THEN Matrix_Data += ((Data_Segment NE Value_A) AND (Data_Segment LT Value_B))
            IF Operator_C EQ 'GE' THEN Matrix_Data += ((Data_Segment NE Value_A) AND (Data_Segment GE Value_B))
            IF Operator_C EQ 'GT' THEN Matrix_Data += ((Data_Segment NE Value_A) AND (Data_Segment GT Value_B))
            IF Operator_C EQ 'NE' THEN Matrix_Data += ((Data_Segment NE Value_A) AND (Data_Segment NE Value_B))   
          ENDIF 
        ENDELSE 
      ENDIF
      ;-----------------------------------------------------------------------------------------
      ; Map the percentage of (double statement OR):
      IF Operator_B EQ 2 THEN BEGIN ; 'OR'
        IF In_NaN[0] NE -1 THEN BEGIN  ; No-data is set.
          IF Operator_A EQ 'EQ' THEN BEGIN 
            IF Operator_C EQ 'EQ' THEN Matrix_Data += (((Data_Segment EQ Value_A) OR (Data_Segment EQ Value_B)) AND (Data_Segment NE In_NaN[1])) 
            IF Operator_C EQ 'LE' THEN Matrix_Data += (((Data_Segment EQ Value_A) OR (Data_Segment LE Value_B)) AND (Data_Segment NE In_NaN[1]))
            IF Operator_C EQ 'LT' THEN Matrix_Data += (((Data_Segment EQ Value_A) OR (Data_Segment LT Value_B)) AND (Data_Segment NE In_NaN[1]))
            IF Operator_C EQ 'GE' THEN Matrix_Data += (((Data_Segment EQ Value_A) OR (Data_Segment GE Value_B)) AND (Data_Segment NE In_NaN[1]))
            IF Operator_C EQ 'GT' THEN Matrix_Data += (((Data_Segment EQ Value_A) OR (Data_Segment GT Value_B)) AND (Data_Segment NE In_NaN[1]))
            IF Operator_C EQ 'NE' THEN Matrix_Data += (((Data_Segment EQ Value_A) OR (Data_Segment NE Value_B)) AND (Data_Segment NE In_NaN[1]))   
          ENDIF
          IF Operator_A EQ 'LE' THEN BEGIN 
            IF Operator_C EQ 'EQ' THEN Matrix_Data += (((Data_Segment LE Value_A) OR (Data_Segment EQ Value_B)) AND (Data_Segment NE In_NaN[1])) 
            IF Operator_C EQ 'LE' THEN Matrix_Data += (((Data_Segment LE Value_A) OR (Data_Segment LE Value_B)) AND (Data_Segment NE In_NaN[1]))
            IF Operator_C EQ 'LT' THEN Matrix_Data += (((Data_Segment LE Value_A) OR (Data_Segment LT Value_B)) AND (Data_Segment NE In_NaN[1]))
            IF Operator_C EQ 'GE' THEN Matrix_Data += (((Data_Segment LE Value_A) OR (Data_Segment GE Value_B)) AND (Data_Segment NE In_NaN[1]))
            IF Operator_C EQ 'GT' THEN Matrix_Data += (((Data_Segment LE Value_A) OR (Data_Segment GT Value_B)) AND (Data_Segment NE In_NaN[1]))
            IF Operator_C EQ 'NE' THEN Matrix_Data += (((Data_Segment LE Value_A) OR (Data_Segment NE Value_B)) AND (Data_Segment NE In_NaN[1]))   
          ENDIF
          IF Operator_A EQ 'LT' THEN BEGIN 
            IF Operator_C EQ 'EQ' THEN Matrix_Data += (((Data_Segment LT Value_A) OR (Data_Segment EQ Value_B)) AND (Data_Segment NE In_NaN[1])) 
            IF Operator_C EQ 'LE' THEN Matrix_Data += (((Data_Segment LT Value_A) OR (Data_Segment LE Value_B)) AND (Data_Segment NE In_NaN[1]))
            IF Operator_C EQ 'LT' THEN Matrix_Data += (((Data_Segment LT Value_A) OR (Data_Segment LT Value_B)) AND (Data_Segment NE In_NaN[1]))
            IF Operator_C EQ 'GE' THEN Matrix_Data += (((Data_Segment LT Value_A) OR (Data_Segment GE Value_B)) AND (Data_Segment NE In_NaN[1]))
            IF Operator_C EQ 'GT' THEN Matrix_Data += (((Data_Segment LT Value_A) OR (Data_Segment GT Value_B)) AND (Data_Segment NE In_NaN[1]))
            IF Operator_C EQ 'NE' THEN Matrix_Data += (((Data_Segment LT Value_A) OR (Data_Segment NE Value_B)) AND (Data_Segment NE In_NaN[1]))   
          ENDIF
          IF Operator_A EQ 'GE' THEN BEGIN 
            IF Operator_C EQ 'EQ' THEN Matrix_Data += (((Data_Segment GE Value_A) OR (Data_Segment EQ Value_B)) AND (Data_Segment NE In_NaN[1])) 
            IF Operator_C EQ 'LE' THEN Matrix_Data += (((Data_Segment GE Value_A) OR (Data_Segment LE Value_B)) AND (Data_Segment NE In_NaN[1]))
            IF Operator_C EQ 'LT' THEN Matrix_Data += (((Data_Segment GE Value_A) OR (Data_Segment LT Value_B)) AND (Data_Segment NE In_NaN[1]))
            IF Operator_C EQ 'GE' THEN Matrix_Data += (((Data_Segment GE Value_A) OR (Data_Segment GE Value_B)) AND (Data_Segment NE In_NaN[1]))
            IF Operator_C EQ 'GT' THEN Matrix_Data += (((Data_Segment GE Value_A) OR (Data_Segment GT Value_B)) AND (Data_Segment NE In_NaN[1]))
            IF Operator_C EQ 'NE' THEN Matrix_Data += (((Data_Segment GE Value_A) OR (Data_Segment NE Value_B)) AND (Data_Segment NE In_NaN[1]))   
          ENDIF
          IF Operator_A EQ 'GT' THEN BEGIN 
            IF Operator_C EQ 'EQ' THEN Matrix_Data += (((Data_Segment GT Value_A) OR (Data_Segment EQ Value_B)) AND (Data_Segment NE In_NaN[1])) 
            IF Operator_C EQ 'LE' THEN Matrix_Data += (((Data_Segment GT Value_A) OR (Data_Segment LE Value_B)) AND (Data_Segment NE In_NaN[1]))
            IF Operator_C EQ 'LT' THEN Matrix_Data += (((Data_Segment GT Value_A) OR (Data_Segment LT Value_B)) AND (Data_Segment NE In_NaN[1]))
            IF Operator_C EQ 'GE' THEN Matrix_Data += (((Data_Segment GT Value_A) OR (Data_Segment GE Value_B)) AND (Data_Segment NE In_NaN[1]))
            IF Operator_C EQ 'GT' THEN Matrix_Data += (((Data_Segment GT Value_A) OR (Data_Segment GT Value_B)) AND (Data_Segment NE In_NaN[1]))
            IF Operator_C EQ 'NE' THEN Matrix_Data += (((Data_Segment GT Value_A) OR (Data_Segment NE Value_B)) AND (Data_Segment NE In_NaN[1]))   
          ENDIF
          IF Operator_A EQ 'NE' THEN BEGIN 
            IF Operator_C EQ 'EQ' THEN Matrix_Data += (((Data_Segment NE Value_A) OR (Data_Segment EQ Value_B)) AND (Data_Segment NE In_NaN[1])) 
            IF Operator_C EQ 'LE' THEN Matrix_Data += (((Data_Segment NE Value_A) OR (Data_Segment LE Value_B)) AND (Data_Segment NE In_NaN[1]))
            IF Operator_C EQ 'LT' THEN Matrix_Data += (((Data_Segment NE Value_A) OR (Data_Segment LT Value_B)) AND (Data_Segment NE In_NaN[1]))
            IF Operator_C EQ 'GE' THEN Matrix_Data += (((Data_Segment NE Value_A) OR (Data_Segment GE Value_B)) AND (Data_Segment NE In_NaN[1]))
            IF Operator_C EQ 'GT' THEN Matrix_Data += (((Data_Segment NE Value_A) OR (Data_Segment GT Value_B)) AND (Data_Segment NE In_NaN[1]))
            IF Operator_C EQ 'NE' THEN Matrix_Data += (((Data_Segment NE Value_A) OR (Data_Segment NE Value_B)) AND (Data_Segment NE In_NaN[1]))   
          ENDIF
          Matrix_Count += (Data_Segment NE In_NaN[1]) ; Non-no-data values.
          ;--------------
        ENDIF ELSE BEGIN ; No-data is NOT set.
          IF Operator_A EQ 'EQ' THEN BEGIN 
            IF Operator_C EQ 'EQ' THEN Matrix_Data += ((Data_Segment EQ Value_A) OR (Data_Segment EQ Value_B)) 
            IF Operator_C EQ 'LE' THEN Matrix_Data += ((Data_Segment EQ Value_A) OR (Data_Segment LE Value_B))
            IF Operator_C EQ 'LT' THEN Matrix_Data += ((Data_Segment EQ Value_A) OR (Data_Segment LT Value_B))
            IF Operator_C EQ 'GE' THEN Matrix_Data += ((Data_Segment EQ Value_A) OR (Data_Segment GE Value_B))
            IF Operator_C EQ 'GT' THEN Matrix_Data += ((Data_Segment EQ Value_A) OR (Data_Segment GT Value_B))
            IF Operator_C EQ 'NE' THEN Matrix_Data += ((Data_Segment EQ Value_A) OR (Data_Segment NE Value_B))  
          ENDIF
          IF Operator_A EQ 'LE' THEN BEGIN 
            IF Operator_C EQ 'EQ' THEN Matrix_Data += ((Data_Segment LE Value_A) OR (Data_Segment EQ Value_B)) 
            IF Operator_C EQ 'LE' THEN Matrix_Data += ((Data_Segment LE Value_A) OR (Data_Segment LE Value_B))
            IF Operator_C EQ 'LT' THEN Matrix_Data += ((Data_Segment LE Value_A) OR (Data_Segment LT Value_B))
            IF Operator_C EQ 'GE' THEN Matrix_Data += ((Data_Segment LE Value_A) OR (Data_Segment GE Value_B))
            IF Operator_C EQ 'GT' THEN Matrix_Data += ((Data_Segment LE Value_A) OR (Data_Segment GT Value_B))
            IF Operator_C EQ 'NE' THEN Matrix_Data += ((Data_Segment LE Value_A) OR (Data_Segment NE Value_B))   
          ENDIF
          IF Operator_A EQ 'LT' THEN BEGIN 
            IF Operator_C EQ 'EQ' THEN Matrix_Data += ((Data_Segment LT Value_A) OR (Data_Segment EQ Value_B)) 
            IF Operator_C EQ 'LE' THEN Matrix_Data += ((Data_Segment LT Value_A) OR (Data_Segment LE Value_B))
            IF Operator_C EQ 'LT' THEN Matrix_Data += ((Data_Segment LT Value_A) OR (Data_Segment LT Value_B))
            IF Operator_C EQ 'GE' THEN Matrix_Data += ((Data_Segment LT Value_A) OR (Data_Segment GE Value_B))
            IF Operator_C EQ 'GT' THEN Matrix_Data += ((Data_Segment LT Value_A) OR (Data_Segment GT Value_B))
            IF Operator_C EQ 'NE' THEN Matrix_Data += ((Data_Segment LT Value_A) OR (Data_Segment NE Value_B))  
          ENDIF
          IF Operator_A EQ 'GE' THEN BEGIN 
            IF Operator_C EQ 'EQ' THEN Matrix_Data += ((Data_Segment GE Value_A) OR (Data_Segment EQ Value_B))
            IF Operator_C EQ 'LE' THEN Matrix_Data += ((Data_Segment GE Value_A) OR (Data_Segment LE Value_B))
            IF Operator_C EQ 'LT' THEN Matrix_Data += ((Data_Segment GE Value_A) OR (Data_Segment LT Value_B))
            IF Operator_C EQ 'GE' THEN Matrix_Data += ((Data_Segment GE Value_A) OR (Data_Segment GE Value_B))
            IF Operator_C EQ 'GT' THEN Matrix_Data += ((Data_Segment GE Value_A) OR (Data_Segment GT Value_B))
            IF Operator_C EQ 'NE' THEN Matrix_Data += ((Data_Segment GE Value_A) OR (Data_Segment NE Value_B))   
          ENDIF
          IF Operator_A EQ 'GT' THEN BEGIN 
            IF Operator_C EQ 'EQ' THEN Matrix_Data += ((Data_Segment GT Value_A) OR (Data_Segment EQ Value_B)) 
            IF Operator_C EQ 'LE' THEN Matrix_Data += ((Data_Segment GT Value_A) OR (Data_Segment LE Value_B))
            IF Operator_C EQ 'LT' THEN Matrix_Data += ((Data_Segment GT Value_A) OR (Data_Segment LT Value_B))
            IF Operator_C EQ 'GE' THEN Matrix_Data += ((Data_Segment GT Value_A) OR (Data_Segment GE Value_B))
            IF Operator_C EQ 'GT' THEN Matrix_Data += ((Data_Segment GT Value_A) OR (Data_Segment GT Value_B))
            IF Operator_C EQ 'NE' THEN Matrix_Data += ((Data_Segment GT Value_A) OR (Data_Segment NE Value_B))   
          ENDIF
          IF Operator_A EQ 'NE' THEN BEGIN 
            IF Operator_C EQ 'EQ' THEN Matrix_Data += ((Data_Segment NE Value_A) OR (Data_Segment EQ Value_B)) 
            IF Operator_C EQ 'LE' THEN Matrix_Data += ((Data_Segment NE Value_A) OR (Data_Segment LE Value_B))
            IF Operator_C EQ 'LT' THEN Matrix_Data += ((Data_Segment NE Value_A) OR (Data_Segment LT Value_B))
            IF Operator_C EQ 'GE' THEN Matrix_Data += ((Data_Segment NE Value_A) OR (Data_Segment GE Value_B))
            IF Operator_C EQ 'GT' THEN Matrix_Data += ((Data_Segment NE Value_A) OR (Data_Segment GT Value_B))
            IF Operator_C EQ 'NE' THEN Matrix_Data += ((Data_Segment NE Value_A) OR (Data_Segment NE Value_B))   
          ENDIF 
        ENDELSE 
      ENDIF
      ;-----------------------------------------------------------------------------------------
      Minutes = (SYSTIME(1)-FileLoopStart)/60 ; Subtract End-Time from Start-Time.
      PRINT,'  Processing Time: ', STRTRIM(Minutes, 2), ' for file ', STRTRIM(i+1, 2), ' of ', STRTRIM(N_ELEMENTS(In_Files), 2)
    ENDFOR ; FOR i
    ;-------------------------------------------------------------------------------------------  
    ; Map the percentage of:
    IF In_Operation EQ 0 THEN BEGIN
      Matrix_Out = MAKE_ARRAY(Segment_Size, VALUE=255, /FLOAT) ; Create output array.
      Data_Out = ((Matrix_Data / Matrix_Count) * 100.00) ; Calculate percentage.
      Matrix_Out[Land] = Data_Out ; Use land mask to build output.
      ;-------------- ; Datatype conversions:
      IF (Out_DataType EQ 1) THEN Matrix_Out = BYTE(Matrix_Out) ; Convert to Byte.
      IF (Out_DataType EQ 2) THEN Matrix_Out = FIX(Matrix_Out + 0.5) ; Convert to Integer.
      IF (Out_DataType EQ 3) THEN Matrix_Out = LONG(Matrix_Out + 0.5) ; Convert to LONG
      IF (Out_DataType EQ 5) THEN Matrix_Out = DOUBLE(Matrix_Out) ; Convert to DOUBLE
      IF (Out_DataType EQ 12) THEN Matrix_Out = UINT(Matrix_Out + 0.5) ; Convert to unsigned Integer.
    ENDIF
    ;-------------------------------------------------------------------------------------------
    ; Map the count of:
    IF In_Operation EQ 1 THEN BEGIN
      Matrix_Out = MAKE_ARRAY(Segment_Size, VALUE=255, /FLOAT) ; Create output array.
      Matrix_Out[Land] = Matrix_Data ; Use land mask to build output.
      ;-------------- ; Datatype conversions:
      IF (Out_DataType EQ 1) THEN Matrix_Out = BYTE(Matrix_Out) ; Convert to Byte.
      IF (Out_DataType EQ 2) THEN Matrix_Out = FIX(Matrix_Out + 0.5) ; Convert to Integer.
      IF (Out_DataType EQ 3) THEN Matrix_Out = LONG(Matrix_Out + 0.5) ; Convert to LONG
      IF (Out_DataType EQ 5) THEN Matrix_Out = DOUBLE(Matrix_Out) ; Convert to DOUBLE
      IF (Out_DataType EQ 12) THEN Matrix_Out = UINT(Matrix_Out + 0.5) ; Convert to unsigned Integer.
    ENDIF
    ;-------------------------------------------------------------------------------------------
    ; Map by frequency:
    IF In_Operation EQ 2 THEN BEGIN
      Matrix_Out = MAKE_ARRAY(Segment_Size, VALUE=255, /FLOAT) ; Create output array.
      Data_Out = ((Matrix_Data / Matrix_Count) * 100.00) ; Calculate percentage.
      ;-------------- ; Get the percentage of frequency:
      IF Frequency_A EQ 'EQ' THEN Data_Out = (Data_Out EQ Frequency_Value)
      IF Frequency_A EQ 'LE' THEN Data_Out = (Data_Out LE Frequency_Value)
      IF Frequency_A EQ 'LT' THEN Data_Out = (Data_Out LT Frequency_Value)
      IF Frequency_A EQ 'GE' THEN Data_Out = (Data_Out GE Frequency_Value)
      IF Frequency_A EQ 'GT' THEN Data_Out = (Data_Out GT Frequency_Value)
      IF Frequency_A EQ 'NE' THEN Data_Out = (Data_Out NE Frequency_Value)
      Matrix_Out[Land] = Data_Out ; Use land mask to build output.
      ;-------------- ; Datatype conversions:
      IF (Out_DataType EQ 1) THEN Matrix_Out = BYTE(Matrix_Out) ; Convert to Byte.
      IF (Out_DataType EQ 2) THEN Matrix_Out = FIX(Matrix_Out + 0.5) ; Convert to Integer.
      IF (Out_DataType EQ 3) THEN Matrix_Out = LONG(Matrix_Out + 0.5) ; Convert to LONG
      IF (Out_DataType EQ 5) THEN Matrix_Out = DOUBLE(Matrix_Out) ; Convert to DOUBLE
      IF (Out_DataType EQ 12) THEN Matrix_Out = UINT(Matrix_Out + 0.5) ; Convert to unsigned Integer.
    ENDIF
    ;-------------------------------------------------------------------------------------------
    ; Write output:
    IF s EQ 0 THEN BEGIN
      OPENW, Unit_Out, Out_File, /GET_LUN ; Create the output file.
      FREE_LUN, Unit_Out ; Close the output file.
    ENDIF
    OPENU, Unit_Out, Out_File, /APPEND, /GET_LUN
    WRITEU, Unit_Out, Matrix_Out 
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