; ##############################################################################################
; NAME: Calculate_MMS.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: NWC Groundwater Dependent Ecosystems Atlas.
; DATE: 10/03/2011
; DLM: 14/05/2011
;
; DESCRIPTION:  This program calculates mean seasonal (monthly) landscape storage (MMS).
; 
;               Storage is calculated as:
;               
;               (1) Storage(n) = Storage(n-1) - CMRSET + (Ratio*P)
;               
;               Where,
;               
;               (2) Ratio = CMRSET/P
;               
;               The values of (2) CMRSET and (2) P (SILO rainfall) are the long term mean over
;               the available period.
;               
;               The values of (1) CMRSET and (1) P (SILO rainfall) are mean monthly sums. Wherein, 
;               for a time series of 2001 to 2010, there would be 12 mean monthly CMRSET and 12 mean 
;               monthly P inputs, with each input representing a single month averaged over the 
;               entire period. That is to say, each of the 12 CMRSET inputs would represent the long
;               term mean CMRSET mm/month for the respective calendar month.
;
; INPUT:        Four or more single band date-sets; long term mean CMRSET and P; mean monthly CMRSET
;               and P.
;
; OUTPUT:       One single band flat binary raster per monthly input; mean seasonal storage.
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


PRO Calculate_MMS
  ;---------------------------------------------------------------------------------------------
  StartTime = SYSTIME(1) ; Get the current system time.
  PRINT,''
  PRINT,'Begin Processing: Calculate_MMS'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
  ; Input/Output:
  ;---------------------------------------------------------------------------------------------
  Prefix = 'MOD09Q1.MOD09A1.CMRSET.' ; Set a string prefix for the output file names.
  ;--------------------------------------------------------------------------------------------- 
  In_Mask = '\\File-wron\Working\work\NWC_Groundwater_Dependent_Ecosystems\Data\Raster\SILO\MODIS.Land.Mask.aust.005.250m.img'
  Mask = READ_BINARY(In_Mask, DATA_TYPE=1)
  ;---------------------------------------------------------------------------------------------  
  ; Select the input data:
  Path='\\Powerapp5-wron\scratch\war409\gamma\'
  Filter=['*.tif','*.img','*.flt','*.bin']
  In_CMRSET = DIALOG_PICKFILE(PATH=Path, TITLE='Select The Input Data: monthly CMRSET ET', FILTER=Filter, /MUST_EXIST, /MULTIPLE_FILES)
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
  In_P = DIALOG_PICKFILE(PATH=Path, TITLE='Select The Input Data: monthly SILO Rainfall', FILTER=Filter, /MUST_EXIST, /MULTIPLE_FILES)
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
  ;---------------------------------------------------------------------------------------------
  ; Select the input data:
  Path='\\Powerapp5-wron\scratch\war409\gamma\'
  Filter=['*.tif','*.img','*.flt','*.bin']
  In_mCMRSET = DIALOG_PICKFILE(PATH=Path, TITLE='Select The Input Data: long term mean CMRSET ET', FILTER=Filter, /MUST_EXIST)
  IF In_mCMRSET[0] EQ '' THEN RETURN ; Error check.
  ;-------------- ; Remove the file path from the input file names:
  fname_Start = STRPOS(In_mCMRSET, '\', /REVERSE_SEARCH)+1 ; Get the position of the first file name character (after the file path).
  fname_Length = (STRLEN(In_mCMRSET)-fname_Start)-4 ; Get the length of each path-less file name.
  FNS_mCMRSET = MAKE_ARRAY(N_ELEMENTS(In_mCMRSET), /STRING) ; Create an array to store the input file names.
  FOR a=0, N_ELEMENTS(In_mCMRSET)-1 DO BEGIN ; Fill the file name array:
    FNS_mCMRSET[a] += STRMID(In_mCMRSET[a], fname_Start[a], fname_Length[a]) ; Get the a-the file name (trim away the file path).
  ENDFOR
  ;---------------------------------------------------------------------------------------------
  ; Select the input data:
  Path='\\Powerapp5-wron\scratch\war409\gamma\'
  Filter=['*.tif','*.img','*.flt','*.bin']
  In_mP = DIALOG_PICKFILE(PATH=Path, TITLE='Select The Input Data: long term mean SILO Rainfall', FILTER=Filter, /MUST_EXIST)
  IF In_mP[0] EQ '' THEN RETURN ; Error check.
  ;-------------- ; Remove the file path from the input file names:
  fname_Start = STRPOS(In_mP, '\', /REVERSE_SEARCH)+1 ; Get the position of the first file name character (after the file path).
  fname_Length = (STRLEN(In_mP)-fname_Start)-4 ; Get the length of each path-less file name.
  FNS_mP = MAKE_ARRAY(N_ELEMENTS(In_mP), /STRING) ; Create an array to store the input file names.
  FOR a=0, N_ELEMENTS(In_mP_P)-1 DO BEGIN ; Fill the file name array:
    FNS_mP[a] += STRMID(In_mP[a], fname_Start[a], fname_Length[a]) ; Get the a-the file name (trim away the file path).
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
    File_Out = Out_Directory + Prefix + Date_String + '.MSS' + '.img' ; Set the output file name
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
      Matrix_mCMRSET = MAKE_ARRAY(Segment_Size, /FLOAT) ; Create an array to hold grid data segment.
      Matrix_mP = MAKE_ARRAY(Segment_Size, /FLOAT) ; Create an array to hold grid data segment.
      ;-------------------------------------------------------------------------------------------
      ; Get Data and Calculate:
      ;-------------------------------------------------------------------------------------------
      Data_CMRSET = READ_BINARY(CMRSET_In, DATA_TYPE=In_DataType) ; Read data.
      Matrix_CMRSET[*] = Data_CMRSET(Segment_Start:Segment_End) * 0.1 ; Get data slice (segment).
      Data_P = READ_BINARY(P_In, DATA_TYPE=In_DataType) ; Read data.
      Matrix_P[*] = Data_P(Segment_Start:Segment_End) * 0.1 ; Get data slice (segment).
      ;-------------- ; Get long term means:
      Data_mCMRSET = READ_BINARY(In_mCMRSET, DATA_TYPE=In_DataType) ; Read data.
      Matrix_mCMRSET[*] = Data_mCMRSET(Segment_Start:Segment_End) * 0.1 ; Get data slice (segment).
      Data_mP = READ_BINARY(In_mP, DATA_TYPE=In_DataType) ; Read data.
      Matrix_mP[*] = Data_mP(Segment_Start:Segment_End) * 0.1 ; Get data slice (segment).
      ;-------------- ; Set mask:
      Land = WHERE(Mask(Segment_Start:Segment_End) EQ 1, Count_Land)
      ;-------------- ; Set StorageZero:
      IF i EQ 0 THEN BEGIN
        StorageZero = MAKE_ARRAY(Segment_Size, VALUE=0.00, /FLOAT)
      ENDIF ELSE BEGIN
        IF s EQ 0 THEN StorageZero = StorageZero_0
        IF s EQ 1 THEN StorageZero = StorageZero_1
        IF s EQ 2 THEN StorageZero = StorageZero_2
        IF s EQ 3 THEN StorageZero = StorageZero_3
        IF s EQ 4 THEN StorageZero = StorageZero_4
        IF s EQ 5 THEN StorageZero = StorageZero_5
        IF s EQ 6 THEN StorageZero = StorageZero_6
        IF s EQ 7 THEN StorageZero = StorageZero_7
        IF s EQ 8 THEN StorageZero = StorageZero_8
        IF s EQ 9 THEN StorageZero = StorageZero_9
      ENDELSE
      ;-------------- ; Calculate Storage:
      Ratio = Matrix_mCMRSET[Land] / Matrix_mP[Land] 
      Storage = StorageZero[Land] - Matrix_CMRSET[Land] + (Ratio*Matrix_P[Land])
      ;-------------- ; Use land mask to build output:
      Storage_Out = MAKE_ARRAY(Segment_Size, VALUE=-999, /FLOAT)
      Storage_Out[Land] = Storage
      ;-------------- ; Update StorageZero:
      IF s EQ 0 THEN StorageZero_0 = Storage_Out
      IF s EQ 1 THEN StorageZero_1 = Storage_Out
      IF s EQ 2 THEN StorageZero_2 = Storage_Out
      IF s EQ 3 THEN StorageZero_3 = Storage_Out
      IF s EQ 4 THEN StorageZero_4 = Storage_Out
      IF s EQ 5 THEN StorageZero_5 = Storage_Out
      IF s EQ 6 THEN StorageZero_6 = Storage_Out
      IF s EQ 7 THEN StorageZero_7 = Storage_Out
      IF s EQ 8 THEN StorageZero_8 = Storage_Out
      IF s EQ 9 THEN StorageZero_9 = Storage_Out
      ;-------------- ; Write data to file:
      IF (Out_DataType EQ 1) THEN Storage_Out = BYTE(Storage_Out) ; Convert to Byte.
      IF (Out_DataType EQ 2) THEN Storage_Out = FIX(Storage_Out + 0.5) ; Convert to Integer.
      IF (Out_DataType EQ 3) THEN Storage_Out = LONG(Storage_Out + 0.5) ; Convert to LONG
      IF (Out_DataType EQ 5) THEN Storage_Out = DOUBLE(Storage_Out) ; Convert to DOUBLE
      IF (Out_DataType EQ 12) THEN Storage_Out = UINT(Storage_Out + 0.5) ; Convert to unsigned Integer.
      OPENU, UNIT_Out, File_Out, /APPEND, /GET_LUN
      WRITEU, UNIT_Out, Storage_Out 
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

