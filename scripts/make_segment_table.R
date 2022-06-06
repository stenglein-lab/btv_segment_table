library(tidyverse)


# This script reads in a table of mapping counts and outputs them on a per-BTV-segment basis
#
# Mark Stenglein June 6, 2022

# ---------------------------------------------------------------------
# Setup params for either running from the command line (from nextflow)
# or for running interactively (in RStudio, for development)
# ---------------------------------------------------------------------
if (!interactive()) {
  # if running from Rscript
  args = commandArgs(trailingOnly=TRUE)
  tsv_file=args[1]
  output_filename=args[2]
  output_dir = "./"
} else {
  # if running via RStudio
  r_bindir = "."
  tsv_file = "./all_read_counts.txt"
  output_filename = "segment_tables.txt"
  output_dir = "../results/"
}

# read in input
df <- read.delim(tsv_file, sep="\t", header=F)
colnames(df) <- c("dataset", "segment_name", "count")

# parse metadata (BTV type, and segment #) out of segment name
btv_regex  <- "(BTV[0-9]+)_seg([0-9]+)"
btv_fields  <- str_match(df$segment_name, btv_regex)

btv_all_match = btv_fields[,1]
btv_serotype  = btv_fields[,2]
btv_segment   = btv_fields[,3]
btv_metadata  = as.data.frame(cbind(btv_all_match, btv_serotype, btv_segment))

# look for invalidly formed names:
btv_malformed <- filter(btv_metadata, is.na(btv_serotype) | is.na(btv_segment)) %>% group_by(btv_all_match) %>% summarize() 
if (nrow(btv_malformed) > 0) {
  message("ERROR: could not parse BTV serotype and segment number out of sequence names")
  message("       which must be in the format: BTV#_seg# (e.g. BTV2_seg10).") 
  message(" ") 
  message("Sequence names with invalid formats: ")
  cat    (btv_malformed)
}

# merge in metadata
df$serotype <- btv_serotype
df$segment  <- btv_segment

# pivot slightly wider for output
df_wider <- df %>% 
  select(dataset, serotype, segment, count) %>%
  pivot_wider(names_from = serotype, values_from = count) %>%
  arrange(dataset, as.numeric(segment))

# write out the table
write.table(df_wider, file = paste0(output_dir, output_filename), quote=F, sep="\t", row.names=F, col.names=T)




