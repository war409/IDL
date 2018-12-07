
function make_url, year, month, day, band, L, path, row, UL, LR

  if month le 9 then $
    month_str = '0'+strtrim(month, 2) else $
    month_str = strtrim(month, 2)
  
  if day le 9 then $
    day_str = '0'+strtrim(day, 2) else $
    day_str = strtrim(day, 2)
    
  if L eq 5 then $
    L_Str = 'LS5_TM' else $
    L_Str = 'LS7_ETM'
    
  if path le 99 then $
    path_Str = '0' +strtrim(path, 2) else $
    path_Str = strtrim(path, 2)

  if row le 99 then $
    row_Str = '0' +strtrim(row, 2) else $
    row_Str = strtrim(row, 2)
    
  year_str = strtrim(year, 2)

  GAurl = 'http://eos.ga.gov.au/thredds/wcs/LANDSAT/' + $
        year_str  + '/'+ $
        month_str + '/' + $
        L_str + '_NBAR_P54_GANBAR01-002_' + $
        path_str+ '_' + row_str + '_'+ $
        year_str+month_str+day_str+ $
        '_BX.nc?SERVICE=wcs&version=1.0.0&request=GetCoverage&coverage='+ $
        band + $
        '&CRS=OGC:CRS84&'+ $
        'BBOX=' + $ 146.995,-36.279,147.463,-35.916
        strtrim(UL[0],2)+','+strtrim(LR[1],2)+','+strtrim(LR[0],2)+','+strtrim(UL[1],2)+ $
        '&format=GeoTIFF_Float&RESX=2.500000000000004E-4&RESY=2.5000000000000076E-4'
;        'BBOX=145.6,-35.2,146.3,-34.5&format=GeoTIFF&RESX=2.500000000000004E-4&RESY=2.5000000000000076E-4'
  
  return, GAurl      

end


pro get_GA_Landsat, $
    path=path, $
    row=row, $
    out_dir=out_dir, $
    UL=UL, $
    LR=LR, $
    YStart=YStart, $
    MStart=MStart, $
    DStart=DStart, $
    YEnd=YEnd, $
    MEnd=MEnd, $
    DEnd=DEnd, $
    out_folder=out_folder, $
    subset_name=subset_name, $
    quality=quality, $
    keep=keep, $
    bands=bands 
    
  compile_opt idl2
  
  if Keyword_Set(quality) eq 0 then quality=75 
  
  ;check if folder exists, if not create
  out_folder_info= FILE_INFO(out_folder)
  if out_folder_info.directory eq 0 then FILE_MKDIR, out_folder
  
  if Keyword_Set(keep) eq 1 then begin
    out_folder_keep = out_folder + '\TIFF'
    if (FILE_INFO(out_folder_keep)).directory eq 0 then FILE_MKDIR, out_folder_keep
  endif
    
  t=systime(1, /julian)  
  temp_file=strcompress(string(t, format='(f15.5)')+'.tiff', /remove_all)
  n= JULDAY(MStart,DStart,YStart)
  n_end = JULDAY(MEnd,DEnd,YEnd)
  L = 5
  path = path
  row  = row
  CALDAT, n, month, day, year
 
  if keyword_set(out_folder) eq 0 then out_folder= !dir
  if keyword_set(subset_name) eq 0 then subset_name= ''
  
       ; If the url object throws an error it will be caught here

   CATCH, errorStatus 
   IF (errorStatus NE 0) THEN BEGIN   
      ;print, 'got an error'
      ;CATCH, /CANCEL
      ; Display the error msg in a dialog and in the IDL output log
      ;r = DIALOG_MESSAGE(!ERROR_STATE.msg, TITLE='URL Error', $
      ;   /ERROR)
      ; PRINT, !ERROR_STATE.msg
      ; Get the properties that will tell us more about the error.
      ;oUrl->GetProperty, RESPONSE_CODE=rspCode, $
      ;   RESPONSE_HEADER=rspHdr, RESPONSE_FILENAME=rspFn
      ;PRINT, 'rspCode = ', rspCode
      ;PRINT, 'rspHdr= ', rspHdr
      ;PRINT, 'rspFn= ', rspFn
      ; Destroy the url object
      ;OBJ_DESTROY, oUrl
      Obj_Destroy, netObject
      
      if L eq 5 then begin 
          L = 7     ; if with landsat 5 try landsat 7
      Endif Else begin  
          L = 5   
          n += 1   ; if with Landsat 7 then go to next day and back to L5
      endElse  
   ENDIF


 
   while n le n_end do begin
  
   CALDAT, n, month, day, year
   print, day, month, year, L, path , row

    if month le 9 then month_str='0' else month_str=''
    if day le 9 then day_str='0' else day_str=''

    fname_jpg = out_folder+'\Landsat_743_'+subset_name+ '_'+$
    strtrim(year,2)+'_'+month_str+strtrim(month,2)+'_'+day_str+strtrim(day,2)+$
    '_L'+strtrim(L,2)+'_'+strtrim(path,2)+'_'+strtrim(row,2)+'.jpg'

    fname_jgw = out_folder+'\Landsat_743_'+subset_name+ '_'+$
    strtrim(year,2)+'_'+month_str+strtrim(month,2)+'_'+day_str+strtrim(day,2)+$
    '_L'+strtrim(L,2)+'_'+strtrim(path,2)+'_'+strtrim(row,2)+'.jgw'

    if (file_info(fname_jpg)).exists eq 0 then begin 
      
       CD, 'c:\users\gue026\'

       if Keyword_Set(keep) eq 1 then $
        fname_tiff = out_folder_keep+'\Landsat_B3_'+subset_name+ '_'+$
          strtrim(year,2)+'_'+month_str+strtrim(month,2)+'_'+day_str+strtrim(day,2)+$
          '_L'+strtrim(L,2)+'_'+strtrim(path,2)+'_'+strtrim(row,2)+'.tiff' $
       else $
        fname_tiff = temp_file        
       GAurl = make_url(year, month, day, 'Band3', L, path, row, UL, LR)
       netObject = Obj_New('IDLnetURL')
       void = netObject -> Get(URL=GAurl, FILENAME=fname_tiff); , /buffer)
       Obj_Destroy, netObject
       band3 = fix(READ_TIFF(fname_tiff))
         
       if Keyword_Set(keep) eq 1 then $
        fname_tiff = out_folder_keep+'\Landsat_B4_'+subset_name+ '_'+$
          strtrim(year,2)+'_'+month_str+strtrim(month,2)+'_'+day_str+strtrim(day,2)+$
          '_L'+strtrim(L,2)+'_'+strtrim(path,2)+'_'+strtrim(row,2)+'.tiff' $
       else $
        fname_tiff = temp_file        
       GAurl = make_url(year, month, day, 'Band4', L, path, row, UL, LR)
       netObject = Obj_New('IDLnetURL')
       void = netObject -> Get(URL=GAurl, FILENAME=fname_tiff)
       Obj_Destroy, netObject
       band4 = fix(READ_TIFF(fname_tiff))
    
       if Keyword_Set(keep) eq 1 then $
        fname_tiff = out_folder_keep+'\Landsat_B7_'+subset_name+ '_'+$
          strtrim(year,2)+'_'+month_str+strtrim(month,2)+'_'+day_str+strtrim(day,2)+$
          '_L'+strtrim(L,2)+'_'+strtrim(path,2)+'_'+strtrim(row,2)+'.tiff' $
       else $
        fname_tiff = temp_file        
       GAurl = make_url(year, month, day, 'Band7', L, path, row, UL, LR)
       netObject = Obj_New('IDLnetURL')
       void = netObject -> Get(URL=GAurl, FILENAME=fname_tiff)
       Obj_Destroy, netObject
       band7 = fix(READ_TIFF(fname_tiff, GEOTIFF=GEOTIFF))

       print, 'Bands 3, 4 and 7 exist!!', day, month, year, L, path , row



    
      ;img_display = [[[rotate(band7,7)]],[[rotate(band4,7)]],[[rotate(band3,7)]]]
      ;cgDisplay, 1200, 1000
      ;cgImage, img_display, /keep_aspect_ratio
      ; save png
      img_png = bytarr(3, (size(band7))[1], (size(band7))[2])
      img_png[0,*,*] = bytscl(band7, min=0, max=6000)
      img_png[1,*,*] = bytscl(band4, min=0, max=6000)
      img_png[2,*,*] = bytscl(band3, min=0, max=6000)
         
      ;WRITE_PNG, fname, img_png, /order
      WRITE_JPEG, fname_jpg, img_png , TRUE=1, quality=quality, /order
      print, 'write jpg and jgw'
      
      openW, lun, fname_jgw, /get_lun
        printF, lun, strtrim((lr[0]-ul[0]) / (size(img_png))[2],2)
        printF, lun, '0'
        printF, lun, '0'
        printF, lun, strtrim((lr[1]-ul[1]) / (size(img_png))[3],2)
        printF, lun, strtrim(ul[0],2)
        printF, lun, strtrim(ul[1],2)
      close, /all
    
       if Keyword_Set(keep) eq 1 then begin
         fname_tiff = out_folder_keep+'\Landsat_B1_'+subset_name+ '_'+$
          strtrim(year,2)+'_'+month_str+strtrim(month,2)+'_'+day_str+strtrim(day,2)+$
          '_L'+strtrim(L,2)+'_'+strtrim(path,2)+'_'+strtrim(row,2)+'.tiff'  
         GAurl = make_url(year, month, day, 'Band1', L, path, row, UL, LR)
         netObject = Obj_New('IDLnetURL')
         void = netObject -> Get(URL=GAurl, FILENAME=fname_tiff)
         Obj_Destroy, netObject
         ;band7 = fix(READ_TIFF(fname_tiff, GEOTIFF=GEOTIFF))

         fname_tiff = out_folder_keep+'\Landsat_B2_'+subset_name+ '_'+$
          strtrim(year,2)+'_'+month_str+strtrim(month,2)+'_'+day_str+strtrim(day,2)+$
          '_L'+strtrim(L,2)+'_'+strtrim(path,2)+'_'+strtrim(row,2)+'.tiff'  
         GAurl = make_url(year, month, day, 'Band2', L, path, row, UL, LR)
         netObject = Obj_New('IDLnetURL')
         void = netObject -> Get(URL=GAurl, FILENAME=fname_tiff)
         Obj_Destroy, netObject
         ;band7 = fix(READ_TIFF(fname_tiff, GEOTIFF=GEOTIFF))

         fname_tiff = out_folder_keep+'\Landsat_B5_'+subset_name+ '_'+$
          strtrim(year,2)+'_'+month_str+strtrim(month,2)+'_'+day_str+strtrim(day,2)+$
          '_L'+strtrim(L,2)+'_'+strtrim(path,2)+'_'+strtrim(row,2)+'.tiff'  
         GAurl = make_url(year, month, day, 'Band5', L, path, row, UL, LR)
         netObject = Obj_New('IDLnetURL')
         void = netObject -> Get(URL=GAurl, FILENAME=fname_tiff)
         Obj_Destroy, netObject
         ;band7 = fix(READ_TIFF(fname_tiff, GEOTIFF=GEOTIFF))
       endif   


    endif else begin
      print, 'file exists, skip'
    endelse    
      
     
      if L eq 5 then begin 
          L = 7     ; if with landsat 5 try landsat 7
      Endif Else begin  
          L = 5   
          n += 1   ; if with Landsat 7 then go to next day and back to L5
      endElse  
    
  ENDWHILE
  
  exit, /no_confirm 

end
    