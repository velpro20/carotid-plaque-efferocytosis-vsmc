# Shared helpers for the numbered reproducible workflow.
# Inputs: project root and standard output directories.
# Outputs: directory creation, logging, parsing, and error capture helpers.
# Dependencies: base R; optional packages are loaded by individual scripts.
# Run order: sourced by 00-12 scripts.

set.seed(20260903)

project_root <- normalizePath(getwd(), winslash = "/", mustWork = FALSE)

ensure_project_dirs <- function(root = project_root) {
  dirs <- c(
    "01_protocol", "02_literature", "03_data/raw", "03_data/metadata",
    "03_data/processed", "04_scripts", "05_results/tables",
    "05_results/figures", "05_results/qc", "06_manuscript",
    "07_submission_package", "08_logs", "09_environment"
  )
  invisible(lapply(file.path(root, dirs), dir.create, recursive = TRUE, showWarnings = FALSE))
}

log_file <- file.path(project_root, "08_logs", "workflow.log")
error_file <- file.path(project_root, "08_logs", "error_log.md")

log_event <- function(message, file = log_file) {
  line <- sprintf("[%s] %s", format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"), message)
  cat(line, "\n", file = file, append = TRUE)
  invisible(line)
}

record_error <- function(step, message, status = NA_integer_) {
  log_event(sprintf("ERROR step=%s status=%s message=%s", step, status, message))
  cat(sprintf("\n- %s | status=%s | %s\n", format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"), status, message),
      file = error_file, append = TRUE)
}

safe_write_csv <- function(x, path, row.names = FALSE) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  write.csv(x, path, row.names = row.names, na = "")
}

read_series_matrix <- function(path) {
  stopifnot(file.exists(path))
  con <- gzfile(path, open = "rt")
  on.exit(close(con), add = TRUE)
  lines <- readLines(con, warn = FALSE)
  begin <- grep("^!series_matrix_table_begin", lines)
  end <- grep("^!series_matrix_table_end", lines)
  if (length(begin) != 1L || length(end) != 1L || end <= begin) {
    stop("Could not locate series matrix table boundaries: ", path)
  }
  txt <- paste(lines[(begin + 1L):(end - 1L)], collapse = "\n")
  tab <- read.delim(text = txt, header = TRUE, sep = "\t", quote = "\"",
                    check.names = FALSE, comment.char = "", stringsAsFactors = FALSE)
  if (ncol(tab) < 2L) stop("Series matrix has fewer than two columns: ", path)
  rownames(tab) <- make.unique(as.character(tab[[1L]]))
  tab <- tab[, -1L, drop = FALSE]
  out <- as.matrix(tab)
  storage.mode(out) <- "numeric"
  out
}

read_counts_matrix <- function(path) {
  stopifnot(file.exists(path))
  con <- gzfile(path, open = "rt")
  on.exit(close(con), add = TRUE)
  tab <- read.delim(con, header = TRUE, sep = "\t", quote = "",
                    check.names = FALSE, comment.char = "",
                    stringsAsFactors = FALSE, fill = TRUE)
  ids <- as.character(tab[[1L]])
  ids[is.na(ids) | ids == ""] <- paste0("unmapped_", which(is.na(ids) | ids == ""))
  rownames(tab) <- make.unique(ids)
  tab <- tab[, -1L, drop = FALSE]
  out <- as.matrix(tab)
  suppressWarnings(storage.mode(out) <- "numeric")
  out[is.na(out)] <- 0
  out
}

bh <- function(p) p.adjust(p, method = "BH")

write_status <- function(path, title, lines) {
  cat(sprintf("# %s\n\n", title), file = path)
  cat(paste0(lines, collapse = "\n"), "\n", file = path, append = TRUE)
}

