pro MODIS_Data_Oz_OWL2

; This program reads in the MODIS images (Aqua and Terra) for a day as provided by Peter Dyce's
; code which uses MRTSwath  and calculates the proportion of water within each pixel - currently
; using J-P Guerschman's new OWL algorithm.

; Written in February 2011 by Catherine Ticehurst, MODIS processing written by Peter Dyce

; August 2011 - removed xstart ystart in headers as default is all that is needed

  ; Compile envi routines
    Forward_Function ENVI_ENTER_DATA
    Forward_Function ENVI_GET_DATA
    Forward_Function ENVI_EVF_OPEN
    Forward_Function ENVI_EVF_READ_RECORD
    Forward_Function envi_get_file_ids
    Forward_Function Envi_get_Map_Info

  ; Start the batch process and prepare for using ENVI for the pixel aggregate resampling
    envi, /restore_base_save_files
    temp_path=getenv('IDL_TMPDIR')
    envi_batch_init, log_file=temp_path+'temp_batch.log', batch_lun=b_lun, /no_status_window

  ; Read in the input directory, output directory, DEM directory, and month - all of which must be
  ; provided through the command line after -arg. Note that the forward slash '/' needs to be used.
  ; e.g. idlrt c:/temp/modis_water_Vol_Op.sav -arg c:/temp/ -arg c:/temp/output/ -arg c:/temp/DEM
  ; Note - to produce a .sav file, at the command line type: .compile name-of-file.pro, (then .compile SFIT.pro - no longer used)
  ; and then type: save, /routines, filename='name-of-file.sav'

  ; UNCOMMENT THESE NEXT BLOCK OF LINES FOR PRODUCING A .SAV FILE VERSION ************************************
   Com_args=command_line_args(count=count) ; uncomment for .sav file
    if count ne 3 then begin                ; uncomment for .sav file
     print,' ERROR - INCORRECT ARGUMENTS'    ; uncomment for .sav file
    endif else begin                        ; uncomment for .sav file
     in_dir=com_args[0]                      ; uncomment for .sav file
     out_dir=com_args[1]                     ; uncomment for .sav file
     MrVBF_file=com_args[2]                  ; uncomment for .sav file
    endelse                                 ; uncomment for .sav file

;     ; COMMENT THE NEXT FIVE LINES FOR PRODUCING A .SAV FILE *************************************
;      out_dir='//FILE-WRON/Working/Work/cjt/IDL_files/output' ;'C:/temp/AMSR/MODFlood/output/'  ; comment for .sav file
;      in_dir='//FILE-WRON/Working/Work/cjt/IDL_files/input' ;'C:/temp/AMSR/MODFlood/input/'    ; comment for .sav file
;      MrVBF_file='//FILE-WRON/Working/Work/cjt/IDL_files/input/SRTM_DEM_3s_01_MrVBF_Aust_500m_NullsMskd' ; comment for .sav file

    ; remove the '/' if it is given at the end of in_dir, Out_dir, or In_DEM
      if strpos(out_dir,'/',/reverse_search) eq strlen(out_dir)-1 then $
         out_dir=strmid(out_dir,0,strlen(out_dir)-1)
      if strpos(in_dir,'/',/reverse_search) eq strlen(in_dir)-1 then $
         in_dir=strmid(in_dir,0,strlen(in_dir)-1)

    ; Define image coordinates for the whole of Australia
    COMMON share, NLat, Slat, Wlon, Elon
      NLat=-10.0
      SLat=-45.0
      WLon=110.0
      ELon=155.0
      Final_MODpix=0.004697424 ;0.0125 ***** ; Need to force the final pixel size to be the same since each image has a slightly different value

;=====================================================================================================
; Calculate flood extent using MODIS swath images for the day

      MODIS_Comb=MODIS_wtr_Calc(out_dir, in_dir,Final_MODpix,MrVBF_file)

;envi_batch_exit ; dont know why but the program crashes when this is used (even though the batch process is initiated at the start
Close, /All
print,'Finished!'
end

;********************************************************************************************************
function MODIS_wtr_Calc, out_dir, in_dir, Final_MODpix, MrVBF_file

; This program reads in all the Australia wide MODIS aqua and terra swath images as ENVI files in the 'input' directory
; for the current day. It calculates the water extent using JP Guerschman's OWL, and produces an extent map for the day based on
; average value as well as reducing clouds.

COMMON share, NLat, Slat, Wlon, Elon

     MODsamp=round((Elon-Wlon)/Final_MODpix) ; Need to force images to be the same size
     MODline=round((Nlat-Slat)/Final_MODpix)


; Read in MODIS images by going into each folder below in_dir (named using yyyy-mm-dd.HHMM) for the current day
; Find all the directories that need to be read
     MOD_dirs=file_search(in_dir+'/*', /test_directory, count=dir_count)
     print,'MOD_dirs=',MOD_dirs

     OWL_exists=0
     HDR_done=0

     Final_OutName=out_dir+'/modis_water' ;_oz_'+strmid(MOD_dirs[0],strlen(MOD_dirs[0])-15,10)

     OWL_Oz=-99

if dir_count gt 0 then begin
for MF=0,dir_count-1 do begin
print,' Processing Image No: ',MF+1,' of ',dir_count

; get the current output directory
      OutFile=out_dir+'/modis_water_'+strmid(MOD_dirs[MF],strlen(MOD_dirs[0])-15,10)+'-'+strmid(MOD_dirs[MF],strlen(MOD_dirs[0])-4)

; Read in the MODIS swath images covering Australia (it will begin with "Y" or "O"), before calculating the water extent

     ModTERRA='/O_500m_Surface_Reflectance_Band' ; the _1.dat, _2.dat are accounted for later
     ModTERRA_QA='/O_1km_Reflectance_Data_State_QA' ; the .dat is accounted for later
     ModAQUA='/Y_500m_Surface_Reflectance_Band'  ; the _1.dat, _2.dat are accounted for later
     ModAQUA_QA='/Y_1km_Reflectance_Data_State_QA' ; the .dat is accounted for later

;     ; check that a Terra or Aqua image exists
     TerraExist=0
     AquaExist=0

     Files=file_search(MOD_dirs[MF]+ModTERRA+'_1.dat', count=count)
     if count ne 0 then TerraExist=1
     print, 'Files=',files

     Files=file_search(MOD_dirs[MF]+ModAQUA+'_1.dat', count=count)
     if count ne 0 then AquaExist=1
     print, 'Files=',files

     print,'Only reads in one Terra (MOD) or one Aqua (MYD) file for processing'

     Mim=TerraExist+AquaExist
     print,'Mim terraexist aquaexist=',Mim, TerraExist, AquaExist

   if Mim gt 0 then begin

; Loop through for each MODIS image, producing a water extent image.

; read in associated MODIS ENVI header file, write the output header file for the final image,
; and extract the values that are needed (ie number of rows, columns and nodata value)
; NOTE THAT IT IS ASSUMED ALL THE MODIS DATA ARE THE SAME DIMENSIONS, EXCEPT FOR THE QUALITY BAND

     ; Read in the terra file if it exists, otherwise it must be an aqua file.
;     if F eq 0 then begin
       if TerraExist eq 1 then begin
         OpenR, Hdr, MOD_dirs[MF]+ModTERRA+'_1.hdr', /get_lun
         OpenR, HdrQ, MOD_dirs[MF]+ModTERRA_QA+'.hdr', /get_lun
       endif else begin
         OpenR, Hdr, MOD_dirs[MF]+ModAQUA+'_1.hdr', /get_lun
         OpenR, HdrQ, MOD_dirs[MF]+ModAQUA_QA+'.hdr', /get_lun
       endelse

     ; Open the MODIS_water image
     OpenW, Out_Hdr, strmid(outfile,0,strlen(outfile))+'.hdr', /Get_lun

     line=''

     ; read in reflectance header for image size [and write output headers]
     ; NOTE: the output files are BYTE (to save memory), not int
     while not(eof(Hdr)) do begin
       readF, Hdr, line
         done=0
         if (strpos(line,'data type') ne -1) then begin
          PrintF, Out_Hdr, 'data type = 1'
          done=1
         endif
         if done eq 0 then PrintF, Out_Hdr, line

       print, line

       ; Read in nsamp and nline for image size
        if strpos(line,'lines') ne -1 and strpos(line,';') eq -1 then begin
           nline=fix(strmid(line,10))
        endif
        if strpos(line,'samples') ne -1 and strpos(line,';') eq -1 then begin
          nsamp=fix(strmid(line,10))
        endif
     endwhile

     ; Read in quality band header for its image size
     while not(eof(HdrQ)) do begin
       readF, HdrQ, line
       print, line
        if strpos(line,'lines') ne -1 and strpos(line,';') eq -1 then begin
         nlineQ=fix(strmid(line,10))
        endif
        if strpos(line,'samples') ne -1 and strpos(line,';') eq -1 then begin
          nsampQ=fix(strmid(line,10))
        endif

       ;  done=0 ;This section only used for 1km output pixels *********
       ;  if (strpos(line,'data type') ne -1) then begin
       ;   PrintF, Out_Hdr, 'data type = 1'
       ;   done=1
       ;  endif
       ;  if done eq 0 then PrintF, Out_Hdr, line
     endwhile

     free_lun, Out_Hdr, Hdr, HdrQ

     print,' samples lines MOD Q =',nsamp,nline,nsampQ,nlineQ

; Read in the MODIS bands from the flat binary files for the current image.
; Read in Terra (MOD) if it exists, otherwise read in Aqua
; IT IS ASSUMED THAT THE QUALITY BAND EXISTS IF THE REFLECTANCE BANDS EXIST

       if TerraExist eq 1 then begin
        MOD_file=ModTerra
        MOD_fileQ=ModTERRA_QA+'.dat'
       endif else begin
        MOD_file=ModAQUA
        MOD_fileQ=ModAQUA_QA+'.dat'
       endelse

     band_state1km=Read_MOD(MOD_dirs[MF]+MOD_fileQ,nsampQ,nlineQ)
 ;    band_state=Read_MOD(MOD_dirs[MF]+MOD_fileQ,nsampQ,nlineQ) ; ******* for 1km output
     band_1=Read_MOD(MOD_dirs[MF]+MOD_file+'_1.dat',nsamp,nline)
     band_2=Read_MOD(MOD_dirs[MF]+MOD_file+'_2.dat',nsamp,nline)
     band_5=Read_MOD(MOD_dirs[MF]+MOD_file+'_5.dat',nsamp,nline)
     band_7=Read_MOD(MOD_dirs[MF]+MOD_file+'_7.dat',nsamp,nline)

;; Resample the MODIS bands (500m) to be same pixel size as the state band (1km pixels) to save memory
;  ***** ONLY FOR 1KM OUTPUT
;     band_1=congrid(band_1,nsampQ,nlineQ)
;     band_2=congrid(band_2,nsampQ,nlineQ)
;     band_5=congrid(band_5,nsampQ,nlineQ)
;     band_7=congrid(band_7,nsampQ,nlineQ)

print,'files read in'
; Resample the cloud and cloud shadow state band (1km pixels) to be the same size as the reflectance bands (500m)
     Refl_Sz=size(band_1)
     band_state=congrid(band_state1km,Refl_Sz[1],Refl_Sz[2])

; Read in MrVBF image to cover same region as MODIS image, then resample to be the same pixel size
      ; First need to read in a MODIS band into ENVI to read its map_info
      envi_open_data_file, MOD_dirs[MF]+MOD_file+'_1.dat', r_fid=In_fid
      temp_map_info=envi_get_map_info(fid=In_fid)
      Input_MODpixX=temp_map_info.PS[0] ; assuming MODIS pixels are square for MrVBF extraction
      Input_MODpixY=temp_map_info.PS[1]
      In_Wlon=temp_map_info.mc[2]
      In_Elon=In_Wlon+nsamp*Input_MODpixX
      In_NLat=temp_map_info.mc[3]
      In_Slat=In_NLat-nline*Input_MODpixY ; assuming all MODIS images have negative Latitudes

      ; Open MrVBF file
      envi_open_data_file, MrVBF_file, r_fid=V_fid

     MrVBF=MrVBF_Geo_Subset(V_fid, Input_MODpixX, nsamp, nline, In_NLat, In_Slat, In_Wlon, In_Elon)

; Calculate the OWL after applying the cloud/cloud shadow mask (Written by Peter Dyce 2009)
      ;get the cloud/cloud shadow mask
       msk_tmp = band_state
       cloud_msk = (msk_tmp * 0 )+1
       n = N_ELEMENTS(cloud_msk)
      ;  set whole image to no cloud .ie no cloud cell = 1
      ; list which of bits to use
      ; set bit no 2 ( 2**2) = 4 for cloud shadow
      ; set bit no 10( 2**10) = 1024 for cloud
      ; these values are added to the maskbitarr[].
      ; reference. MODIS Surface Reflectance User's Guide. V 1.2 June 2008
      ; page 25 Table 15. State QA description (16 bit)
        maskbitarr= [ '4.','1024.' ]
        n = N_ELEMENTS(maskbitarr)
       FOR i=0,n-1 DO BEGIN

       ; get internal cloud algorithm flag
         msk_tmp = band_state and maskbitarr[i]

         where_cloud =  (where(msk_tmp eq maskbitarr[i]))
         m = n_elements(where_cloud)
         print ,'no cells classed as cloud affected = ',m
        ; then set cloud pixels to 0
         if (where_cloud[0] ne -1) then cloud_msk[where_cloud] = 0.0 ; Cate's line

      ENDFOR
     ; last set the array where_cloud to match all zero pixels in cloud_msk.
       where_cloud =  where(cloud_msk eq 0.0)
     ; where_cloud is actually what I used as the mask.

    ; creates mask (pixels with good values in all bands)
    mask_ok = band_1 ne (32767) and $
        band_2 ne (32767) and $
        band_5 ne (32767) and $
        band_7 ne (32767)
    ; identifies the voids in the mosaic image (Note that it should be -28672, but it can be anything less than -20000
       where_voids= where (band_1 lt (-20000) and $
                     band_2 lt (-20000) and $
                     band_5 lt (-20000) and $
                     band_7 lt (-20000))

print,'OWI calculations beginning

    ; NEW OWL ALGORITHM
    ; define beta for calculating OWL
     B=[-3.41375620,-0.000959735270,0.00417955330,14.1927990,-0.430407140,-0.0961932990]

    ; Calculate the new OWL and mask salt-lakes that dont have water
    ;Z=B[0]+B[1]*SWIR1+B[2]*SWIR3+B[3]*[[float(NIR-RED)]/[float(NIR+RED)]]+B[4]*[[float(NIR-SWIR1)]/[float(NIR+SWIR1)]]+B[5]*MrVBF
    Z=B[0]+B[1]*band_5+B[2]*band_7+B[3]*[[float(band_2-band_1)]/[float(band_2+band_1)]]+B[4]*[[float(band_2-band_5)]/[float(band_2+band_5)]]+B[5]*MrVBF
    print,'sizeZ=',size(Z)

    OWL=byte(100*[[1./[1.+exp(Z)]]])
    ;print,'band 1 2 5 7 VBF Z pix=',band_1[5640,2040],band_2[5640,2040],band_5[5640,2040],band_7[5640,2040],MrVBF[5640,2040],Z[5640,2040]
    ;print,'OWL =',OWL[5640,2040]

        ; mask out cloud and null values
        where_LT_0 = where(owl lt 0)
        where_GE_100 = where(owl gt 100)
        where_nulls=where(mask_ok eq 0)
        where_Ocean=where(MrVBF eq -9999)

        if where_LT_0[0] ne -1 then owl[where_LT_0] =   255       ;set any thing less than zero -> to null
        if where_GE_100[0] ne -1 then owl[where_GE_100] = 255
        if where_cloud[0] ne -1 then owl[where_cloud]   = 250   ;-1.0  ;set cloud to NAN
        if where_voids[0] ne -1 then owl[where_voids]   = 255   ;-2.0  ;set no data  to NAN
        if where_nulls[0] ne -1 then OWL[where_nulls]= 255
        if where_Ocean[0] ne -1 then owl[where_Ocean]=255

; Convert image to byte format to save space
        OWL = byte(owl)

; Write the final MODIS OWL water band to output file

     OpenW, Out, OutFile, /Get_lun
     WriteU, Out, OWL
     Free_lun, Out

; Place the image on an Australian wide mosaic (Note the final image size is forced to a set pixel size)
     Out_name=OutFile+'_Oz'
     envi_open_data_file, OutFile, r_fid=ref_fid
     map_info=envi_get_map_info(fid=ref_fid)

     Subset_Image=-1
     SubsetImage=MODIS_Geo_Subset(ref_fid, out_name, Final_MODpix, MODsamp, MODline, final_OutName, HDR_done)
    ; SubsetImage=MODIS_Geo_Subset(OutFile, out_name, Final_MODpix, MODsamp, MODline, final_OutName, HDR_done)
     HDR_done=1
     if SubsetImage[0] eq -1 then print, 'Problem with subset

     if OWL_exists eq 0 then OWL_Oz=SubsetImage else begin
      ; Combine existing MODIS images from the same day - use maximum water value when there are two valid values
      Cloud_Msk=SubsetImage
      Cloud_Msk[*,*]=250B
      Null_Msk=SubsetImage
      Null_Msk[*,*]=255B

      where_max=where((SubsetImage gt OWL_Oz) and (SubsetImage lt Cloud_Msk))
      if where_max[0] ne -1 then OWL_Oz[where_max]=SubsetImage[where_max]

      where_clouds_overNulls=where((SubsetImage eq Cloud_Msk) and (OWL_Oz eq Null_Msk))
      if where_clouds_overNulls[0] ne -1 then OWL_Oz[where_clouds_overNulls]=SubsetImage[where_clouds_overNulls]

      where_land_overClouds=where((SubsetImage lt Cloud_Msk) and (OWL_Oz ge Cloud_Msk))
      if where_land_overClouds[0] ne -1 then OWL_Oz[where_land_overCLouds]=SubsetImage[where_land_overClouds]

     endelse
     OWL_exists=1

  endif ;else OWL_Oz=-99 ; if no MODIS images exist

endfor
endif else OWL_Oz=-99 ; if no input directories exist

; Output the final combined OWI image for the day (header is output within MODIS_geo_Subset function
     if OWL_Oz[0] ne -99 then begin
       OpenW, Out, Final_OutName, /Get_Lun
       WriteU, Out, OWL_Oz
       free_lun, Out
     endif
print,'MODsamp MODline=',MODsamp,MODline,Final_MODpix

print,'MODIS_OWL done'
return, OWL_Oz
end

;*****************************************************************************************************
 ; This function reads in the MODIS images (all intarr) as flat binary files
 function Read_MOD, FileName, ns, nl

   OpenR, InFl, FileName, /Get_lun

   ; the QA band is unsigned integer, while the reflectance bands are integer
   if strpos(FileName,'QA') ne -1 then Band=uintarr(ns,nl) else Band=intarr(ns,nl)
   ReadU, InFl, Band
   Free_lun, InFl

 return, Band
 end

;*****************************************************************************************************
 ; This function averages bands based on the new image, and the old averaged image
 function Image_Average, Image_comb, Image_water, F

        CombSz=size(Image_Comb)
        WtrSz=size(Image_water)

        if (CombSz[1] ne WtrSz[1]) or (CombSz[2] ne WtrSz[2]) then stop, "two images are different sizes"

        ; dont average where there are clouds or null values
        where_nulls=where(Image_comb eq -2)
        if where_nulls[0] ne -1 then Image_comb[where_nulls]=Image_water[where_nulls]
        where_cloud=where((Image_comb eq -1) and (Image_water ne -2))
        if where_cloud[0] ne -1 then Image_comb[where_cloud]=Image_water[where_cloud]
        where_average=where((Image_comb ge 0) and (Image_water ge 0))
        if where_average[0] ne -1 then Image_comb[where_average]= $
                     Image_comb[where_average]*(float(F)/float(F+1))+Image_water[where_average]/float(F+1)

 return, Image_comb
 end

;----------------------------------------------------------------------------------------------
; This function subsets a MODIS georeferenced band so they are all exactly the same size, and cover the same
; extent. Note that since these images are OWI, the data type is BYTE - to save memory
; NOTE the assumption is made the the input image is in byte format

function MODIS_Geo_Subset, fid, out_name, Final_MODpix, MODsamp, MODline, Final_OutName, HDR_done

COMMON share, NLat, Slat, Wlon, Elon
         ;TopLat, BotLat, TopLon, BotLon,

     done=0
     envi_file_query, fid, dims=dims, data_type=data_type

  print,'file dims =',dims
  print,'datatype =',data_type
  MaxSamp=dims[2]
  MaxLine=dims[4]

  map_info=envi_get_map_info(fid=fid)

  ; work out image size and coordinates
  PixSizeX=map_info.PS[0]
  PixSizeY=map_info.PS[1]

  XMap=WLon
  YMap=NLat

  ;Samp=fix((ELon-WLon)/PixSizeX)+2 ;1 (+2 gives it correct South Lat and West Long)
  ;Line=fix((NLat-SLat)/PixSizeY)+2 ;1 ; swap latitude subtraction since they are negatives
  Samp=round((ELon-WLon)/PixSizeX) ;1 (+2 gives it correct South Lat and West Long)
  Line=round((NLat-SLat)/PixSizeY) ;1 ; swap latitude subtraction since they are negatives

  print,'PixSizeX PixSizeY =',PixSizeX,PixSizeY
  print,'XMap YMap=',XMap,YMap
  print,'samp line =',samp,line

  map_info.mc[2]=Xmap
  map_info.mc[3]=Ymap

  envi_convert_file_coordinates, fid, XF, YF, XMap, YMap ; IDL coordinates are ENVI coords-1

  print,'XF YF=',XF, YF
  ; need to stop XF/YF becoming rounded down to nearest integer if it is closer to the higher integer
  if XF ge 0 then begin
    if XF-fix(XF) gt 0.5 then XF=fix(XF)+1 else XF=fix(XF)
  endif else begin
    if abs(XF-fix(XF)) gt 0.5 then XF=fix(XF)-1 else XF=fix(XF)
  endelse

  if YF ge 0 then begin
   if YF-fix(YF) gt 0.5 then YF=fix(YF)+1 else YF=fix(YF)
  endif else begin
   if abs(YF-fix(YF)) gt 0.5 then YF=fix(YF)-1 else YF=fix(YF)
  endelse
  print,'new XF YF=',XF, YF

  dims[1]=XF
  dims[2]=XF+Samp-1
  dims[3]=YF ; dont get negative YF since images are swaths
  dims[4]=YF+Line-1

  if dims[1] lt 0 then begin
    dims[1]=0
    dims[2]=dims[2]+1
  endif
  if dims[3] lt 0 then begin
    dims[3]=0
    dims[4]=dims[4]+1
  endif

  if dims[2] gt MaxSamp then dims[2]=MaxSamp
  if dims[4] gt MaxLine then dims[4]=MaxLine

  print,'new dims =',dims

  dataSub=envi_get_data(fid=fid, dims=dims, pos=0, interp=0)
print,'datasubset dims =',dims

; Check that the file size covers the full subset area, otherwise output the section that does.

  ;print, size(dataSub)
  DatSize=size(dataSub)

   ; Need to force output image to have pixel size of Final_MODpix
       xfactor=1.*map_info.ps[0]/Final_MODpix
       yfactor=1.*map_info.ps[1]/Final_MODpix

; write subset to new file
  if (DatSize[1] eq Samp) and (DatSize[2] eq Line) then begin

       ;Get the data again at the new pixel size
       DataSub_NewSz=envi_get_data(dims=dims,fid=fid,pos=0,interp=0,xfactor=xfactor,yfactor=yfactor)
       map_info.ps[0]=Final_MODpix
       map_info.ps[1]=Final_MODpix
       New_size=size(DataSub_NewSz)
       New_samp=New_size[1]
       New_Line=New_size[2]

       ; Do one last resize since the pixel size may vary by up to one pixel
       DataSub_NewSz=congrid(DataSub_NewSz,MODsamp,MODline)

       print,'out_name=',out_name
       OpenW, Out, Out_name, /Get_Lun
       WriteU, Out, DataSub_NewSz

       envi_setup_head, fname=out_name, Data_type=1, Interleave=0, nb=1, ns=MODsamp, nl=MODline, $
                        offset=0, /write, map_info=map_info

       free_lun, out
  endif else begin ; Image only covers part of the area of interest

       ImageOut=bytarr(Samp,Line)
       ImageOut[*,*]=255 ; the null value
       print,'Samp DatSize1 Line datsize2=',Samp, DatSize[1], Line, DatSize[2]
       print,'dims=',dims
       ;ImageOut[Samp-DatSize[1]:Samp-1,Line-DatSize[2]:Line-1]=DataSub
       if dims[1] eq 0 then begin
          ;StartS=Samp-DatSize[1] ; only works if the subset is at the left corner of the image
          StartS=dims[1]-XF
          print,'StartS XF =',StartS, XF
          print,'StartS+DatSize[1]-1=',StartS+DatSize[1]-1
          print,'Samp-1=',Samp-1
          if (StartS+DatSize[1]-1 lt Samp-1) then StopS=StartS+DatSize[1]-1 else begin
            StopS=Samp-1
            TempSub=DataSub
            DataSub=bytarr(DatSize[1]-1,DatSize[2]); Need to do this shift due to the dataset starting from zero
            DataSub=TempSub[0:DatSize[1]-2,*]
          endelse
          print,'in a'
       endif else begin
          StartS=0
          StopS=DatSize[1]-1
          print,'in b'
       endelse
       if dims[3] eq 0 then begin ; this part should not happen due to swath data being used
          ;StartL=Line-DatSize[2]
          StartL=dims[3]-YF
          if (StartL+DatSize[2]-1 lt Line-1) then StopL=StartL+DatSize[2]-1 else begin
            StopL=Line-1
            TempSub=DataSub
            DataSub=bytarr(DatSize[1],DatSize[2]-1) ; Need to do this shift due to the dataset starting from zero
            DataSub=TempSub[*,0:DatSize[2]-2]
          endelse
       endif else begin
          StartL=0
          StopL=Datsize[2]-1 ;Line-1
       endelse

       print,'StartS StopS StartL StopL=',StartS,StopS,StartL,StopL

       if ((StopS gt 0) and (StopL gt 0)) then begin
        ImageOut[StartS:StopS,StartL:StopL]=DataSub
       endif else ImageOut[*,*]=255

       ;Get the data again at the new pixel size
       envi_write_envi_file, ImageOut, /in_memory, r_fid=fidR
       envi_file_query, fidR, dims=NewDims
       DataSub_NewSz=envi_get_data(dims=NewDims,fid=fidR,pos=0,interp=0,xfactor=xfactor,yfactor=yfactor)
       map_info.ps[0]=Final_MODpix
       map_info.ps[1]=Final_MODpix
       New_size=size(DataSub_NewSz)
       New_samp=New_size[1]
       New_Line=New_size[2]
       print,'newdims x Yfactor=',newDims, xfactor, yfactor

       ; Do one last resize since the pixel size may vary by up to one pixel
       DataSub_NewSz=congrid(DataSub_NewSz,MODsamp,MODline)

       print,'out_name with 1 1 xystart=',out_name
       OpenW, Out, Out_name, /Get_Lun
       WriteU, Out, DataSub_NewSz

       envi_setup_head, fname=out_name, Data_type=1, Interleave=0, nb=1, ns=MODsamp, nl=MODline, $
                        offset=0, /write, map_info=map_info

       free_lun, out

  endelse

  ; Output header file of final combined MODIS OWI for current day during the first loop
      if HDR_done eq 0 then begin
        envi_setup_head, fname=Final_OutName, Data_type=1, Interleave=0, nb=1, ns=MODsamp, nl=MODline, $
                        offset=0, /write, map_info=map_info
      endif

;done=1
return, DataSub_NewSz
end

;----------------------------------------------------------------------------------------------
; This function subsets a MrVBF georeferenced band so it covers the same size and extent as the
; current input MODIS (whose extent and size varies).
; NOTE the assumption is made the the input image is in float format

function MrVBF_Geo_Subset, fid, Final_MODpix, MODsamp, MODline, NLat, Slat, Wlon, Elon

;COMMON share, NLat, Slat, Wlon, Elon
;         ;TopLat, BotLat, TopLon, BotLon,

     done=0
     envi_file_query, fid, dims=dims, data_type=data_type

  print,'file dims =',dims
  print,'datatype =',data_type
  MaxSamp=dims[2]
  MaxLine=dims[4]

  map_info=envi_get_map_info(fid=fid)

  ; work out image size and coordinates
  PixSizeX=map_info.PS[0]
  PixSizeY=map_info.PS[1]

  XMap=WLon
  YMap=NLat

  Samp=round((ELon-WLon)/PixSizeX)
  Line=round((NLat-SLat)/PixSizeY)

  print,'PixSizeX PixSizeY =',PixSizeX,PixSizeY
  print,'XMap YMap=',XMap,YMap
  print,'samp line =',samp,line

  map_info.mc[2]=Xmap
  map_info.mc[3]=Ymap

  envi_convert_file_coordinates, fid, XF, YF, XMap, YMap ; IDL coordinates are ENVI coords-1

  print,'XF YF=',XF, YF
  ; need to stop XF/YF becoming rounded down to nearest integer if it is closer to the higher integer
  if XF ge 0 then begin
    if XF-fix(XF) gt 0.5 then XF=fix(XF)+1 else XF=fix(XF)
  endif else begin
    if abs(XF-fix(XF)) gt 0.5 then XF=fix(XF)-1 else XF=fix(XF)
  endelse

  if YF ge 0 then begin
   if YF-fix(YF) gt 0.5 then YF=fix(YF)+1 else YF=fix(YF)
  endif else begin
   if abs(YF-fix(YF)) gt 0.5 then YF=fix(YF)-1 else YF=fix(YF)
  endelse
  print,'new XF YF=',XF, YF

  dims[1]=XF
  dims[2]=XF+Samp-1
  dims[3]=YF ; dont get negative YF since images are swaths
  dims[4]=YF+Line-1

  if dims[1] lt 0 then begin
    dims[1]=0
    dims[2]=dims[2]+1
  endif
  if dims[3] lt 0 then begin
    dims[3]=0
    dims[4]=dims[4]+1
  endif

  if dims[2] gt MaxSamp then dims[2]=MaxSamp
  if dims[4] gt MaxLine then dims[4]=MaxLine

  print,'new dims =',dims

  dataSub=envi_get_data(fid=fid, dims=dims, pos=0, interp=0)
print,'datasubset dims =',dims

; Check that the file size covers the full subset area, otherwise output the section that does.

  ;print, size(dataSub)
  DatSize=size(dataSub)

   ; Need to force output image to have pixel size of Final_MODpix
       xfactor=1.*map_info.ps[0]/Final_MODpix
       yfactor=1.*map_info.ps[1]/Final_MODpix

; write subset to new file
  if (DatSize[1] eq Samp) and (DatSize[2] eq Line) then begin

       ;Get the data again at the new pixel size
       DataSub_NewSz=envi_get_data(dims=dims,fid=fid,pos=0,interp=0,xfactor=xfactor,yfactor=yfactor)
       map_info.ps[0]=Final_MODpix
       map_info.ps[1]=Final_MODpix
       New_size=size(DataSub_NewSz)
       New_samp=New_size[1]
       New_Line=New_size[2]

       ; Do one last resize since the pixel size may vary by up to one pixel
       DataSub_NewSz=congrid(DataSub_NewSz,MODsamp,MODline)

  endif else begin ; Image only covers part of the area of interest

       ImageOut=fltarr(Samp,Line)
       ImageOut[*,*]=255. ; the null value
       print,'Samp DatSize1 Line datsize2=',Samp, DatSize[1], Line, DatSize[2]
       print,'dims=',dims
       ;ImageOut[Samp-DatSize[1]:Samp-1,Line-DatSize[2]:Line-1]=DataSub
       if dims[1] eq 0 then begin
          ;StartS=Samp-DatSize[1] ; only works if the subset is at the left corner of the image
          StartS=dims[1]-XF
          print,'StartS XF =',StartS, XF
          print,'StartS+DatSize[1]-1=',StartS+DatSize[1]-1
          print,'Samp-1=',Samp-1
          if (StartS+DatSize[1]-1 lt Samp-1) then StopS=StartS+DatSize[1]-1 else begin
            StopS=Samp-1
            TempSub=DataSub
            DataSub=fltarr(DatSize[1]-1,DatSize[2]); Need to do this shift due to the dataset starting from zero
            DataSub=TempSub[0:DatSize[1]-2,*]
          endelse
          print,'in a'
       endif else begin
          StartS=0
          StopS=DatSize[1]-1
          print,'in b'
       endelse
       if dims[3] eq 0 then begin ; this part should not happen due to swath data being used
          ;StartL=Line-DatSize[2]
          StartL=dims[3]-YF
          if (StartL+DatSize[2]-1 lt Line-1) then StopL=StartL+DatSize[2]-1 else begin
            StopL=Line-1
            TempSub=DataSub
            DataSub=fltarr(DatSize[1],DatSize[2]-1) ; Need to do this shift due to the dataset starting from zero
            DataSub=TempSub[*,0:DatSize[2]-2]
          endelse
       endif else begin
          StartL=0
          StopL=Datsize[2]-1 ;Line-1
       endelse

       print,'StartS StopS StartL StopL=',StartS,StopS,StartL,StopL

       if ((StopS gt 0) and (StopL gt 0)) then begin
        ImageOut[StartS:StopS,StartL:StopL]=DataSub
       endif else ImageOut[*,*]=255

       ;Get the data again at the new pixel size
       envi_write_envi_file, ImageOut, /in_memory, r_fid=fidR
       envi_file_query, fidR, dims=NewDims
       DataSub_NewSz=envi_get_data(dims=NewDims,fid=fidR,pos=0,interp=0,xfactor=xfactor,yfactor=yfactor)
       map_info.ps[0]=Final_MODpix
       map_info.ps[1]=Final_MODpix
       New_size=size(DataSub_NewSz)
       New_samp=New_size[1]
       New_Line=New_size[2]
       print,'newdims x Yfactor=',newDims, xfactor, yfactor

       ; Do one last resize since the pixel size may vary by up to one pixel
       DataSub_NewSz=congrid(DataSub_NewSz,MODsamp,MODline)

  endelse

return, DataSub_NewSz
end

