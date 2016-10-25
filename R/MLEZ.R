#' MLEZ
#' 
#' This function fitted parameters of probability distribution functions (see \code{\link{selecDIST}})
#' by means of maximum likelihood and Performs evolutionary global optimization via the 
#' Differential Evolution algorithm (see \pkg{DEoptim} package).
#'
#' @param x: Intensity values 
#' @param type: a character specifying the name of distribution function that it will 
#' be employed: exponencial, gamma, gev, gumbel, log.normal3, normal, pearson, log.pearson3 and 
#' wakeby (see \code{\link{selecDIST}}).
#' @param para.int: Initial parameters as a vector \eqn{\Theta}}.
#' @param silent: A logical to silence the \code{\link{try}}() function wrapping the \code{\link{DEoptim}}() function.
#' @param null.on.not.converge: A logical to trigging simple return of NULL if the optim() function returns a nonzero convergence status.
#' @param ... 
#'
#' @return
#' @export
#'
#' @examples
MLEZ <- function (Intensity, type, para.int = NULL, silent = TRUE, null.on.not.converge = TRUE, 
                ptransf = function(t) return(t), pretransf = function(t) return(t), 
                ...) 
{
  x <- Intensity
  type <- selecDIST(Type = type)
  
  if (is.null(para.int)) {
    lmr <- lmomco::lmoms(x)
    para.int <- lmomco::lmom2par(lmr, type = type, ...)
  }
  if (is.null(para.int)) {
    warning("could not estimate initial parameters via L-moments")
    return(NULL)
  }
  if (length(para.int$para) == 1) {
    warning("function is not yet built for single parameter optimization")
    return(NULL)
  }
  "afunc" <- function(para, x = NULL, ...) {
    lmomco.para <- lmomco::vec2par(pretransf(para), type = type, 
                                   paracheck = TRUE)
    if (is.null(lmomco.para)) 
      return(Inf)
    pdf <- lmomco::par2pdf(x, lmomco.para)
    L <- -sum(log(pdf), na.rm = TRUE)
    return(L)
  }
  
  rt <- NULL
  
  total.par <- abs(para.int$para)
  lower <- para.int$para*0.7*(-1)
  upper <- para.int$para*1.3
  try(rt <- DEoptim::DEoptim(afunc, lower, upper, x = x, 
                    control = DEoptim::DEoptim.control(NP = 50, itermax = 100, trace = FALSE, packages = "lmomco")),silent = silent)
  
  if (is.null(rt)) {
    warning("optim() attempt is NULL")
    return(NULL)
  }
  else {
    if (null.on.not.converge & rt$convergence != 0) {
      warning("optim() reports convergence error")
      return(NULL)
    }
    lmomco.para <- lmomco::vec2par(pretransf(rt$optim$bestmem), type = type)
    lmomco.para$AIC <- 2 * length(rt$optim$bestmem) - 2 * (-1 * rt$value)
    lmomco.para$optim <- rt
    return(lmomco.para)
  }
}