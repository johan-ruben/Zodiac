FUNCTION gs_Image::Init, imgData, nonNegative = nonNegative

  compile_opt idl2
  
  self.imgData = Ptr_New(/allocate_heap)
  self.nonNegative = !false
  self.isCompressed = !false
    
  case 1B of
    ~Isa(imgData, /number, /array): Message, 'Data must be a numeric array.'
    else:
  endcase
  
  self.nDimensions = Size(imgData, /n_dimensions)
  case imgData.typeCode of
    5: self.numberFormat = 'double'
    else: self.numberFormat = 'single'
  endcase
  
  self.dataDims = List(imgData.dim, /extract)
  
  if ~StrCmp(self.numberFormat, 'double', /fold_case) then *self.imgData = Float(imgData) else *self.imgData = imgData
  
  if KeyWord_Set(nonNegative) then begin
    self.nonNegative = !true
    *self.imgData >= 0.
  endif
  
  Return, 1
  
END

;========================================================================================

PRO gs_Image::CleanUp

  compile_opt idl2
    
  if Ptr_Valid(self.imgData) then Ptr_Free, self.imgData
  if Obj_Valid(self.dataDims) then Obj_Destroy, self.dataDims
  
  if self.offloadHandle ne '' then begin
    ShmUnMap, self.offloadHandle
    File_Delete, self.offload
  endif
  
END

;========================================================================================

PRO gs_Image::GetProperty, nDimensions = nDimensions, dataDims = dataDims, imgData = imgData, numberFormat = numberFormat, nonNegative = nonNegative, isCompressed = isCompressed

  compile_opt idl2
  
  if Arg_Present(nDimensions) then nDimensions = self.nDimensions
  if Arg_Present(dataDims) then dataDims = self.dataDims.ToArray()
  
  if Arg_Present(imgData) then begin
    
    if self.isCompressed then begin
      if StrCmp(self.numberFormat, 'double', /fold_case) then tp = 5 else tp = 4
      imgData = Zlib_Uncompress(*self.imgData, /gzip_header, dimensions = self.dataDims.ToArray(), type = tp)
    endif else begin
      imgData = *self.imgData
    endelse
    
  endif
  
  if Arg_Present(numberFormat) then numberFormat = self.numberFormat
  if Arg_Present(nonNegative) then nonNegative = self.nonNegative 
  if Arg_Present(isCompressed) then isCompressed = self.isCompressed
END

;=========================================================================================

FUNCTION gs_Image::_OverloadPlus, left, right, _extra = extra

  compile_opt idl2
  
  className = Tag_Names(self, /structure_name)
  
  case 1B of
    
    Isa(left, /scalar) && Obj_Valid(left) && Obj_Isa(left, 'gs_Image') && Isa(right, /scalar) && Obj_Valid(right) && Obj_Isa(right, 'gs_Image'): begin
      
      case 1B of
        left.nDimensions ne right.nDimensions: Message, 'Number of dimensions does not match.'
        jg_Any(left.dataDims ne right.dataDims): Message, 'Matrix size mis-match.'
        else:
      endcase
            
      Return, Obj_New(className, left.imgData + right.imgData, nonNegative = left.nonNegative && right.nonNegative, _extra = extra)
      
    end
    
    Obj_Valid(left) && Obj_Isa(left, 'gs_Image') && Isa(right, /number, /array): begin
      
      case 1B of
        left.nDimensions ne right.nDim: Message, 'Number of dimensions does not match.'
        jg_Any(left.dataDims ne right.dim): Message, 'Matrix size mis-match.'
        else:
      endcase
      
      Return, Obj_New(className, left.imgData + right, nonNegative = left.nonNegative, _extra = extra)
      
    end
    
    Obj_Valid(right) && Obj_Isa(right, 'gs_Image') && Isa(left, /number, /array): begin

      case 1B of
        right.nDimensions ne left.nDim: Message, 'Number of dimensions does not match.'
        jg_Any(right.dataDims ne left.dim): Message, 'Matrix size mis-match.'
        else:
      endcase

      Return, Obj_New(className, right.imgData + left, nonNegative = right.nonNegative, _extra = extra)

    end
    
    Obj_Valid(left) && Obj_Isa(left, 'gs_Image') && Isa(right, /scalar, /number): begin
      
      Return, Obj_New(className, left.imgData + right, nonNegative = left.nonNegative, _extra = extra)
      
    end
    
    Obj_Valid(right) && Obj_Isa(right, 'gs_Image') && Isa(left, /scalar, /number): begin

      Return, Obj_New(className, right.imgData + left, nonNegative = right.nonNegative, _extra = extra)

    end
    
    else: Message, 'Addition not defined for operands.'
    
  endcase

END

;========================================================================================

FUNCTION gs_Image::GetRegion, regions, name, _extra = extra

  compile_opt idl2
  
  case 1B of
    ~Obj_Valid(regions) || ~Obj_Isa(regions, 'gs_RegionMap'): Message, 'Regions must be specified as gs_RagionMap.'
    ~Array_Equal(regions.dataDims, self.dataDims.ToArray()): Message, 'Data dimensions do not agree.'
    else:
  endcase
  
  ii = regions.Indices(name)
  
  case self.numberFormat of
    'single': imgData = FltArr(self.dataDims.ToArray())
    'double': imgData = DblArr(self.dataDims.ToArray())
  endcase
  
  imgData[ii] = (*self.imgData)[ii]
  
  className = Tag_Names(self, /structure_name)
  Return, Obj_New(className, imgData, nonNegative = self.nonNegative, _extra = extra)
  
END

;========================================================================================

FUNCTION gs_Image::Rescale, rescaler, regions, _extra = extra

  compile_opt idl2
  
  case 1B of
    ~Obj_Valid(rescaler) || ~Obj_Isa(rescaler, 'gs_rescaler'): Message, 'Rescaler must be of type gs_Rescaler.'
    ~Obj_Valid(regions) || ~Obj_Isa(regions, 'gs_RegionMap'): Message, 'Region map must be of type gs_RegionMap.'
    else:
  endcase
    
  img = DblArr(self.dataDims.ToArray())
  
  foreach name, regions.names do begin
    
    ii = regions.Indices(name, count = count)
    if count gt 0 then img[ii] = rescaler.Rescale((*self.imgData)[ii], name)
    
  endforeach
  
  className = Tag_Names(self, /structure_name)
  Return, Obj_New(className, img, nonNegative = self.nonNegative, _extra = extra)
  
END

;========================================================================================

FUNCTION gs_Image::_OverloadMinus, left, right, _extra = extra

  compile_opt idl2
    
  className = Tag_Names(self, /structure_name)
  
  case 1B of

    Obj_Valid(left) && Obj_Isa(left, 'gs_Image') && Obj_Valid(right) && Obj_Isa(right, 'gs_Image'): begin

      case 1B of
        left.nDimensions ne right.nDimensions: Message, 'Number of dimensions does not match.'
        jg_Any(left.dataDims ne right.dataDims): Message, 'Matrix size mis-match.'
        else:
      endcase

      Return, Obj_new(className, left.imgData - right.imgData, nonNegative = left.nonNegative && right.nonNegative, _extra = extra)

    end

    Obj_Valid(left) && Obj_Isa(left, 'gs_Image') && Isa(right, /number, /array): begin

      case 1B of
        left.nDimensions ne right.nDim: Message, 'Number of dimensions does not match.'
        jg_Any(left.dataDims ne right.dim): Message, 'Matrix size mis-match.'
        else:
      endcase

      Return, Obj_new(className, left.imgData - right, nonNegative = left.nonNegative, _extra = extra)

    end

    Obj_Valid(right) && Obj_Isa(right, 'gs_Image') && Isa(left, /number, /array): begin

      case 1B of
        right.nDimensions ne left.nDim: Message, 'Number of dimensions does not match.'
        jg_Any(right.dataDims ne left.dim): Message, 'Matrix size mis-match.'
        else:
      endcase

      Return, Obj_new(className, -right.imgData + left, nonNegative = right.nonNegative, _extra = extra)

    end

    Obj_Valid(left) && Obj_Isa(left, 'gs_Image') && Isa(right, /scalar, /number): begin

      Return, Obj_new(className, left.imgData - right, nonNegative = left.nonNegative, _extra = extra)

    end

    Obj_Valid(right) && Obj_Isa(right, 'gs_Image') && Isa(left, /scalar, /number): begin

      Return, Obj_new(className, -right.imgData + left, nonNegative = right.nonNegative, _extra = extra)

    end

    else: Message, 'Subtraction not defined for operands.'

  endcase

END

;=========================================================================================

FUNCTION gs_Image::_OverloadMinusUnary, _extra = extra

  compile_opt idl2
  
  className = Tag_Names(self, /structure_name)
  Return, Obj_New(className, -(*self.imgData), _extra = extra)

END

;=========================================================================================

FUNCTION gs_Image::_OverloadAsterisk, left, right, _extra = extra

  compile_opt idl2
  
  className = Tag_Names(self, /structure_name)
  
  case 1B of

    Isa(left, /scalar) && Obj_Valid(left) && Obj_Isa(left, 'gs_Image') && Isa(right, /scalar) && Obj_Valid(right) && Obj_Isa(right, 'gs_Image'): begin

      case 1B of
        left.nDimensions ne right.nDimensions: Message, 'Number of dimensions does not match.'
        jg_Any(left.dataDims ne right.dataDims): Message, 'Matrix size mis-match.'
        else:
      endcase

      Return, Obj_new(className, left.imgData*right.imgData, nonNegative = left.nonNegative && right.nonNegative, _extra = extra)

    end

    Obj_Valid(left) && Obj_Isa(left, 'gs_Image') && Isa(right, /number, /array): begin

      case 1B of
        left.nDimensions ne right.nDim: Message, 'Number of dimensions does not match.'
        jg_Any(left.dataDims ne right.dim): Message, 'Matrix size mis-match.'
        else:
      endcase

      Return, Obj_new(className,left.imgData*right, nonNegative = left.nonNegative, _extra = extra)

    end

    Obj_Valid(right) && Obj_Isa(right, 'gs_Image') && Isa(left, /number, /array): begin

      case 1B of
        right.nDimensions ne left.nDim: Message, 'Number of dimensions does not match.'
        jg_Any(right.dataDims ne left.dim): Message, 'Matrix size mis-match.'
        else:
      endcase

      Return, Obj_new(className,right.imgData*left, nonNegative = right.nonNegative, _extra = extra)

    end

    Obj_Valid(left) && Obj_Isa(left, 'gs_Image') && Isa(right, /scalar, /number): begin

      Return, Obj_new(className,left.imgData *right, nonNegative = left.nonNegative, _extra = extra)

    end

    Obj_Valid(right) && Obj_Isa(right, 'gs_Image') && Isa(left, /scalar, /number): begin

      Return, Obj_new(className,right.imgData*left, nonNegative = right.nonNegative, _extra = extra)

    end

    else: Message, 'Multiplication not defined for operands.'

  endcase


END

;=========================================================================================

FUNCTION gs_Image::_OverloadSlash, left, right, _extra = extra

  compile_opt idl2
  
  className = Tag_Names(self, /structure_name)
  
  case 1B of

    Obj_Valid(left) && Obj_Isa(left, 'gs_Image') && Obj_Valid(right) && Obj_Isa(right, 'gs_Image'): begin

      case 1B of
        left.nDimensions ne right.nDimensions: Message, 'Number of dimensions does not match.'
        jg_Any(left.dataDims ne right.dataDims): Message, 'Matrix size mis-match.'
        else:
      endcase

      Return, Obj_new(className, left.imgData/right.imgData, nonNegative = left.nonNegative && right.nonNegative, _extra = extra)

    end

    Obj_Valid(left) && Obj_Isa(left, 'gs_Image') && Isa(right, /number, /array): begin

      case 1B of
        left.nDimensions ne right.nDim: Message, 'Number of dimensions does not match.'
        jg_Any(left.dataDims ne right.dim): Message, 'Matrix size mis-match.'
        else:
      endcase

      Return, Obj_new(className, left.imgData/right, nonNegative = left.nonNegative, _extra = extra)

    end

    Obj_Valid(right) && Obj_Isa(right, 'gs_Image') && Isa(left, /number, /array): begin

      case 1B of
        right.nDimensions ne left.nDim: Message, 'Number of dimensions does not match.'
        jg_Any(right.dataDims ne left.dim): Message, 'Matrix size mis-match.'
        else:
      endcase

      Return, Obj_new(className, left/right.imgData, nonNegative = right.nonNegative, _extra = extra)

    end

    Obj_Valid(left) && Obj_Isa(left, 'gs_Image') && Isa(right, /scalar, /number): begin

      Return, Obj_new(className, left.imgData/right, nonNegative = left.nonNegative, _extra = extra)

    end

    Obj_Valid(right) && Obj_Isa(right, 'gs_Image') && Isa(left, /scalar, /number): begin

      Return, Obj_new(className, left/right.imgData, nonNegative = right.nonNegative, _extra = extra)

    end

    else: Message, 'Division not defined for operands.'

  endcase

END

;=========================================================================================

FUNCTION gs_Image::New, imgData, nonNegative = nonNegative, _extra = extra

  compile_opt idl2
  
  if N_Elements(nonNegative) gt 0 then nn = nonNegative else nn = self.nonNegative
  
  className = Tag_Names(self, /structure_name)
  Return, Obj_New(className, imgData, nonNegative = nn, _extra = extra)

END

;=========================================================================================

PRO gs_Image::Compress

  compile_opt idl3
  
  if ~self.isCompressed then begin   
    *self.imgData = Zlib_compress(*self.imgData, /gzip_header)
    self.isCompressed = !true
  endif

END

;==================================================================

PRO gs_Image::Uncompress

  compile_opt idl3
  
  if self.isCompressed then begin
    self.GetProperty, imgData = imgData
    *self.imgData = imgData
    self.isCompressed = !false
  endif

END

;=========================================================================================

PRO gs_Image::Unload, fileName, directory = directory

  compile_opt idl3
  
  if self.offloadHandle ne '' then Return
  
  if N_Elements(fileName) eq 0 then begin
    fName = gs_GetRandomFileName('.tmp', path = GetEnv('LUNDATEMP'))
  endif else if KeyWord_Set(directory) then begin   
     fName = gs_GetRandomFileName('.tmp', path = fileName)   
  endif else fName = fileName
    
  OpenW, lun, fName, /get_lun
  WriteU, lun, *self.imgData
  Free_Lun, lun
  
  if StrCmp(self.numberFormat, 'double', /fold_case) then tp = 5 else tp = 4
  self.offload = fName
  ShmMap, dimension =  self.dataDims.ToArray(), type = tp, get_name = nme, fileName = self.offLoad 
  self.offloadHandle = nme
  im = ShmVar(self.offloadHandle)
  self.imgData = Ptr_New(im, /no_copy)
  
END

;=========================================================================================

PRO gs_Image::Reload

  compile_opt idl3
  
  if self.offloadHandle ne '' then begin
    img = *self.imgData
    self.imgData = Ptr_New(img, /no_copy)
    ShmUnMap, self.offloadHandle
    File_Delete, self.offload
    self.offload = ''
    self.offloadHandle = ''
  endif

END

;=========================================================================================

PRO gs_Image__define

  compile_opt idl2
  
  dum = {gs_Image, imgData: Ptr_New(), numberFormat: '', nDimensions: 0L, dataDims: Obj_New(), nonNegative: !false, isCompressed: !false, offload: '', offloadHandle: '', inherits idl_object}

END