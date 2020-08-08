message("Loading libraries...")
suppressPackageStartupMessages({
  library(rvest)
  library(xml2)
  library(dplyr)
  library(lubridate)
  library(glue)
  library(stringr)
})

message("Sourcing functions...")
read_page <- function(url, page) {
  glue("{url}_P{page}.htm") %>%
    read_html()
}

get_review_ids <- function(.data) {
  .data %>%
    html_nodes(xpath = "//*[contains(@id, 'empReview')]") %>%
    html_attr("id")
}

get_review_datetime <- function(.data, review_id) {
  x <- glue('//*[@id="{review_id}"]/div/div[1]/div/time')
  .data %>%
    html_nodes(xpath = x) %>%
    html_attr("datetime")
}

clean_review_datetime <- function(x) {
  x <- trimws(sub("(GMT-).*", "", x))
  parse_date_time(x, "a b d y H:M:S", tz = "gmt")
}

get_review_title <- function(.data, review_id) {
  x <- glue('//*[@id="{review_id}"]/div/div[2]/div[2]/h2/a')
  .data %>%
    html_nodes(xpath = x) %>%
    html_text() %>%
    str_remove_all(., '"')
}

get_employee_role <- function(.data, review_id) {
  x <- glue('//*[@id="{review_id}"]/div/div[2]/div[2]/div[2]/div/span/span[1]')
  .data %>%
    html_nodes(xpath = x) %>%
    html_text()
}

get_employee_history <- function(.data, review_id) {
  x <- glue('//*[@id="{review_id}"]/div/div[2]/div[2]/p')
  .data %>%
    html_nodes(xpath = x) %>%
    html_text()
}

get_employeer_pros <- function(.data, review_id) {
  x <- glue('//*[@id="{review_id}"]/div/div[2]/div[2]/div[4]/p[2]')
  .data %>%
    html_nodes(xpath = x) %>%
    html_text()
}

get_employeer_cons <- function(.data, review_id) {
  x <- glue('//*[@id="{review_id}"]/div/div[2]/div[2]/div[5]/p[2]')
  .data %>%
    html_nodes(xpath = x) %>%
    html_text()
}

get_overall_rating <- function(.data, review_id) {
  x <- glue('//*[@id="{review_id}"]/div/div[2]/div[2]/div[1]/span/div[1]/div/div')
  .data %>%
    html_nodes(xpath = x) %>%
    html_text() %>%
    as.numeric()
}

scrape_reviews <- function(url, page_number) {
  message("Scraping page [", page_number, "] at [", Sys.time(), "]")
  page <- read_page(url, page_number)
  review_ids <- get_review_ids(page)

  review_time <- unlist(lapply(review_ids, get_review_datetime, .data = page))
  review_title <- unlist(lapply(review_ids, get_review_title, .data = page))
  employee_role <- unlist(lapply(review_ids, get_employee_role, .data = page))
  employee_history <- unlist(lapply(review_ids, get_employee_history, .data = page))
  employeer_pros <- unlist(lapply(review_ids, get_employeer_pros, .data = page))
  employeer_cons <- unlist(lapply(review_ids, get_employeer_cons, .data = page))
  employeer_rating <- unlist(lapply(review_ids, get_overall_rating, .data = page))

  tibble(
    review_time_raw = review_time,
    # review_time = clean_review_datetime(review_time),
    review_title = review_title,
    employee_role = employee_role,
    employee_history = employee_history,
    employeer_pros = employeer_pros,
    employeer_cons = employeer_cons,
    employeer_rating = employeer_rating
  )
}
