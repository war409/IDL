; ##############################################################################################
; NAME: MODIS_AET_Get_Date_zero_with_no_gaps.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: NWC GDE Atlas
; DATE: 05/03/2011
; DLM: 21/12/2012
;
; DESCRIPTION:  This program calculates gap free date zero MOD09A1 and MOD09Q1 bands.
;
; INPUT:       
;
; OUTPUT:              
;
; PARAMETERS:  
;
; NOTES:   
;
; ############################################################################################## 


;---------------------------------------------------------------------------------------------
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
  RETURN, Dates ; Return a full list of all possible 8-day [julian day] dates for the years 2000 to 2011.
END
;---------------------------------------------------------------------------------------------


;---------------------------------------------------------------------------------------------
FUNCTION MOD09A1_fname_unzipped, Path, Day, Month, Year ; Get the full file name and path of each MOD09A1 file for the selected date.
  COMPILE_OPT idl2
  IF Month LE 9 THEN Prefix_Month = '0' ELSE Prefix_Month = ' ' ; Add leading zero to month.
  IF Day LE 9 THEN Prefix_Day = '0' ELSE Prefix_Day = ' ' ; Add leading zero to day.
  DOY = JULDAY(Month, Day, Year)  -  JULDAY(1, 1, Year) + 1 ; Get date as DOY.
  IF DOY GT 9 and DOY LE 99 THEN Prefix_DOY = '0' ; Add leading zero to DOY.
  IF DOY LE 9 THEN Prefix_DOY = '00' ; Add leading zero to DOY.
  IF DOY GT 99 THEN Prefix_DOY = ' '
  fname = STRARR(10) ; Create array to hold file names.
  FOR i=0, 9 DO BEGIN ; Band loop:
    CASE i OF
      0: Band_text= 'aust.005.b01.img'
      1: Band_text= 'aust.005.b02.img'
      2: Band_text= 'aust.005.b03.img'
      3: Band_text= 'aust.005.b04.img'
      4: Band_text= 'aust.005.b05.img'
      5: Band_text= 'aust.005.b06.img'
      6: Band_text= 'aust.005.b07.img'
      7: Band_text= 'aust.005.b08.img'
      8: Band_text= 'aust.005.b12.img'
      9: Band_text= 'aust.005.b13.img'
    ENDCASE
    fname_i = STRCOMPRESS(Path + $
      'MOD09A1.' + STRING(Year) + '.' + $
      Prefix_DOY + STRING(DOY) + '.' + $
      Band_text , /REMOVE_ALL) ; Set the full file name and path for the selected date and the i-th band.
    fname[i] = fname_i ; Add the new file name to the file name array.
  ENDFOR
  RETURN, fname ; Return the file name array to the main procedure.
END
;---------------------------------------------------------------------------------------------


;---------------------------------------------------------------------------------------------
FUNCTION MOD09Q1_fname_unzipped, Path, Day, Month, Year ; Get the full file name and path of each MOD09A1 file for the selected date.
  COMPILE_OPT idl2
  IF Month LE 9 THEN Prefix_Month = '0' ELSE Prefix_Month = ' ' ; Add leading zero to month.
  IF Day LE 9 THEN Prefix_Day = '0' ELSE Prefix_Day = ' ' ; Add leading zero to day.
  DOY = JULDAY(Month, Day, Year)  -  JULDAY(1, 1, Year) + 1 ; Get date as DOY.
  IF DOY GT 9 and DOY LE 99 THEN Prefix_DOY = '0' ; Add leading zero to DOY.
  IF DOY LE 9 THEN Prefix_DOY = '00' ; Add leading zero to DOY.
  IF DOY GT 99 THEN Prefix_DOY = ' '
  fname = STRARR(10) ; Create array to hold file names.
  FOR i=0, 1 DO BEGIN ; Band loop:
    CASE i OF
      0: Band_text= 'aust.005.b01.img'
      1: Band_text= 'aust.005.b02.img'
      2: Band_text= 'aust.005.b12.img'
    ENDCASE
    fname_i = STRCOMPRESS(Path + $
      'MOD09Q1.' + STRING(Year) + '.' + $
      Prefix_DOY + STRING(DOY) + '.' + $
      Band_text , /REMOVE_ALL) ; Set the full file name and path for the selected date and the i-th band.
    fname[i] = fname_i ; Add the new file name to the file name array.
  ENDFOR
  RETURN, fname ; Return the file name array to the main procedure.
END
;---------------------------------------------------------------------------------------------


;---------------------------------------------------------------------------------------------
FUNCTION BITWISE_OPERATOR, DATA, BINARY1, MATCH1, WHERE_VALUE
  STATE = ((DATA AND BINARY1) EQ MATCH1) ; Apply bitwise statement.
  INDEX = WHERE(STATE EQ WHERE_VALUE, COUNT) ; Get count of pixels that conform to the statement.
  RETURN, [INDEX] ; Return values to the main procedure.
END
;---------------------------------------------------------------------------------------------


;---------------------------------------------------------------------------------------------
FUNCTION BITWISE_OPERATOR_AND, DATA, BINARY1, MATCH1, BINARY2, MATCH2, WHERE_VALUE
  STATE = ((DATA AND BINARY1) EQ MATCH1) AND ((DATA AND BINARY2) EQ MATCH2) ; Apply bitwise statement.
  INDEX = WHERE(STATE EQ WHERE_VALUE, COUNT) ; Get count of pixels that conform to the statement.
  RETURN, [INDEX] ; Return values to the main procedure.
END
;---------------------------------------------------------------------------------------------


PRO MODIS_AET_Get_Date_zero_with_no_gaps
  ;---------------------------------------------------------------------------------------------
  T_TIME = SYSTIME(1) ; Get the program start time.
  PRINT,''
  PRINT,'Begin processing: MODIS_AET_Get_Date_zero_with_no_gaps'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
  ;*********************************************************************************************
  ; Input/Output:
  ;*********************************************************************************************
  ;---------------------------------------------------------------------------------------------
  MODIS_Products = ['MOD09A1', 'MOD09Q1'] 
  In_Product = MODIS_Products[0] ; Set the MODIS product name.
  In_Directory = '\\wron\Working\work\war409\mod09\' ; Set MODIS parent directory.
  Out_Directory = '\\wron\Working\work\war409\' ; Set the output directory.
  ;-------------- ; Get all valid 8-day dates for the selected time period:
  All_Dates = MODIS_8Day_Dates()
  Date_Start = JULDAY(2, 15, 2000)
  Date_End = JULDAY(12, 31, 2000)
  Get_Dates = Where((All_Dates GE Date_Start) AND (All_Dates LE Date_End), Date_Count)
  ;-------------------------------------------------------------------------------------------
  ; Date loop:
  ;-------------------------------------------------------------------------------------------
  FOR i=0, Date_Count-1 DO BEGIN
    iTime = SYSTIME(1) ; Get loop start time.
    ;-----------------------------------------------------------------------------------------
    ; Get Data:
    ;-----------------------------------------------------------------------------------------  
    iDates = Get_Dates[i] ; Get the i-th date.
    CALDAT, All_Dates[iDates], Month, Day, Year ; Get the i-th month, day, and year.
    ;-------------- ; Get MOD09A1:
    IF In_Product EQ 'MOD09A1' THEN BEGIN
      Input_file = MOD09A1_fname_unzipped(In_Directory, Day, Month, Year) ; Get the i-th date file list. 
      ;-------------- ; Get BLUE data:
      fname_Blue = Input_file[2]
      BLUE = READ_BINARY(fname_Blue, DATA_TYPE=2) ; Get data.
      SIZE_DATA = SIZE(BLUE)
      ;-------------- ; Get SWIR2 data:
      fname_SWIR2 = Input_file[5]
      SWIR2 = READ_BINARY(fname_SWIR2, DATA_TYPE=2) ; Get data.
      ;-------------- ; Get State data:
      fname_State = Input_file[8]
      STATE = READ_BINARY(fname_State, DATA_TYPE=12) ; Get data.
      ;-------------- ; Check if any of the selected input files are missing or corrupt:
      IF N_ELEMENTS(BLUE) EQ 1 OR $
        N_ELEMENTS(SWIR2) EQ 1 OR $
        N_ELEMENTS(STATE) EQ 1 $
      THEN Corrupted=1 ELSE Corrupted=0
    ENDIF
    ;-------------- ; Get MOD09Q1:
    IF In_Product EQ 'MOD09Q1' THEN BEGIN
      Input_file = MOD09Q1_fname_unzipped(In_Directory, Day, Month, Year) ; Get the i-th date file list.
      ;-------------- ; Get RED data:
      fname_Red = Input_file[0]
      RED = READ_BINARY(fname_Red, DATA_TYPE=2) ; Get data.
      SIZE_DATA = SIZE(RED)
      ;-------------- ; Get NIR data:
      fname_NIR = Input_file[1]
      NIR = READ_BINARY(fname_NIR, DATA_TYPE=2) ; Get data.
      ;-------------- ; Get State data:
      fname_State = Input_file[2]
      STATE = READ_BINARY(fname_State, DATA_TYPE=12) ; Get data.      
      ;-------------- ; Check if any of the selected input files are missing or corrupt:
      IF N_ELEMENTS(RED) EQ 1 OR $
        N_ELEMENTS(NIR) EQ 1 OR $
        N_ELEMENTS(STATE) EQ 1 $
      THEN Corrupted=1 ELSE Corrupted=0
    ENDIF
    ;-----------------------------------------------------------------------------------------
    IF Corrupted EQ 0 THEN BEGIN ; Continue to the next loop if one or more of the input files are missing or corrupt:
      ;-------------- ; Set MOD09A1:
      IF In_Product EQ 'MOD09A1' THEN BEGIN
        ;-------------- ; Apply modis cloud mask to BLUE:
        INDEX_FILL = WHERE(STATE EQ FLOAT(65535), COUNT_FILL)
        IF (COUNT_FILL GT 0) THEN BLUE[INDEX_FILL] = -999 ; Replace fill cells
        INDEX_CLOUD = BITWISE_OPERATOR_AND(STATE, 1, 1, 2, 0, 1) ; STATE = ((1033 AND 1) EQ 1) AND ((1033 AND 2) EQ 0)
        IF (N_ELEMENTS(INDEX_CLOUD) GT 1) THEN BLUE[INDEX_CLOUD] = -999 ; Replace cloud cells.
        INDEX_MIXED = BITWISE_OPERATOR(STATE, 3, 2, 1)
        IF (N_ELEMENTS(INDEX_MIXED) GT 1) THEN BLUE[INDEX_MIXED] = -999 ; Replace mixed cloud cells. 
        INDEX_SHADOW = BITWISE_OPERATOR(STATE, 4, 0, 0)
        IF (N_ELEMENTS(INDEX_SHADOW) GT 1) THEN BLUE[INDEX_SHADOW] = -999 ; Replace cloud shadow cells. 
        ;-------------- ; Apply modis cloud mask to SWIR2:
        INDEX_FILL = WHERE(STATE EQ FLOAT(65535), COUNT_FILL)
        IF (COUNT_FILL GT 0) THEN SWIR2[INDEX_FILL] = -999 ; Replace fill cells
        INDEX_CLOUD = BITWISE_OPERATOR_AND(STATE, 1, 1, 2, 0, 1) ; STATE = ((1033 AND 1) EQ 1) AND ((1033 AND 2) EQ 0)
        IF (N_ELEMENTS(INDEX_CLOUD) GT 1) THEN SWIR2[INDEX_CLOUD] = -999 ; Replace cloud cells.
        INDEX_MIXED = BITWISE_OPERATOR(STATE, 3, 2, 1)
        IF (N_ELEMENTS(INDEX_MIXED) GT 1) THEN SWIR2[INDEX_MIXED] = -999 ; Replace mixed cloud cells. 
        INDEX_SHADOW = BITWISE_OPERATOR(STATE, 4, 0, 0)
        IF (N_ELEMENTS(INDEX_SHADOW) GT 1) THEN SWIR2[INDEX_SHADOW] = -999 ; Replace cloud shadow cells. 
        ;-------------- ; ; Update last valid arrays:
        IF i EQ 0 THEN BEGIN
          last_valid_BLUE = MAKE_ARRAY(SIZE_DATA, /INTEGER) ; Create array to hold valid reflectance values.
          last_valid_SWIR2 = MAKE_ARRAY(SIZE_DATA, /INTEGER) ; Create array to hold valid reflectance values.
          last_valid_BLUE = BLUE ; Set the initial values. 
          last_valid_SWIR2 = SWIR2 ; Set the initial values.
        ENDIF ELSE BEGIN ; Update last valid arrays:
          INDEX_VALID_BLUE = WHERE(BLUE NE -999, COUNT_VALID_BLUE)
          IF (N_ELEMENTS(COUNT_VALID_BLUE) GT 1) THEN last_valid_BLUE[INDEX_VALID_BLUE] = BLUE[INDEX_VALID_BLUE]
          INDEX_VALID_SWIR2 = WHERE(SWIR2 NE -999, COUNT_VALID_SWIR2)
          IF (N_ELEMENTS(COUNT_VALID_SWIR2) GT 1) THEN last_valid_SWIR2[INDEX_VALID_SWIR2] = SWIR2[INDEX_VALID_SWIR2]        
        ENDELSE
        ;----------------------------
      ENDIF ELSE BEGIN ; Set MOD09Q1:
        ;-------------- ; Apply modis cloud mask to RED:
        INDEX_FILL = WHERE(STATE EQ FLOAT(65535), COUNT_FILL)
        IF (COUNT_FILL GT 0) THEN RED[INDEX_FILL] = -999 ; Replace fill cells
        INDEX_CLOUD = BITWISE_OPERATOR_AND(STATE, 1, 1, 2, 0, 1) ; STATE = ((1033 AND 1) EQ 1) AND ((1033 AND 2) EQ 0)
        IF (N_ELEMENTS(INDEX_CLOUD) GT 1) THEN RED[INDEX_CLOUD] = -999 ; Replace cloud cells.
        INDEX_MIXED = BITWISE_OPERATOR(STATE, 3, 2, 1)
        IF (N_ELEMENTS(INDEX_MIXED) GT 1) THEN RED[INDEX_MIXED] = -999 ; Replace mixed cloud cells. 
        INDEX_SHADOW = BITWISE_OPERATOR(STATE, 4, 0, 0)
        IF (N_ELEMENTS(INDEX_SHADOW) GT 1) THEN RED[INDEX_SHADOW] = -999 ; Replace cloud shadow cells. 
        ;-------------- ; Apply modis cloud mask to NIR:
        INDEX_FILL = WHERE(STATE EQ FLOAT(65535), COUNT_FILL)
        IF (COUNT_FILL GT 0) THEN NIR[INDEX_FILL] = -999 ; Replace fill cells
        INDEX_CLOUD = BITWISE_OPERATOR_AND(STATE, 1, 1, 2, 0, 1) ; STATE = ((1033 AND 1) EQ 1) AND ((1033 AND 2) EQ 0)
        IF (N_ELEMENTS(INDEX_CLOUD) GT 1) THEN NIR[INDEX_CLOUD] = -999 ; Replace cloud cells.
        INDEX_MIXED = BITWISE_OPERATOR(STATE, 3, 2, 1)
        IF (N_ELEMENTS(INDEX_MIXED) GT 1) THEN NIR[INDEX_MIXED] = -999 ; Replace mixed cloud cells. 
        INDEX_SHADOW = BITWISE_OPERATOR(STATE, 4, 0, 0)
        IF (N_ELEMENTS(INDEX_SHADOW) GT 1) THEN NIR[INDEX_SHADOW] = -999 ; Replace cloud shadow cells.
        ;-------------- ; ; Update last valid arrays:
        IF i EQ 0 THEN BEGIN
          last_valid_RED = MAKE_ARRAY(SIZE_DATA, /INTEGER) ; Create array to hold valid reflectance values.
          last_valid_NIR = MAKE_ARRAY(SIZE_DATA, /INTEGER) ; Create array to hold valid reflectance values.
          last_valid_RED = RED ; Set the initial values. 
          last_valid_NIR = NIR ; Set the initial values.
        ENDIF ELSE BEGIN ; Update last valid arrays:
          INDEX_VALID_RED = WHERE(RED NE -999, COUNT_VALID_RED)
          IF (N_ELEMENTS(COUNT_VALID_RED) GT 1) THEN last_valid_RED[INDEX_VALID_RED] = RED[INDEX_VALID_RED]
          INDEX_VALID_NIR = WHERE(NIR NE -999, COUNT_VALID_NIR)
          IF (N_ELEMENTS(COUNT_VALID_NIR) GT 1) THEN last_valid_NIR[INDEX_VALID_NIR] = NIR[INDEX_VALID_NIR]        
        ENDELSE
      ENDELSE
      ;----------------------------
    ENDIF ELSE BEGIN
      PRINT, '  ', STRTRIM(ROUND(SYSTIME(1)-iTime), 2), ' Seconds for date: ', $
      STRTRIM(i+1, 2), ' of ', STRTRIM(Date_Count, 2), ' (', $
      Day_String, '/', Month_String, '/', STRTRIM(Year, 2), ') ', '- One or more of the input files are missing or invalid.'
    ENDELSE
    IF Corrupted EQ 0 THEN BEGIN
      PRINT, '  ', STRTRIM(ROUND(SYSTIME(1)-iTime), 2), ' Seconds for date: ', $
      STRTRIM(i+1, 2), ' of ', STRTRIM(Date_Count, 2), ' (', $
      Day_String, '/', Month_String, '/', STRTRIM(Year, 2), ')'
    ENDIF
  ENDFOR
  ;---------------------------------------------------------------------------------------------
  ; Write: 
  ;---------------------------------------------------------------------------------------------
  IF In_Product EQ 'MOD09A1' THEN BEGIN
    ;-------------- ; Write BLUE:
    FILE_OUT = Out_Directory + 'MOD09A1.2010.Date.Zero.aust.005.b03.img' ; Set the output file name.
    OPENW, UNIT_OWL, FILE_OUT, /GET_LUN ; Create the output file.
    FREE_LUN, UNIT_OWL ; Close the new file.
    OPENU, UNIT_OWL, FILE_OUT, /GET_LUN, /APPEND ; Open the output file.
    WRITEU, UNIT_OWL, last_valid_BLUE ; Write data to file.
    FREE_LUN, UNIT_OWL ; Close the output file.
    ;-------------- ; Write SWIR2:
    FILE_OUT = Out_Directory + 'MOD09A1.2010.Date.Zero.aust.005.b06.img' ; Set the output file name.
    OPENW, UNIT_OWL, FILE_OUT, /GET_LUN ; Create the output file.
    FREE_LUN, UNIT_OWL ; Close the new file.
    OPENU, UNIT_OWL, FILE_OUT, /GET_LUN, /APPEND ; Open the output file.
    WRITEU, UNIT_OWL, last_valid_SWIR2 ; Write data to file.
    FREE_LUN, UNIT_OWL ; Close the output file.
  ENDIF ELSE BEGIN
    ;-------------- ; Write RED:
    FILE_OUT = Out_Directory + 'MOD09Q1.2010.Date.Zero.aust.005.b01.img' ; Set the output file name.
    OPENW, UNIT_OWL, FILE_OUT, /GET_LUN ; Create the output file.
    FREE_LUN, UNIT_OWL ; Close the new file.
    OPENU, UNIT_OWL, FILE_OUT, /GET_LUN, /APPEND ; Open the output file.
    WRITEU, UNIT_OWL, last_valid_RED ; Write data to file.
    FREE_LUN, UNIT_OWL ; Close the output file.
    ;-------------- ; Write NIR:
    FILE_OUT = Out_Directory + 'MOD09Q1.2010.Date.Zero.aust.005.b02.img' ; Set the output file name.
    OPENW, UNIT_OWL, FILE_OUT, /GET_LUN ; Create the output file.
    FREE_LUN, UNIT_OWL ; Close the new file.
    OPENU, UNIT_OWL, FILE_OUT, /GET_LUN, /APPEND ; Open the output file.
    WRITEU, UNIT_OWL, last_valid_NIR ; Write data to file.
    FREE_LUN, UNIT_OWL ; Close the output file.
  ENDELSE
  ;---------------------------------------------------------------------------------------------
  MINUTES = (SYSTIME(1)-T_TIME)/60 ; Get the program end time.
  HOURS = MINUTES/60
  PRINT,''
  PRINT,'Total processing time: ', STRTRIM(MINUTES, 2), ' minutes (', STRTRIM(HOURS, 2),   ' hours)'
  PRINT,''
  PRINT,'Finished processing: MODIS_AET_Get_Date_zero_with_no_gaps.pro'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
END
   