# setGenericVerif("rmsScaling", function(x) standardGeneric("rmsScaling"))
#' Optimum Phase Rotation
#'
#' @param x any data that can be converted into a numeric vector with 
#'          as.vector.
#' @param rot The phase rotation increment.
#' @param plot A lenth-one boolean vector. If TRUE, the kurtosis as a function
#'             of phase angle is plotet.
#' @name optPhaseRotation
#' @rdname optPhaseRotation
#' @export
optPhaseRotation <- function(x, rot = 0.01, plot = TRUE){
  # x_dec <- as.vector(gpr/apply(as.matrix(gpr),2,RMS))
  x_dec <- as.vector(x)
  pi_seq <- seq(0, pi, by = rot)
  kurt <- numeric(length(pi_seq))
  nx <- length(x_dec)
  for(i in seq_along(pi_seq)){
    xrot <- phaseRotation(x_dec, pi_seq[i])
    # xrot_scaled2 <- (xrot -   mean(xrot))^2
    # kurt[i] <- ((1/nx) * sum( xrot_scaled2^2)) / 
    # ( (1/nx) *sum( xrot_scaled2))^2 
    kurt[i] <- e1071::kurtosis( xrot)
  }
  phi_max <- pi_seq[which.max(kurt)]
  message("rotation angle = ", phi_max/pi*180, " degree")
  # dev.off(); windows()
  if(plot==TRUE){
    plot(pi_seq/pi*180,kurt,type="l")
    abline(v=phi_max/pi*180,col="red")
  }
  return(phi_max)
  # x_dec <- phaseRotation(x_dec, phi_max)
}




