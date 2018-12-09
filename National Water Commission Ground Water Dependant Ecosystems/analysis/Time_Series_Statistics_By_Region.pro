; ##############################################################################################
; NAME: Time_Series_Statistics_By_Region.pro
; LANGUAGE: IDL + ENVI
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: WfHC MDBA MBP
; DATE: 17/07/2011
; DLM: 05/09/2011
;
; DESCRIPTION:  This program calculates the mean, standard deviation, minimum, maximum, median 
;               variance, and/or sum of the input gridded data.
;
;               This tool calculates statistics by region; where the input grid and selected 
;               regions of interest (ROI) intersect. Regions are defined by an ENVI ROI (.roi) 
;               file. The user may select one or more regions.
;               
;               The statistics by region and date (input) are written to a user defined comma-
;               delimited text file. The ROI ID and name, the input grid date, and name are
;               included in addition to the user selected statistics.
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
;               FUNCTION_WIDGET_Date
;               FUNCTION_WIDGET_Set_Value_Conditional
;               FUNCTION_WIDGET_Checklist
;               
;               To identify the workspace (CWD) run the following from the IDL command line: 
;               
;               CD, CURRENT=CWD & PRINT, CWD
;               
;               For more information contact Garth.Warren@csiro.au
;
; ##############################################################################################


PRO Time_Series_Statistics_By_Region
  ;---------------------------------------------------------------------------------------------
  StartTime = SYSTIME(1) ; Get the current system time.
  PRINT,''
  PRINT,'Begin Processing: Time_Series_Statistics_By_Region'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
  ; Input/Output: 
  ;---------------------------------------------------------------------------------------------
  ; Select the input data:
  Path='C:\Documents and Settings\war409\MODIS\MOD15A2.005.MASK\'
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
  ; Set No Data:
  No_DATA = FUNCTION_WIDGET_Set_Value_Conditional(TITLE='Provide Input: No Data', ACCEPT_STRING='Set a grid value to NaN', $
    DECLINE_STRING='Do not set a grid value to NaN', DEFAULT='-999.00', /FLOAT)
  IF (No_DATA[0] NE -1) THEN NaN = No_DATA[1] ; Set NaN value.
  ;---------------------------------------------------------------------------------------------
  ; Select the input ROI: 
  Path='C:\Documents and Settings\war409\MODIS\
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
  ; Set the statistic:
  Values=['Mean', 'Standard Deviation','Variance', 'Minimum', 'Maximum', 'Median', 'Sum']
  In_Statistic = FUNCTION_WIDGET_Checklist(TITLE='Provide Input', VALUE=Values, LABEL='Select one or more statistics:')
  Statistic_Index = WHERE(In_Statistic EQ 1) 
  Statistic_String = Values[Statistic_Index] ; Get a string array containing the selected statistic names. 
  ;---------------------------------------------------------------------------------------------  
  ; Set the output file: 
  Path='C:\Documents and Settings\war409\MODIS\'
  Out_File = DIALOG_PICKFILE(PATH=Path, TITLE='Set The Output File', DEFAULT_EXTENSION='txt', /OVERWRITE_PROMPT)
  IF Out_File EQ '' THEN BEGIN
    PRINT,'** Invalid Input **'
    RETURN ; Quit program.
  ENDIF
  ;---------------------------------------------------------------------------------------------
  ; Create the output file: 
  File_Header = MAKE_ARRAY((N_ELEMENTS(ROI_Names)*(N_ELEMENTS(Statistic_String)))+6, /STRING) ; Create an array to store the output file header.
  File_Header[0] = 'Days_Since' ; Set the first element in the array (a unique ID for each row in the output file).
  File_Header[1] = 'Filename' ; Set the second element in the array (the file name of the i-th input).
  File_Header[2] = 'YYYYMMDD' ; Set the third element in the array (the date of the i-th input).  
  File_Header[3] = 'YYYY'
  File_Header[4] = 'MM'
  File_Header[5] = 'DD'
  
  FOR a=0, N_ELEMENTS(ROI_Names)-1 DO BEGIN ; Fill the output header array:
    IF a EQ 0 THEN b=6 ELSE b=b+N_ELEMENTS(Statistic_String) ; Update the array position index.
    File_Header[b] += RNS[a] ; + '_' + Statistic_String[c] ; Add the ROI and statistic names to the array.
  ENDFOR
  OPENW, UNIT_Out, Out_File, /GET_LUN ; Create the output file.
  PRINTF, FORMAT='(10000(A,:,","))', UNIT_Out, '"' + File_Header + '"' ; Write the output file header.
  FREE_LUN, UNIT_Out ; Close the output file.
  ;---------------------------------------------------------------------------------------------
  ; File loop: 
  ;---------------------------------------------------------------------------------------------    
  FOR i=0, N_ELEMENTS(In_Files)-1 DO BEGIN ; Loop through each input file.
    LoopStart = SYSTIME(1) ;  Get loop start time.
    ;-------------- ; Manipulate dates:
    CALDAT, Dates_Unique[i], iM, iD, iY ; Convert the i-th julday to calday.
    IF (iM LE 9) THEN M_String = '0' + STRING(STRTRIM(iM,2)) ELSE M_String = STRING(STRTRIM(iM,2))  ; Add leading zero.
    IF (iD LE 9) THEN D_String = '0' + STRING(STRTRIM(iD,2)) ELSE D_String = STRING(STRTRIM(iD,2))  ; Add leading zero.
    
    YYYY = STRING(STRTRIM(iY,2)) 
    MM = STRING(STRTRIM(iM,2)) 
    DD = STRING(STRTRIM(iD,2)) 
    
    Date_String = STRING(STRTRIM(iY,2)) + M_String + D_String    
    Date_Index = WHERE(In_Dates EQ Dates_Unique[i], Count) ; Get file index.
    IF Count GT 1 THEN RETURN ; Error check.
    File_In = In_Files[Date_Index] ; Get file.
    FNS_In = FNS[Date_Index] ; Get file short.  
    ;-------------- ; Get data:
    ENVI_OPEN_FILE, File_In, R_FID=FID, /NO_REALIZE ; Open the i-th file.
    ENVI_FILE_QUERY, FID, DIMS=DIMS, NS=NS, NL=NL, NB=NB, BNAMES=BNAMES, FNAME=FNAME, DATA_TYPE=Datatype ; Get file information.
    ;-------------- ; Create arrays to hold input data:
    ;Matrix_Combined = MAKE_ARRAY(N_ELEMENTS(ROI_Names), 2, /FLOAT) ; Create array to hold combined ROI statistics.
    Matrix_Statistics = MAKE_ARRAY(N_ELEMENTS(ROI_Names), N_ELEMENTS(Statistic_String), /FLOAT) ; Create array to hold ROI statistics.
    ;Matrix_CellCount = MAKE_ARRAY(N_ELEMENTS(ROI_Names), /FLOAT) ; Create array to hold the count of cells in each ROI.
    ;Matrix_ValidCount = MAKE_ARRAY(N_ELEMENTS(ROI_Names), /FLOAT) ; Create array to hold the count of non NaN (valid) cells in each ROI.
    ;Matrix_NaNCount = MAKE_ARRAY( N_ELEMENTS(ROI_Names), /FLOAT) ; Create array to hold the count of NaN cells in each ROI.
    ;-------------------------------------------------------------------------------------------
    ; ROI loop: 
    ;-------------------------------------------------------------------------------------------
    FOR j=0, N_ELEMENTS(ROI_Names)-1 DO BEGIN ; Loop through each input file.
      Data_ROI = ENVI_GET_ROI_DATA(ROI_ID[ROI_Index[j]], FID=FID, POS=[0]) ; Get data for the i-th file and j-th ROI.
      IF (Datatype NE 4) OR (Datatype NE 4) THEN Data_ROI = FLOAT(Data_ROI) ; Convert to floating point.
      ;-------------- ; Set NaN:
      IF (No_DATA[0] NE -1) THEN BEGIN
        n = WHERE(Data_ROI EQ FLOAT(NaN), NaN_Count)
        IF (NaN_Count GT 0) THEN Data_ROI[n] = !VALUES.F_NAN
      ENDIF
      ;-------------- ; Get information:
      Data_Sum = TOTAL(Data_ROI, 1, /NAN) ; The sum of values in the ROI.
      Data_CellCount = N_ELEMENTS(Data_ROI) ; The count of cells in the ROI.
      Data_ValidCount = TOTAL(FINITE(Data_ROI), 1) ; The count of non-NaN cells in the ROI.
      Data_NaNCount = Data_CellCount - Data_ValidCount ; The count of NaN cells in the ROI.
      ;-------------- ; Add data to arrays:
      ;Matrix_Combined[j,0] = Data_Sum
      ;Matrix_Combined[j,1] = Data_ValidCount
      ;Matrix_CellCount[j] = Data_CellCount
      ;Matrix_ValidCount[j] = Data_ValidCount
      ;Matrix_NaNCount[j] = Data_NaNCount
      ;-----------------------------------------------------------------------------------------
      ; Calculate statistics: 
      ;-----------------------------------------------------------------------------------------
      FOR k=0, N_ELEMENTS(Statistic_String)-1 DO BEGIN
        IF Statistic_String[k] EQ 'Mean' THEN Matrix_Statistics[j] = MEAN(Data_ROI, /NAN)
        IF Statistic_String[k] EQ 'Standard Deviation' THEN BEGIN
          IF Data_ValidCount LT 2 THEN Matrix_Statistics[j] = !VALUES.F_NAN ELSE Matrix_Statistics[j] =  STDDEV(Data_ROI, /NAN)
        ENDIF
        IF Statistic_String[k] EQ 'Variance' THEN BEGIN
          IF Data_ValidCount LT 2 THEN Matrix_Statistics[j] = !VALUES.F_NAN ELSE Matrix_Statistics[j] = VARIANCE(Data_ROI, /NAN)
        ENDIF
        IF Statistic_String[k] EQ 'Minimum' THEN Matrix_Statistics[j] = MIN(Data_ROI, /NAN)
        IF Statistic_String[k] EQ 'Maximum' THEN Matrix_Statistics[j] = MAX(Data_ROI, /NAN)
        IF Statistic_String[k] EQ 'Median' THEN Matrix_Statistics[j] = MEDIAN(Data_ROI, /EVEN)
        IF Statistic_String[k] EQ 'Sum' THEN Matrix_Statistics[j] = TOTAL(Data_ROI, 1, /NAN)
      ENDFOR
      ;-------------- ; Print information:
      PRINT, '    File ', STRTRIM(i+1, 2), ' of ', STRTRIM(N_ELEMENTS(In_Files), 2), ': ROI ', $
        STRTRIM(j+1, 2), ' of ', STRTRIM(N_ELEMENTS(ROI_Names), 2)
    ENDFOR
    ;-------------------------------------------------------------------------------------------
    ; Calculate combined (all ROI per file) statistics: 
    ;Combined_Sum = TOTAL(Matrix_Combined[*,0], 1, /NAN) ; The combined ROI sum.
    ;Combined_ValidCount = TOTAL(Matrix_Combined[*,1], 1, /NAN) ; The count of non-NaN cells in all ROIs combined. 
    ;Combined_NaNCount = TOTAL(Matrix_NaNCount, 1, /NAN) ; The count of NaN cells in all ROIs combined.
    ;Combined_Mean = (Combined_Sum / Combined_ValidCount) ; The combined ROI mean.
    ;-------------- ; Set output:
    OPENU, UNIT_Out, Out_File, /APPEND, /GET_LUN ; Open the output file.
    Matrix_Out = MAKE_ARRAY(N_ELEMENTS(ROI_Names)*(N_ELEMENTS(Statistic_String)), /FLOAT) ; Create an array to hold output data.
    
    FOR a=0, N_ELEMENTS(ROI_Names)-1 DO BEGIN ; Fill the output array:
      IF a EQ 0 THEN b=0 ELSE b=b+N_ELEMENTS(Statistic_String) ; Update counter.
      ; FILL
      ;Matrix_Out[b] += Matrix_ValidCount[a]
      ;Matrix_Out[b+1] += Matrix_NaNCount[a]
      FOR c=0, N_ELEMENTS(Statistic_String)-1 DO BEGIN
        Matrix_Out[b+c] += Matrix_Statistics[a,c]
      ENDFOR
    ENDFOR
    
    ; Write to file: 
    PRINTF, FORMAT='(10000(A,:,","))', UNIT_Out, STRING(STRTRIM((49+(8*i)),2)), $ 
                                        '"'+ FNS_In +'"', $ 
                                        '"'+ Date_String +'"', $ 
                                        '"'+ YYYY +'"', $ 
                                        '"'+ MM +'"', $ 
                                        '"'+ DD +'"', $ 
                                        STRTRIM(Matrix_Out, 2) 
    
    FREE_LUN, UNIT_Out ; Close the output file.
    ;-------------------------------------------------------------------------------------------
    Minutes = (SYSTIME(1)-LoopStart)/60 ; Get the file loop end time.
    PRINT, '  Processing Time: ', STRTRIM(Minutes, 2), ' minutes, for file ', STRTRIM(i+1, 2), $
      ' of ', STRTRIM(In_Files, 2)
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

