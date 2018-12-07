; ##############################################################################################
; Name: threshold.pro 
; Language: IDL 
; Author: Garth Warren 
; Date: 03/10/2012 
; DLM: 03/10/2012 
; 
; Description: This tool applies a threshold to the user selected input data via a user defined 
;              relational statement. For each input: cells that conform to the statement are
;              are given a value of 1; values that do not conform to the statement are given a 
;              value of 0.
;
;              For example, say the input data contains values from 0.0 to 1.0 however the user 
;              is only interested in values that are greater than 0.5. By defining the relational
;              statement as ‘Event GT 0.5’ the tool will identify those values that satisfy the 
;              criteria and give them a value of 1 in the output, while a value of 0 is applied
;              to those cells that do not meet the criteria.
;
;              The statement may contain up to two user-selected operators; e.g. the relational 
;              statement ‘Event GT 0.5’ AND ‘Event LE 0.75’ will identify those values in the 
;              input that have a cell value of more than 0.5 but less than or equal to 0.75.
;
;              Similarly, ‘Event GT 0.5’ OR ‘Event LE 0.25’ identifies values greater than 50 
;              and values less than or equal to 0.25.
;          
; Input:        One or more single band gridded files.
;
; Output:       One single flat binary file (.img) of the user selected data type per input. 
;               
; Arguments:    Via in=program pop-up dialog widgets.
;               
;               1.    Select The Input Data
;               
;               2.    Select The Output Directory
;               
;               3.    Select The Input Datatype
;                     
;               4.    Select The Desired Output Datatype          
;               
;               5.    Define An Input No-Data Value
;               
;               6.    Set The Relational Statement
;              
; Notes:        This program calls one or more external functions. You will need to compile the  
;               necessary functions in IDL, or save the functions to the current IDL workspace  
;               prior to running this tool.
;               
;               FUNCTION_WIDGET_Droplist
;               FUNCTION_WIDGET_Set_Value_Conditional
;               FUNCTION_WIDGET_Set_Relational_Statement
;               
;               To identify the workspace (CWD) run the following from the IDL command line: 
;               
;               CD, CURRENT=CWD & PRINT, CWD
;               
;               For more information contact Garth.Warren@csiro.au 
; 
; ##############################################################################################




; **********************************************************************************************
PRO threshold
  time = SYSTIME(1) ; Get the procedure start time.
  
  ;*********************************************************************************************
  ; Set the input arguments: 
  ;*********************************************************************************************
  
  input_folder = '\\wron\Working\' ; Set the input directory.
  output_folder = '\\wron\Working\' ; Set the output directory.
  
  
  ;---------------------------------------------------------------------------------------------
  ; Select the input data: 
  ;---------------------------------------------------------------------------------------------
  
  
  files = DIALOG_PICKFILE(PATH='C:\Documents and Settings\war409\My Documents\', $
                           TITLE='Select The Input Data', $
                           FILTER=['*rain_s1102_200104*', '*rain_s1102_201001.img', '*rad01.csv'], $ 
                           ; FILTER=['*.tif','*.img','*.flt','*.bin'], $
                           /MUST_EXIST, $
                           /MULTIPLE_FILES) 
                           
                           
                           
  IF files[0] EQ '' THEN RETURN ; Error check.
  
  files = files[SORT(files)] ; Sort the input file list.
  start = STRPOS(files, '\', /REVERSE_SEARCH)+1 ; Get the position of the first file name character (after the file path).
  length = (STRLEN(files)-start)-4 ; Get the length of each path-less file name.
  filenames = MAKE_ARRAY(N_ELEMENTS(files), /STRING) ; Create an array to store the input file names.
  
  FOR a=0, N_ELEMENTS(files)-1 DO BEGIN ; Remove the file path from the input file names.
    filenames[a] = STRMID(files[a], start[a], length[a]) ; Get the a-the file name (trim away the file path).
  ENDFOR
  
  ;---------------------------------------------------------------------------------------------
  ; Select the output directory: 
  ;---------------------------------------------------------------------------------------------
  
  output_directory = DIALOG_PICKFILE(PATH=output_folder, TITLE='Define The Output File', $ 
                                       /OVERWRITE_PROMPT, /DIRECTORY) 
                                       
  IF output_directory EQ '' THEN RETURN ; Error check.
  
  ;---------------------------------------------------------------------------------------------
  ; Select the input datatype: 
  ;---------------------------------------------------------------------------------------------
  
  datatype = FUNCTION_WIDGET_Droplist(TITLE='Select Input Datatype:', $ 
    VALUE=['0 : UNDEFINED : Undefined', '1 : BYTE : Byte', $
    '2 : INT : Integer', '3 : LONG : Longword integer', '4 : FLOAT : Floating point', $
    '5 : DOUBLE : Double-precision floating', '6 : COMPLEX : Complex floating', $
    '7 : STRING : String', '8 : STRUCT : Structure', '9 : DCOMPLEX : Double-precision complex', $
    '10 : POINTER : Pointer', '11 : OBJREF : Object reference', '12 : UINT : Unsigned Integer', $
    '13 : ULONG : Unsigned Longword Integer', '14 : LONG64 : 64-bit Integer', $
    '15 : ULONG64 : Unsigned 64-bit Integer']) 
  
  IF (datatype EQ 7) OR (datatype EQ 8) OR (datatype EQ 9) OR (datatype EQ 10) OR (datatype EQ 11) THEN BEGIN 
    PRINT,'** Invalid Data Type **'
    RETURN ; Quit program.
  ENDIF 
  
  ;---------------------------------------------------------------------------------------------
  ; Select the output datatype: 
  ;---------------------------------------------------------------------------------------------

  output_datatype = FUNCTION_WIDGET_Droplist(TITLE='Select Output Datatype:', VALUE=['0 : UNDEFINED : Undefined', '1 : BYTE : Byte', $
    '2 : INT : Integer', '3 : LONG : Longword integer', '4 : FLOAT : Floating point', $
    '5 : DOUBLE : Double-precision floating', '6 : COMPLEX : Complex floating', $
    '7 : STRING : String', '8 : STRUCT : Structure', '9 : DCOMPLEX : Double-precision complex', $
    '10 : POINTER : Pointer', '11 : OBJREF : Object reference', '12 : UINT : Unsigned Integer', $
    '13 : ULONG : Unsigned Longword Integer', '14 : LONG64 : 64-bit Integer', $
    '15 : ULONG64 : Unsigned 64-bit Integer'])
  
  IF (output_datatype EQ 7) OR (output_datatype EQ 8) OR (output_datatype EQ 9) OR (output_datatype EQ 10) OR (output_datatype EQ 11) THEN BEGIN
    PRINT,'** Invalid Data Type **'
    RETURN ; Quit program.
  ENDIF
  
  ;---------------------------------------------------------------------------------------------
  ; Set the no-data value: 
  ;---------------------------------------------------------------------------------------------
  
  nodata = FUNCTION_WIDGET_Set_Value_Conditional(TITLE='Provide Input: No Data', $
                                                      ACCEPT_STRING='Set a grid value to NaN', $
                                                      DECLINE_STRING='Do not set a grid value to NaN', $
                                                      DEFAULT='-9999.00', /FLOAT) 
                                                      
  IF (nodata[0] NE -1) THEN NaN = nodata[1] ; Set the NaN value.

  ;---------------------------------------------------------------------------------------------
  ; Set the relational statement: 
  ;---------------------------------------------------------------------------------------------

  ; Set the relational operation parameters.
  statement = FUNCTION_WIDGET_Set_Relational_Statement(TITLE='Set: Relational Statement', $ 
                                                            DEFAULT_A='25', DEFAULT_B='75') 
  
  IF statement[0] EQ -1 THEN BEGIN ; Error check.
    PRINT,'** Invalid Selection **'
    RETURN ; Quit program.
  ENDIF
  
  ; Set the results.
  operators = ['EQ','LE','LT','GE','GT','NE']
  options = ['---','AND','OR']
  operator_A = operators[statement[0]] 
  value_A = statement[1] 
  
  IF statement[2] NE -1 THEN operator_B = options[statement[2]] ELSE operator_B = -1
  IF statement[2] NE -1 THEN operator_C = operators[statement[3]] ELSE operator_C = -1
  IF statement[2] NE -1 THEN value_B = statement[4] ELSE value_B = -1
  
  ; Print the statement to the console.
  IF statement[2] EQ -1 THEN PRINT,'statement: (Event ', operator_A, ' ', $
                              STRTRIM(value_A, 2),')' ELSE PRINT, 'Statement:  (Event  ', $
                              operator_A, '  ', STRTRIM(value_A, 2), ')  ', operator_B, $ 
                              '  (Event  ', operator_C, '  ', STRTRIM(value_B, 2), ')' 
  
  ;*********************************************************************************************
  ; Apply the selected threshold: 
  ;*********************************************************************************************
  
  ;-------------------------------------------------------------------------------------------
  ; File loop: 
  ;-------------------------------------------------------------------------------------------
  
  FOR i=0, N_ELEMENTS(files)-1 DO BEGIN ; Loop through each input file.
    StartTime = SYSTIME(1) ;  Get loop start time.
    
    data = READ_BINARY(files[i], DATA_TYPE=datatype) ; Open the i-th file.
    
    ;-----------------------------------------------------------------------------------------
    ; Apply threshold (single statement): 
    ;-----------------------------------------------------------------------------------------
    
    IF operator_B EQ -1 THEN BEGIN ; '---'      
      IF In_NaN[0] NE -1 THEN BEGIN  ; No-Data is set.
        IF operator_A EQ 'EQ' THEN matrix = ((data EQ value_A) AND (data NE In_NaN[1]))
        IF operator_A EQ 'LE' THEN matrix = ((data LE value_A) AND (data NE In_NaN[1]))
        IF operator_A EQ 'LT' THEN matrix = ((data LT value_A) AND (data NE In_NaN[1]))
        IF operator_A EQ 'GE' THEN matrix = ((data GE value_A) AND (data NE In_NaN[1]))
        IF operator_A EQ 'GT' THEN matrix = ((data GT value_A) AND (data NE In_NaN[1]))
        IF operator_A EQ 'NE' THEN matrix = ((data NE value_A) AND (data NE In_NaN[1]))
        Matrix_Count = (data NE In_NaN[1]) ; Non-no-data values.
      ENDIF ELSE BEGIN ; No-Data is NOT set.
        IF operator_A EQ 'EQ' THEN matrix = (data EQ value_A)
        IF operator_A EQ 'LE' THEN matrix = (data LE value_A) 
        IF operator_A EQ 'LT' THEN matrix = (data LT value_A)
        IF operator_A EQ 'GE' THEN matrix = (data GE value_A)
        IF operator_A EQ 'GT' THEN matrix = (data GT value_A)
        IF operator_A EQ 'NE' THEN matrix = (data NE value_A)
      ENDELSE
    ENDIF 
    
    ;----------------------------------------------------------------------------------------- 
    ; Apply threshold (double statement AND): 
    ;-----------------------------------------------------------------------------------------
    
    IF operator_B EQ 1 THEN BEGIN ; 'AND'
      IF In_NaN[0] NE -1 THEN BEGIN  ; No-data is set.
        
        IF operator_A EQ 'EQ' THEN BEGIN 
          IF operator_C EQ 'EQ' THEN matrix = (((data EQ value_A) AND (data EQ value_B)) AND (data NE In_NaN[1])) 
          IF operator_C EQ 'LE' THEN matrix = (((data EQ value_A) AND (data LE value_B)) AND (data NE In_NaN[1]))
          IF operator_C EQ 'LT' THEN matrix = (((data EQ value_A) AND (data LT value_B)) AND (data NE In_NaN[1]))
          IF operator_C EQ 'GE' THEN matrix = (((data EQ value_A) AND (data GE value_B)) AND (data NE In_NaN[1]))
          IF operator_C EQ 'GT' THEN matrix = (((data EQ value_A) AND (data GT value_B)) AND (data NE In_NaN[1]))
          IF operator_C EQ 'NE' THEN matrix = (((data EQ value_A) AND (data NE value_B)) AND (data NE In_NaN[1]))   
        ENDIF
        
        IF operator_A EQ 'LE' THEN BEGIN 
          IF operator_C EQ 'EQ' THEN matrix = (((data LE value_A) AND (data EQ value_B)) AND (data NE In_NaN[1])) 
          IF operator_C EQ 'LE' THEN matrix = (((data LE value_A) AND (data LE value_B)) AND (data NE In_NaN[1]))
          IF operator_C EQ 'LT' THEN matrix = (((data LE value_A) AND (data LT value_B)) AND (data NE In_NaN[1]))
          IF operator_C EQ 'GE' THEN matrix = (((data LE value_A) AND (data GE value_B)) AND (data NE In_NaN[1]))
          IF operator_C EQ 'GT' THEN matrix = (((data LE value_A) AND (data GT value_B)) AND (data NE In_NaN[1]))
          IF operator_C EQ 'NE' THEN matrix = (((data LE value_A) AND (data NE value_B)) AND (data NE In_NaN[1]))   
        ENDIF
        
        IF operator_A EQ 'LT' THEN BEGIN 
          IF operator_C EQ 'EQ' THEN matrix = (((data LT value_A) AND (data EQ value_B)) AND (data NE In_NaN[1])) 
          IF operator_C EQ 'LE' THEN matrix = (((data LT value_A) AND (data LE value_B)) AND (data NE In_NaN[1]))
          IF operator_C EQ 'LT' THEN matrix = (((data LT value_A) AND (data LT value_B)) AND (data NE In_NaN[1]))
          IF operator_C EQ 'GE' THEN matrix = (((data LT value_A) AND (data GE value_B)) AND (data NE In_NaN[1]))
          IF operator_C EQ 'GT' THEN matrix = (((data LT value_A) AND (data GT value_B)) AND (data NE In_NaN[1]))
          IF operator_C EQ 'NE' THEN matrix = (((data LT value_A) AND (data NE value_B)) AND (data NE In_NaN[1]))   
        ENDIF
        
        IF operator_A EQ 'GE' THEN BEGIN 
          IF operator_C EQ 'EQ' THEN matrix = (((data GE value_A) AND (data EQ value_B)) AND (data NE In_NaN[1])) 
          IF operator_C EQ 'LE' THEN matrix = (((data GE value_A) AND (data LE value_B)) AND (data NE In_NaN[1]))
          IF operator_C EQ 'LT' THEN matrix = (((data GE value_A) AND (data LT value_B)) AND (data NE In_NaN[1]))
          IF operator_C EQ 'GE' THEN matrix = (((data GE value_A) AND (data GE value_B)) AND (data NE In_NaN[1]))
          IF operator_C EQ 'GT' THEN matrix = (((data GE value_A) AND (data GT value_B)) AND (data NE In_NaN[1]))
          IF operator_C EQ 'NE' THEN matrix = (((data GE value_A) AND (data NE value_B)) AND (data NE In_NaN[1]))   
        ENDIF
        
        IF operator_A EQ 'GT' THEN BEGIN 
          IF operator_C EQ 'EQ' THEN matrix = (((data GT value_A) AND (data EQ value_B)) AND (data NE In_NaN[1])) 
          IF operator_C EQ 'LE' THEN matrix = (((data GT value_A) AND (data LE value_B)) AND (data NE In_NaN[1]))
          IF operator_C EQ 'LT' THEN matrix = (((data GT value_A) AND (data LT value_B)) AND (data NE In_NaN[1]))
          IF operator_C EQ 'GE' THEN matrix = (((data GT value_A) AND (data GE value_B)) AND (data NE In_NaN[1]))
          IF operator_C EQ 'GT' THEN matrix = (((data GT value_A) AND (data GT value_B)) AND (data NE In_NaN[1]))
          IF operator_C EQ 'NE' THEN matrix = (((data GT value_A) AND (data NE value_B)) AND (data NE In_NaN[1]))   
        ENDIF
        
        IF operator_A EQ 'NE' THEN BEGIN 
          IF operator_C EQ 'EQ' THEN matrix = (((data NE value_A) AND (data EQ value_B)) AND (data NE In_NaN[1])) 
          IF operator_C EQ 'LE' THEN matrix = (((data NE value_A) AND (data LE value_B)) AND (data NE In_NaN[1]))
          IF operator_C EQ 'LT' THEN matrix = (((data NE value_A) AND (data LT value_B)) AND (data NE In_NaN[1]))
          IF operator_C EQ 'GE' THEN matrix = (((data NE value_A) AND (data GE value_B)) AND (data NE In_NaN[1]))
          IF operator_C EQ 'GT' THEN matrix = (((data NE value_A) AND (data GT value_B)) AND (data NE In_NaN[1]))
          IF operator_C EQ 'NE' THEN matrix = (((data NE value_A) AND (data NE value_B)) AND (data NE In_NaN[1]))   
        ENDIF
        
      ENDIF ELSE BEGIN ; No-data is NOT set.
        
        IF operator_A EQ 'EQ' THEN BEGIN 
          IF operator_C EQ 'EQ' THEN matrix = ((data EQ value_A) AND (data EQ value_B)) 
          IF operator_C EQ 'LE' THEN matrix = ((data EQ value_A) AND (data LE value_B))
          IF operator_C EQ 'LT' THEN matrix = ((data EQ value_A) AND (data LT value_B))
          IF operator_C EQ 'GE' THEN matrix = ((data EQ value_A) AND (data GE value_B))
          IF operator_C EQ 'GT' THEN matrix = ((data EQ value_A) AND (data GT value_B))
          IF operator_C EQ 'NE' THEN matrix = ((data EQ value_A) AND (data NE value_B))  
        ENDIF
        
        IF operator_A EQ 'LE' THEN BEGIN 
          IF operator_C EQ 'EQ' THEN matrix = ((data LE value_A) AND (data EQ value_B)) 
          IF operator_C EQ 'LE' THEN matrix = ((data LE value_A) AND (data LE value_B))
          IF operator_C EQ 'LT' THEN matrix = ((data LE value_A) AND (data LT value_B))
          IF operator_C EQ 'GE' THEN matrix = ((data LE value_A) AND (data GE value_B))
          IF operator_C EQ 'GT' THEN matrix = ((data LE value_A) AND (data GT value_B))
          IF operator_C EQ 'NE' THEN matrix = ((data LE value_A) AND (data NE value_B))   
        ENDIF
        
        IF operator_A EQ 'LT' THEN BEGIN 
          IF operator_C EQ 'EQ' THEN matrix = ((data LT value_A) AND (data EQ value_B)) 
          IF operator_C EQ 'LE' THEN matrix = ((data LT value_A) AND (data LE value_B))
          IF operator_C EQ 'LT' THEN matrix = ((data LT value_A) AND (data LT value_B))
          IF operator_C EQ 'GE' THEN matrix = ((data LT value_A) AND (data GE value_B))
          IF operator_C EQ 'GT' THEN matrix = ((data LT value_A) AND (data GT value_B))
          IF operator_C EQ 'NE' THEN matrix = ((data LT value_A) AND (data NE value_B))  
        ENDIF
        
        IF operator_A EQ 'GE' THEN BEGIN 
          IF operator_C EQ 'EQ' THEN matrix = ((data GE value_A) AND (data EQ value_B))
          IF operator_C EQ 'LE' THEN matrix = ((data GE value_A) AND (data LE value_B))
          IF operator_C EQ 'LT' THEN matrix = ((data GE value_A) AND (data LT value_B))
          IF operator_C EQ 'GE' THEN matrix = ((data GE value_A) AND (data GE value_B))
          IF operator_C EQ 'GT' THEN matrix = ((data GE value_A) AND (data GT value_B))
          IF operator_C EQ 'NE' THEN matrix = ((data GE value_A) AND (data NE value_B))   
        ENDIF
        
        IF operator_A EQ 'GT' THEN BEGIN 
          IF operator_C EQ 'EQ' THEN matrix = ((data GT value_A) AND (data EQ value_B)) 
          IF operator_C EQ 'LE' THEN matrix = ((data GT value_A) AND (data LE value_B))
          IF operator_C EQ 'LT' THEN matrix = ((data GT value_A) AND (data LT value_B))
          IF operator_C EQ 'GE' THEN matrix = ((data GT value_A) AND (data GE value_B))
          IF operator_C EQ 'GT' THEN matrix = ((data GT value_A) AND (data GT value_B))
          IF operator_C EQ 'NE' THEN matrix = ((data GT value_A) AND (data NE value_B))   
        ENDIF
        
        IF operator_A EQ 'NE' THEN BEGIN 
          IF operator_C EQ 'EQ' THEN matrix = ((data NE value_A) AND (data EQ value_B)) 
          IF operator_C EQ 'LE' THEN matrix = ((data NE value_A) AND (data LE value_B))
          IF operator_C EQ 'LT' THEN matrix = ((data NE value_A) AND (data LT value_B))
          IF operator_C EQ 'GE' THEN matrix = ((data NE value_A) AND (data GE value_B))
          IF operator_C EQ 'GT' THEN matrix = ((data NE value_A) AND (data GT value_B))
          IF operator_C EQ 'NE' THEN matrix = ((data NE value_A) AND (data NE value_B))   
        ENDIF 
      
      ENDELSE 
    ENDIF
    
    ;-----------------------------------------------------------------------------------------
    ; Apply threshold (double statement OR):
    ;-----------------------------------------------------------------------------------------
    
    IF operator_B EQ 2 THEN BEGIN ; 'OR'
      IF In_NaN[0] NE -1 THEN BEGIN  ; No-data is set.
        
        IF operator_A EQ 'EQ' THEN BEGIN 
          IF operator_C EQ 'EQ' THEN matrix = (((data EQ value_A) OR (data EQ value_B)) AND (data NE In_NaN[1])) 
          IF operator_C EQ 'LE' THEN matrix = (((data EQ value_A) OR (data LE value_B)) AND (data NE In_NaN[1]))
          IF operator_C EQ 'LT' THEN matrix = (((data EQ value_A) OR (data LT value_B)) AND (data NE In_NaN[1]))
          IF operator_C EQ 'GE' THEN matrix = (((data EQ value_A) OR (data GE value_B)) AND (data NE In_NaN[1]))
          IF operator_C EQ 'GT' THEN matrix = (((data EQ value_A) OR (data GT value_B)) AND (data NE In_NaN[1]))
          IF operator_C EQ 'NE' THEN matrix = (((data EQ value_A) OR (data NE value_B)) AND (data NE In_NaN[1]))   
        ENDIF
        
        IF operator_A EQ 'LE' THEN BEGIN 
          IF operator_C EQ 'EQ' THEN matrix = (((data LE value_A) OR (data EQ value_B)) AND (data NE In_NaN[1])) 
          IF operator_C EQ 'LE' THEN matrix = (((data LE value_A) OR (data LE value_B)) AND (data NE In_NaN[1]))
          IF operator_C EQ 'LT' THEN matrix = (((data LE value_A) OR (data LT value_B)) AND (data NE In_NaN[1]))
          IF operator_C EQ 'GE' THEN matrix = (((data LE value_A) OR (data GE value_B)) AND (data NE In_NaN[1]))
          IF operator_C EQ 'GT' THEN matrix = (((data LE value_A) OR (data GT value_B)) AND (data NE In_NaN[1]))
          IF operator_C EQ 'NE' THEN matrix = (((data LE value_A) OR (data NE value_B)) AND (data NE In_NaN[1]))   
        ENDIF
        
        IF operator_A EQ 'LT' THEN BEGIN 
          IF operator_C EQ 'EQ' THEN matrix = (((data LT value_A) OR (data EQ value_B)) AND (data NE In_NaN[1])) 
          IF operator_C EQ 'LE' THEN matrix = (((data LT value_A) OR (data LE value_B)) AND (data NE In_NaN[1]))
          IF operator_C EQ 'LT' THEN matrix = (((data LT value_A) OR (data LT value_B)) AND (data NE In_NaN[1]))
          IF operator_C EQ 'GE' THEN matrix = (((data LT value_A) OR (data GE value_B)) AND (data NE In_NaN[1]))
          IF operator_C EQ 'GT' THEN matrix = (((data LT value_A) OR (data GT value_B)) AND (data NE In_NaN[1]))
          IF operator_C EQ 'NE' THEN matrix = (((data LT value_A) OR (data NE value_B)) AND (data NE In_NaN[1]))   
        ENDIF
        
        IF operator_A EQ 'GE' THEN BEGIN 
          IF operator_C EQ 'EQ' THEN matrix = (((data GE value_A) OR (data EQ value_B)) AND (data NE In_NaN[1])) 
          IF operator_C EQ 'LE' THEN matrix = (((data GE value_A) OR (data LE value_B)) AND (data NE In_NaN[1]))
          IF operator_C EQ 'LT' THEN matrix = (((data GE value_A) OR (data LT value_B)) AND (data NE In_NaN[1]))
          IF operator_C EQ 'GE' THEN matrix = (((data GE value_A) OR (data GE value_B)) AND (data NE In_NaN[1]))
          IF operator_C EQ 'GT' THEN matrix = (((data GE value_A) OR (data GT value_B)) AND (data NE In_NaN[1]))
          IF operator_C EQ 'NE' THEN matrix = (((data GE value_A) OR (data NE value_B)) AND (data NE In_NaN[1]))   
        ENDIF
        
        IF operator_A EQ 'GT' THEN BEGIN 
          IF operator_C EQ 'EQ' THEN matrix = (((data GT value_A) OR (data EQ value_B)) AND (data NE In_NaN[1])) 
          IF operator_C EQ 'LE' THEN matrix = (((data GT value_A) OR (data LE value_B)) AND (data NE In_NaN[1]))
          IF operator_C EQ 'LT' THEN matrix = (((data GT value_A) OR (data LT value_B)) AND (data NE In_NaN[1]))
          IF operator_C EQ 'GE' THEN matrix = (((data GT value_A) OR (data GE value_B)) AND (data NE In_NaN[1]))
          IF operator_C EQ 'GT' THEN matrix = (((data GT value_A) OR (data GT value_B)) AND (data NE In_NaN[1]))
          IF operator_C EQ 'NE' THEN matrix = (((data GT value_A) OR (data NE value_B)) AND (data NE In_NaN[1]))   
        ENDIF
        
        IF operator_A EQ 'NE' THEN BEGIN 
          IF operator_C EQ 'EQ' THEN matrix = (((data NE value_A) OR (data EQ value_B)) AND (data NE In_NaN[1])) 
          IF operator_C EQ 'LE' THEN matrix = (((data NE value_A) OR (data LE value_B)) AND (data NE In_NaN[1]))
          IF operator_C EQ 'LT' THEN matrix = (((data NE value_A) OR (data LT value_B)) AND (data NE In_NaN[1]))
          IF operator_C EQ 'GE' THEN matrix = (((data NE value_A) OR (data GE value_B)) AND (data NE In_NaN[1]))
          IF operator_C EQ 'GT' THEN matrix = (((data NE value_A) OR (data GT value_B)) AND (data NE In_NaN[1]))
          IF operator_C EQ 'NE' THEN matrix = (((data NE value_A) OR (data NE value_B)) AND (data NE In_NaN[1]))   
        ENDIF
        
      ENDIF ELSE BEGIN ; No-data is NOT set.
        
        IF operator_A EQ 'EQ' THEN BEGIN 
          IF operator_C EQ 'EQ' THEN matrix = ((data EQ value_A) OR (data EQ value_B)) 
          IF operator_C EQ 'LE' THEN matrix = ((data EQ value_A) OR (data LE value_B))
          IF operator_C EQ 'LT' THEN matrix = ((data EQ value_A) OR (data LT value_B))
          IF operator_C EQ 'GE' THEN matrix = ((data EQ value_A) OR (data GE value_B))
          IF operator_C EQ 'GT' THEN matrix = ((data EQ value_A) OR (data GT value_B))
          IF operator_C EQ 'NE' THEN matrix = ((data EQ value_A) OR (data NE value_B))  
        ENDIF
        
        IF operator_A EQ 'LE' THEN BEGIN 
          IF operator_C EQ 'EQ' THEN matrix = ((data LE value_A) OR (data EQ value_B)) 
          IF operator_C EQ 'LE' THEN matrix = ((data LE value_A) OR (data LE value_B))
          IF operator_C EQ 'LT' THEN matrix = ((data LE value_A) OR (data LT value_B))
          IF operator_C EQ 'GE' THEN matrix = ((data LE value_A) OR (data GE value_B))
          IF operator_C EQ 'GT' THEN matrix = ((data LE value_A) OR (data GT value_B))
          IF operator_C EQ 'NE' THEN matrix = ((data LE value_A) OR (data NE value_B))   
        ENDIF
        
        IF operator_A EQ 'LT' THEN BEGIN 
          IF operator_C EQ 'EQ' THEN matrix = ((data LT value_A) OR (data EQ value_B)) 
          IF operator_C EQ 'LE' THEN matrix = ((data LT value_A) OR (data LE value_B))
          IF operator_C EQ 'LT' THEN matrix = ((data LT value_A) OR (data LT value_B))
          IF operator_C EQ 'GE' THEN matrix = ((data LT value_A) OR (data GE value_B))
          IF operator_C EQ 'GT' THEN matrix = ((data LT value_A) OR (data GT value_B))
          IF operator_C EQ 'NE' THEN matrix = ((data LT value_A) OR (data NE value_B))  
        ENDIF
        
        IF operator_A EQ 'GE' THEN BEGIN 
          IF operator_C EQ 'EQ' THEN matrix = ((data GE value_A) OR (data EQ value_B))
          IF operator_C EQ 'LE' THEN matrix = ((data GE value_A) OR (data LE value_B))
          IF operator_C EQ 'LT' THEN matrix = ((data GE value_A) OR (data LT value_B))
          IF operator_C EQ 'GE' THEN matrix = ((data GE value_A) OR (data GE value_B))
          IF operator_C EQ 'GT' THEN matrix = ((data GE value_A) OR (data GT value_B))
          IF operator_C EQ 'NE' THEN matrix = ((data GE value_A) OR (data NE value_B))   
        ENDIF
        
        IF operator_A EQ 'GT' THEN BEGIN 
          IF operator_C EQ 'EQ' THEN matrix = ((data GT value_A) OR (data EQ value_B)) 
          IF operator_C EQ 'LE' THEN matrix = ((data GT value_A) OR (data LE value_B))
          IF operator_C EQ 'LT' THEN matrix = ((data GT value_A) OR (data LT value_B))
          IF operator_C EQ 'GE' THEN matrix = ((data GT value_A) OR (data GE value_B))
          IF operator_C EQ 'GT' THEN matrix = ((data GT value_A) OR (data GT value_B))
          IF operator_C EQ 'NE' THEN matrix = ((data GT value_A) OR (data NE value_B))   
        ENDIF
        
        IF operator_A EQ 'NE' THEN BEGIN 
          IF operator_C EQ 'EQ' THEN matrix = ((data NE value_A) OR (data EQ value_B)) 
          IF operator_C EQ 'LE' THEN matrix = ((data NE value_A) OR (data LE value_B))
          IF operator_C EQ 'LT' THEN matrix = ((data NE value_A) OR (data LT value_B))
          IF operator_C EQ 'GE' THEN matrix = ((data NE value_A) OR (data GE value_B))
          IF operator_C EQ 'GT' THEN matrix = ((data NE value_A) OR (data GT value_B))
          IF operator_C EQ 'NE' THEN matrix = ((data NE value_A) OR (data NE value_B))   
        ENDIF 
      
      ENDELSE 
    ENDIF 
    
    ;-----------------------------------------------------------------------------------------
    ; Set the output filename: 
    ;-----------------------------------------------------------------------------------------
    
    ; Single statement.
    IF ((statement[2] EQ -1) OR (statement[2] EQ 0)) THEN filename = output_directory + filenames[i] + '.' + $ 
                                        operator_A + '.' + STRTRIM(value_A,2) + '.img'
    
    ; Double statement 'AND'.
    IF statement[2] EQ 1 THEN filename = output_directory + filenames[i] + '.' + $ 
                                       operator_A + '.' + STRTRIM(value_A,2) + '.AND.' + operator_C + $ 
                                       '.' + STRTRIM(value_B,2) + '.img'
    
    ; Double statement 'OR'.
    IF statement[2] EQ 2 THEN filename = output_directory + filenames[i] + '.' + $ 
                                       operator_A + '.' + STRTRIM(value_A,2) + '.OR.' + operator_C + $ 
                                       '.' + STRTRIM(value_B,2) + '.img'
    
    ;-----------------------------------------------------------------------------------------
    ; Convert data to the selected datatype: 
    ;-----------------------------------------------------------------------------------------
    
    IF (output_datatype EQ 1) THEN matrix = BYTE(matrix) ; Convert to Byte.
    IF (output_datatype EQ 2) THEN matrix = FIX(matrix + 0.5) ; Convert to Integer.
    IF (output_datatype EQ 3) THEN matrix = LONG(matrix + 0.5) ; Convert to Long integer.
    IF (output_datatype EQ 4) THEN matrix = FLOAT(matrix + 0.5) ; Convert to Float.
    IF (output_datatype EQ 5) THEN matrix = DOUBLE(matrix) ; Convert to Double.
    IF (output_datatype EQ 12) THEN matrix = UINT(matrix + 0.5) ; Convert to unsigned Integer.

    ;-----------------------------------------------------------------------------------------
    ; Write output to file: 
    ;-----------------------------------------------------------------------------------------
     
    OPENW, UNIT_OUT, filename, /GET_LUN ; Create the output file on disk.
    FREE_LUN, UNIT_OUT ; Close the new file.
    OPENU, UNIT_OUT, filename, /GET_LUN, /APPEND ; Open the new file for writing.  
    WRITEU, UNIT_OUT, matrix ; Write data to the output file.
    FREE_LUN, UNIT_OUT ; Close the output file.
    
    ;-----------------------------------------------------------------------------------------
    ; Print the loop processing time: 
    ;-----------------------------------------------------------------------------------------
    
    minutes = (SYSTIME(1)-StartTime)/60 ; Subtract End-Time from Start-Time.
    PRINT,'  Processing Time: ', STRTRIM(minutes, 2), ' for file ', STRTRIM(i+1, 2), ' of ', STRTRIM(N_ELEMENTS(files), 2) 
    
  ENDFOR ; FOR i. 
  
  ;---------------------------------------------------------------------------------------------
  ; Print the procedure processing time: 
  ;---------------------------------------------------------------------------------------------
  
  minutes = (SYSTIME(1)-time) / 60 
  hours = minutes / 60 
  PRINT, ''
  PRINT, 'Total processing time: ', STRTRIM(minutes, 2), ' minutes (', STRTRIM(hours, 2),   ' hours)' 
  PRINT, ''
  
END 

; **********************************************************************************************








