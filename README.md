
<!-- README.md is generated from README.Rmd. Please edit that file -->

# glassdoor-scraper

<!-- badges: start -->

<!-- badges: end -->

A demonstration of scraping glassdoor reviews using `rvest`.

``` r
source("R/scrape.R")
#> Loading libraries...
#> Sourcing functions...

# example urls, we'll go with Apple
tesla_url <- "https://www.glassdoor.com/Reviews/Tesla-Reviews-E43129"
apple_url <- "https://www.glassdoor.com/Reviews/Apple-Reviews-E1138"

# loop through n pages, wrap in try catch in case we fail to parse
out <- lapply(2:3, function(x) {
  tryCatch({
    scrape_reviews(
      url = apple_url,
      page = x
    )
  }, error = function(e) {
    warning("Failed to parse page [", x, "]", call. = FALSE)
    NULL
  })
})
#> Scraping page [2] at [2020-08-07 19:38:11]
#> Scraping page [3] at [2020-08-07 19:38:14]

# filter for stuff we successfully extracted
reviews <- bind_rows(Filter(Negate(is.null), out), .id = "page")

reviews %>%
  distinct() %>%
  mutate(review_time = clean_review_datetime(review_time_raw)) %>%
  select(
    page,
    review_time,
    review_time_raw,
    review_title,
    employee_role,
    employee_history,
    employeer_pros,
    employeer_cons,
    employeer_rating
  ) %>% 
  glimpse()
#> Rows: 20
#> Columns: 9
#> $ page             <chr> "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "2…
#> $ review_time      <dttm> 2020-08-06 15:55:43, 2020-08-05 08:36:23, 2020-08-0…
#> $ review_time_raw  <chr> "Thu Aug 06 2020 15:55:43 GMT-0700 (Pacific Daylight…
#> $ review_title     <chr> "Solid", "Apple product Zone", "Even rewarding work …
#> $ employee_role    <chr> "Former Employee - AHA Advisor", "Current Employee -…
#> $ employee_history <chr> "I worked at Apple full-time for more than 5 years",…
#> $ employeer_pros   <chr> "The benefits are some of the best you'll find.", "T…
#> $ employeer_cons   <chr> "No latter to climb. Customer service in general kin…
#> $ employeer_rating <dbl> 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5…
```
