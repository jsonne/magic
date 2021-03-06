kifiAggData <- function(data, 
                        n = 8, 
                        years = -999,
                        date.col = 1,
                        over.fun = sum, 
                        dsn = ".",
                        out.str = "data",
                        out.proj = NULL, 
                        n.cores = 2,
                        ...) {
  
  # Required packages
  lib <- c("doParallel", "raster")
  sapply(lib, function(...) stopifnot(require(..., character.only = T)))
  
  # Parallelization
  registerDoParallel(cl <- makeCluster(n.cores))
  
  # Loop through single years
  tmp.ts.agg <- foreach(h = years) %do% {
    
    if (h == -999) {
      tmp.ts <- data[, date.col]
    } else {
      tmp.ts <- data[grep(h, data[, date.col]), ]
    }
    
    # Aggregate every n layers of each year or whole time span
    tmp.ts.agg <- foreach(i = seq(1, nrow(tmp.ts), n), .packages = lib) %dopar% {
      if (length(na.omit(tmp.ts[i:(i+7), 2])) > 0) {
        tmp <- stack(na.omit(tmp.ts[i:(i+7), 2]))
      } else {
        tmp <- NA
      }
      
      if (class(tmp) != "logical") {
        
        # Output projection
        if (!is.null(out.proj)) 
          # Crop projected raster by projected extent -> avoids edge NAs
          tmp <- crop(projectRaster(tmp, crs = out.proj, method = "ngb"), 
                      projectExtent(tmp, crs = out.proj))
        
        # Aggregation
        overlay(tmp, fun = over.fun, unstack = TRUE, 
                filename = paste(dsn, out.str, "_", strftime(tmp.ts[i, date.col], format = "%Y%j"), sep = ""), ...)
      } else {
        NA
      }
    }
    return(tmp.ts.agg)
  }
  
  # Deregister parallel backend and return output
  stopCluster(cl)
  return(tmp.ts.agg)
}

# ### Call
# 
# kifiAggData(data = modis.fire.dly.ts.fls, 
#             years = modis.fire.ts.years[1:2], 
#             over.fun = max, 
#             dsn = "/media/pa_NDown/ki_modis_ndvi/data/overlay/md14a1_agg/", 
#             out.str = "md14a1",
#             format = "GTiff", overwrite = TRUE)