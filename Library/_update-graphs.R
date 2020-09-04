
  

  library(rmarkdown)
  
  all_files <-
    list.files(path = ".", pattern = ".Rmd")
  
  for (page in all_files) {
    render(page, 
           c("html_document"),
           output_dir = "../docs")  
  }      
  
  