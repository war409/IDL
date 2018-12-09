;+
; NAME:
;       Density_scatterplot
;
; PURPOSE:
;
;      This program creates a scatterplot of two arrays and displays density with a color ramp
;
; AUTHOR:
;
;       Juan Pablo Guerschman
;
; CATEGORY:
;
;       plots
;
; CALLING SEQUENCE:
;
;       Density_scatterplot, x, y [, xtitle=xtitle] [, ytitle=ytitle] [, NBINS=NBINS] 
;                [, MIN1=MIN1] [, MIN2=MIN2] [, MAX1=MAX1] [, MAX2=MAX2]
;
;          
; EXAMPLE:
;
;        x= RandomU(seed1, 1000, 1000)
;        y= RandomU(seed2, 1000, 1000)
;        Density_Scatterplot, x, y
;        
;        
;        X = '\\File-wron\Working\work\Juan_Pablo\AET_C5\SILO\RAIN\200101_rain.flt'
;        Y = '\\File-wron\Working\work\Juan_Pablo\AET_C5\SILO\RAIN\200102_rain.flt'
;        
;        Data_X = READ_BINARY(X, DATA_TYPE=4)
;        Data_Y = READ_BINARY(Y, DATA_TYPE=4)
;
;
; MODIFICATION HISTORY:
;       Written by:     Juan PAblo Guerschman, May 2010
;-


pro Density_scatterplot, X, Y, xtitle=xtitle, ytitle=ytitle, NBINS=NBINS, MIN1=MIN1, MIN2=MIN2, MAX1=MAX1, MAX2=MAX2
  compile_opt idl2
   
   xcolors, index=27
      
   if Keyword_Set(MIN1) eq 1 THEN MIN1=MIN1 ELSE MIN1=min(X)  
   if Keyword_Set(MIN2) eq 1 THEN MIN2=MIN2 ELSE MIN2=min(Y)
   if Keyword_Set(MAX1) eq 1 THEN MAX1=MAX1 ELSE MAX1=max(X)  
   if Keyword_Set(MAX2) eq 1 THEN MAX2=MAX2 ELSE MAX2=max(Y)
   if Keyword_Set(NBINS) eq 1 THEN NBINS=NBINS ELSE NBINS=400.
   if Keyword_Set(xtitle) eq 1 THEN xtitle=xtitle ELSE xtitle=''
   if Keyword_Set(ytitle) eq 1 THEN ytitle=ytitle ELSE ytitle=''
   
   BIN1= (MAX1 - MIN1) / NBINS
   BIN2= (MAX2 - MIN2) / NBINS
  
   xvector = findgen(NBINS) * BIN1 + MIN1
   yvector = findgen(NBINS) * BIN2 + MIN2
   
   Result = HIST_2D(X, Y, MAX1=MAX1, MIN1=MIN1, MAX2=MAX2, MIN2=MIN2, BIN1=BIN1, BIN2=BIN2)
   s = Size(Result, /Dimensions)

    pos=[0.1, 0.05, 0.95, 0.95]
  ;TVImage, Bytscl(Result) , /Keep_Aspect, background=fsc_color('white'), /erase, Position=pos
  TVImage, Bytscl(Result) , /Keep_Aspect, Position=pos
    contour, Result,  levels = 10, xtitle=xtitle, ytitle=xtitle, /NODATA, /noerase , Position=pos
       
       
end
      
      
      