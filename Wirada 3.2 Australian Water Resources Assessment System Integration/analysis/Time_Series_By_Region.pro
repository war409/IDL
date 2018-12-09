; ##############################################################################################
; NAME: Time_Series_By_Region.pro
; LANGUAGE: IDL + ENVI
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: WfHC MDBA MBP
; DATE: 17/07/2011
; DLM: 17/07/2011
;
; DESCRIPTION:  This tool extracts cell value/s where the input grid and ENVI region of interest 
;               (ROI) intersect. Regions are defined by an ENVI ROI (.roi) file. The user may 
;               select one or more regions.
;               
;               The identified cell values are written to a user defined comma-delimited text  
;               file. The ROI ID and name, the input grid date, and filename are included.
;
; INPUT:        One or more ENVI compatible rasters. One or more regions of interest (ROI)  
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
;               
;               To identify the workspace (CWD) run the following from the IDL command line: 
;               
;               CD, CURRENT=CWD & PRINT, CWD
;               
;               For more information contact Garth.Warren@csiro.au
;
; ##############################################################################################


PRO Time_Series_By_Region
  ;---------------------------------------------------------------------------------------------
  StartTime = SYSTIME(1) ; Get the current system time.
  PRINT,''
  PRINT,'Begin Processing: Time_Series_By_Region'
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
  ; Set the output file: 
  Path='C:\Documents and Settings\war409\MODIS\'
  Out_File = DIALOG_PICKFILE(PATH=Path, TITLE='Set The Output File', DEFAULT_EXTENSION='txt', /OVERWRITE_PROMPT)
  IF Out_File EQ '' THEN BEGIN
    PRINT,'** Invalid Input **'
    RETURN ; Quit program.
  ENDIF
  ;---------------------------------------------------------------------------------------------
  ; Create the output file: 
  File_Header = MAKE_ARRAY(7, /STRING) ; Create an array to store the output file header.
  File_Header[0] = 'Cat_ID' ; Set the first element in the array (a unique ID for each row in the output file).
  File_Header[1] = 'Filename' ; Set the second element in the array (the file name of the i-th input).
  File_Header[2] = 'Days_Since'
  File_Header[3] = 'YYYY'
  File_Header[4] = 'MM'
  File_Header[5] = 'DD'
  File_Header[6] = 'LAI'
  ;--------------
  OPENW, UNIT_Out, Out_File, /GET_LUN ; Create the output file
  PRINTF, FORMAT='(10000(A,:,","))', UNIT_Out, '"' + File_Header + '"' ; Write the output file header
  FREE_LUN, UNIT_Out ; Close the output file
  ;---------------------------------------------------------------------------------------------
  ; ROI loop:  
  ;---------------------------------------------------------------------------------------------
  FOR j=0, N_ELEMENTS(ROI_Names)-1 DO BEGIN ; Loop through each input file.
    LoopStart = SYSTIME(1) ;  Get loop start time.
    
    ENVI_OPEN_FILE, In_Files[0], R_FID=FID, /NO_REALIZE ; Open a file to get file information.
    ENVI_FILE_QUERY, FID, DIMS=DIMS, NS=NS, NL=NL, NB=NB, BNAMES=BNAMES, FNAME=FNAME, DATA_TYPE=Datatype ; Get file information.
    roi_size = N_ELEMENTS(ENVI_GET_ROI_DATA(ROI_ID[ROI_Index[j]], FID=FID, POS=[0])) ; Get the count of cells in the current ROI.
    file_size = (NS*NL) ; Get the count of cells in the input file(s). 
    
    IF Datatype EQ 1 THEN Matrix_Data = MAKE_ARRAY(N_ELEMENTS(In_Files), roi_size, /BYTE) ; Byte (8 bits).
    IF Datatype EQ 2 THEN Matrix_Data = MAKE_ARRAY(N_ELEMENTS(In_Files), roi_size, /INTEGER) ; Integer (16 bits).
    IF Datatype EQ 3 THEN Matrix_Data = MAKE_ARRAY(N_ELEMENTS(In_Files), roi_size, /LONG) ; Long integer (32 bits).
    IF Datatype EQ 4 THEN Matrix_Data = MAKE_ARRAY(N_ELEMENTS(In_Files), roi_size, /FLOAT) ; Floating-point (32 bits).
    IF Datatype EQ 5 THEN Matrix_Data = MAKE_ARRAY(N_ELEMENTS(In_Files), roi_size, /DOUBLE) ; Double-precision floating-point (64 bits).
    IF Datatype EQ 6 THEN Matrix_Data = MAKE_ARRAY(N_ELEMENTS(In_Files), roi_size, /COMPLEX) ; Complex (2x32 bits).
    IF Datatype EQ 9 THEN Matrix_Data = MAKE_ARRAY(N_ELEMENTS(In_Files), roi_size, /DCOMPLEX) ; Double-precision complex (2x64 bits).
    IF Datatype EQ 12 THEN Matrix_Data = MAKE_ARRAY( N_ELEMENTS(In_Files), roi_size, /UINT) ; Unsigned integer (16 bits).
    IF Datatype EQ 13 THEN Matrix_Data = MAKE_ARRAY( N_ELEMENTS(In_Files), roi_size, /ULONG) ; Unsigned long integer (32 bits).
    IF Datatype EQ 14 THEN Matrix_Data = MAKE_ARRAY(N_ELEMENTS(In_Files), roi_size, /L64) ; Long 64-bit integer.
    IF Datatype EQ 15 THEN Matrix_Data = MAKE_ARRAY(N_ELEMENTS(In_Files), roi_size, /UL64) ; Unsigned long 64-bit integer.
    
    roiname_array = MAKE_ARRAY(N_ELEMENTS(In_Files), roi_size, /STRING) 
    fns_array = MAKE_ARRAY(N_ELEMENTS(In_Files), roi_size, /STRING) 
    days_array = MAKE_ARRAY(N_ELEMENTS(In_Files), roi_size, /FLOAT) 
    yyyy_array = MAKE_ARRAY(N_ELEMENTS(In_Files), roi_size, /STRING) 
    mm_array = MAKE_ARRAY(N_ELEMENTS(In_Files), roi_size, /STRING) 
    dd_array = MAKE_ARRAY(N_ELEMENTS(In_Files), roi_size, /STRING) 
    
    ;-------------------------------------------------------------------------------------------
    ; File loop: 
    ;-------------------------------------------------------------------------------------------
    FOR i=0, N_ELEMENTS(In_Files)-1 DO BEGIN ; Loop through each input file.      
      ;-------------- ; Manipulate dates: 
      
      datenow = Dates_Unique[i]
      
      CALDAT, datenow, iM, iD, iY ; Convert the i-th julday to calday.
      
      
      
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
      Data_ROI = ENVI_GET_ROI_DATA(ROI_ID[ROI_Index[j]], FID=FID, POS=[0]) ; Get data for the i-th file and j-th ROI.
      
      ; Add data to arrays.
      roiname_array[i,*] = RNS[j] 
      fns_array[i,*] = '"'+ FNS_In +'"' 
       
      startdate = JULDAY(1, 1, 2000) 
      dateval = TIMEGEN(1, FINAL=datenow, UNITS='Days', STEP_SIZE=1, START=startdate)
      days_since = N_Elements(dateval)
      days_array[i,*] = days_since ; STRING(STRTRIM((49+(8*i)),2)) 
      
      yyyy_array[i,*] = '"'+ YYYY +'"'
      mm_array[i,*] = '"'+ MM +'"'
      dd_array[i,*] = '"'+ DD +'"'
      Matrix_Data[i,*] = Data_ROI 
      
      ;-------------- ; Print information: 
      PRINT, '    File ', STRTRIM(i+1, 2), ' of ', STRTRIM(N_ELEMENTS(In_Files), 2), ': ROI ', $
        STRTRIM(j+1, 2), ' of ', STRTRIM(N_ELEMENTS(ROI_Names), 2)
    ENDFOR
 
    ;-------------------------------------------------------------------------------------------   
    ; Write to file: 
    OPENU, UNIT_Out, Out_File, /APPEND, /GET_LUN ; Open the output file.
    
    FOR i=0, N_ELEMENTS(In_Files)-1 DO BEGIN 
      FOR r=0, roi_size-1 DO BEGIN
        ; Write to file: 
        PRINTF, FORMAT='(10000(A,:,","))', UNIT_Out, $ 
                                            roiname_array[i,r], $ 
                                            fns_array[i,r], $ 
                                            days_array[i,r], $ 
                                            yyyy_array[i,r], $ 
                                            mm_array[i,r], $ 
                                            dd_array[i,r], $ 
                                            Matrix_Data[i,r]
      ENDFOR
    ENDFOR 
    
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
  
  EXIT, /NO_CONFIRM
  
END

