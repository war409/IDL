; ##############################################################################################
; NAME: Calculate_IDE.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: NWC Groundwater Dependent Ecosystems Atlas.
; DATE: 10/03/2011
; DLM: 14/05/2011
;
; DESCRIPTION:  This program calculates the probability of being an Inflow Dependent Ecosystem 
;               (pIDE).
;               
;               IDE is calculated as: 
;               
;               pIDE = 1 - (0.5 * ERFC((ALOG10(Ratio) / 0.0886) / 2^0.5))
;
;               Where, Ratio = CMRSET/P
;               
;               The values of CMRSET and P (SILO rainfall) are recommended to be the long term mean 
;               over the maximum period available.
;
; INPUT:        Two or more single band date-sets; CMRSET and P (SILO rainfall). Multiple CMRSET and
;               P may be selected if the user wants to test IDE at different length periods.
;
; OUTPUT:       One single band flat binary raster per input; containing pIDE. 
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


PRO Calculate_IDE
  ;---------------------------------------------------------------------------------------------
  StartTime = SYSTIME(1) ; Get the current system time.
  PRINT,''
  PRINT,'Begin Processing: Calculate_IDE'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
  ; Input/Output:
  ;---------------------------------------------------------------------------------------------
  Prefix = 'MOD09Q1.MOD09A1.CMRSET.20010101.20101231.pIDE' ; Set a string prefix for the output file names.
  ;--------------------------------------------------------------------------------------------- 
  In_Mask = '\\File-wron\Working\work\NWC_Groundwater_Dependent_Ecosystems\Data\Raster\SILO\MODIS.Land.Mask.aust.005.250m.img'
  Mask = READ_BINARY(In_Mask, DATA_TYPE=1)
  ;---------------------------------------------------------------------------------------------
  ; Select the input data:
  Path='\\Powerapp5-wron\scratch\war409\gamma\'
  Filter=['*.tif','*.img','*.flt','*.bin']
  In_CMRSET = DIALOG_PICKFILE(PATH=Path, TITLE='Select The Input Data: CMRSET', FILTER=Filter, /MUST_EXIST, /MULTIPLE_FILES)
  IF In_CMRSET[0] EQ '' THEN RETURN ; Error check.
  In_CMRSET = In_CMRSET[SORT(In_CMRSET)] ; Sort the input file list.
  ;-------------- ; Remove the file path from the input file names:
  fname_Start = STRPOS(In_CMRSET, '\', /REVERSE_SEARCH)+1 ; Get the position of the first file name character (after the file path).
  fname_Length = (STRLEN(In_CMRSET)-fname_Start)-4 ; Get the length of each path-less file name.
  FNS_CMRSET = MAKE_ARRAY(N_ELEMENTS(In_CMRSET), /STRING) ; Create an array to store the input file names.
  FOR a=0, N_ELEMENTS(In_CMRSET)-1 DO BEGIN ; Fill the file name array:
    FNS_CMRSET[a] += STRMID(In_CMRSET[a], fname_Start[a], fname_Length[a]) ; Get the a-the file name (trim away the file path).
  ENDFOR
  ;-------------- ; Get the input dates:
  CMRSET_Dates = FUNCTION_WIDGET_Date(In_Files=FNS_CMRSET, /JULIAN) ; Get the input file name dates.
  IF CMRSET_Dates[0] NE -1 THEN BEGIN ; Check for valid dates.
    In_CMRSET = In_CMRSET[SORT(CMRSET_Dates)] ; Sort file name by date.
    FNS_CMRSET = FNS_CMRSET[SORT(CMRSET_Dates)] ; Sort file name by date.
    CMRSET_Unique = CMRSET_Dates[UNIQ(CMRSET_Dates)] ; Get unique input dates.
    CMRSET_Unique = CMRSET_Unique[SORT(CMRSET_Unique)] ; Sort the unique dates.   
    CMRSET_Unique = CMRSET_Unique[UNIQ(CMRSET_Unique)] ; Get unique input dates.
  ENDIF ELSE BEGIN
    PRINT,'** Invalid Date Selection **'
    RETURN ; Quit program
  ENDELSE
  ;---------------------------------------------------------------------------------------------
  ; Select the input data:
  Path='\\Powerapp5-wron\scratch\war409\gamma\'
  Filter=['*.tif','*.img','*.flt','*.bin']
  In_P = DIALOG_PICKFILE(PATH=Path, TITLE='Select The Input Data: SILO Rainfall', FILTER=Filter, /MUST_EXIST, /MULTIPLE_FILES)
  IF In_P[0] EQ '' THEN RETURN ; Error check.
  In_P = In_P[SORT(In_P)] ; Sort the input file list.
  ;-------------- ; Remove the file path from the input file names:
  fname_Start = STRPOS(In_P, '\', /REVERSE_SEARCH)+1 ; Get the position of the first file name character (after the file path).
  fname_Length = (STRLEN(In_P)-fname_Start)-4 ; Get the length of each path-less file name.
  FNS_P = MAKE_ARRAY(N_ELEMENTS(In_P), /STRING) ; Create an array to store the input file names.
  FOR a=0, N_ELEMENTS(In_P)-1 DO BEGIN ; Fill the file name array:
    FNS_P[a] += STRMID(In_P[a], fname_Start[a], fname_Length[a]) ; Get the a-the file name (trim away the file path).
  ENDFOR
  ;-------------- ; Get the input dates:
  P_Dates = FUNCTION_WIDGET_Date(In_Files=FNS_P, /JULIAN) ; Get the input file name dates.
  IF P_Dates[0] NE -1 THEN BEGIN ; Check for valid dates.
    In_P = In_P[SORT(P_Dates)] ; Sort file name by date.
    FNS_P = FNS_P[SORT(P_Dates)] ; Sort file name by date.
    P_Unique = P_Dates[UNIQ(P_Dates)] ; Get unique input dates.
    P_Unique = P_Unique[SORT(P_Unique)] ; Sort the unique dates.   
    P_Unique = P_Unique[UNIQ(P_Unique)] ; Get unique input dates.
  ENDIF ELSE BEGIN
    PRINT,'** Invalid Date Selection **'
    RETURN ; Quit program
  ENDELSE
  ;-------------- ; Error check:
  IF P_Unique NE CMRSET_Unique THEN BEGIN
    PRINT,'** Invalid Date Selection **'
    PRINT, 'The selected SILO rainfall dates must match the selected CMRSET ET dates'
    RETURN ; Quit program
  ENDIF
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
  ; Date Loop:
  ;---------------------------------------------------------------------------------------------
  FOR i=0, N_ELEMENTS(CMRSET_Unique)-1 DO BEGIN
    LoopStart = SYSTIME(1) ;  Get loop start time.
    IF CMRSET_Unique[i] NE P_Unique[i] THEN RETURN ; Error check.
    CALDAT, CMRSET_Unique[i], iM, iD, iY ; Convert the i-th julday to calday.
    IF (iM LE 9) THEN M_String = '0' + STRING(STRTRIM(iM,2)) ELSE M_String = STRING(STRTRIM(iM,2))  ; Add leading zero.
    IF (iD LE 9) THEN D_String = '0' + STRING(STRTRIM(iD,2)) ELSE D_String = STRING(STRTRIM(iD,2))  ; Add leading zero.
    Date_String = STRING(STRTRIM(iY,2)) + M_String + D_String
    CMRSET_Index = WHERE(CMRSET_Dates EQ CMRSET_Unique[i], Count) ; Get CMRSET file index.
    IF Count GT 1 THEN RETURN ; Error check.
    CMRSET_In = In_CMRSET[CMRSET_Index] ; Get CMRSET file.
    CMRSET_FNS = FNS_CMRSET[CMRSET_Index] ; Get CMRSET file short.
    P_Index = WHERE(P_Dates EQ P_Unique[i], Count) ; Get P file index.
    IF Count GT 1 THEN RETURN ; Error check.
    P_In = In_P[P_Index] ; Get P file.
    P_FNS = FNS_P[P_Index] ; Get P file short.
    ;-------------- ; Create output file:
    ; File_Out = Out_Directory + Prefix + Date_String + '.img' ; Set the output file name
    File_Out = Out_Directory + Prefix + '.img'
    OPENW, UNIT_Out, File_Out, /GET_LUN ; Create the output file.
    FREE_LUN, UNIT_Out ; Close the output file.  
    ;-------------------------------------------------------------------------------------------
    ; Segment loop:
    ;-------------------------------------------------------------------------------------------    
    In_First = READ_BINARY(In_CMRSET[0], DATA_TYPE=In_DataType) ; Open the first input file.
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
      LoopStartSegment = SYSTIME(1) ;  Get loop start time.
      ;-----------------------------------------------------------------------------------------
      ; Update segment loop parameters and build arrays:
      ;-----------------------------------------------------------------------------------------
      IF s GE 1 THEN BEGIN ; Update the segment parameters:
        Segment_Start = LONG(Segment_Start + Segment_Size) ; Update segment start position.
        Segment_End = LONG((s+1)*Segment_Size) ; Update segment end position.
      ENDIF
      ;-------------- ; In the final loop fix the end position if segment length is not a round integer.
      IF s EQ Count_S-1 THEN Segment_End = LONG(Elements) ; Update end position.
      ;-------------- ; Get the current segment size:
      Segment_Size = LONG(Segment_End - Segment_Start)+1 ; Get the current segment size.
      ;-------------- ; Create empty arrays to hold analysis data:
      Matrix_CMRSET = MAKE_ARRAY(Segment_Size, /FLOAT) ; Create an array to hold grid data segment.
      Matrix_P = MAKE_ARRAY(Segment_Size, /FLOAT) ; Create an array to hold grid data segment.
      ;-------------------------------------------------------------------------------------------
      ; Get Data:
      ;-------------------------------------------------------------------------------------------
      Data_CMRSET = READ_BINARY(CMRSET_In, DATA_TYPE=In_DataType) ; Read data.
      Data_CMRSET_tmp = Data_CMRSET(Segment_Start:Segment_End)
      Matrix_CMRSET[*] = Data_CMRSET_tmp * 0.1 ; Get data slice (segment).
      Data_P = READ_BINARY(P_In, DATA_TYPE=In_DataType) ; Read data. Mulitply input by scale factor.
      Data_P_tmp = Data_P(Segment_Start:Segment_End)
      Matrix_P[*] = Data_P_tmp * 0.1 ; Get data slice (segment). Mulitply input by scale factor.
      ;-------------- ; Set mask:
      Land = WHERE(Mask(Segment_Start:Segment_End) EQ 1, Count_Land)
      ;-------------- ; Calculate IDE:
      Ratio = Matrix_CMRSET[Land] / Matrix_P[Land]
      pIDE = 1 - (0.5 * ERFC((ALOG10(Ratio) / 0.092278) / 2^0.5))
      ;-------------- ; Use land mask to build output:
      pIDE_Out = MAKE_ARRAY(Segment_Size, VALUE=-999, /FLOAT)
      pIDE_Out[Land] = pIDE
      ;-------------- ; Write data to file:
      IF (Out_DataType EQ 1) THEN pIDE_Out = BYTE(pIDE_Out) ; Convert to Byte.
      IF (Out_DataType EQ 2) THEN pIDE_Out = FIX(pIDE_Out + 0.5) ; Convert to Integer.
      IF (Out_DataType EQ 3) THEN pIDE_Out = LONG(pIDE_Out + 0.5) ; Convert to LONG
      IF (Out_DataType EQ 5) THEN pIDE_Out = DOUBLE(pIDE_Out) ; Convert to DOUBLE
      IF (Out_DataType EQ 12) THEN pIDE_Out = UINT(pIDE_Out + 0.5) ; Convert to unsigned Integer.
      OPENU, UNIT_Out, File_Out, /APPEND, /GET_LUN
      WRITEU, UNIT_Out, pIDE_Out
      FREE_LUN, UNIT_Out
      ;-------------------------------------------------------------------------------------- 
      Minutes = (SYSTIME(1)-LoopStartSegment)/60 ; Get the file loop end time
      PRINT, '  Processing Time: ', STRTRIM(Minutes, 2), ' minutes, for segment ', STRTRIM(s+1, 2), $
        ' of ', STRTRIM(Count_S, 2)
      ;--------------------------------------------------------------------------------------
    ENDFOR
    ;-------------------------------------------------------------------------------------------
    Minutes = (SYSTIME(1)-LoopStart)/60 ; Get the file loop end time
    PRINT, 'Processing Time: ', STRTRIM(Minutes, 2), ' minutes, for date ', STRTRIM(i+1, 2), $
      ' of ', STRTRIM(N_ELEMENTS(CMRSET_Unique), 2)
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

