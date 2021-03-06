
#' Add a Structure
#' 
#' Add a structure to a grob matrix / image / text object.
#' 
#' @param grob_object The R6 object initialized by one of:
#' \itemize{
#' 
#' \item \code{\link{grob_matrix}}
#' \item \code{\link{grob_image}}
#' \item \code{\link{grob_text}}
#' 
#' }
#' @param structure The structure the user wishes to add.
#' 
#' @param value If \code{grob_object} is outputted by \code{\link{grob_matrix}},
#' then a single value, or a vector of values corresponding to each column of 
#' the initial object passed through \code{\link{grob_matrix}}, the user wants to apply to the 
#' grob matrix object. 
#' 
#' Otherwise, a single value to apply to the \code{structure}.
#' 
#' @return The initial R6 object of the grob object class with its structure properties altered.
#' 
#' @details 
#' 
#' Accepted structures:
#' 
#' \describe{
#' 
#' \item{Matrix / Text}{
#' 
#' \itemize{
#' 
#' \item \code{column_widths_p}
#' \item \code{n_lines}
#' \item \code{padding_p}
#' 
#' }
#' }
#' 
#' \item{Image}{
#' \itemize{
#' 
#' \item \code{aspect_ratio_multiplier}
#' \item \code{maintain_aspect_ratio}
#' 
#' }
#' }
#' 
#' }
#' 
#' To see descriptions of the structures above, see the documentation of \code{\link{ga_list}}.
#' 
#' @export
#' 
#' @examples
#' 
#' df = data.frame(x = c(5, 14, 6, 10), y = c(3, 30, 17, 7))
#' df %>%
#'   grob_matrix() %>% 
#'   add_structure(structure = 'column_widths_p', value = c(1, 4)) %>%
#'   view_grob()
#'   
#' gg = ggplot2::ggplot(data = df, mapping = ggplot2::aes(x = x, y = y)) +
#'   ggplot2::geom_line(color = 'red')
#'   
#' gg %>%
#'   grob_image() %>% 
#'   view_grob()
#'   

add_structure = function(grob_object,
                         structure,
                         value) {
  
  is_grob_matrix = methods::is(grob_object, 'grob_matrix_object')
  is_grob_image = methods::is(grob_object, 'grob_image_object')
  
  
  if (!any(is_grob_image, is_grob_matrix)) {
    
    error_msg = glue::glue("
      Please provide an object outputted by grob_matrix(), grob_text() or grob_image() in add_structure().
      ")
    
    stop(error_msg, call. = FALSE)
     
  }
  
  type = dplyr::case_when(
    is_grob_matrix ~ 'matrix',
    is_grob_image ~ 'image'
    )
  
  structure = check_structure(
    grob_object = grob_object,
    structure = structure,
    type = type,
    value = value,
    location = 'add_structure()'
    )
  
  if (type %in% 'matrix') {
    
    value = convert_to_matrix(value)
    value = check_matrix_structure_value(
      value = value,
      df = grob_object$test,
      location = "add_structure()",
      type = structure
      )
    grob_object$last_edit = "structure"
    grob_object$current_structure = structure
    
  }
  
  grob_object$structure_list[[structure]] = value

  return(grob_object)
  
}

check_structure = function(grob_object, type, structure, value, location) {
  
  if (type %in% 'matrix') {
  
    default_structure = get_matrix_structure(
      grob_matrix_object = grob_object,
      structure = structure
      )
      
    if (nrow(default_structure) == 0) {
      
      valid_structures = matrix_structures
      
      error_msg = glue::glue("
        structure parameter within {location} must be one of: \\
        {paste(valid_structures, collapse = ', ')}
        ")
      
      stop(error_msg, call. = FALSE)
    
    }
    
    if (!all(dim(default_structure$value[[1]]) == dim(value)) & !all(dim(value) == 1)) {
      
      error_msg = glue::glue("
        The structure '{structure}' must have a inputted value within {location} \\
        of 1x1 or {nrow(default_structure)}x{ncol(default_structure)}, not \\
        {nrow(value)}x{ncol(value)}.
        ")
      
      stop(error_msg, call. = FALSE)
      
    }
    
  } else if (type %in% 'image') {
    
    default_structure = get_image_structure(structure = structure)
    
    if (nrow(default_structure) == 0) {
      
      valid_structures = image_structures
      
      error_msg = glue::glue("
        structure parameter within {location} must be one of: \\
        {paste(valid_structures, collapse = ', ')}
        ")
      
      stop(error_msg, call. = FALSE)
    
    }
    
    if (length(value) != 1) {
      
      error_msg = glue::glue("
        Please provide a single value for the {structure} value within {location}.
        ")
      
      stop(error_msg, call. = FALSE)
  
    }
  
  }
  
  return(structure)
  
}

check_structure_validity = function(structure, location) {
  
  valid_structures = matrix_structures
  
  if (!structure %in% valid_structures) {
    
    error_msg = glue::glue("
      structure parameter within {location} must be one of: \\
      {paste(valid_structures, collapse = ', ')}
      ")
    
    stop(error_msg, call. = FALSE)
  
  }
  
  return(structure)
  
}


check_matrix_structure_value = function(value,
                                        df,
                                        location,
                                        type) {
  
  dim_of_df = dim(df[1, !colnames(df) %in% "grobblR_group"])
  dim_of_value = dim(value)
  
  if (!all(dim_of_df == dim_of_value) & !all(dim_of_value == 1)) {
    
    error_msg = glue::glue("
      The value provided in {location} for '{type}' must either be \\
      of the dimensions {dim_of_df[1]}x{dim_of_df[2]} or a single value.
      The inputted dimensions are {dim_of_value[1]}x{dim_of_value[2]}.
      ")
    
    stop(error_msg, call. = FALSE)
    
  }
  
  if (all(dim_of_value == 1)) {
    
    value = convert_to_matrix(rep(value, dim_of_df[2]))
    
  }
  
  return(value)

}

