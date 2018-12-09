
;-------------------------------------------------------------------------

function Norm_Ratio, b1,b2
  
  return, (b2-b1)/(b2+b1*1.0)

end

;-------------------------------------------------------------------------

function NDVI_NDWI_FUNCT, X, P 
  
  ;print, 'P passed to NDVI_NDWI_FUNCT= ' , P

  NDVI = X[*,*,0]
  NDWI = X[*,*,1]  
  orig = P[0]
  Slope= P[1]
  P0 = P[2]
  ;P1 = P[3]
  P1 = 0.0
  Line = orig + slope * NDVI    
  Vdist = NDWI - Line
  Pwater = 1 / ( 1 + EXP(P0 * ( Vdist + P1 )))
   
  return, Pwater

end

;-------------------------------------------------------------------------

function ALL_BANDS_MODEL, X, P 

  B1 = X[*,*,0]
  B2 = X[*,*,1]  
  B3 = X[*,*,2]
  B4 = X[*,*,3]  
  B5 = X[*,*,4]
  B6 = X[*,*,5]  
  NDVI = X[*,*,6]
  NDWI = X[*,*,7]
 
  z= P[0] + $
     P[1] * B1 + $
     P[2] * B2 + $
     P[3] * B3 + $
     P[4] * B4 + $
     P[5] * B5 + $
     P[6] * B6 + $
     P[7] * NDVI + $
     P[8] * NDWI 
  Pwater = 1 / ( 1 + EXP(z))
   
  return, Pwater

end

;-------------------------------------------------------------------------

function ONE_BANDS_MODEL, X, P 

  B1 = X[*,*,0]
 
  z= P[0] + $
     P[1] * B1 
     
  Pwater = 1 / ( 1 + EXP(z))  
  
  return, Pwater

end

;-------------------------------------------------------------------------

function TWO_BANDS_MODEL, X, P 

  B1 = X[*,*,0]
  B2 = X[*,*,1]  
 
  z= P[0] + $
     P[1] * B1 + $
     P[2] * B2 
  Pwater = 1 / ( 1 + EXP(z))  
  
  return, Pwater

end

;-------------------------------------------------------------------------

function THREE_BANDS_MODEL, X, P 

  B1 = X[*,*,0]
  B2 = X[*,*,1]  
  B3 = X[*,*,2]  
 
  z= P[0] + $
     P[1] * B1 + $
     P[2] * B2 + $
     P[3] * B3 
  Pwater = 1 / ( 1 + EXP(z))  
  
  return, Pwater

end

;-------------------------------------------------------------------------

function FOUR_BANDS_MODEL, X, P 

  B1 = X[*,*,0]
  B2 = X[*,*,1]  
  B3 = X[*,*,2]  
  B4 = X[*,*,3]  
 
  z= P[0] + $
     P[1] * B1 + $
     P[2] * B2 + $
     P[3] * B3 + $
     P[4] * B4 
  Pwater = 1 / ( 1 + EXP(z))  
  
  return, Pwater

end

;-------------------------------------------------------------------------

function FIVE_BANDS_MODEL, X, P 

  B1 = X[*,*,0]
  B2 = X[*,*,1]  
  B3 = X[*,*,2]  
  B4 = X[*,*,3]  
  B5 = X[*,*,4]
  
  z= P[0] + $
     P[1] * B1 + $
     P[2] * B2 + $
     P[3] * B3 + $
     P[4] * B4 + $ 
     P[5] * B5
  Pwater = 1 / ( 1 + EXP(z))  
  
  return, Pwater

end

;-------------------------------------------------------------------------

function SIX_BANDS_MODEL, X, P 

  B1 = X[*,*,0]
  B2 = X[*,*,1]  
  B3 = X[*,*,2]  
  B4 = X[*,*,3]  
  B5 = X[*,*,4]
  
  z= P[0] + $
     P[1] * B1 + $
     P[2] * B2 + $
     P[3] * B3 + $
     P[4] * B4 + $ 
     P[5] * B5
  Pwater = 1 / ( 1 + EXP(z))  
  
  return, Pwater

end

;-------------------------------------------------------------------------

function SEVEN_BANDS_MODEL, X, P 

  B1 = X[*,*,0]
  B2 = X[*,*,1]  
  B3 = X[*,*,2]  
  B4 = X[*,*,3]
  B5 = X[*,*,4]
  B6 = X[*,*,5]
  B7 = X[*,*,6]  
  
  z= P[0] + $
     P[1] * B1 + $
     P[2] * B2 + $
     P[3] * B3 + $
     P[4] * B4 + $
     P[5] * B5 + $
     P[6] * B6 + $
     P[7] * B7
  Pwater = 1 / ( 1 + EXP(z))  
  
  return, Pwater

end

;-------------------------------------------------------------------------
function NINE_BANDS_MODEL, X, P 

  B1 = X[*,*,0]
  B2 = X[*,*,1]  
  B3 = X[*,*,2]  
  B4 = X[*,*,3]
  B5 = X[*,*,4]
  B6 = X[*,*,5]
  B7 = X[*,*,6]
  B8 = X[*,*,7]
  B9 = X[*,*,8]  
  
  z= P[0] + $
     P[1] * B1 + $
     P[2] * B2 + $
     P[3] * B3 + $
     P[4] * B4 + $
     P[5] * B5 + $
     P[6] * B6 + $
     P[7] * B7 + $
     P[8] * B8 + $
     P[9] * B9
  Pwater = 1 / ( 1 + EXP(z))  
  
  return, Pwater

end

;-------------------------------------------------------------------------
  
pro Open_Water_DOIT_Logistic_Modelling
  compile_opt idl2

  P_= !P
  !P.Multi =  [0,2,2]
  !P.Background = FSC_COLOR('white')
  !P.Color = FSC_COLOR('black')
  
  ;-------------------------------------------------------------------------
  
  ; OPEN and GET Landsat at 500m 
  fname= '\\wron\Working\work\Juan_Pablo\Open_Water_mapping\LANDSAT_NBAR\mosaic_20041126_20041212_20041228_INTEGER_resized_MOD09A1.mos'
  ENVI_OPEN_FILE, fname, R_FID=FID
  ENVI_FILE_QUERY, FID, DIMS=DIMS, NL=NL, NS=NS, NB=NB
  Landsat_Reflectance = IntArr(ns,nl,nb)
  for i=0, NB-1 do Landsat_Reflectance[*,*,i] = ENVI_GET_DATA(FID=FID, DIMS=DIMS, POS=i)

  Landsat_Reflectance_NDVI = Norm_Ratio(Landsat_Reflectance[*,*,2], Landsat_Reflectance[*,*,3])  ; Calculates NDVI
  Landsat_Reflectance_NDWI = Norm_Ratio(Landsat_Reflectance[*,*,4], Landsat_Reflectance[*,*,3])  ; Calculates NDWI
  ;Landsat_Reflectance_NDWI7 = Norm_Ratio(Landsat_Reflectance[*,*,5], Landsat_Reflectance[*,*,3])  ; Calculates NDWI7
  ;Landsat_Reflectance_mNDWI = Norm_Ratio(Landsat_Reflectance[*,*,4], Landsat_Reflectance[*,*,2])  ; Calculates mNDWI



  ; OPEN and GET Landsat derived proportion water 500m 
  fname= '\\wron\Working\work\Juan_Pablo\Open_Water_mapping\Landsat_GA_Definiens\mosaic_20041126_20041212_20041228_class_resized_MOD09A1.mos'
  ENVI_OPEN_FILE, fname, R_FID=FID
  ENVI_FILE_QUERY, FID, DIMS=DIMS, NL=NL, NS=NS, NB=NB
  Landsat_Class = FltArr(ns,nl,nb)
  for i=0, NB-1 do Landsat_Class[*,*,i] = ENVI_GET_DATA(FID=FID, DIMS=DIMS, POS=i) ; add the data for each band to the 'Landsat_Class' array.
  Landsat_Class_TOT_WATER = Landsat_Class[*,*,1] + Landsat_Class[*,*,5]  ; TOT_WATER is bands 2 + 6
  
  
  
  ; OPEN SRTM DEM 3s:
  fname= '\\File-wron\Working\work\war409\Work\WfHC\wirada\wraa\awra\open_water_mapping\spatial\raster\elevation\srtm\subset\SRTM.DEM.3s.01.RESAMPLE.SNAP.SUBSET.img'
  ENVI_OPEN_FILE, fname, R_FID=FID
  ENVI_FILE_QUERY, FID, DIMS=DIMS, NL=NL, NS=NS, NB=NB
  SRTM_DEM3 = IntArr(ns,nl,nb)
  for i=0, NB-1 do SRTM_DEM3[*,*,i] = ENVI_GET_DATA(FID=FID, DIMS=DIMS, POS=i) 

  ; OPEN SRTM DEM 3s MrVBF:
  fname= '\\File-wron\Working\work\war409\Work\WfHC\wirada\wraa\awra\open_water_mapping\spatial\raster\elevation\srtm\subset\SRTM.DEM.3s.01.MrVBF.RESAMPLE.SNAP.SUBSET.mos'
  ENVI_OPEN_FILE, fname, R_FID=FID
  ENVI_FILE_QUERY, FID, DIMS=DIMS, NL=NL, NS=NS, NB=NB
  SRTM_DEM3MrVBF = IntArr(ns,nl,nb)
  for i=0, NB-1 do SRTM_DEM3MrVBF[*,*,i] = ENVI_GET_DATA(FID=FID, DIMS=DIMS, POS=i)   
  
  ; OPEN SRTM DEM 3s DEGREE SLOPE:
  fname= '\\File-wron\Working\work\war409\Work\WfHC\wirada\wraa\awra\open_water_mapping\spatial\raster\elevation\srtm\subset\SRTM.DEM.3s.01.Degree.Slope.RESAMPLE.SNAP.SUBSET.img'
  ENVI_OPEN_FILE, fname, R_FID=FID
  ENVI_FILE_QUERY, FID, DIMS=DIMS, NL=NL, NS=NS, NB=NB
  SRTM_DEM3SlopeDegree = IntArr(ns,nl,nb)
  for i=0, NB-1 do SRTM_DEM3SlopeDegree[*,*,i] = ENVI_GET_DATA(FID=FID, DIMS=DIMS, POS=i)   

  ; OPEN SRTM DEM 3s PERCENT SLOPE:
  fname= '\\File-wron\Working\work\war409\Work\WfHC\wirada\wraa\awra\open_water_mapping\spatial\raster\elevation\srtm\subset\SRTM.DEM.3s.01.Percent.Slope.RESAMPLE.SNAP.SUBSET.img'
  ENVI_OPEN_FILE, fname, R_FID=FID
  ENVI_FILE_QUERY, FID, DIMS=DIMS, NL=NL, NS=NS, NB=NB
  SRTM_DEM3SlopePercent = IntArr(ns,nl,nb)
  for i=0, NB-1 do SRTM_DEM3SlopePercent[*,*,i] = ENVI_GET_DATA(FID=FID, DIMS=DIMS, POS=i)   
  
  ; OPEN SRTM DEM 3s ASPECT:
  fname= '\\File-wron\Working\work\war409\Work\WfHC\wirada\wraa\awra\open_water_mapping\spatial\raster\elevation\srtm\subset\SRTM.DEM.3s.01.Aspect.RESAMPLE.SNAP.SUBSET.img'
  ENVI_OPEN_FILE, fname, R_FID=FID
  ENVI_FILE_QUERY, FID, DIMS=DIMS, NL=NL, NS=NS, NB=NB
  SRTM_DEM3Aspect = IntArr(ns,nl,nb)
  for i=0, NB-1 do SRTM_DEM3Aspect[*,*,i] = ENVI_GET_DATA(FID=FID, DIMS=DIMS, POS=i)   

  !P.multi = [0,5,4]
   window, i, xsize=1250, ysize=900, title=string(i)
   xcolors, index=22, brewer=1, title= 'Out' 
          
  ;-------------------------------------------------------------------------
  for i=0, 3 do begin
     case i of
      0: Weights =  1D + (Landsat_Class[*,*,5] - Landsat_Class[*,*,5]) ; all points the same 
      1: Weights =  1D / (1.1 - Landsat_Class[*,*,5]) ; points with 100% water 10 times more than 0% 
      2: Weights =  1D / ((1 + 0.1) - Landsat_Class[*,*,5]) + 1 / ((0 + 0.1) + Landsat_Class[*,*,5]) 
      3: Weights =  1D / ((1 + 0.01) - Landsat_Class[*,*,5]) + 1 / ((0 + 0.01) + Landsat_Class[*,*,5]) 
     endcase 
          expr = 'THREE_BANDS_MODEL(X, P)'
          
          x= [[[Landsat_Reflectance_NDVI]],[[Landsat_Reflectance_NDWI]], $
          [[SRTM_DEM3MrVBF]]]
          ;x= [[[Landsat_Reflectance_NDVI]],[[Landsat_Reflectance_NDWI]], $
          ;[[SRTM_DEM3MrVBF]]]          
          Size_X = Size(x)
          P = fltarr(Size_X[3]+1)        ; number of params = bands of x + 1
          y= Landsat_Class[*,*,5]
          ;y= Landsat_Class_TOT_WATER
          t= SysTime(1)
          Optimised_params = MPFITEXPR(expr, x, y, 1D, P, YFIT=YFIT,  ERRMSG=ERRMSG, NITER=NITER, WEIGHTS=WEIGHTS, /QUIET)
          correl = CORRELATE(Y, YFIT)
          Nash_E = NS_efficiency(YFIT, Y)
          RMSE = sqrt(total((YFIT - Y)^2 / n_elements(YFIT)))
          
          text_out = Strarr(6)
          text_out[0]= expr  
          text_out[1]=StrCompress('RMSE='+String(RMSE))
          text_out[2]=StrCompress('r= '+ string(correl))
          text_out[3]=StrCompress('r^2= '+ String( correl^2))
          text_out[4]=StrCompress('Nash E='+ String(Nash_E))
          text_out[5]=StrCompress('NITER= '+ String(NITER)+ '  ERRMSG= '+String(ERRMSG))
   
          print
          print, expr, i, SysTime(1)-t, ' seconds' 
          print, 'RMSE=',RMSE
          print, 'correl= ', correl
          print, 'correl^2= ', correl^2
          print, 'Nash E=', Nash_E
          print, 'params= ', Optimised_params 
          print, 'NITER= ', NITER , '  ERRMSG= ',ERRMSG
          plot, Landsat_Class_TOT_WATER, Weights, psym=3, xtitle='Prop water', ytitle='Weights', Yrange=[min(Weights)-1,max(Weights)+1] 
          plot, yfit, y, psym=3, xtitle='yfit', ytitle='y' 
            oplot_regress, yfit, y
          TVImage, Rotate(Bytscl(THREE_BANDS_MODEL(X, Optimised_params), MIN=-1, MAX=1),7), /Keep_Aspect, /AXES
              xyouts,0,0, 'MODELLED' 
          TVImage, Rotate(Bytscl(THREE_BANDS_MODEL(X, Optimised_params)-y , MIN=-0.3, MAX=0.3),7), /Keep_Aspect, /AXES
              xyouts,0,0, 'MODELLED-OBSERVED' 
          plot, [0,0], [1,1], /nodata, color=FSC_COLOR('white')  ; this is just a blank plot to make room for the xyouts below
          for z=0,N_elements(text_out)-1 do xyouts,0,z*.1, text_out[z], CHARSIZE=0.6
          envi_enter_data, THREE_BANDS_MODEL(X, Optimised_params)
          envi_enter_data, THREE_BANDS_MODEL(X, Optimised_params) - y
    endfor
      envi_enter_data, y
      !P = P_ 
      print, ''
      print, '*** FIN ***'                 
end