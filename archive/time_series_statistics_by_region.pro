; ##############################################################################################
; NAME: time_series_statistics_by_region.pro
; LANGUAGE: IDL + ENVI
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: WIRADA 3.2 Activity 1
; DATE: 17/07/2011
; DLM: 26/09/2011
;
; DESCRIPTION:  This program calculates the of the input gridded data.
;
;               This tool calculates statistics by region; where the input grid and selected 
;               regions of interest (ROI) intersect. Regions are defined by an ENVI ROI (.roi) 
;               file. The user may select one or more regions.
;               
;               The statistics by region and date (input) are written to a user defined comma-
;               delimited text file. The ROI name, and the input grid dates are included in
;               addition to the selected statistics.
;
; INPUT:        Two or more ENVI compatible rasters. One or more regions of interest (ROI)  
;               defined in an ENVI .roi file.
;
; OUTPUT:       One comma-delimited text file. The output file (inc. hearder information) is 
;               formatted dynamically depending on the selected regions and statistics.
;
; PARAMETERS:   Via pop-up dialog widgets.
;   
; NOTES:        This program calls one or more external functions. You will need to compile the  
;               necessary functions in IDL, or save the functions to the current IDL workspace  
;               prior to running this tool.
;               
;               FUNCTION_WIDGET_Set_Value_Conditional
;               
;               To identify the workspace (CWD) run the following from the IDL command line: 
;               
;               CD, CURRENT=CWD & PRINT, CWD
;               
;               For more information contact Garth.Warren@csiro.au
;
; ##############################################################################################


PRO time_series_statistics_by_region
  ;---------------------------------------------------------------------------------------------
  StartTime = SYSTIME(1) ; Get the current system time.
  PRINT,''
  PRINT,'Begin Processing: time_series_statistics_by_region'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
  ; Input/Output:
  ;---------------------------------------------------------------------------------------------
  ; Set the analysis date range:
  DateStart = JULDAY(1, 1, 1980)
  DateEnd   = JULDAY(12, 31, 2008)
  ;---------------------------------------------------------------------------------------------
  ; Select the input folder:
  Path='\\wron\Working\WIRADA\AWRA_data\NWA11Calibration\working\EXP5\AWAP\rain\'
  In_Folder = DIALOG_PICKFILE(PATH=Path, TITLE='Select The Folder That Contains The Input Data', /MUST_EXIST, /DIRECTORY)
  ;---------------------------------------------------------------------------------------------
  ; Set No Data:
  No_DATA = FUNCTION_WIDGET_Set_Value_Conditional(TITLE='Provide Input: No Data', ACCEPT_STRING='Set a grid value to NaN', $
    DECLINE_STRING='Do not set a grid value to NaN', DEFAULT='-999.00', /FLOAT)
  IF (No_DATA[0] NE -1) THEN NaN = No_DATA[1] ; Set NaN value.
  ;---------------------------------------------------------------------------------------------
  ; Select the input ROI:
  Path='\\wron\Working\work\war409\work\wfhc\wirada\32\activity_one\data\vector\roi\
  In_ROI = DIALOG_PICKFILE(PATH=Path, TITLE='Select The Input ROI', FILTER='*.roi', /MUST_EXIST)
  IF In_ROI EQ '' THEN BEGIN
    PRINT,'** Invalid Input **'
    RETURN ; Quit program.
  ENDIF
  ;-------------- ; Open the selected ROI:
  ENVI_RESTORE_ROIS, In_ROI
  ROI_ID = ENVI_GET_ROI_IDS(ROI_NAMES=ROI_Names, /SHORT_NAME) ; Get the ROI ID.
  ;-------------- ; Select one or more ROI: ENVI widget.
  Base = WIDGET_AUTO_BASE(TITLE='Select One Or More ROI')
  WM = WIDGET_MULTI(Base, LIST=ROI_Names, UVALUE='LIST', /AUTO)
  Select_ROI = AUTO_WID_MNG(Base)
  IF (Select_ROI.ACCEPT EQ 0) THEN RETURN  ; Error check.
  ROI_Index = WHERE(Select_ROI.LIST EQ 1) ; Get ROI index.
  ROI_Names = ROI_Names[ROI_Index] ; Get the selected ROI names.
  ROI_Start = STRPOS(ROI_Names, '=', /REVERSE_SEARCH)+1 ; Get the ROI names start index.
  ROI_Length = (STRLEN(ROI_Names)-ROI_Start)-1 ; Get the length of ROI names.
  RNS = MAKE_ARRAY(1, N_ELEMENTS(ROI_Names), /STRING) ; Create an array to store the selected input ROI names.
  FOR a=0, N_ELEMENTS(ROI_Names)-1 DO BEGIN ; Fill the ROI name array:
    RNS[*,a] += STRMID(ROI_Names[a], ROI_Start[a], ROI_Length[a]) ; Get the current ROI name and trim excess characters.
  ENDFOR 
  ;---------------------------------------------------------------------------------------------
  ; Set the output file:
  Path='\\wron\Working\work\war409\work\wfhc\wirada\32\activity_one\data\'
  Out_File = DIALOG_PICKFILE(PATH=Path, TITLE='Set The Output File', DEFAULT_EXTENSION='txt', /OVERWRITE_PROMPT)
  IF Out_File EQ '' THEN BEGIN
    PRINT,'** Invalid Input **'
    RETURN ; Quit program.
  ENDIF
  ;---------------------------------------------------------------------------------------------
  ; Create the output file:
  File_Header = MAKE_ARRAY((N_ELEMENTS(ROI_Names)+3), /STRING) ; Create an array to store the output file header.
  File_Header[0] = 'YYYY' ; Set the first element in the array (year).
  File_Header[1] = 'MM' ; Set the second element in the array (month).
  File_Header[2] = 'DD' ; Set the third element in the array (day).
  FOR a=0, N_ELEMENTS(ROI_Names)-1 DO BEGIN ; Fill the output header array:
    IF a EQ 0 THEN b=3 ELSE b=b+1 ; Update the array position index.
    File_Header[b] += RNS[a]
  ENDFOR
  OPENW, UNIT_Out, Out_File, /GET_LUN ; Create the output file.
  PRINTF, FORMAT='(10000(A,:,","))', UNIT_Out, File_Header ; Write the output file header.
  FREE_LUN, UNIT_Out ; Close the output file.
  ;---------------------------------------------------------------------------------------------
  ; Date loop:
  ;---------------------------------------------------------------------------------------------
  DateCount = DateEnd - DateStart ; Get the count of days between the start and end dates.
  FOR i=0, DateCount-1 DO BEGIN ; Loop through each input file.
    LoopStart = SYSTIME(1) ;  Get loop start time.
    ;-------------- ; Manipulate dates:
    iDate = DateStart + i
    CALDAT, iDate, iM, iD, iY ; Convert the i-th julday to calday.
    MM = STRING(STRTRIM(iM,2))
    DD = STRING(STRTRIM(iD,2))
    YYYY = STRING(STRTRIM(iY,2))
    IF iM LE 9 THEN MM = '0' + MM
    IF iD LE 9 THEN DD = '0' + DD
    Date_String = YYYY + MM + DD
    DayofYear = JULDAY(iM, iD, iY) - JULDAY(1, 1, iY) + 1
    IF DayofYear LE 9 THEN app_doy = '00'
    IF DayofYear GT 9 AND DayofYear LE 99 THEN app_doy = '0'
    IF DayofYear GT 99 THEN app_doy = ''
    DOY_String = YYYY + app_doy + String(STRTRIM(DayofYear,2))
    ;-------------- ; Build input filename:
    File_In = In_Folder + '\' + YYYY + '\' + 'rr.' + Date_String + Date_String + '.flt'
    File_Exist = FILE_TEST(File_In) ; Check if the file exists.
    IF (File_Exist EQ 1) THEN BEGIN 
      ;-------------- ; Get data:
      ENVI_OPEN_FILE, File_In, R_FID=FID, /NO_REALIZE ; Open the i-th file.
      ENVI_FILE_QUERY, FID, DIMS=DIMS, NS=NS, NL=NL, NB=NB, BNAMES=BNAMES, FNAME=FNAME, DATA_TYPE=Datatype ; Get file information.
      ;-------------- ; Create array to hold input data:
      Matrix_Mean = MAKE_ARRAY(N_ELEMENTS(ROI_Names), /FLOAT) ; Create array to hold ROI statistics.
      ;-------------------------------------------------------------------------------------------
      ; ROI loop:
      ;-------------------------------------------------------------------------------------------
      FOR j=0, N_ELEMENTS(ROI_Names)-1 DO BEGIN ; Loop through each input file.
        Data_ROI = ENVI_GET_ROI_DATA(ROI_ID[ROI_Index[j]], FID=FID, POS=[0]) ; Get data for the i-th file and j-th ROI.
        IF (Datatype NE 4) OR (Datatype NE 5) THEN Data_ROI = FLOAT(Data_ROI) ; Convert to floating point.
        ;-------------- ; Set NaN:
        IF (No_DATA[0] NE -1) THEN BEGIN
          n = WHERE(Data_ROI EQ FLOAT(NaN), NaN_Count)
          IF (NaN_Count GT 0) THEN Data_ROI[n] = !VALUES.F_NAN
        ENDIF
        ;-------------- ; Calculate mean:
        Matrix_Mean[j] = MEAN(Data_ROI, /NAN)
        ;-------------- ; Replace NaN with -9999
        m = WHERE(FINITE(Matrix_Mean, /NAN), NaN_Count2) 
        IF (NaN_Count2 GT 0) THEN Matrix_Mean[m] = -9999
      ENDFOR
      ;-------------------------------------------------------------------------------------------
      ; Write:
      OPENU, UNIT_Out, Out_File, /APPEND, /GET_LUN ; Open the output file.
      PRINTF, FORMAT='(10000(A,:,","))', UNIT_Out, YYYY, MM, DD, STRTRIM(Matrix_Mean, 2)
      FREE_LUN, UNIT_Out ; Close the output file.
    ENDIF
    ;-------------------------------------------------------------------------------------------
    Seconds = (SYSTIME(1)-LoopStart) ; Get the file loop end time.
    PRINT, '  Processing Time: ', STRTRIM(Seconds, 2), ' seconds, for date ', STRTRIM(i+1, 2),' of ', STRTRIM(DateCount, 2)
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

