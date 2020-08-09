message("Loading libraries...")
suppressPackageStartupMessages({
  library(rvest)
  library(xml2)
  library(dplyr)
  library(lubridate)
  library(glue)
  library(stringr)
  library(tidyr)
  library(janitor)
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

get_sub_ratings <- function(.data, review_id) {
  out <- lapply(1:5, function(x) {
    subcategory <- .data %>%
      html_nodes(xpath = glue('//*[@id="{review_id}"]/div/div[2]/div[2]/div[1]/span/div[2]/ul/li[{x}]/div')) %>%
      html_text()

    rating <- .data %>%
      html_nodes(xpath = glue('//*[@id="{review_id}"]/div/div[2]/div[2]/div[1]/span/div[2]/ul/li[{x}]/span/span/span/span')) %>%
      html_attr("title") %>%
      as.numeric()

    tibble(subcategory = subcategory, rating = rating)
  })

  no_sub_ratings <- sum(unlist(Map(nrow, out))) == 0
  if (no_sub_ratings) {
    tibble(
      "work_life_balance" = NA_real_,
      "culture_values" = NA_real_,
      "career_opportunities" = NA_real_,
      "compensation_and_benefits" = NA_real_,
      "senior_management" = NA_real_
    )
  } else {
    out %>%
      bind_rows() %>%
      pivot_wider(
        names_from = subcategory,
        values_from = rating
      ) %>%
      clean_names("snake")
  }
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
  subcategories <- bind_rows(lapply(review_ids, function(x) {
    get_sub_ratings(page, x)
  }))

  bind_cols(tibble(
    review_id = review_ids,
    review_time_raw = review_time,
    review_title = review_title,
    employee_role = employee_role,
    employee_history = employee_history,
    employeer_pros = employeer_pros,
    employeer_cons = employeer_cons,
    employeer_rating = employeer_rating
  ), subcategories)
}

try_scrape_reviews <- function(url, page) {
  tryCatch({
    scrape_reviews(
      url = url,
      page = page
    )
  }, error = function(e) {
    warning("Failed to parse page [", page, "]", call. = FALSE)
    NULL
  })
}
