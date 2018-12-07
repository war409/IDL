















PRO subset_via_evf

  
  files = DIALOG_PICKFILE(PATH='\\osm-08-mel.it.csiro.au\OSM_MEL_LW_RRMARCHIVE_archive\Users\war409\Projects\Fault_related_lineaments\Data\', TITLE='Select The Input Data', FILTER=['*.img','*.flt','*.bin','*.dat'], /MUST_EXIST, /MULTIPLE_FILES)
  IF files[0] EQ '' THEN RETURN ; Error check.
  files = files[SORT(files)] ; Sort the input file list.
  
  
  
  ; Remove the file path from the input filenames...
  
  start = STRPOS(files, '\', /REVERSE_SEARCH)+1 ; Get the position of the first filename character (after the file path).
  length = (STRLEN(files)-start)-4 ; Get the length of each path-less filename.
  names = MAKE_ARRAY(N_ELEMENTS(files), /STRING) ; Create an array to store the input file names.
  
  FOR k=0, N_ELEMENTS(files)-1 DO BEGIN ; Fill the filename array.
    names[k] += STRMID(files[k], start[k], length[k]) ; Get the kth filename (remove the file path).
  ENDFOR
  
  
  
  
  Mask_evf_fname = '\\osm-08-mel.it.csiro.au\OSM_MEL_LW_RRMARCHIVE_archive\Users\war409\Projects\Fault_related_lineaments\Data\SP_Area_of_interest_May2017.evf'
  Mask_evf_id = envi_evf_open(Mask_evf_fname)
  
  
  
  
  

  
  ;get info for the evf to be used as a mask
  envi_evf_info, Mask_evf_id, num_recs=Mask_num_recs, $ 
    data_type=Mask_data_type, projection=Mask_projection, $ 
    layer_name=Mask_layer_name
  
  
  
  
;  ;get info for the evf to be used as a subset  
;  envi_evf_info, subs_evf_id, num_recs=subs_num_recs, $ 
;    data_type=subs_data_type, projection=subs_projection, $ 
;    layer_name=subs_layer_name
  
  
  for i=0, Mask_num_recs-1 do begin 
    Mask_record = envi_evf_read_record(Mask_evf_id, i, type=5)
  endfor
  
  
  
  for i=0, subs_num_recs-1 do begin 
    subs_record = envi_evf_read_record(subs_evf_id, i, type=5)
  endfor
  
  
  
    ENVI_OPEN_FILE, files[0], r_fid=fid
    
    if(fid eq -1) then begin
      ENVI_BATCH_EXIT
      return
    endif
  
  
  
  ENVI_FILE_QUERY, fid, dims=dims, fname=fname, ns=ns, nl=nl, nb=nb
  map_info = envi_get_map_info(fid=fid)
  
  ;changing to each image directory so the roi can be saved into the same directory
  convert_dir=STRING(files[0])
  backslash=STRPOS(convert_dir, '\', /REVERSE_SEARCH)
  directory=STRMID(convert_dir, 0, backslash+1)
  cd, directory
  
  ;remove the .shp and change it to .roi, add 'Therm' when doing the thermal band
  Mask_rmvSHP = FILE_BASENAME(Mask_layer_name, '.shp') + 'Therm_.roi'
  subs_rmvSHP = FILE_BASENAME(subs_layer_name, '.shp') + 'Therm_.roi'
  
  ;remove the 'Layer: ' from the front of the file name
  Mask_roi_out_name = STRMID(Mask_rmvSHP, 7)
  subs_roi_out_name = STRMID(subs_rmvSHP, 7)
  
  ;add 'therm' when processing the thermal band
  mask_out_name = '9293_84overlapTherm_mask'
  file_out_name = fname + '_overlapTherm_subs'
  
  
  ;convert the map coordinates to image coordinates
  envi_convert_file_coordinates,fid,Mask_xf,Mask_yf, $
    Mask_record[0,*], Mask_record[1,*]
    
    Mask_roi_id = ENVI_CREATE_ROI(ns=ns, nl=nl, $
       color=4, name='Mask_evfs')
    
    Mask_xpts=reform(Mask_xf)
    Mask_ypts=reform(Mask_yf)
    
  envi_convert_file_coordinates,fid,subs_xf,subs_yf, $
    subs_record[0,*], subs_record[1,*]
    
    subs_roi_id = ENVI_CREATE_ROI(ns=ns, nl=nl, $
       color=4, name='subs_evfs')
    
    subs_xpts=reform(subs_xf)
    subs_ypts=reform(subs_yf)  
  
  
  
  
  ENVI_DEFINE_ROI, Mask_roi_id, /polygon, xpts=Mask_xpts, ypts=Mask_ypts
  
  ENVI_DEFINE_ROI, subs_roi_id, /polygon, xpts=subs_xpts, ypts=subs_ypts
  
  
  
  
  
  Mask_roi_ids = envi_get_roi_ids(fid=fid)
     envi_save_rois, Mask_roi_out_name, Mask_roi_ids
  
  subs_roi_ids = envi_get_roi_ids(fid=fid)
     envi_save_rois, subs_roi_out_name, subs_roi_ids
  
  subs_roi_dims = ROUND([-1L, min(subs_xf), max(subs_xf), min(subs_yf), max(subs_yf)])
    
  mask= BYTARR([ns,nl])
  ;roi_ids = envi_get_roi_ids(fid=fid)
  addr = ENVI_GET_ROI(Mask_roi_ids[0])
  mask[addr]=1
  
  
  
  ENVI_WRITE_ENVI_FILE, mask, BNAMES='mask', DATA_TYPE=1, MAP_INFO=map_info, $
    r_fid=m_fid, OUT_NAME=mask_out_name
  
  
  
  
  
  ;the pos will need to change depending on the number of bands
  ;in the chosen file
  ;landsat 5 stack, not including the termal band
  ;pos=[0,1,2,3,4,5]
  ;thermal band, when processed as a single image, not a stack
  pos=[0]
  
  
  
  
  
  
  ENVI_DOIT, 'ENVI_MASK_APPLY_DOIT', DIMS=subs_roi_dims, fid=fid, m_fid=m_fid, m_pos=0, $ 
    VALUE=0, OUT_NAME=file_out_name, r_fid=r_fid, pos=pos
  
;  ENVI_DELETE_ROIS, /ALL
  
    
    
    
  
  
  
  
  
  
  

end




