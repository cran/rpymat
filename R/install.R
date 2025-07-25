#' @name conda-env
#' @title 'Miniconda' environment
#' @description These functions/variables are used to configure
#' 'Miniconda' environment.
#' @param matlab 'Matlab' path to add to the configuration path;
#' see 'Details'
#' @param python_ver \code{python} version to use; see 'Configuration'
#' @param packages additional \code{python} or \code{conda} packages to install
#' @param update whether to update \code{conda}; default is false
#' @param force whether to force install the 'Miniconda' even a previous
#' version exists; default is false. Setting \code{false=TRUE} rarely
#' works. Please see 'Configuration'.
#' @param standalone whether to install \code{conda} regardless of existing
#' \code{conda} environment
#' @param cache whether to use cached configurations; default is true
#' @param env_name alternative environment name to use; default is
#' \code{"rpymat-conda-env"}
#' @param ask whether to ask for user's agreement to remove the repository.
#' This parameter should be true if your functions depend on
#' \code{remove_conda} (see 'CRAN Repository Policy'). This argument might
#' be removed and force to be interactive in the future.
#' @param fun 'Matlab' function name, character (experimental)
#' @param ... for \code{add_packages}, these are additional parameters
#' passing to \code{\link[reticulate]{conda_install}}; for
#' \code{call_matlab}, \code{...} are the parameters passing to \code{fun}
#' @param .options 'Matlab' compiler options
#' @param .debug whether to enable debug mode
#' @param verbose whether to print messages
#' @returns None
#' @section Background & Objectives:
#' Package \code{reticulate} provides sophisticated tool-sets that
#' allow us to call \code{python} functions within \code{R}. However, the
#' installation of 'Miniconda' and \code{python} can be tricky on many
#' platforms, for example, the 'M1' chip, or some other 'ARM' machines.
#' The package \code{rpymat} provides easier approach to configure on these
#' machines with totally isolated environments. Any modifications to this
#' environment will not affect your other set ups.
#'
#' Since 2014, 'Matlab' has introduced its official compiler for \code{python}.
#' The package \code{rpymat} provides a simple approach to link the
#' compiler, provided that you have proper versions of 'Matlab' installed.
#' \href{https://www.mathworks.com/support/requirements/python-compatibility.html}{Here} is a list of
#' 'Matlab' versions with official compilers and their corresponding
#' \code{python} versions.
#'
#' @section Configuration:
#' If 'Matlab' compiler is not to be installed, In most of the cases,
#' function \code{configure_conda} with default arguments automatically
#' downloads the latest 'Miniconda' and configures the latest \code{python}.
#' If any other versions of 'Miniconda' is ought to be installed,
#' please set options \code{"reticulate.miniconda.url"} to change the
#' source location.
#'
#' If 'Matlab' is to be installed, please specify the 'Matlab' path when
#' running \code{configure_conda}. If the environment has been setup,
#' \code{configure_matlab} can link the 'Matlab' compilers without
#' removing the existing environment. For 'ARM' users, unfortunately,
#' there will be no 'Matlab' support as the compilers are written for
#' the 'Intel' chips.
#'
#' @section Initialization:
#' Once \code{conda} and \code{python} environment has been installed, make sure
#' you run \code{ensure_rpymat()} before running any \code{python} code. This
#' function will make sure correct compiler is linked to your current
#' \code{R} session.
#'
#' @examples
#'
#' # The script will interactively install \code{conda} to `R_user_dir`
#' \dontrun{
#'
#' # Install conda and python 3.9
#'
#' configure_conda(python_ver = '3.9')
#'
#'
#' # Add packages h5py, pandas, jupyter
#'
#' add_packages(c('h5py', 'pandas', 'jupyter'))
#'
#' # Add pip packages
#'
#' add_packages("itk", pip = TRUE)
#'
#' # Initialize the isolated environment
#'
#' ensure_rpymat()
#'
#'
#' # Remove the environment
#'
#' remove_conda()
#'
#' }
#'
NULL

#' @rdname conda-env
#' @export
CONDAENV_NAME <- local({
  name <- NULL
  function(env_name){
    if(!missing(env_name)){
      stopifnot(length(env_name) == 1 && is.character(env_name))
      if(env_name == ""){
        name <<- "rpymat-conda-env"
      } else {
        name <<- sprintf("rpymat-conda-env-%s", env_name)
      }
      message("Environment switched to: ", name)
    } else if(is.null(name)) {
      conda_prefix <- trimws(Sys.getenv("R_RPYMAT_CONDA_PREFIX", unset = ""))
      if( conda_prefix == "" ) {
        return("rpymat-conda-env")
      } else {
        return(sprintf("%s-rpymat-conda-env", basename(conda_prefix)))
      }
    }
    name
  }
})

clean_env_name <- function(env_name) {
  if(length(env_name) != 1 || is.na(env_name)) {
    env_name <- ""
  }
  env_name <- trimws(env_name)
  env_name <- gsub("[^a-zA-Z0-9_]+", "-", env_name)
  env_name <- gsub("^[^a-zA-Z]+", "", env_name)
  if( env_name == "" ) {
    env_name <- ensure_rpymat_internals$name()
  }
  if(!length(env_name)) {
    env_name <- CONDAENV_NAME()
  }
  env_name
}

install_root <- function(){
  if(Sys.info()["sysname"] == "Darwin"){
    path <- path.expand("~/Library/r-rpymat")
  } else {
    root <- normalizePath(rappdirs::user_data_dir(), winslash = "/",
                          mustWork = FALSE)
    path <- file.path(root, "r-rpymat", fsep = "/")
  }
  getOption("rpymat.install_root", path)
}

#' @rdname conda-env
#' @export
conda_path <- function(){
  conda_exe <- Sys.getenv("R_RPYMAT_CONDA_EXE", unset = "")
  if( !identical(conda_exe, "") ) {
    path <- dirname(dirname(conda_exe))
    if(dir.exists(path)) {
      return(path)
    }
  }
  file.path(install_root(), "miniconda", fsep = "/")
}

#' @rdname conda-env
#' @export
conda_bin <- function(){
  conda_exe <- Sys.getenv("R_RPYMAT_CONDA_EXE", unset = "")
  if( !identical(conda_exe, "") && file.exists(conda_exe) ) {
    return( conda_exe )
  }

  bin_path <- file.path(install_root(), "miniconda", "condabin", c("conda", "conda.exe", "conda.bin", "conda.bat"), fsep = "/")
  bin_path <- bin_path[file.exists(bin_path)]
  if(length(bin_path)){
    bin_path <- bin_path[[1]]
  } else {
    bin_path <- tryCatch({
      reticulate::conda_binary()
    }, error = function(e) {
      character(0)
    })
  }
  bin_path
}

#' @rdname conda-env
#' @export
env_path <- function(env_name = NA){

  current_env <- Sys.getenv("R_RPYMAT_CONDA_PREFIX", unset = "")
  conda_exe <- Sys.getenv("R_RPYMAT_CONDA_EXE", unset = "")

  env_name <- clean_env_name(env_name)

  re <- NULL
  if(!identical(current_env, "")) {
    re <- file.path(dirname(current_env), env_name)
  } else if( !identical(conda_exe, "") ) {
    re <- file.path(dirname(dirname(conda_exe)), 'envs', env_name)
  }

  if(length(re) != 1) {
    re <- file.path(install_root(), "miniconda", 'envs', env_name)
  }

  return( normalizePath(
    re,
    winslash = "\\",
    mustWork = FALSE
  ) )
}

#' @rdname conda-env
#' @export
list_pkgs <- function(..., env_name = NA) {
  reticulate::py_list_packages(envname = env_path(env_name = env_name), ...)
}

set_conda <- function(temporary = TRUE){
  old_path <- Sys.getenv('RETICULATE_MINICONDA_PATH', unset = "")
  if(old_path == ""){
    old_path <- getOption("reticulate.conda_binary", "")
  }
  if(
    temporary && length(old_path) == 1 && old_path != "" &&
    tryCatch({
      isTRUE(file.exists(old_path))
    }, error = function(e) { FALSE })
  ){
    parent_env <- parent.frame()
    do.call(on.exit, list(bquote({
      options("reticulate.conda_binary" = .(getOption("reticulate.conda_binary", "")))
      Sys.setenv("RETICULATE_MINICONDA_PATH" = .(Sys.getenv('RETICULATE_MINICONDA_PATH', unset = "")))
    }),
    add = TRUE,
    after = FALSE), envir = parent_env)
  }
  Sys.setenv("RETICULATE_MINICONDA_PATH" = conda_path())


  conda_path <- file.path(conda_path(), "condabin", c("conda", "conda.exe", "conda.bin", "conda.bat"))
  conda_path <- conda_path[file.exists(conda_path)]
  if(length(conda_path)){
    options("reticulate.conda_binary" = conda_path[[1]])
  } else {
    options("reticulate.conda_binary" = NULL)
  }
}

# https://www.mathworks.com/content/dam/mathworks/mathworks-dot-com/support/sysreq/files/python-compatibility.pdf
mat_pyver <- function(mat_ver){
  version_file <- system.file("matlab-python-versions.txt", package = 'rpymat')
  s <- readLines(version_file)
  s <- s[s != ""]
  s <- strsplit(s, "[ ]+")
  names <- sapply(s, '[[', 1)
  version_list <- structure(lapply(s, function(x){
    x[-1]
  }), names = names)
  re <- version_list[[mat_ver]]
  if(!length(re)){
    # read from Github
    version_file <- "https://raw.githubusercontent.com/dipterix/rpymat/main/inst/matlab-python-versions.txt"
    s <- readLines(version_file)
    s <- s[s != ""]
    s <- strsplit(s, "[ ]+")
    names <- sapply(s, '[[', 1)
    version_list <- structure(lapply(s, function(x){
      x[-1]
    }), names = names)
    re <- version_list[[mat_ver]]
  }
  re
}

#' @rdname conda-env
#' @export
configure_matlab <- function(matlab, python_ver = 'auto'){

  # TODO: must configure python first

  # matlab <- '/Applications/MATLAB_R2020b.app'
  matlab <- matlab[[1]]
  mat_engine_path <- file.path(matlab, "extern/engines/python/")
  py_path <- reticulate::conda_python(env_path())

  if(python_ver == 'auto'){
    # check matlab version

    try({
      s <- readLines(file.path(mat_engine_path, 'setup.py'))
      s <- trimws(s)
      s <- s[startsWith(s, "version")]
      if(length(s)){

        s <- s[[length(s)]]
        s <- tolower(s)
        m <- regexec("20[0-9]{2}[abcdefgh]", s)
        mat_ver <- unlist(regmatches(s, m))

        compatible_ver <- mat_pyver(mat_ver)


        if(length(compatible_ver)){
          # check installed python version
          ver <- system2(py_path, "-V", stdout = TRUE, stderr = TRUE)
          m <- regexec("([23]\\.[0-9]+)\\.[0-9]+", ver)
          ver <- regmatches(ver, m)[[1]][[2]]
          # ver <- stringr::str_match(ver, "([23]\\.[0-9]+)\\.[0-9]+")
          # ver <- ver[[2]]

          if(!ver %in% compatible_ver) {
            python_ver <- compatible_ver[[length(compatible_ver)]]
            message(sprintf("Current python version is `%s`, but matlab engine requires python version to be one of the followings: %s. Trying to install python %s. To proceed, your python version will change in the virtual environment (it is safe and your system python won't change).", ver, paste(compatible_ver, collapse = ', '), python_ver))
            if(interactive()){
              if(!isTRUE(utils::askYesNo("Continue? "))){
                stop("User abort", call. = FALSE)
              }
            }

          }
        }


      }

    })

  }

  if(python_ver != 'auto'){
    add_packages(NULL, python_ver = python_ver)
  }


  setwd2(mat_engine_path)


  build_dir <- file.path(install_root(), "matlab-engine-build")
  if(dir.exists(build_dir)){ unlink(build_dir, recursive = TRUE, force = TRUE) }
  dir.create(build_dir)
  build_dir <- normalizePath(build_dir)
  system2(py_path, c(
    "setup.py",
    "build",
    sprintf('--build-base="%s"', build_dir),
    "install"
  ), wait = TRUE)
}

auto_python_version <- function(matlab){
  matlab <- matlab[[1]]
  mat_engine_path <- file.path(matlab, "extern/engines/python/")
  s <- readLines(file.path(mat_engine_path, 'setup.py'))
  s <- trimws(s)
  s <- s[startsWith(s, "version")]

  s <- s[[length(s)]]
  s <- tolower(s)
  m <- regexec("20[0-9]{2}[abcdefgh]", s)
  mat_ver <- unlist(regmatches(s, m))
  compatible_ver <- mat_pyver(mat_ver)
  compatible_ver
}

#' @rdname conda-env
#' @export
configure_conda <- function(
    python_ver = "auto", packages = NULL, matlab = NULL, update = FALSE,
    force = FALSE, standalone = FALSE, env_name = CONDAENV_NAME()){

  packages <- unique(c(packages, "numpy"))

  error <- TRUE
  set_conda(temporary = TRUE)

  # TODO: check if conda bin exists
  path <- conda_path()

  if(length(matlab)){
    python_vers <- auto_python_version(matlab)
    if( isTRUE(python_ver == 'auto') ){
      python_ver <- python_vers[[length(python_vers)]]
    } else {
      ver <- package_version(python_ver)
      if( !sprintf("%s.%s", ver$major, ver$minor) %in% python_vers ){
        stop("Requested python version is ", python_ver, ". However, this is imcompatible with your matlab installed at ", matlab[[1]], ". Please choose from the following pythons: ", paste(python_vers, collapse = ", "))
      }
    }
  }

  if( dir.exists(path) && !conda_is_user_defined() && !force ) {
    if( identical(env_name, CONDAENV_NAME()) ) {
      stop("conda path already exists. Please consider removing it by calling `rpymat::remove_conda()`")
    }
  }

  miniconda_needs_install <- FALSE
  # if( force || update || !dir.exists(path) ) {
  if( !dir.exists(path) && (standalone || !conda_is_user_defined()) ) {
    # needs install
    miniconda_needs_install <- TRUE
    # if( !standalone && conda_is_user_defined() ) {
    #   # rpymat is inside of a conda environment
    #   miniconda_needs_install <- FALSE
    # }
  }

  if( miniconda_needs_install ){
    miniconda_installer_url()
    tryCatch({

      default_timeout <- getOption("timeout", 60)
      options(timeout = 30*60)
      on.exit({
        options(timeout = default_timeout)
      }, add = TRUE, after = TRUE)

      reticulate::install_miniconda(path = path, update = update, force = force)
    }, error = function(e){
      print(e)
    }, warning = function(e){
      print(e)
    })
    # install_conda(path = path, update = update, force = force)
  }

  # conda tos
  conda_tos("https://repo.anaconda.com/pkgs/main", silent_fail = TRUE)
  conda_tos("https://repo.anaconda.com/pkgs/r", silent_fail = TRUE)

  # create virtual env
  if(force || update || !env_name %in% reticulate::conda_list()[['name']]){
    if( isTRUE(python_ver == "auto") ){
      reticulate::conda_create(env_path(env_name = env_name))
    } else {
      reticulate::conda_create(env_path(env_name = env_name), python_version = python_ver)
    }
  }

  # check matlab
  if(length(matlab)){
    configure_matlab(matlab, python_ver = python_ver)
  }

  if(!length(matlab) || length(packages)) {
    add_packages(packages, python_ver, env_name = env_name)
  }
  error <- FALSE
}

#' @rdname conda-env
#' @param channel channels from which the term-of-service is to be agreed on
#' @param agree whether to agree on or reject the terms; default is true
#' @param silent_fail whether the failure to agreeing to the term should not
#' result in error; default is \code{FALSE}, which results in error if the
#' command fails.
#' @export
conda_tos <- function(channel, agree = TRUE, silent_fail = FALSE) {
  conda_bin_path <- normalizePath(conda_bin(), winslash = "/", mustWork = FALSE)
  if(length(conda_bin_path) != 1 || !nzchar(conda_bin_path) ||
     conda_bin_path %in% c("", ".", "..", "/") || !file.exists(conda_bin_path)) {
    if(silent_fail) {
      warning("No conda bin is found. Please configure conda first.")
    } else {
      stop("No conda bin is found. Please configure conda first.")
    }
    return(invisible())
  }
  if(agree) {
    agree_str <- "accept"
  } else {
    agree_str <- "reject"
  }
  tryCatch(
    {
      system2(conda_bin_path, args = c("tos", agree_str, "--channel", shQuote(channel)))
    },
    error = function(e) {
      if(silent_fail) {
        warning(e)
      } else {
        stop(e)
      }
    }
  )
  return(invisible())
}


conda_is_user_defined <- function() {
  actual_root <- normalizePath(conda_path(), mustWork = FALSE, winslash = "/")
  root <- normalizePath(file.path(install_root(), "miniconda"), mustWork = FALSE, winslash = "/")
  !identical(actual_root, root)
}

#' @rdname conda-env
#' @export
remove_conda <- function(ask = TRUE, env_name = NA){
  if(!interactive()){
    stop("Must run in interactive mode")
  }

  if(conda_is_user_defined()) {
    envpath <- env_path(env_name = env_name)
    if( !dir.exists(envpath) ){ return(invisible()) }
    if( ask ){
      message(sprintf("Removing conda at %s? \nThis operation only affects `rpymat` package and is safe.", envpath))
      ans <- utils::askYesNo("", default = FALSE, prompts = c("yes", "no", "cancel - default is `no`"))
      if(!isTRUE(ans)){
        if(is.na(ans)){
          message("Abort")
        }
        return(invisible())
      }
    }

    system2(conda_bin(), args = c(sprintf("remove --name %s --all --yes", shQuote(env_name))))

  } else {
    root <- normalizePath(install_root(), mustWork = FALSE)

    if( !dir.exists(root) ){ return(invisible()) }
    if( ask ){
      message(sprintf("Removing conda at %s? \nThis operation only affects `rpymat` package and is safe.", root))
      ans <- utils::askYesNo("", default = FALSE, prompts = c("yes", "no", "cancel - default is `no`"))
      if(!isTRUE(ans)){
        if(is.na(ans)){
          message("Abort")
        }
        return(invisible())
      }
    }
    unlink(root, recursive = TRUE, force = TRUE)
  }

  return(invisible())
}

#' @rdname conda-env
#' @export
add_packages <- function(packages = NULL, python_ver = 'auto', ..., env_name = NA) {
  set_conda(temporary = TRUE)


  # install packages
  packages <- unique(packages)
  if(!length(packages)){ return() }
  if( isTRUE(python_ver == "auto") ){
    reticulate::conda_install(env_path(env_name = env_name), packages = packages, ...)
  } else {
    reticulate::conda_install(env_path(env_name = env_name), packages = packages,
                              python_version = python_ver, ...)
  }

}

# Find BLAS path, unix only
BLAS_path <- function(env_name = NA){
  fs <- list.files(file.path(env_path(env_name = env_name), "lib"), pattern = "^libblas\\..*(dylib|so)", ignore.case = TRUE)
  prefered <- c("libblas.dylib", "libblas.so")

  if(!length(fs)){ return() }
  sel <- fs[tolower(fs) %in% prefered]
  if(length(sel)){
    return(normalizePath(file.path(env_path(env_name = env_name), "lib", sel[[1]])))
  }
  return(normalizePath(file.path(env_path(env_name = env_name), "lib", fs[[1]])))
}

ensure_rpymat_internals <- local({

  conf <- NULL
  conda_prefix <- NULL
  blas <- NULL

  init <- function(verbose = TRUE, cache = TRUE, env_name = NA){
    set_conda(temporary = FALSE)

    if(
      !cache || !inherits(conf, "py_config") ||
      !identical(conda_prefix, Sys.getenv("R_RPYMAT_CONDA_PREFIX", unset = ""))
    ) {
      if(!dir.exists(env_path(env_name = env_name))) {
        configure_conda(env_name = env_name)
      }

      if(get_os() == "windows"){
        # C:\Users\KickStarter\AppData\Local\r-rpymat\miniconda\python.exe
        python_bin <- normalizePath(file.path(env_path(env_name = env_name), "python.exe"), winslash = "\\")
        win_modifier <- Sys.getenv("CONDA_DLL_SEARCH_MODIFICATION_ENABLE", unset = NA)
        if(is.na(win_modifier)) {
          Sys.setenv("CONDA_DLL_SEARCH_MODIFICATION_ENABLE" = "1")
        }
      } else {
        python_bin <- normalizePath(file.path(env_path(env_name = env_name), 'bin', "python"))

        # Also there are some inconsistency between BLAS used in R and conda packages
        # Mainly on OSX (because Apple dropped libfortran), but not limited
        # https://github.com/rstudio/reticulate/issues/456#issuecomment-1046045432
        omp_threads <- Sys.getenv("OMP_NUM_THREADS", unset = NA)
        if(is.na(omp_threads)){
          Sys.setenv("OMP_NUM_THREADS" = "1")
        }
        # Find OPENBLAS library
        blas <<- BLAS_path(env_name = env_name)
        if(length(blas)){
          Sys.setenv(OPENBLAS = blas)
        }

      }

      Sys.setenv("RETICULATE_PYTHON" = python_bin)


      # reticulate::use_condaenv(CONDAENV_NAME(), required = TRUE)
      # reticulate::py_config()
      conf <<- reticulate::py_discover_config(use_environment = env_path(env_name = env_name))
      conda_prefix <<- Sys.getenv("R_RPYMAT_CONDA_PREFIX", unset = "")
    }

    if(verbose){
      print(conf)
      if(length(blas)){
        cat("\nOPENBLAS =", blas, "\n")
      }
    }
    invisible(conf)
  }

  test <- function() {
    if(!inherits(conf, "py_config")) { return(NULL) }
    conf
  }

  name <- function() {
    if(!inherits(conf, "py_config")) { return(NULL) }
    basename(conf$prefix)
  }

  list(
    init = init,
    test = test,
    name = name
  )
})

#' @rdname conda-env
#' @export
ensure_rpymat <- ensure_rpymat_internals$init

#' @rdname conda-env
#' @export
matlab_engine <- function(){
  set_conda(temporary = FALSE)
  reticulate::use_condaenv(CONDAENV_NAME(), required = TRUE, conda = conda_bin())

  if(reticulate::py_module_available("matlab.engine")){
    matlab <- reticulate::import('matlab.engine')
    return(invisible(matlab))
    # try({
    #   eng <- matlab$start_matlab(matlab_param)
    # })
  }
  return(invisible())
  # eng$biliear(matrix(rnorm(10), nrow = 1), matrix(rnorm(10), nrow = 1), 0.5)
  # eng$biliear(rnorm(10), rnorm(10), 0.5)

}

#' @rdname conda-env
#' @export
call_matlab <- function(fun, ..., .options = getOption("rpymat.matlab_opt", "-nodesktop -nojvm"), .debug = getOption("rpymat.debug", FALSE)){

  matlab <- matlab_engine()
  if(is.null(matlab)){
    stop("Matlab engine not configured. Please run `configure_matlab(matlab_root)` to set up matlab")
  }


  existing_engines <- getOption("rpymat.matlab_engine", NULL)
  if(is.null(existing_engines)){
    existing_engines <- fastqueue2()
    options("rpymat.matlab_engine" = existing_engines)
  }

  suc <- FALSE

  if(.debug){
    message("Existing engine: ", existing_engines$size())
  }
  if(existing_engines$size()){
    same_opt <- vapply(as.list(existing_engines), function(item){
      if(!is.environment(item)){ return(FALSE) }
      isTRUE(item$options == .options)
    }, FALSE)

    if(any(same_opt)){
      idx <- which(same_opt)[[1]]
      if(idx > 1){
        burned <- existing_engines$mremove(n = idx - 1, missing = NA)
        for(item in burned){
          if(is.environment(item)){
            existing_engines$add(item)
          }
        }
      }
      item <- existing_engines$remove()
      suc <- tryCatch({
        force(item$engine$workspace)
        TRUE
      }, error = function(e){
        # engine is invalid, quit
        item$engine$quit()
        FALSE
      })
    }
  }
  if(!suc){
    if(.debug){
      message("Creating new matlab engine with options: ", .options)
    }
    item <- new.env(parent = emptyenv())
    engine <- matlab$start_matlab(.options)
    item$engine <- engine
    item$options <- .options
    reg.finalizer(item, function(item){

      if(getOption("rpymat.debug", FALSE)){
        message("Removing a matlab instance.")
      }
      try({item$engine$quit()}, silent = TRUE)
    }, onexit = TRUE)
  } else {
    if(.debug){
      message("Using existing idle engine")
    }
  }
  on.exit({
    tryCatch({
      force(item$engine$workspace)

      if(.debug){
        message("Engine is still alive, keep it for future use")
      }
      existing_engines$add(item)
    }, error = function(e){
      if(.debug) {
        message("Engine is not alive, removing from the list.")
      }
      item$engine$quit()
    })
  })
  if(.debug) {
    message("Executing matlab call")
  }
  engine <- item$engine
  res <- engine[[fun]](...)

  return(res)
}

