; ##############################################################################################
; NAME: Time_Series_Raster_Arithmetic.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: NWC Groundwater Dependent Ecosystems Atlas.
; DATE: 18/03/2011
; DLM: 18/03/2011
;
; DESCRIPTION:  This tool performs simple arithmetic on the input data. The user may select whether 
;               to add the values of the two input data; subtract Y from X, or X from Y; multiply 
;               the input data; or divide the values of X by Y, or Y by X.
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


PRO Time_Series_Raster_Arithmetic
  ;---------------------------------------------------------------------------------------------
  StartTime = SYSTIME(1) ; Get the current system time.
  PRINT,''
  PRINT,'Begin Processing: Time_Series_Raster_Arithmetic'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
  ; Input/Output:
  ;---------------------------------------------------------------------------------------------
  Prefix = 'MOD09Q1_MOD09A1.MCD43A4.CMRSET'
  ;---------------------------------------------------------------------------------------------
  In_Mask = '\\File-wron\Working\work\NWC_Groundwater_Dependent_Ecosystems\Data\Raster\SILO\MODIS.Land.Mask.aust.005.500m.img'
  Mask = READ_BINARY(In_Mask, DATA_TYPE=1)
  ;---------------------------------------------------------------------------------------------
  ; Select the input data:
  Path='\\File-wron\Working\work\NWC_Groundwater_Dependent_Ecosystems\Data\Raster\SILO\AET.8Day.500m\'
  Filter=['*.tif','*.img','*.flt','*.bin']
  In_FilesX = DIALOG_PICKFILE(PATH=Path, TITLE='Select The Input Data', FILTER=Filter, /MUST_EXIST, /MULTIPLE_Files)
  IF In_FilesX[0] EQ '' THEN RETURN ; Error check.
  In_FilesX = In_FilesX[SORT(In_FilesX)] ; Sort the input file list.
  ;-------------- ; Remove the file path from the input file names:
  fname_Start = STRPOS(In_FilesX, '\', /REVERSE_SEARCH)+1 ; Get the position of the first file name character (after the file path).
  fname_Length = (STRLEN(In_FilesX)-fname_Start)-4 ; Get the length of each path-less file name.
  FNSX = MAKE_ARRAY(N_ELEMENTS(In_FilesX), /STRING) ; Create an array to store the input file names.
  FOR a=0, N_ELEMENTS(In_FilesX)-1 DO BEGIN ; Fill the file name array:
    FNSX[a] += STRMID(In_FilesX[a], fname_Start[a], fname_Length[a]) ; Get the a-the file name (trim away the file path).
  ENDFOR
  ;-------------- ; Get the input dates:
  In_DatesX = FUNCTION_WIDGET_Date(IN_Files=FNSX, /JULIAN) ; Get the input file name dates.
  IF In_DatesX[0] NE -1 THEN BEGIN ; Check for valid dates.
    In_FilesX = In_FilesX[SORT(In_DatesX)] ; Sort file name by date.
    FNSX = FNSX[SORT(In_DatesX)] ; Sort file name by date.
    DatesX_Unique = In_DatesX[UNIQ(In_DatesX)] ; Get unique input dates.
    DatesX_Unique = DatesX_Unique[SORT(DatesX_Unique)] ; Sort the unique dates.   
    DatesX_Unique = DatesX_Unique[UNIQ(DatesX_Unique)] ; Get unique input dates.
  ENDIF ELSE BEGIN
    PRINT,'** Invalid Date Selection **'
    RETURN ; Quit program
  ENDELSE
  ;---------------------------------------------------------------------------------------------
  ; Select the input data:
  Path='\\File-wron\Working\work\NWC_Groundwater_Dependent_Ecosystems\Data\Raster\SILO\AET.Monthly.500m\'
  Filter=['*.tif','*.img','*.flt','*.bin']
  In_FilesY = DIALOG_PICKFILE(PATH=Path, TITLE='Select The Input Data', FILTER=Filter, /MUST_EXIST, /MULTIPLE_Files)
  IF In_FilesY[0] EQ '' THEN RETURN ; Error check.
  In_FilesY = In_FilesY[SORT(In_FilesY)] ; Sort the input file list.
  ;-------------- ; Remove the file path from the input file names:
  fname_Start = STRPOS(In_FilesY, '\', /REVERSE_SEARCH)+1 ; Get the position of the first file name character (after the file path).
  fname_Length = (STRLEN(In_FilesY)-fname_Start)-4 ; Get the length of each path-less file name.
  FNSY = MAKE_ARRAY(N_ELEMENTS(In_FilesY), /STRING) ; Create an array to store the input file names.
  FOR a=0, N_ELEMENTS(In_FilesY)-1 DO BEGIN ; Fill the file name array:
    FNSY[a] += STRMID(In_FilesY[a], fname_Start[a], fname_Length[a]) ; Get the a-the file name (trim away the file path).
  ENDFOR
  ;-------------- ; Get the input dates:
  In_DatesY = FUNCTION_WIDGET_Date(IN_Files=FNSY, /JULIAN) ; Get the input file name dates.
  IF In_DatesY[0] NE -1 THEN BEGIN ; Check for valid dates.
    In_FilesY = In_FilesY[SORT(In_DatesY)] ; Sort file name by date.
    FNSY = FNSY[SORT(In_DatesY)] ; Sort file name by date.
    DatesY_Unique = In_DatesY[UNIQ(In_DatesY)] ; Get unique input dates.
    DatesY_Unique = DatesY_Unique[SORT(DatesY_Unique)] ; Sort the unique dates.   
    DatesY_Unique = DatesY_Unique[UNIQ(DatesY_Unique)] ; Get unique input dates.
  ENDIF ELSE BEGIN
    PRINT,'** Invalid Date Selection **'
    RETURN ; Quit program
  ENDELSE
  ;---------------------------------------------------------------------------------------------  
  ; Select the input data type:
  In_DataTypeX = FUNCTION_WIDGET_Droplist(TITLE='Select Input Datatype X:', VALUE=['0 : UNDEFINED : Undefined', '1 : BYTE : Byte', $
    '2 : INT : Integer', '3 : LONG : Longword integer', '4 : FLOAT : Floating point', $
    '5 : DOUBLE : Double-precision floating', '6 : COMPLEX : Complex floating', $
    '7 : STRING : String', '8 : STRUCT : Structure', '9 : DCOMPLEX : Double-precision complex', $
    '10 : POINTER : Pointer', '11 : OBJREF : Object reference', '12 : UINT : Unsigned Integer', $
    '13 : ULONG : Unsigned Longword Integer', '14 : LONG64 : 64-bit Integer', $
    '15 : ULONG64 : Unsigned 64-bit Integer'])
  IF (In_DataTypeX EQ 7) OR (In_DataTypeX EQ 8) OR (In_DataTypeX EQ 9) OR (In_DataTypeX EQ 10) OR (In_DataTypeX EQ 11) THEN BEGIN
    PRINT,'** Invalid Data Type **'
    RETURN ; Quit program.
  ENDIF
  ;---------------------------------------------------------------------------------------------  
  ; Select the input data type:
  In_DataTypeY = FUNCTION_WIDGET_Droplist(TITLE='Select Input Datatype Y:', VALUE=['0 : UNDEFINED : Undefined', '1 : BYTE : Byte', $
    '2 : INT : Integer', '3 : LONG : Longword integer', '4 : FLOAT : Floating point', $
    '5 : DOUBLE : Double-precision floating', '6 : COMPLEX : Complex floating', $
    '7 : STRING : String', '8 : STRUCT : Structure', '9 : DCOMPLEX : Double-precision complex', $
    '10 : POINTER : Pointer', '11 : OBJREF : Object reference', '12 : UINT : Unsigned Integer', $
    '13 : ULONG : Unsigned Longword Integer', '14 : LONG64 : 64-bit Integer', $
    '15 : ULONG64 : Unsigned 64-bit Integer'])
  IF (In_DataTypeY EQ 7) OR (In_DataTypeY EQ 8) OR (In_DataTypeY EQ 9) OR (In_DataTypeY EQ 10) OR (In_DataTypeY EQ 11) THEN BEGIN
    PRINT,'** Invalid Data Type **'
    RETURN ; Quit program.
  ENDIF
  ;---------------------------------------------------------------------------------------------
  ; Set the operation:
  In_Operation = FUNCTION_WIDGET_Checklist(TITLE='Provide Input', VALUE=['X + Y','X - Y','Y - X', $
    'X * Y','X / Y','Y / X'], LABEL='Select one or more operations:')
  ;---------------------------------------------------------------------------------------------
  ; Set the output folder:
  Path='\\File-wron\Working\work\NWC_Groundwater_Dependent_Ecosystems\Data\Raster\SILO\MOD09Q1_MOD09A1.MCD43A4.CMRSET\'
  Out_Directory = DIALOG_PICKFILE(PATH=Path, TITLE='Select The Output Folder', /DIRECTORY, /OVERWRITE_PROMPT)
  IF Out_Directory EQ '' THEN RETURN ; Error check.
  ;---------------------------------------------------------------------------------------------
  ; Date Loop:
  ;---------------------------------------------------------------------------------------------
  FOR i=0, N_ELEMENTS(DatesX_Unique)-1 DO BEGIN
    LoopStart = SYSTIME(1) ;  Get loop start time.
    IF DatesX_Unique[i] NE DatesY_Unique[i] THEN RETURN ; Error check.
    CALDAT, DatesX_Unique[i], iM, iD, iY ; Convert the i-th julday to calday.
    IF (iM LE 9) THEN M_String = '0' + STRING(STRTRIM(iM,2)) ELSE M_String = STRING(STRTRIM(iM,2))  ; Add leading zero.
    IF (iD LE 9) THEN D_String = '0' + STRING(STRTRIM(iD,2)) ELSE D_String = STRING(STRTRIM(iD,2))  ; Add leading zero.
    Date_String = STRING(STRTRIM(iY,2)) + M_String + D_String
    X_Index = WHERE(In_DatesX EQ DatesX_Unique[i], Count) ; Get file index.
    IF Count GT 1 THEN RETURN ; Error check.
    FileX_In = In_FilesX[X_Index] ; Get file.
    FNSX_In = FNSX[X_Index] ; Get file short.
    Y_Index = WHERE(In_DatesY EQ DatesY_Unique[i], Count) ; Get file index.
    IF Count GT 1 THEN RETURN ; Error check.
    FileY_In = In_FilesY[Y_Index] ; Get file.
    FNSY_In = FNSY[Y_Index] ; Get file short.
    ;-------------- ; Create output files:
    IF In_Operation[0] EQ 1 THEN BEGIN ; X + Y: 
      File_XplusY = Out_Directory + Prefix + '.XplusY.' + Date_String + '.img' ; Set the output file name
      OPENW, UNIT_XplusY, File_XplusY, /GET_LUN ; Create the output file.
      FREE_LUN, UNIT_XplusY ; Close the output file.
    ENDIF
    IF In_Operation[1] EQ 1 THEN BEGIN ; X - Y: 
      File_XminusY = Out_Directory + Prefix + '.XminusY.' + Date_String + '.img' ; Set the output file name
      OPENW, UNIT_XminusY, File_XminusY, /GET_LUN ; Create the output file.
      FREE_LUN, UNIT_XminusY ; Close the output file.
    ENDIF
    IF In_Operation[2] EQ 1 THEN BEGIN ; Y - X: 
      File_YminusX = Out_Directory + Prefix + '.YminusX.' + Date_String + '.img' ; Set the output file name
      OPENW, UNIT_YminusX, File_YminusX, /GET_LUN ; Create the output file.
      FREE_LUN, UNIT_YminusX ; Close the output file.
    ENDIF 
    IF In_Operation[3] EQ 1 THEN BEGIN ; X * Y: 
      File_XtimesY = Out_Directory + Prefix + '.XtimesY.' + Date_String + '.img' ; Set the output file name
      OPENW, UNIT_XtimesY, File_XtimesY, /GET_LUN ; Create the output file.
      FREE_LUN, UNIT_XtimesY ; Close the output file.
    ENDIF
    IF In_Operation[4] EQ 1 THEN BEGIN ; X / Y: 
      File_XdivY = Out_Directory + Prefix + '.XdivY.' + Date_String + '.img' ; Set the output file name
      OPENW, UNIT_XdivY, File_XdivY, /GET_LUN ; Create the output file.
      FREE_LUN, UNIT_XdivY ; Close the output file.
    ENDIF
    IF In_Operation[5] EQ 1 THEN BEGIN ; Y / X: 
      File_YdivX = Out_Directory + Prefix + '.YdivX.' + Date_String + '.img' ; Set the output file name
      OPENW, UNIT_YdivX, File_YdivX, /GET_LUN ; Create the output file.
      FREE_LUN, UNIT_YdivX ; Close the output file.
    ENDIF 
    ;-------------------------------------------------------------------------------------------
    ; Segment loop:
    ;-------------------------------------------------------------------------------------------
    In_First = READ_BINARY(FileX_In, DATA_TYPE=In_DataTypeX) ; Open the first input file.
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
      Matrix_X = MAKE_ARRAY(Segment_Size, /FLOAT) ; Create an array to hold grid data segment.
      Matrix_Y = MAKE_ARRAY(Segment_Size, /FLOAT) ; Create an array to hold grid data segment.
      ;-------------------------------------------------------------------------------------------
      ; Get data and calculate:
      ;-------------------------------------------------------------------------------------------
      Data_X = READ_BINARY(FileX_In, DATA_TYPE=In_DataTypeX) ; Read data.
      Matrix_X[*] = Data_X(Segment_Start:Segment_End) * 0.1 ; Get data slice (segment).
      Data_Y = READ_BINARY(FileY_In, DATA_TYPE=In_DataTypeY) ; Read data.
      Matrix_Y[*] = Data_Y(Segment_Start:Segment_End) * 0.1 ; Get data slice (segment)
      ;-------------- ; Set mask:
      Land = WHERE(Mask(Segment_Start:Segment_End) EQ 1, Count_Land)
      ;-------------- ; Calculate and write:
      IF In_Operation[0] EQ 1 THEN BEGIN 
        XplusY = (Matrix_X[Land] + Matrix_Y[Land]) ; Calculate
        XplusY_Out = MAKE_ARRAY(Segment_Size, VALUE=-999, /FLOAT)
        XplusY_Out[Land] = XplusY ; Rebuild using mask.
        OPENU, UNIT_XplusY, File_XplusY, /APPEND, /GET_LUN
        WRITEU, UNIT_XplusY, XplusY_Out ; Write.
        FREE_LUN, UNIT_XplusY
      ENDIF
      IF In_Operation[1] EQ 1 THEN BEGIN 
        XminusY = (Matrix_X[Land] - Matrix_Y[Land]) ; Calculate
        XminusY_Out = MAKE_ARRAY(Segment_Size, VALUE=-999, /FLOAT)
        XminusY_Out[Land] = XminusY ; Rebuild using mask. 
        OPENU, UNIT_XminusY, File_XminusY, /APPEND, /GET_LUN
        WRITEU, UNIT_XminusY, XminusY_Out ; Write.
        FREE_LUN, UNIT_XminusY        
      ENDIF
      IF In_Operation[2] EQ 1 THEN BEGIN
        YminusX = (Matrix_Y[Land] - Matrix_X[Land]) ; Calculate
        YminusX_Out = MAKE_ARRAY(Segment_Size, VALUE=-999, /FLOAT)
        YminusX_Out[Land] = YminusX ; Rebuild using mask. 
        OPENU, UNIT_YminusX, File_YminusX, /APPEND, /GET_LUN
        WRITEU, UNIT_YminusX, YminusX_Out ; Write.
        FREE_LUN, UNIT_YminusX       
      ENDIF
      IF In_Operation[3] EQ 1 THEN BEGIN 
        XtimesY = (Matrix_X[Land] * Matrix_Y[Land]) ; Calculate
        XtimesY_Out = MAKE_ARRAY(Segment_Size, VALUE=-999, /FLOAT)
        XtimesY_Out[Land] = XtimesY ; Rebuild using mask.  
        OPENU, UNIT_XtimesY, File_XtimesY, /APPEND, /GET_LUN
        WRITEU, UNIT_XtimesY, XtimesY_Out ; Write.
        FREE_LUN, UNIT_XtimesY           
      ENDIF
      IF In_Operation[4] EQ 1 THEN BEGIN 
        XdivY = (Matrix_X[Land] / Matrix_Y[Land]) ; Calculate
        XdivY_Out = MAKE_ARRAY(Segment_Size, VALUE=-999, /FLOAT)
        XdivY_Out[Land] = XdivY ; Rebuild using mask.    
        OPENU, UNIT_XdivY, File_XdivY, /APPEND, /GET_LUN
        WRITEU, UNIT_XdivY, XdivY_Out ; Write.
        FREE_LUN, UNIT_XdivY 
      ENDIF
      IF In_Operation[5] EQ 1 THEN BEGIN 
        YdivX = (Matrix_Y[Land] / Matrix_X[Land]) ; Calculate
        YdivX_Out = MAKE_ARRAY(Segment_Size, VALUE=-999, /FLOAT)
        YdivX_Out[Land] = YdivX ; Rebuild using mask.  
        OPENU, UNIT_YdivX, File_YdivX, /APPEND, /GET_LUN
        WRITEU, UNIT_YdivX, YdivX_Out ; Write.
        FREE_LUN, UNIT_YdivX     
      ENDIF
      ;-------------------------------------------------------------------------------------- 
      Minutes = (SYSTIME(1)-LoopStartSegment)/60 ; Get the file loop end time
      PRINT, '  Processing Time: ', STRTRIM(Minutes, 2), ' minutes, for segment ', STRTRIM(s+1, 2), $
        ' of ', STRTRIM(Count_S, 2)
      ;--------------------------------------------------------------------------------------
    ENDFOR
    ;-------------------------------------------------------------------------------------------
    Minutes = (SYSTIME(1)-LoopStart)/60 ; Get the file loop end time
    PRINT, 'Processing Time: ', STRTRIM(Minutes, 2), ' minutes, for date ', STRTRIM(i+1, 2), $
      ' of ', STRTRIM(N_ELEMENTS(DatesX_Unique), 2)
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

