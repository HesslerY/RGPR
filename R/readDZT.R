.gprDZT <- function(x, fName = character(0), desc = character(0),
                    fPath = character(0), Vmax = NULL, ch = 1){
  if(is.null(Vmax)) Vmax <- 50
  
  
  #  take the channel ch
  if(ch > length(x$data)){
    stop("The data has only ", length(x$data), "channel(s)")
  }
  x$data <- x$data[[ch]]
  antName <- x$hd$ANT[ch]
  
  dd <- as.Date(x$hd$DATE, format = "%Y-%m-%d")
  dd <- as.character(dd)
  if(is.na(dd)){
    dd <- format(Sys.time(), "%Y-%m-%d")
  }
  ttime <- yy <- 1/x$hd$SPS * (seq_len(ncol(x$data)) - 1)
  traceTime <- as.double(as.POSIXct(strptime(paste(dd, "01:30:00"), 
                                             "%Y-%m-%d %H:%M:%S") )) + ttime
  if(length(fName) == 0){
    x_name <- "LINE"
  }else{
    x_name <- fName
  }
  # defaults
  x_posunit   <- "m"
  x_depthunit <- "ns"
  x_pos       <- x$pos[1:ncol(x$data)]
  x_depth     <- x$depth[1:nrow(x$data)]
  x_dx        <- 1 / x$hd$SPM
  
  # Fiducial markers > each class has a different name (letter)
  x_fid       <- rep("", ncol(x$data))
  test <- which(x$hd$MRKS < 0)
  fidval <- LETTERS[as.numeric(as.factor(x$hd$MRKS[test]))]
  ufidval <- unique(fidval)
  for( i in seq_along(ufidval)){
    test2 <- which(fidval == ufidval[i])
    fid_nb <- seq_along(test2)
    x_fid[test][test2] <- paste0(ufidval[i], 
                                 sprintf(paste0("%0", max(nchar(fid_nb)), "d"), 
                                         fid_nb))
  }
  
  if(!is.null(x$dzx)){
    # spatial/horizontal units
    # pos
    if(!is.null(x$dzx$pos)){
      x_pos <- x$dzx$pos
      # x_dx <- mean(diff(x_pos))
    }
    # spatial sampling
    if(!is.null(x$dzx$dx)){
      x_dx <- x$dzx$dx
    } 
    # if(!is.null(x$dzx$unitsPerScan)){
    #   x_dx <- x$dzx$unitsPerScan
    # }
    # fids/markers
    if(all(x_fid == "") &&
       !is.null(x$dzx$markers) && 
       length(x$dzx$markers) == ncol(x$data)){
      x_fid <- x$dzx$markers
    }
    # else if(all(x_fid == "") && !is.null(x$dzx$unitsPerMark)){
    #   x_fid <- rep("", ncol(x$data))
    #   x_fid_id <- which((x_pos %% x$dzx$unitsPerMark) == 0)
    #   x_fid[x_fid_id] <- "FID"
    # }
    if(!is.null(x$dzx$hUnit)){
      x_posunit <-x$dzx$hUnit
      if(grepl("in", x_posunit)){
        x_pos <- x_pos * 0.0254
        x_posunit <- "m"
      }
    }
    # # depth/vertical units
    # if(!is.null(x$dzx$vUnit)){
    #   x_depthunit <- x$dzx$vUnit
    #   if(grepl("in", x_depthunit)){
    #     x_depth <- x_depth * 0.0254
    #     x_depthunit <- "m"
    #   }
    # }
  }
  antfreq <- switch(antName,
                    '3200'   = numeric(0), # adjustable
                    '3200MLF' = numeric(0), # adjustable
                    '500MHz' = 500,
                    '3207' = 100,
                    '3207AP' = 100,
                    '5106' = 200,
                    '5106A' = 200,
                    '50300' = 300,
                    '350' = 350,
                    '350HS' = 350,
                    '50270' = 270,
                    '50270S' = 270,
                    '50400' = 400,
                    '50400S' = 400,
                    '800' = 800,
                    '3101' = 900,
                    '3101A' = 900,
                    '51600' = 1600,
                    '51600S' = 1600,
                    '62000' = 2000,
                    '62000-003' = 2000,
                    '62300' = 2300,
                    '62300XT' = 2300,
                    '52600' = 2600,
                    '52600S' = 2600,
                    'D50800' = 800,
                    numeric(0))  # 800,300,
  if(length(antfreq) == 0){
    # estimate anntenna frequency from the name (it it contains ### MHz)
    antfreq <- freqFromString(antName)
  }
  if(length(antfreq) == 0){
    antfreq <- 0
    message("Antenna frequency set to 0 MHz. Set it with 'antfreq(x) <- ... '")
    # antsep <- numeric(0)
  }
  #else{
  #}
  v <- 2 * x$hd$DEPTH / x$hd$RANGE
  
  # antenna sparation could be estimated from frequency...
  # antsep <- antSepFromAntFreq(antfreq)
  antsep <- 0
  message("Antenna separation set to 0 ", x_posunit, 
          ". Set it with 'antsep(x) <- ... '")
  
  new("GPR",   
      version      = "0.2",
      data        = bits2volt(Vmax = Vmax, nbits = x$hd$BITS) * x$data,
      traces      = 1:ncol(x$data),
      fid         = x_fid,
      #coord = coord,
      coord       = matrix(nrow = 0, ncol = 0),
      pos         = x_pos,
      depth       = x$depth[1:nrow(x$data)],
      rec         = matrix(nrow = 0, ncol = 0),
      trans       = matrix(nrow = 0, ncol = 0),
      time0       = rep(0, ncol(x$data)),
      # time = x$hdt[1,] * 3600 + x$hdt[2,] * 60 + x$hdt[3,],
      time        = traceTime,
      proc        = character(0),
      vel         = list(v),
      name        = x_name,
      description = desc,
      filepath    = fPath,
      dz          =  x$hd$RANGE /  (x$hd$NSAMP - 1 ), 
      dx          = x_dx,
      depthunit   = x_depthunit,
      posunit     = x_posunit,
      freq        = antfreq, 
      antsep      = antsep,     # check
      surveymode  = "reflection",
      date        = as.character(dd), #format(Sys.time(), "%d/%m/%Y"),
      crs         = character(0),
      hd          = x$hd
  )
}




#' @export
readDZT <- function(dsn){
  
  if(!inherits(dsn, "connection")){
    dsn <- file(dsn, 'rb')
  }
  
  hd <- c()
  MINHEADSIZE <- 1024  # absolute minimum total header size
  nScans <- 0
  #--------------------------------- READ HEADER ------------------------------#  
  # 0x00ff ('\xff\a') if header, 0xfnff for old file
  #rh_tag <- readChar(dsn, nchars = 1, useBytes = TRUE)
  hd$TAG <- .readBin_ushort(dsn)
  # Offset to Data from beginning of file
  #   if rh_data < MINHEADSIZE then offset is MINHEADSIZE * rh_data
  #   else offset is MINHEADSIZE *rh_nchan
  hd$OFFSETDATA <- .readBin_ushort(dsn)   # rh_offsetdata
  # samples per scan
  hd$NSAMP <- .readBin_ushort(dsn)        # rh_nsamp
  # bits per data word (8,16, 32) *
  hd$BITS <- .readBin_ushort(dsn)         # rh_bits
  # Binary_offset
  # if rh_system is SIR 30, then equals repeats/sample
  #     otherwise is 0x80 for 8 bit data and 0x8000 for 16 bit data
  hd$ZERO <-.readBin_short(dsn)           # rh_zero
  # scans per second
  hd$SPS <- .readBin_float(dsn)           # rh_sps
  # scans per meter
  hd$SPM <- .readBin_float(dsn)           # rh_spm
  # meters per mark
  hd$MPM <- .readBin_float(dsn)           # rh_mpm
  # position (ns)
  hd$POSITION <- .readBin_float(dsn)      # rh_position
  # range (ns)
  hd$RANGE <- .readBin_float(dsn)         # rh_range
  # number of passes for 2-D files
  hd$NPASS <- .readBin_ushort(dsn)        # rh_npass
  # creation date
  creaDT <- .readRFDate(dsn, where = 32)
  # modification date
  modDT  <- .readRFDate(dsn, where = 36)
  hd$DATE <- creaDT$date
  hd$TIME <- creaDT$time
  # skip across some proprietary stuff
  seek(dsn, where = 44, origin = "start")
  # offset to text
  hd$OFFSETTEXT <- .readBin_ushort(dsn)   # rh_text
  # size of text
  hd$NTEXT <- .readBin_ushort(dsn)        # rh_ntext
  # offset to processing history
  hd$PROC <- .readBin_ushort(dsn)         # rh_proc
  # size of processing history
  hd$NPROC <- .readBin_ushort(dsn)        # rh_nproc
  # number of channels
  hd$NCHAN <- .readBin_ushort(dsn)        # rh_nchan
  # average dilectric
  hd$EPSR <- .readBin_float(dsn)          # rhf_epsr
  # position in meters (useless?)
  hd$TOP <- .readBin_float(dsn)           # rhf_top
  # range in meters
  hd$DEPTH <- .readBin_float(dsn)        # rhf_depth
  seek(dsn, where = 98, origin = "start")
  # antenna name
  ant_name <- character(hd$NCHAN)
  for(i in seq_len(hd$NCHAN)){
    seek(dsn, where = 98 + MINHEADSIZE * (i - 1), origin = "start")
    ant_name[i] <- suppressWarnings(readChar(dsn, nchars = 14, useBytes = FALSE))
  }
  # hd$ANT <- readChar(dsn, nchars = 14, useBytes = TRUE)
  hd$ANT <- ant_name
  # byte containing versioning bits
  hd$VSBYTE <- .readBin_ushort(dsn) 
  
  #--------------------------------- READ DATA --------------------------------#
  # number of bytes in file
  nB <- .flen(dsn)
  
  # whether or not the header is normal or big-->determines offset to data array
  if( hd$OFFSETDATA < MINHEADSIZE){
    hd$OFFSETDATA <- MINHEADSIZE * hd$OFFSETDATA
  }else{
    hd$OFFSETDATA <- MINHEADSIZE * hd$NCHAN
  }
  
  if(nScans == 0){ # read all the scans
    nNumScans <- (nB - hd$OFFSETDATA)/(hd$NCHAN * hd$NSAMP * hd$BITS/8);
  }
  
  seek(dsn, where = hd$OFFSETDATA, origin = "start")
  
  nNumSkipScans <- 0
  
  if(hd$BITS == 8){
    invisible(readBin(dsn, "integer", n = hd$NSAMP * nNumSkipScans * hd$NCHAN,
                      size = 2L))
    A <- matrix(nrow = hd$NSAMP, ncol = nNumScans * hd$NCHAN)
    A[] <- readBin(dsn, what = "int", n = prod(dim(A)),  size = 1)
    test <- A >= 0
    A[ test] <- A[ test] - 128
    A[!test] <- A[!test] + 127
  }else if(hd$BITS == 16){
    #.skipBin(dsn, hd$NSAMP * nNumSkipScans * hd$NCHAN, size = 2)
    invisible(readBin(dsn, "integer", n = hd$NSAMP * nNumSkipScans * hd$NCHAN, 
                      size = 2L))
    A <- matrix(nrow = hd$NSAMP, ncol = nNumScans * hd$NCHAN)
    A[] <- readBin(dsn, what = "int", n = prod(dim(A)),  size = 2)
    test <- A >= 0
    A[ test] <- A[ test] - 32768
    A[!test] <- A[!test] + 32767
  }else if(hd$BITS == 32){
    # invisible(readBin(dsn, "integer", n = hd$NSAMP * nNumSkipScans * hd$NCHAN, 
    #                   size = 2L))
    A <- matrix(nrow = hd$NSAMP, ncol = nNumScans * hd$NCHAN)
    A[] <- readBin(dsn, what = "int", n = prod(dim(A)),  size = 4) 
  }
  
  tt <- (seq_len(hd$NSAMP) - 1) * hd$RANGE /  (hd$NSAMP - 1 )
  # yy <- 1/hd$SPM * (seq_len(ncol(A) ) - 1)
  # plot3D::image2D(x = tt, y = yy, z = A)
  
  if(hd$SPM  > 0){
    yy <- 1/hd$SPM * (seq_len(ncol(A) / hd$NCHAN) - 1)
  }else{
    yy <- seq_len(ncol(A))
  }
  Adata <- vector(mode = "list", length = hd$NCHAN)
  for(i in seq_len(hd$NCHAN)){
    Adata[[i]] <- A[, seq(i, by = hd$NCHAN, to = ncol(A))]
    if(i == 1){
      hd$MRKS <- Adata[[i]][2,]
      Adata[[i]] <- Adata[[i]][-c(1, 2), ]   
    }
    # plot3D::image2D(y = tt[1:nrow(Adata[[i]])], x = yy, 
    # z = t(Adata[[i]][nrow(Adata[[i]]):1,]))
  }
  
  .closeFileIfNot(dsn)
  
  
  return(list(hd = hd, data = Adata, depth = tt, pos = yy))
}

# setwd("/media/huber/Seagate1TB/UNIBAS/PROJECTS/RGPR/CODE/DEVELOPMENT/FILE_FORMAT")
# dsn <- "dzt/jarvis/PROJECT001__014.DZG"
# dsn <- "dzt/jarvis/PROJECT001__014.DZT"
# mrk <- readDZG(dsn)

#' @export
readDZG <- function(dsn){
  x <- scan(dsn, what = character(), sep = "\n", quiet = TRUE)
  
  test_gssis <- grepl("(\\$GSSIS)", x, ignore.case = TRUE, useBytes = TRUE )
  test_gpgga <- grepl("(\\$GPGGA)", x, ignore.case = TRUE, useBytes = TRUE )
  
  if(sum(test_gssis) != sum(test_gpgga)){
    stop("File '.dzg' is corrupted! I cannot read it... sorry.")
  }
  
  pat_gssis <- paste0("\\$(?<ID>GSSIS),(?<tr>[0-9]+),(?<time>[-]?[0-9.]+)") 
  pat_gpgga <- paste0("\\$(?<ID>GPGGA),(?<UTC>[0-9.]+),(?<lat>[0-9.]+),",
                      "(?<NS>[NS]),(?<lon>[0-9.]+),(?<EW>[EW]),(?<fix>[0-9]),",
                      "(?<NbSat>[0-9.]+),(?<HDOP>[0-9.]+),(?<H>[0-9.]+),",
                      "(?<mf>[MmFf]+)") 
  #,(?<HGeoid>[0-9.]+),(?<mf2>[mMfF+),",
  # "(?<TDGPS>[0-9.]+),(?<DGPSID> [A-z0-9.]+)"
  # )
  
  # matches <- regexpr(pat_gpgga, x[xgpgga], perl=TRUE)
  # first <- attr(matches, "capture.start")
  # last <- first + attr(matches, "capture.length") -1
  # gpgga <- mapply(substring, x[xgpgga], first, last, USE.NAMES = FALSE)
  gpgga <- extractPattern(x[test_gpgga], pat = pat_gpgga, 
                          shift1 = 0, shift2 = -1)  
  gssis <- extractPattern(x[test_gssis], pat = pat_gssis, 
                          shift1 = 0, shift2 = -1)
  
  dim(gpgga) <- c(sum(test_gpgga), 11)
  gpgga <- as.data.frame(gpgga, stringsAsFactors = FALSE)
  colnames(gpgga) <- c("ID", "UTC", "lat", "NS", "lon", "EW", 
                       "fix", "NbSat", "HDOP", "H", "mf")
  dim(gssis) <- c(sum(test_gssis), 3)
  gssis <- as.data.frame(gssis, stringsAsFactors = FALSE)
  colnames(gssis) <- c("ID", "trace", "time")
  
  xyzt <- .getLonLatFromGPGGA(gpgga)
  
  # trace number start at 0!!
  mrk <- cbind(xyzt[ ,1:3], as.integer(gssis$trace) + 1,  xyzt[ ,4])
  # mrk <- as.matrix(mrk)
  names(mrk) <- c("x", "y", "z", "id", "time")
  
  .closeFileIfNot(dsn)
  return(mrk)
}

#' Read GSSI's .dzx file
#' 
#' .dzx files are xml files
#' @param dsn connection or filepath
#' @return a list containing the markers, the trace position and the spatial
#'         sampling.
#' @export
readDZX <- function(dsn){
  if(!inherits(dsn, "connection")){
    dsn <- file(dsn, 'rb')
  }
  
  xmltxt <-  verboseF(readLines(dsn), verbose = FALSE)
  if(length(xmltxt) == 0){
    .closeFileIfNot(dsn)
    return(NULL)
  }
  doc <- verboseF(XML::xmlParse(xmltxt),  verbose = FALSE)
  
  lst <- list()
  
  glbProp <- XML::xmlChildren(doc)$DZX[["GlobalProperties"]]
  if(!is.null(glbProp)){
    unitsPerMark <- XML::xmlElementsByTagName(glbProp, "unitsPerMark")
    if(length(unitsPerMark) > 0){
      unitsPerMark <- as.numeric(XML::xmlValue(unitsPerMark[[1]]))
      if(unitsPerMark > 0){
        lst$unitsPerMark <- unitsPerMark
      }
    }
    unitsPerScan <- XML::xmlElementsByTagName(glbProp, "unitsPerScan")
    if(length(unitsPerScan) > 0){
      unitsPerScan <- as.numeric(XML::xmlValue(unitsPerScan[[1]]))
      if(unitsPerScan > 0){
        lst$unitsPerScan <- unitsPerScan
      }
    }
    vUnit <- XML::xmlElementsByTagName(glbProp, "verticalUnit")
    if(length(vUnit) > 0){
      vUnit <- XML::xmlValue(vUnit[[1]])
      lst$vUnit <- vUnit
    }
    hUnit <- XML::xmlElementsByTagName(glbProp, "horizontalUnit")
    if(length(hUnit) > 0){
      hUnit <- XML::xmlValue(hUnit[[1]])
      lst$hUnit <- hUnit
    }
  }
  
  # Scan range !!
  # FIXME : multi channel files
  fl <- XML::xmlChildren(doc)$DZX[["File"]]
  if(!is.null(fl)){
    s1 <- XML::xmlElementsByTagName(fl, "scanRange", recursive = TRUE)
    if(length(s1) > 0){
      s0 <- as.integer(strsplit(XML::xmlValue(s1[[1]]), split = ",")[[1]])
      nscans <- length(s0[1]:s0[2])
      #--- select all the distance tags
      dst <- XML::xmlElementsByTagName(fl, "distance", recursive = TRUE)
      #--- select the sibling tags "scan" and "mark"
      # here I assume that all tags "distance" have a sibling tag "mark" and "scan"
      if(length(dst) > 0){
        f <- function(x){
          papa <- XML::xmlParent(x)
          i1 <- as.numeric(XML::xmlValue(XML::xmlElementsByTagName(papa, "scan")))
          i2 <- XML::xmlValue(XML::xmlElementsByTagName(papa, "mark"))
          if(length(i2) == 0) i2 <- ""
          i3 <- as.numeric(XML::xmlValue(x))  # distance
          return(unname(c(i1, i2, i3)))
        }
        uu <- sapply(dst, f, USE.NAMES = FALSE)
        if(inherits(uu, "matrix")){
          id <- as.integer(uu[1, ]) + 1L
          pos <- as.numeric(uu[3,])
          lst$dx <- mean(diff(pos)/ (diff(id) - 1))
          lst$pos <- approx(id, pos, seq_len(nscans))$y
          lst$markers <- character(length = nscans)
          lst$markers[id] <- uu[2,]
        }else{
          message("I was unable to read the markers in the file *.dzx")
        }
        
      }
    }
    .closeFileIfNot(dsn)
    
    if(length(lst) > 0){
      return(lst)
    }else{
      return(NULL)
    }
  }
}
# readDZX <- function(dsn){
#   
#   if(!inherits(dsn, "connection")){
#     dsn <- file(dsn, 'rb')
#   }
#   
#   xmltxt <-  verboseF(readLines(dsn), verbose = FALSE)
#   if(length(xmltxt) == 0){
#     return(NULL)
#   }
#   doc <- verboseF(XML::xmlParse(xmltxt),  verbose = FALSE)
#   
#   lst <- list()
#   
#   glbProp <- XML::xmlChildren(doc)$DZX[["GlobalProperties"]]
#   if(!is.null(glbProp)){
#     unitsPerMark <- XML::xmlElementsByTagName(glbProp, "unitsPerMark")
#     if(length(unitsPerMark) > 0){
#       unitsPerMark <- as.numeric(XML::xmlValue(unitsPerMark[[1]]))
#       if(unitsPerMark > 0){
#         lst$unitsPerMark <- unitsPerMark
#       }
#     }
#     unitsPerScan <- XML::xmlElementsByTagName(glbProp, "unitsPerScan")
#     if(length(unitsPerScan) > 0){
#       unitsPerScan <- as.numeric(XML::xmlValue(unitsPerScan[[1]]))
#       if(unitsPerScan > 0){
#         lst$unitsPerScan <- unitsPerScan
#       }
#     }
#     vUnit <- XML::xmlElementsByTagName(glbProp, "verticalUnit")
#     if(length(vUnit) > 0){
#       vUnit <- XML::xmlValue(vUnit[[1]])
#       lst$vUnit <- vUnit
#     }
#     hUnit <- XML::xmlElementsByTagName(glbProp, "horizontalUnit")
#     if(length(hUnit) > 0){
#       hUnit <- XML::xmlValue(hUnit[[1]])
#       lst$hUnit <- hUnit
#     }
#   }
#   
#   # Scan range !!
#   # FIXME : multi channel files
#   fl <- XML::xmlChildren(doc)$DZX[["File"]]
#   if(!is.null(fl)){
#     s1 <- XML::xmlElementsByTagName(fl, "scanRange", recursive = TRUE)
#     if(length(s1) > 0){
#       s0 <- as.integer(strsplit(XML::xmlValue(s1[[1]]), split = ",")[[1]])
#       nscans <- length(s0[1]:s0[2])
#       #--- distance
#       dst <- XML::xmlElementsByTagName(fl, "distance", recursive = TRUE)
#       if(length(dst) > 0){
#         d0 <- as.numeric(sapply(dst, XML::xmlValue))
#         lst$dx <- (d0[2] - d0[1])/(nscans- 1)
#         lst$pos <- seq(from = d0[1], by = lst$dx, length.out = nscans)
#       }
#       
#       #--- marks !!
#       tst <- XML::xmlElementsByTagName(fl, "mark", recursive = TRUE)
#       if(length(tst) > 0){
#         markers_name <- as.character(sapply(tst, XML::xmlValue))
#         markers_pos <- as.numeric(sapply(tst, .xmlValueSibling ))
#         lst$markers <- character(length = nscans)
#         lst$markers[markers_pos] <- markers_name
#       }
#     }
#     # return(list(markers = markers, pos = pos, dx = dx))
#   }
#   
#   .closeFileIfNot(dsn)
#   
#   if(length(lst) > 0){
#     return(lst)
#   }else{
#     return(NULL)
#   }
# }

.xmlValueSibling <- function(x, after = FALSE){
  XML::xmlValue(XML::getSibling(x, after = after))
}

.readRFDate <- function(con, where = 31){
  seek(con, where = where, origin = "start")
  rhb_cdt0 <- readBin(con, what = "raw", n = 4L, size = 1L, endian = "little")
  
  aa <- rawToBits(rhb_cdt0)
  xdate <- paste(.bit2int(aa[25 + (7:1)]) + 1980, 
                 sprintf("%02d", .bit2int(aa[21 + (4:1)])),  # sprintf()
                 sprintf("%02d", .bit2int(aa[16 + (5:1)])), sep = "-")
  xtime <- paste(sprintf("%02d", .bit2int(aa[11 + (5:1)])),
                 sprintf("%02d", .bit2int(aa[5 + (6:1)])),
                 sprintf("%02d", .bit2int(aa[5:1])* 2), sep = ":" )
  return(list(date = xdate, time = xtime))
}

