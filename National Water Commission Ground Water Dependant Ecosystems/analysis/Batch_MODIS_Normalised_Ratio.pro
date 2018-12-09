; ##############################################################################################
; NAME: Batch_MODIS_Normalised_Ratio.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: NA
; DATE: 12/12/2010
; DLM: 05/09/2011 Added auto filename creation and missing file catch. Removed class 'cloud-mix'
;                 from the mask.
;
; DESCRIPTION:  This program calculates MODIS derived normalised ratios of the form:
; 
;               (BAND - BAND) / (BAND + BAND)
;               
;               The user may choose to calculate one or more of the listed indices.
;               
;               This program operates in batch mode by MODIS 8-day date. For each unique date the 
;               selected indices are calculated and saved to file.
;
; INPUT:        One or more single-band date-sets.
;
; OUTPUT:       One single-band flat binary raster per input date-set.
;               
; PARAMETERS:   Define the parameters via in-program pop-up dialog widgets.
;                     
; NOTES:        This program calls one or more external functions. You will need to compile the  
;               necessary functions in IDL, or save the functions to the current IDL workspace  
;               prior to running this tool.
;               
;               To identify your IDL workspace run the following from the IDL command line:
;               
;               CD, CURRENT=CWD & PRINT, CWD
;               
;               For more information contact Garth.Warren@csiro.au
;
; ##############################################################################################

;-----------------------------------------------------------------------------------------------
FUNCTION MODIS_8Day_Dates
  COMPILE_OPT idl2
  Dates_2000 = INDGEN(46) * 8 +  JULDAY(1,1,2000)
  Dates_2001 = INDGEN(46) * 8 +  JULDAY(1,1,2001)
  Dates_2002 = INDGEN(46) * 8 +  JULDAY(1,1,2002)
  Dates_2003 = INDGEN(46) * 8 +  JULDAY(1,1,2003)
  Dates_2004 = INDGEN(46) * 8 +  JULDAY(1,1,2004)
  Dates_2005 = INDGEN(46) * 8 +  JULDAY(1,1,2005)
  Dates_2006 = INDGEN(46) * 8 +  JULDAY(1,1,2006)
  Dates_2007 = INDGEN(46) * 8 +  JULDAY(1,1,2007)
  Dates_2008 = INDGEN(46) * 8 +  JULDAY(1,1,2008)
  Dates_2009 = INDGEN(46) * 8 +  JULDAY(1,1,2009)
  Dates_2010 = INDGEN(46) * 8 +  JULDAY(1,1,2010)
  Dates_2011 = INDGEN(46) * 8 +  JULDAY(1,1,2011)
  Dates_2012 = INDGEN(46) * 8 +  JULDAY(1,1,2012)
  Dates = [Dates_2000, Dates_2001, Dates_2002, Dates_2003, Dates_2004, Dates_2005, Dates_2006, $
    Dates_2007, Dates_2008, Dates_2009, Dates_2010, Dates_2011, Dates_2012]
  RETURN, Dates ; Return a full list of all possible MODIS 8-day [julian day] dates for the years 2000 to 2011.
END
;-----------------------------------------------------------------------------------------------

;-----------------------------------------------------------------------------------------------
FUNCTION MOD09A1_Filenames, Day, Month, Year ; Get the MOD09A1 filenames for the selected date.
  DayofYear = JULDAY(Month, Day, Year) - JULDAY(1, 1, Year) + 1
  IF DayofYear LE 9 THEN app_doy = '00'
  IF DayofYear GT 9 AND DayofYear LE 99 THEN app_doy = '0'
  IF DayofYear GT 99 THEN app_doy = ''
  Filenames = STRARR(10)
  FOR i=0, 9 DO BEGIN
    CASE i OF
      0: Band = 'aust.005.b01.img' ; Red.
      1: Band = 'aust.005.b02.img' ; NIR.
      2: Band = 'aust.005.b03.img' ; Blue.
      3: Band = 'aust.005.b04.img' ; Green.
      4: Band = 'aust.005.b05.img' ; SWIR1.
      5: Band = 'aust.005.b06.img' ; SWIR2.
      6: Band = 'aust.005.b07.img' ; SWIR3.
      7: Band  = 'aust.005.b08.img' ; Reflectance quality.
      8: Band = 'aust.005.b12.img' ; State flags.
      9: Band = 'aust.005.b13.img' ; Day of year.
    ENDCASE
    Filename = strcompress('MOD09A1.' + String(Year) + '.' + app_doy + String(DayofYear) + '.' + Band, /REMOVE_ALL)
    Filenames[i] = Filename
  ENDFOR
  RETURN, Filenames
END
;-----------------------------------------------------------------------------------------------

;-----------------------------------------------------------------------------------------------
FUNCTION BITWISE_OPERATOR, Data, Binary1, Match1, WhereValue
  State = ((Data AND Binary1) EQ Match1) ; Apply bit statement.
  Index = WHERE(State EQ WhereValue, Count) ; Get the count of cells that conform to the statement.
  RETURN, [Index] ; Return index.
END
;-----------------------------------------------------------------------------------------------

;-----------------------------------------------------------------------------------------------
FUNCTION BITWISE_OPERATOR_AND, Data, Binary1, Match1, Binary2, Match2, WhereValue
  State = ((Data AND Binary1) EQ Match1) AND ((Data AND Binary2) EQ Match2) ; Apply bit statement.
  Index = WHERE(State EQ WhereValue, Count) ; Get the count of cells that conform to the statement.
  RETURN, [Index] ; Return index.
END
;-----------------------------------------------------------------------------------------------

PRO Batch_MODIS_Normalised_Ratio
  ;---------------------------------------------------------------------------------------------
  StartTime = SYSTIME(1) ; Get the current system time.
  PRINT,''
  PRINT,'Begin Processing: Batch_Normalised_Ratio'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
  ; Input/Output:
  ;---------------------------------------------------------------------------------------------
  Prefix = 'MOD09A1.aust.005.500m.' ; Set a string prefix for the output file names.
  ;---------------------------------------------------------------------------------------------
  ; Set the analysis date range:
  All8Day = MODIS_8Day_Dates() ; Get a list of all valid 8-day dates for years 2000 to 2012.
  DateStart = JULDAY(1, 1, 2000)
  DateEnd   = JULDAY(9, 1, 2011)
  ;---------------------------------------------------------------------------------------------
  ; Select the input folder:
  Path='G:\data\modis\MOD09A1.005\'
  In_Folder = DIALOG_PICKFILE(PATH=Path, TITLE='Select The Folder That Contains The Input Data', /MUST_EXIST, /DIRECTORY)
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
  ; Set the normalised ratio:
  In_Ratio = FUNCTION_WIDGET_Select_Ratio_v2()
  IF (In_Ratio[0] EQ -1) OR (MAX(In_Ratio) LT 1) THEN BEGIN ; Selection check.
    PRINT,'** You Must Select At Least One Index **'
    RETURN ; Quit program
  ENDIF
  ;---------------------------------------------------------------------------------------------
  ; Set the output folder:
  Path='H:\war409\'
  Out_Directory = DIALOG_PICKFILE(PATH=Path, TITLE='Select The Output Folder', /DIRECTORY, /OVERWRITE_PROMPT)
  IF Out_Directory EQ '' THEN RETURN ; Error check.
  ;--------------------------------------------------------------------------------------------- 
  ; Date loop:
  ;---------------------------------------------------------------------------------------------
  ; Get the valid 8-day dates that fall within the selected range of dates.
  SelectedDates = WHERE((All8Day GE DateStart) AND (All8Day LE DateEnd), DateCount)
  ;-------------- ; Loop through each 8-day period:
  FOR i=0, DateCount-1 DO BEGIN ; FOR i
    LoopStart = SYSTIME(1) ;  Get loop start time.
    ;-------------- ; Manipulate dates and get files:
    i8Day = SelectedDates[i]
    CALDAT, All8Day[i8Day], Month, Day, Year ; Convert Julian dates to calendar dates.
    Filenames = MOD09A1_Filenames(Day, Month, Year)
    ;-------------- ; Get the NIR band:
    IF (In_Ratio[0] EQ 1) OR (In_Ratio[1] EQ 1) OR (In_Ratio[2] EQ 1) OR (In_Ratio[3] EQ 1) OR (In_Ratio[4] EQ 1) THEN BEGIN
      NIR_In = In_Folder + Filenames[1] ; Get the NIR band for the current date.
      NIR_Exist = FILE_TEST(NIR_In) ; Check if the file exists.
      IF (NIR_Exist EQ 1) THEN NIR = READ_BINARY(NIR_In, DATA_TYPE=2) ELSE NIR = -1 ; Get data.
    ENDIF ELSE NIR = [0,0]
    ;-------------- ; Get the Red band:
    IF (In_Ratio[0] EQ 1) THEN BEGIN
      Red_In = In_Folder + Filenames[0] ; Get the red band for the current date.
      Red_Exist = FILE_TEST(Red_In) ; Check if the file exists.
      IF (Red_Exist EQ 1) THEN Red = READ_BINARY(Red_In, DATA_TYPE=2) ELSE Red = -1 ; Get data.
    ENDIF ELSE Red = [0,0]
    ;-------------- ; Get the SWIR1 band:
    IF (In_Ratio[1] EQ 1) OR (In_Ratio[5] EQ 1) THEN BEGIN
      SWIR1_In = In_Folder + Filenames[4] ; Get the MIR band for the current date.
      SWIR1_Exist = FILE_TEST(SWIR1_In) ; Check if the file exists.
      IF (SWIR1_Exist EQ 1) THEN SWIR1 = READ_BINARY(SWIR1_In, DATA_TYPE=2) ELSE SWIR1 = -1 ; Get data.
    ENDIF ELSE SWIR1 = [0,0]
    ;-------------- ; Get the SWIR2 band:
    IF (In_Ratio[2] EQ 1) OR (In_Ratio[6] EQ 1) THEN BEGIN
      SWIR2_In = In_Folder + Filenames[5] ; Get the MIR band for the current date.
      SWIR2_Exist = FILE_TEST(SWIR2_In) ; Check if the file exists.
      IF (SWIR2_Exist EQ 1) THEN SWIR2 = READ_BINARY(SWIR2_In, DATA_TYPE=2) ELSE SWIR2 = -1 ; Get data.
    ENDIF ELSE SWIR2 = [0,0]
    ;-------------- ; Get the SWIR3 band:
    IF (In_Ratio[3] EQ 1) OR (In_Ratio[7] EQ 1) THEN BEGIN
      SWIR3_In = In_Folder + Filenames[6] ; Get the MIR band for the current date.
      SWIR3_Exist = FILE_TEST(SWIR3_In) ; Check if the file exists.
      IF (SWIR3_Exist EQ 1) THEN SWIR3 = READ_BINARY(SWIR3_In, DATA_TYPE=2) ELSE SWIR3 = -1 ; Get data.
    ENDIF ELSE SWIR3 = [0,0]
    ;-------------- ; Get the Green band:
    IF (In_Ratio[4] EQ 1) OR (In_Ratio[5] EQ 1) OR (In_Ratio[6] EQ 1) OR (In_Ratio[7] EQ 1) THEN BEGIN
      Green_In = In_Folder + Filenames[3] ; Get the green band for the current date.
      Green_Exist = FILE_TEST(Green_In) ; Check if the file exists.
      IF (Green_Exist EQ 1) THEN Green = READ_BINARY(Green_In, DATA_TYPE=2) ELSE Green = -1 ; Get data.
    ENDIF ELSE Green = [0,0]
    ;-------------- ; Get the State band:
    State_In = In_Folder + Filenames[8] ; Get the state band for the current date.
    State_Exist = FILE_TEST(State_In) ; Check if the file exists.
    IF (State_Exist EQ 1) THEN State = READ_BINARY(State_In, DATA_TYPE=12) ELSE State = -1 ; Open the f-th file.
    ;-------------- ; Check if any of the bands returned -1:
    IF (N_ELEMENTS(Red) EQ 1) OR $
       (N_ELEMENTS(NIR) EQ 1) OR $
       (N_ELEMENTS(Green) EQ 1) OR $
       (N_ELEMENTS(SWIR1) EQ 1) OR $
       (N_ELEMENTS(SWIR2) EQ 1) OR $
       (N_ELEMENTS(SWIR3) EQ 1) OR $
       (N_ELEMENTS(State) EQ 1) $
    THEN Corrupted = 1 ELSE Corrupted = 0
    ;-------------- ; Skip date if one or more input files is missing or corrupt:
    IF Corrupted EQ 0 THEN BEGIN
      ;-------------- ; Get date as DOY:
      DayOfYear = (JULDAY(Month, Day, Year) - JULDAY(1, 1, Year) + 1) ; Get date as DOY.
      IF DayOfYear LE 9 THEN DayOfYear_string = '00' + STRING(STRTRIM(DayOfYear, 2)) ; Add leading zero to DOY.
      IF DayOfYear GT 9 and DayOfYear LE 99 THEN DayOfYear_string = '0' + STRING(STRTRIM(DayOfYear, 2)) ; Add leading zero to DOY.
      IF DayOfYear GT 99 THEN DayOfYear_string = STRING(STRTRIM(DayOfYear, 2))
      ;-------------- ; Get dates as strings:
      IF Month LE 9 THEN M_string = '0' + STRING(STRTRIM(Month, 2)) ELSE M_string = STRING(STRTRIM(Month, 2)) ; Add leading zero.
      IF Day LE 9 THEN D_string = '0' + STRING(STRTRIM(Day, 2)) ELSE D_string = STRING(STRTRIM(Day, 2)) ; Add leading zero.
      Date_string = STRTRIM(Year, 2) + M_string + D_string ; Set the output file name date string (YYYYMMDD).
      DOY_string = STRTRIM(Year, 2) + '.' + DayOfYear_string ; Set the output file name date string (YYYYDOY).
      ;-------------- ; Build output file (NDVI):
      IF (In_Ratio[0] EQ 1) THEN BEGIN
        File_NDVI = Out_Directory + Prefix + DOY_string + '.NDVI' + '.img' ; Set the output filename.
        OPENW, UNIT, File_NDVI, /GET_LUN ; Create the output file.
        FREE_LUN, UNIT ; Close the output file.
      ENDIF
      ;-------------- ; Build output file (NDWI 1):
      IF (In_Ratio[1] EQ 1) THEN BEGIN
        File_NDWI1SWIR1 = Out_Directory + Prefix + DOY_string + '.NDWI1.SWIR1' + '.img' ; Set the output file name.
        OPENW, UNIT, File_NDWI1SWIR1, /GET_LUN ; Create the output file.
        FREE_LUN, UNIT ; Close the output file.
      ENDIF
      ;-------------- ; Build output file (NDWI 1):
      IF (In_Ratio[2] EQ 1) THEN BEGIN
        File_NDWI1SWIR2 = Out_Directory + Prefix + DOY_string + '.NDWI1.SWIR2' + '.img' ; Set the output file name.
        OPENW, UNIT, File_NDWI1SWIR2, /GET_LUN ; Create the output file.
        FREE_LUN, UNIT ; Close the output file.
      ENDIF 
      ;-------------- ; Build output file (NDWI 1):
      IF (In_Ratio[3] EQ 1) THEN BEGIN
        File_NDWI1SWIR3 = Out_Directory + Prefix + DOY_string + '.NDWI1.SWIR3' + '.img' ; Set the output file name.
        OPENW, UNIT, File_NDWI1SWIR3, /GET_LUN ; Create the output file.
        FREE_LUN, UNIT ; Close the output file.
      ENDIF
      ;-------------- ; Build output file (NDWI 2):
      IF (In_Ratio[4] EQ 1) THEN BEGIN
        File_NDWI2 = Out_Directory + Prefix + DOY_string + '.NDWI2' + '.img' ; Set the output file name.
        OPENW, UNIT, File_NDWI2, /GET_LUN ; Create the output file.
        FREE_LUN, UNIT ; Close the output file.
      ENDIF
      ;-------------- ; Build output file (mNDWI):
      IF (In_Ratio[5] EQ 1) THEN BEGIN
        File_mNDWISWIR1 = Out_Directory + Prefix + DOY_string + '.mNDWI.SWIR1' + '.img' ; Set the output file name.
        OPENW, UNIT, File_mNDWISWIR1, /GET_LUN ; Create the output file.
        FREE_LUN, UNIT ; Close the output file.
      ENDIF
      ;-------------- ; Build output file (mNDWI):
      IF (In_Ratio[6] EQ 1) THEN BEGIN
        File_mNDWISWIR2 = Out_Directory + Prefix + DOY_string + '.mNDWI.SWIR2' + '.img' ; Set the output file name.
        OPENW, UNIT, File_mNDWISWIR2, /GET_LUN ; Create the output file.
        FREE_LUN, UNIT ; Close the output file.
      ENDIF
      ;-------------- ; Build output file (mNDWI):
      IF (In_Ratio[7] EQ 1) THEN BEGIN
        File_mNDWISWIR3 = Out_Directory + Prefix + DOY_string + '.mNDWI.SWIR3' + '.img' ; Set the output file name.
        OPENW, UNIT, File_mNDWISWIR3, /GET_LUN ; Create the output file.
        FREE_LUN, UNIT ; Close the output file.
      ENDIF
      ;-----------------------------------------------------------------------------------------
      ; Set mask:
      ;-----------------------------------------------------------------------------------------   
      Matrix_Mask = MAKE_ARRAY(N_ELEMENTS(State), VALUE=1, /INTEGER)
      Fill = WHERE(State EQ 65535, CountFill) ; Fill cells
      IF (N_ELEMENTS(Fill) GT 1) THEN Matrix_Mask[Fill] = 0
      CloudIndex = BITWISE_OPERATOR_AND(State, 1, 1, 2, 0, 1) ; Cloud cells ["Cloud"= 0000000000000001]; STATE = ((1033 AND 1) EQ 1) AND ((1033 AND 2) EQ 0)
      IF (N_ELEMENTS(CloudIndex) GT 1) THEN Matrix_Mask[CloudIndex] = 0
      ShadowIndex = BITWISE_OPERATOR(State, 4, 0, 0) ; Cloud shadow cells ["Cloud_Shadow"= 0000000000000100]
      IF (N_ELEMENTS(ShadowIndex) GT 1) THEN Matrix_Mask[ShadowIndex] = 0
      InternalIndex = BITWISE_OPERATOR(State, 1024, 0, 0) ; Internal cloud cells
      IF (N_ELEMENTS(InternalIndex) GT 1) THEN Matrix_Mask[InternalIndex] = 0
      ShallowIndex = BITWISE_OPERATOR_AND(State, 0, 0, 56, 0, 1) ; ["shallow ocean"= 0000000000000000] ; ((8196 AND 0) EQ 0) AND ((8196 AND 56) EQ 0)
      IF (N_ELEMENTS(ShallowIndex) GT 1) THEN Matrix_Mask[ShallowIndex] = 0
      ContinentalIndex = BITWISE_OPERATOR_AND(State, 48, 48, 8, 0, 1) ; ["continental ocean"= 0000000000110000] ; ((1073 AND 48) EQ 48) AND ((1073 AND 8) EQ 0)
      IF (N_ELEMENTS(ContinentalIndex) GT 1) THEN Matrix_Mask[ContinentalIndex] = 0
      DeepIndex = BITWISE_OPERATOR(State, 56, 56, 1) ; ["deep ocean"= 0000000000111000] ; ((123 AND 56) EQ 56)
      IF (N_ELEMENTS(DeepIndex) GT 1) THEN Matrix_Mask[DeepIndex] = 0
      FillRed = WHERE(Red EQ -32768, CountFill)
      IF (N_ELEMENTS(FillRed) GT 1) THEN Matrix_Mask[FillRed] = 0
      FillNIR = WHERE(NIR EQ -32768, CountFill)
      IF (N_ELEMENTS(FillNIR) GT 1) THEN Matrix_Mask[FillNIR] = 0
      FillGreen = WHERE(Green EQ -32768, CountFill)
      IF (N_ELEMENTS(FillGreen) GT 1) THEN Matrix_Mask[FillGreen] = 0
      FillSWIR1 = WHERE(SWIR1 EQ -32768, CountFill)
      IF (N_ELEMENTS(FillSWIR1) GT 1) THEN Matrix_Mask[FillSWIR1] = 0
      FillSWIR2 = WHERE(SWIR2 EQ -32768, CountFill)
      IF (N_ELEMENTS(FillSWIR2) GT 1) THEN Matrix_Mask[FillSWIR2] = 0
      FillSWIR3 = WHERE(SWIR3 EQ -32768, CountFill)
      IF (N_ELEMENTS(FillSWIR3) GT 1) THEN Matrix_Mask[FillSWIR3] = 0
      Mask = WHERE(Matrix_Mask EQ 1, Count_Mask)
      ;-----------------------------------------------------------------------------------------
      ; Calculate NDVI:
      ;-----------------------------------------------------------------------------------------
      IF (In_Ratio[0] EQ 1) THEN BEGIN
        NDVI = (NIR[Mask] - Red[Mask]) / (NIR[Mask] + Red[Mask] * 1.00)
        NDVI_Out = MAKE_ARRAY(N_ELEMENTS(State), VALUE=-999, /FLOAT)
        NDVI_Out[Mask] = NDVI
        IF (Out_DataType EQ 2) THEN NDVI_Out = FIX(NDVI_Out + 0.5) ; Signed Integer:
        IF (Out_DataType EQ 3) THEN NDVI_Out = LONG(NDVI_Out + 0.5) ; Long Integer:
        IF (Out_DataType EQ 4) THEN NDVI_Out = NDVI_Out ; Float:
        IF (Out_DataType EQ 12) THEN NDVI_Out = UINT(NDVI_Out + 0.5) ; Unsigned Integer:
        IF (Out_DataType EQ 5) THEN BEGIN
          NDVI_Out = MAKE_ARRAY(N_ELEMENTS(State), VALUE=-999, /DOUBLE)
          NDVI_Out[Mask] = NDVI          
        ENDIF
        OPENU, UNIT, File_NDVI, /GET_LUN, /APPEND ; Open the output file for editing.
        WRITEU, UNIT, NDVI_Out ; Write output data.
        FREE_LUN, UNIT ; Close the output file.
      ENDIF
      ;-----------------------------------------------------------------------------------------
      ; Calculate NDWI 1 (SWIR1):
      ;-----------------------------------------------------------------------------------------
      IF (In_Ratio[1] EQ 1) THEN BEGIN
        NDWI1SWIR1 = (NIR[Mask] - SWIR1[Mask]) / (NIR[Mask] + SWIR1[Mask] * 1.00)
        NDWI1SWIR1_Out = MAKE_ARRAY(N_ELEMENTS(State), VALUE=-999, /FLOAT)
        NDWI1SWIR1_Out[Mask] = NDWI1SWIR1
        IF (Out_DataType EQ 2) THEN NDWI1SWIR1_Out = FIX(NDWI1SWIR1_Out + 0.5) ; Signed Integer:
        IF (Out_DataType EQ 3) THEN NDWI1SWIR1_Out = LONG(NDWI1SWIR1_Out + 0.5) ; Long Integer:
        IF (Out_DataType EQ 4) THEN NDWI1SWIR1_Out = NDWI1SWIR1_Out ; Float:
        IF (Out_DataType EQ 12) THEN NDWI1SWIR1_Out = UINT(NDWI1SWIR1_Out + 0.5) ; Unsigned Integer:
        IF (Out_DataType EQ 5) THEN BEGIN ; Double:
          NDWI1SWIR1_Out = MAKE_ARRAY(N_ELEMENTS(State), VALUE=-999, /DOUBLE)
          NDWI1SWIR1_Out[Mask] = NDWI1SWIR1
        ENDIF
        OPENU, UNIT, File_NDWI1SWIR1, /GET_LUN, /APPEND ; Open the output file for editing.
        WRITEU, UNIT, NDWI1SWIR1_Out ; Write output data.
        FREE_LUN, UNIT ; Close the output file.
      ENDIF
      ;-----------------------------------------------------------------------------------------
      ; Calculate NDWI 1 (SWIR2):
      ;-----------------------------------------------------------------------------------------
      IF (In_Ratio[2] EQ 1) THEN BEGIN
        NDWI1SWIR2 = (NIR[Mask] - SWIR2[Mask]) / (NIR[Mask] + SWIR2[Mask] * 1.00)
        NDWI1SWIR2_Out = MAKE_ARRAY(N_ELEMENTS(State), VALUE=-999, /FLOAT)
        NDWI1SWIR2_Out[Mask] = NDWI1SWIR2
        IF (Out_DataType EQ 2) THEN NDWI1SWIR2_Out = FIX(NDWI1SWIR2_Out + 0.5) ; Signed Integer:
        IF (Out_DataType EQ 3) THEN NDWI1SWIR2_Out = LONG(NDWI1SWIR2_Out + 0.5) ; Long Integer:
        IF (Out_DataType EQ 4) THEN NDWI1SWIR2_Out = NDWI1SWIR2_Out ; Float:
        IF (Out_DataType EQ 12) THEN NDWI1SWIR2_Out = UINT(NDWI1SWIR2_Out + 0.5) ; Unsigned Integer:
        IF (Out_DataType EQ 5) THEN BEGIN ; Double:
          NDWI1SWIR2_Out = MAKE_ARRAY(N_ELEMENTS(State), VALUE=-999, /DOUBLE)
          NDWI1SWIR2_Out[Mask] = NDWI1SWIR2
        ENDIF
        OPENU, UNIT, File_NDWI1SWIR2, /GET_LUN, /APPEND ; Open the output file for editing.
        WRITEU, UNIT, NDWI1SWIR2_Out ; Write output data.
        FREE_LUN, UNIT ; Close the output file.
      ENDIF
      ;-----------------------------------------------------------------------------------------
      ; Calculate NDWI 1 (SWIR3):
      ;-----------------------------------------------------------------------------------------
      IF (In_Ratio[3] EQ 1) THEN BEGIN
        NDWI1SWIR3 = (NIR[Mask] - SWIR3[Mask]) / (NIR[Mask] + SWIR3[Mask] * 1.00)
        NDWI1SWIR3_Out = MAKE_ARRAY(N_ELEMENTS(State), VALUE=-999, /FLOAT)
        NDWI1SWIR3_Out[Mask] = NDWI1SWIR3
        IF (Out_DataType EQ 2) THEN NDWI1SWIR3_Out = FIX(NDWI1SWIR3_Out + 0.5) ; Signed Integer:
        IF (Out_DataType EQ 3) THEN NDWI1SWIR3_Out = LONG(NDWI1SWIR3_Out + 0.5) ; Long Integer:
        IF (Out_DataType EQ 4) THEN NDWI1SWIR3_Out = NDWI1SWIR3_Out ; Float:
        IF (Out_DataType EQ 12) THEN NDWI1SWIR3_Out = UINT(NDWI1SWIR3_Out + 0.5) ; Unsigned Integer:
        IF (Out_DataType EQ 5) THEN BEGIN ; Double:
          NDWI1SWIR3_Out = MAKE_ARRAY(N_ELEMENTS(State), VALUE=-999, /DOUBLE)
          NDWI1SWIR3_Out[Mask] = NDWI1SWIR3
        ENDIF
        OPENU, UNIT, File_NDWI1SWIR3, /GET_LUN, /APPEND ; Open the output file for editing.
        WRITEU, UNIT, NDWI1SWIR3_Out ; Write output data.
        FREE_LUN, UNIT ; Close the output file.
      ENDIF   
      ;-----------------------------------------------------------------------------------------
      ; Calculate NDWI 2:
      ;-----------------------------------------------------------------------------------------
      IF (In_Ratio[4] EQ 1) THEN BEGIN ; Calculate NDWI 2:
        NDWI2 = (Green[Mask] - NIR[Mask]) / (Green[Mask] + NIR[Mask] * 1.00)
        NDWI2_Out = MAKE_ARRAY(N_ELEMENTS(State), VALUE=-999, /FLOAT)
        NDWI2_Out[Mask] = NDWI2
        IF (Out_DataType EQ 2) THEN NDWI2_Out = FIX(NDWI2_Out + 0.5) ; Signed Integer:
        IF (Out_DataType EQ 3) THEN NDWI2_Out = LONG(NDWI2_Out + 0.5) ; Long Integer:
        IF (Out_DataType EQ 4) THEN NDWI2_Out = NDWI2_Out ; Float:
        IF (Out_DataType EQ 12) THEN NDWI2_Out = UINT(NDWI2_Out + 0.5) ; Unsigned Integer:
        IF (Out_DataType EQ 5) THEN BEGIN ; Double:
          NDWI2_Out = MAKE_ARRAY(N_ELEMENTS(State), VALUE=-999, /DOUBLE)
          NDWI2_Out[Mask] = NDWI2
        ENDIF
        OPENU, UNIT, File_NDWI2, /GET_LUN, /APPEND ; Open the output file for editing.
        WRITEU, UNIT, NDWI2_Out ; Write output data.
        FREE_LUN, UNIT ; Close the output file.
      ENDIF
      ;-----------------------------------------------------------------------------------------
      ; Calculate mNDWI (SWIR1):
      ;-----------------------------------------------------------------------------------------
      IF (In_Ratio[5] EQ 1) THEN BEGIN ; Calculate mNDWI:
        mNDWISWIR1 = (Green[Mask] - SWIR1[Mask]) / (Green[Mask] + SWIR1[Mask] * 1.00)
        mNDWISWIR1_Out = MAKE_ARRAY(N_ELEMENTS(State), VALUE=-999, /FLOAT)
        mNDWISWIR1_Out[Mask] = mNDWISWIR1
        IF (Out_DataType EQ 2) THEN mNDWISWIR1_Out = FIX(mNDWISWIR1_Out + 0.5) ; Signed Integer:
        IF (Out_DataType EQ 3) THEN mNDWISWIR1_Out = LONG(mNDWISWIR1_Out + 0.5) ; Long Integer:
        IF (Out_DataType EQ 4) THEN mNDWISWIR1_Out = mNDWISWIR1_Out ; Float:
        IF (Out_DataType EQ 12) THEN mNDWISWIR1_Out = UINT(mNDWISWIR1_Out + 0.5) ; Unsigned Integer:
        IF (Out_DataType EQ 5) THEN BEGIN ; Double:
          mNDWISWIR1_Out = MAKE_ARRAY(N_ELEMENTS(State), VALUE=-999, /DOUBLE)
          mNDWISWIR1_Out[Mask] = mNDWISWIR1
        ENDIF
        OPENU, UNIT, File_mNDWISWIR1, /GET_LUN, /APPEND ; Open the output file for editing.
        WRITEU, UNIT, mNDWISWIR1_Out ; Write output data.
        FREE_LUN, UNIT ; Close the output file.
      ENDIF
      ;-----------------------------------------------------------------------------------------
      ; Calculate mNDWI (SWIR2):
      ;-----------------------------------------------------------------------------------------
      IF (In_Ratio[6] EQ 1) THEN BEGIN ; Calculate mNDWI:
        mNDWISWIR2 = (Green[Mask] - SWIR2[Mask]) / (Green[Mask] + SWIR2[Mask] * 1.00)
        mNDWISWIR2_Out = MAKE_ARRAY(N_ELEMENTS(State), VALUE=-999, /FLOAT)
        mNDWISWIR2_Out[Mask] = mNDWISWIR2
        IF (Out_DataType EQ 2) THEN mNDWISWIR2_Out = FIX(mNDWISWIR2_Out + 0.5) ; Signed Integer:
        IF (Out_DataType EQ 3) THEN mNDWISWIR2_Out = LONG(mNDWISWIR2_Out + 0.5) ; Long Integer:
        IF (Out_DataType EQ 4) THEN mNDWISWIR2_Out = mNDWISWIR2_Out ; Float:
        IF (Out_DataType EQ 12) THEN mNDWISWIR2_Out = UINT(mNDWISWIR2_Out + 0.5) ; Unsigned Integer:
        IF (Out_DataType EQ 5) THEN BEGIN ; Double:
          mNDWISWIR2_Out = MAKE_ARRAY(N_ELEMENTS(State), VALUE=-999, /DOUBLE)
          mNDWISWIR2_Out[Mask] = mNDWISWIR2
        ENDIF
        OPENU, UNIT, File_mNDWISWIR2, /GET_LUN, /APPEND ; Open the output file for editing.
        WRITEU, UNIT, mNDWISWIR2_Out ; Write output data.
        FREE_LUN, UNIT ; Close the output file.
      ENDIF
      ;-----------------------------------------------------------------------------------------
      ; Calculate mNDWI (SWIR3):
      ;-----------------------------------------------------------------------------------------
      IF (In_Ratio[7] EQ 1) THEN BEGIN ; Calculate mNDWI:
        mNDWISWIR3 = (Green[Mask] - SWIR3[Mask]) / (Green[Mask] + SWIR3[Mask] * 1.00)
        mNDWISWIR3_Out = MAKE_ARRAY(N_ELEMENTS(State), VALUE=-999, /FLOAT)
        mNDWISWIR3_Out[Mask] = mNDWISWIR3
        IF (Out_DataType EQ 2) THEN mNDWISWIR3_Out = FIX(mNDWISWIR3_Out + 0.5) ; Signed Integer:
        IF (Out_DataType EQ 3) THEN mNDWISWIR3_Out = LONG(mNDWISWIR3_Out + 0.5) ; Long Integer:
        IF (Out_DataType EQ 4) THEN mNDWISWIR3_Out = mNDWISWIR3_Out ; Float:
        IF (Out_DataType EQ 12) THEN mNDWISWIR3_Out = UINT(mNDWISWIR3_Out + 0.5) ; Unsigned Integer:
        IF (Out_DataType EQ 5) THEN BEGIN ; Double:
          mNDWISWIR3_Out = MAKE_ARRAY(N_ELEMENTS(State), VALUE=-999, /DOUBLE)
          mNDWISWIR3_Out[Mask] = mNDWISWIR3
        ENDIF
        OPENU, UNIT, File_mNDWISWIR3, /GET_LUN, /APPEND ; Open the output file for editing.
        WRITEU, UNIT, mNDWISWIR3_Out ; Write output data.
        FREE_LUN, UNIT ; Close the output file.
      ENDIF
      ;-----------------------------------------------------------------------------------------   
      Seconds = (SYSTIME(1)-LoopStart) ; Get the file loop end time
      PRINT, '  Processing Time: ', STRTRIM(Seconds, 2), ' seconds, for date ', STRTRIM(i+1, 2), $
        ' of ', STRTRIM(DateCount, 2)
      ;-----------------------------------------------------------------------------------------
    ENDIF ELSE BEGIN
      ;-----------------------------------------------------------------------------------------   
      Seconds = (SYSTIME(1)-LoopStart) ; Get the file loop end time
      PRINT, '  Processing Time: ', STRTRIM(Seconds, 2), ' seconds, for date ', STRTRIM(i+1, 2), $
        ' of ', STRTRIM(DateCount, 2), '. One or more of the input bands are missing or are corrupt.'
      ;-----------------------------------------------------------------------------------------
    ENDELSE
  ENDFOR
  ;---------------------------------------------------------------------------------------------
  Minutes = (SYSTIME(1)-StartTime)/60 ; Subtract the program End-Time from the program Start-Time.
  Hours = Minutes/60 ; Convert minutes to hours.
  PRINT,''
  PRINT,'Total Processing Time: ', STRTRIM(Minutes, 2), ' minutes (', STRTRIM(Hours, 2), ' hours).'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
END

