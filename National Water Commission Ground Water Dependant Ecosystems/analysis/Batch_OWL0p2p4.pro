; ##############################################################################################
; NAME: Batch_OWL0p2p4.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: NA
; DATE: 23/08/2011
; DLM: 23/08/2011
;
; DESCRIPTION:  This program calculates MOD09A1 OWL version 0.2.4.
; 
; INPUT:        One or more single-band date-sets.
;
; OUTPUT:       One single-band flat binary raster per input date-set.
;               
; PARAMETERS:   Define the parameters via in-program pop-up dialog widgets...
; 
; NOTES:        For more information contact Garth.Warren@csiro.au
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
FUNCTION mNDWI_Filename, Day, Month, Year ; Get the MOD09A1 mNDWI filename for the selected date.
  DayofYear = JULDAY(Month, Day, Year) - JULDAY(1, 1, Year) + 1
  IF DayofYear LE 9 THEN app_doy = '00'
  IF DayofYear GT 9 AND DayofYear LE 99 THEN app_doy = '0'
  IF DayofYear GT 99 THEN app_doy = ''
 
  Filenames = STRARR(1)
  Filename = strcompress('MOD09A1.aust.005.500m.' + String(Year) + '.' + app_doy + String(DayofYear) + '.mNDWI.img', /REMOVE_ALL)
  Filenames[0] = Filename

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

PRO Batch_OWL0p2p4
  ;---------------------------------------------------------------------------------------------
  StartTime = SYSTIME(1) ; Get the current system time.
  PRINT,''
  PRINT,'Begin Processing: Batch_OWL0p2p4'
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
  Path='H:\war409\MOD09A1.005\'
  In_Folder = DIALOG_PICKFILE(PATH=Path, TITLE='Select The Folder That Contains The Input Data', /MUST_EXIST, /DIRECTORY)
  ;---------------------------------------------------------------------------------------------
  ; Select the input folder:
  Path='H:\war409\MOD09A1.005.mNDWI\'
  In_mNDWI = DIALOG_PICKFILE(PATH=Path, TITLE='Select The Folder That Contains The mNDWI Data', /MUST_EXIST, /DIRECTORY)
  ;---------------------------------------------------------------------------------------------
  ; Select the MrVBF input:
  Path='\\file-wron\Working\work\Juan_Pablo\Open_Water_mapping\MrVBF\' ; SRTM.DEM.3s.01.MrVBF.Aust.500m.img
  In_MrVBF = DIALOG_PICKFILE(PATH=Path, TITLE='Select The Input MrVBF Dataset', /MUST_EXIST)
  MrVBF = READ_BINARY(In_MrVBF, DATA_TYPE=4)
  ;---------------------------------------------------------------------------------------------
  ; Set the output folder:
  Path='H:\war409\OWL2_Fill_tmp\'
  Out_Directory = DIALOG_PICKFILE(PATH=Path, TITLE='Select The Output Folder', /DIRECTORY, /OVERWRITE_PROMPT)
  IF Out_Directory EQ '' THEN RETURN ; Error check.
  ;---------------------------------------------------------------------------------------------
  ; Date loop:
  ;---------------------------------------------------------------------------------------------
  ; Get the valid 8-day dates that fall within the selected range of dates:
  SelectedDates = WHERE((All8Day GE DateStart) AND (All8Day LE DateEnd), DateCount)
  ;-------------- ; Loop through each 8-day period:
  FOR i=0, DateCount-1 DO BEGIN ; FOR i
    LoopStart = SYSTIME(1) ;  Get loop start time.
    ;-------------- ; Manipulate dates and get files:
    i8Day = SelectedDates[i]
    CALDAT, All8Day[i8Day], Month, Day, Year ; Convert Julian dates to calendar dates.
    Filenames = MOD09A1_Filenames(Day, Month, Year)
    FilemNDWI = mNDWI_Filename(Day, Month, Year)
    ;-------------- ; Get the Red band:
    Red_In = In_Folder + Filenames[0] ; Get the red band for the current date.
    Red_Exist = FILE_TEST(Red_In) ; Check if the file exists.
    IF (Red_Exist EQ 1) THEN Red = READ_BINARY(Red_In, DATA_TYPE=2) ELSE Red = -1 ; Get data.
    ;-------------- ; Get the NIR band:
    NIR_In = In_Folder + Filenames[1] ; Get the NIR band for the current date.
    NIR_Exist = FILE_TEST(NIR_In) ; Check if the file exists.
    IF (NIR_Exist EQ 1) THEN NIR = READ_BINARY(NIR_In, DATA_TYPE=2) ELSE NIR = -1 ; Get data.
    ;-------------- ; Get the SWIR2 band:
    SWIR2_In = In_Folder + Filenames[5] ; Get the MIR band for the current date.
    SWIR2_Exist = FILE_TEST(SWIR2_In) ; Check if the file exists.
    IF (SWIR2_Exist EQ 1) THEN SWIR2 = READ_BINARY(SWIR2_In, DATA_TYPE=2) ELSE SWIR2 = -1 ; Get data.
    ;-------------- ; Get the SWIR3 band:
    SWIR3_In = In_Folder + Filenames[6] ; Get the MIR band for the current date.
    SWIR3_Exist = FILE_TEST(SWIR3_In) ; Check if the file exists.
    IF (SWIR3_Exist EQ 1) THEN SWIR3 = READ_BINARY(SWIR3_In, DATA_TYPE=2) ELSE SWIR3 = -1 ; Get data.
    ;-------------- ; Get the State band:
    State_In = In_Folder + Filenames[8] ; Get the state band for the current date.
    State_Exist = FILE_TEST(State_In) ; Check if the file exists.
    IF (State_Exist EQ 1) THEN State = READ_BINARY(State_In, DATA_TYPE=12) ELSE State = -1 ; Open the f-th file.
    ;-------------- ; Get mNDWI:
    mNDWI_In = In_mNDWI + FilemNDWI[0]
    mNDWI_Exist = FILE_TEST(mNDWI_In)
    IF (mNDWI_Exist EQ 1) THEN mNDWI = READ_BINARY(mNDWI_In, DATA_TYPE=4) ELSE mNDWI = -1
    ;-------------- ; Check if any of the bands returned -1.
    IF (N_ELEMENTS(Red) EQ 1) OR (N_ELEMENTS(NIR) EQ 1) OR $
      (N_ELEMENTS(SWIR2) EQ 1) OR (N_ELEMENTS(SWIR3) EQ 1) OR (N_ELEMENTS(State) EQ 1) $
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
      ;-------------- ; Build output file
      OutputFilename = Out_Directory + Prefix + DOY_string + '.OWLv2.mNDWI.Fill' + '.img' ; Set the output filename.
      OPENW, UNIT, OutputFilename, /GET_LUN ; Create the output file.
      FREE_LUN, UNIT ; Close the output file.
      ;-----------------------------------------------------------------------------------------
      ; Set mask: 
      ;-----------------------------------------------------------------------------------------    
      Matrix_Mask = MAKE_ARRAY(N_ELEMENTS(Red), VALUE=1, /INTEGER)
      
      FillIndex = WHERE(State EQ 65535, CountFill) ; Fill cells
      IF (N_ELEMENTS(FillIndex) GT 1) THEN Matrix_Mask[FillIndex] = 0
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
      
      FillRed = WHERE(Red EQ -32768, CountFill) ; Fill cells
      IF (N_ELEMENTS(FillRed) GT 1) THEN Matrix_Mask[FillRed] = 0
      FillNIR = WHERE(NIR EQ -32768, CountFill) ; Fill cells
      IF (N_ELEMENTS(FillNIR) GT 1) THEN Matrix_Mask[FillNIR] = 0
      FillSWIR2 = WHERE(SWIR2 EQ -32768, CountFill) ; Fill cells
      IF (N_ELEMENTS(FillSWIR2) GT 1) THEN Matrix_Mask[FillSWIR2] = 0
      FillSWIR3 = WHERE(SWIR3 EQ -32768, CountFill) ; Fill cells
      IF (N_ELEMENTS(FillSWIR3) GT 1) THEN Matrix_Mask[FillSWIR3] = 0
      
      Mask = WHERE(Matrix_Mask EQ 1, Count_Mask)
      ;-----------------------------------------------------------------------------------------
      ; Calculate OWL version 2:
      ;-----------------------------------------------------------------------------------------
      NDVI = (NIR[Mask] - Red[Mask]) / (NIR[Mask] + Red[Mask] * 1.0) ; Calculate NDVI.
      NDWI = (NIR[Mask] - SWIR2[Mask]) / (NIR[Mask] + SWIR2[Mask] * 1.0) ; Calculate NDWI.
      ;-------------- ; Calculate OWL:
      Z = -3.4137561 + (-0.000959735270 * SWIR2[Mask]) + (0.00417955330 * SWIR3[Mask]) + (14.1927990 * NDVI) + (-0.430407140 * NDWI) + (-0.0961932990 * MrVBF[Mask])        
      OWL2 = 1.00 / (1 + EXP(Z)) ; Apply logistic model.
      ;-------------- ; Apply mNDWI threshold:
      IF (N_ELEMENTS(mNDWI) GT 1) THEN BEGIN
        IndexmNDWI = WHERE(mNDWI[Mask] GE 0.80, Count_HighmNDWI)
        IF (Count_HighmNDWI GT 1) THEN OWL2[IndexmNDWI] = 1.0
      ENDIF
      ;-------------- ; Convert output to byte:
      OWL2_BYTE = BYTE((OWL2 LT 255) * (OWL2+0.005) * 100.00 + (OWL2 EQ 255) * 255.00)
      ;-------------- ; Use mask to build output:
      OWL2_Out = MAKE_ARRAY(N_ELEMENTS(Red), VALUE=255, /BYTE)
      OWL2_Out[Mask] = OWL2_BYTE
      ;-------------- ; Write:
      OPENU, UNIT, OutputFilename, /GET_LUN, /APPEND ; Open the output file for editing.
      WRITEU, UNIT, OWL2_Out ; Write output data.
      FREE_LUN, UNIT ; Close the output file.
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

