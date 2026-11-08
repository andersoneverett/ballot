# Chart theme that uses the same --bb-* colors as styles.css (read from that file, so they never drift apart).
bb_colors <- function(css = "styles.css") {
  x <- paste(readLines(css, warn = FALSE), collapse = "\n")
  m <- regmatches(x, gregexpr("--bb-[a-z]+:#[0-9A-Fa-f]{6}", x))[[1]]
  stats::setNames(sub("^--bb-[a-z]+:", "", m), sub("^--bb-([a-z]+):.*", "\\1", m))
}

theme_ballot <- function(base_size = 12, colors = bb_colors()) {
  ggplot2::theme_minimal(base_size = base_size, base_family = "sans") +
    ggplot2::theme(
      text = ggplot2::element_text(color = colors[["black"]]),
      plot.background = ggplot2::element_rect(fill = colors[["white"]], color = NA),
      panel.background = ggplot2::element_rect(fill = colors[["white"]], color = NA),
      panel.grid.major.x = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major.y = ggplot2::element_line(color = colors[["line"]], linewidth = 0.3),
      axis.text = ggplot2::element_text(color = colors[["gray"]]),
      axis.title = ggplot2::element_text(color = colors[["gray"]]),
      axis.ticks = ggplot2::element_line(color = colors[["line"]]),
      plot.title = ggplot2::element_text(family = "serif", face = "bold", size = ggplot2::rel(1.4), color = colors[["black"]]),
      plot.subtitle = ggplot2::element_text(color = colors[["gray"]]),
      plot.caption = ggplot2::element_text(color = colors[["gray"]], hjust = 0),
      strip.text = ggplot2::element_text(face = "bold", hjust = 0, color = colors[["black"]]),
      legend.position = "bottom",
      legend.title = ggplot2::element_blank()
    )
}

scale_fill_ballot <- function(colors = bb_colors()) {
  ggplot2::scale_fill_manual(values = c(
    For = colors[["pass"]], Against = colors[["fail"]],
    Passed = colors[["pass"]], Failed = colors[["fail"]]
  ))
}
