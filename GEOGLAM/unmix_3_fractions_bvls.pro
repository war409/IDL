function unmix_3_fractions_bvls, spectra, endmembers, lower_bound=lower_bound, upper_bound=upper_bound, sum2oneWeight=sum2oneWeight
  compile_opt idl2
  
  IF ( NOT KEYWORD_SET( lower_bound ) ) THEN lower_bound = 0.0
  IF ( NOT KEYWORD_SET( upper_bound ) ) THEN upper_bound = 1.0
  IF ( NOT KEYWORD_SET( sum2oneWeight ) ) THEN sum2oneWeight = 1.0
  
  size_endmembers = Size(endmembers) 
  size_spectra    = Size(spectra)
  
  unmixed = fltarr(size_spectra[2], size_endmembers[2]) & unmixed[*] = !VALUES.F_NAN
  
    AA = [endmembers,fltarr(1,size_endmembers[2])+sum2oneWeight]
    
    BND = fltarr(2, size_endmembers[2])
    BND[0, *] = lower_bound * 1.0
    BND[1, *] = upper_bound * 1.0
    
     
    for i=0, size_spectra[2]-1 do begin
      A = AA
      B = [spectra[*, i], 1]
      bvls, A, B, BND, X_BVLS
      unmixed[i, *] = X_BVLS
    endfor 

    return, unmixed
    
end

    
    