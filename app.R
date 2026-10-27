library(shiny)

source("R/validate.R", local = TRUE)
source("R/snail_layout.R", local = TRUE)
source("R/snail_autofill.R", local = TRUE)
source("R/cp_sat_feasibility.R", local = TRUE)

read_grid_inputs <- function(input, n) {
  mat <- matrix("", n, n)
  for (i in seq_len(n)) {
    for (j in seq_len(n)) {
      raw <- input[[paste0("cell_", i, "_", j)]]
      mat[i, j] <- if (is.null(raw)) "" else trimws(as.character(raw))
    }
  }
  mat
}

cell_input <- function(i, j) {
  textInput(
    inputId = paste0("cell_", i, "_", j),
    label = NULL,
    value = "",
    width = "3em"
  )
}

classic_grid <- function(n) {
  tags$table(
    class = "grid-table",
    tags$thead(
      tags$tr(
        tags$th(""),
        lapply(seq_len(n), function(j) tags$th(j))
      )
    ),
    tags$tbody(
      lapply(seq_len(n), function(i) {
        tags$tr(
          tags$th(i),
          lapply(seq_len(n), function(j) {
            tags$td(cell_input(i, j))
          })
        )
      })
    )
  )
}

snail_grid <- function(n) {
  col_headers <- div(
    class = "snail-col-headers",
    lapply(seq_len(n), function(j) {
      span(class = "snail-header-cell", j)
    })
  )

  row_headers <- div(
    class = "snail-row-headers",
    lapply(seq_len(n), function(i) {
      span(class = "snail-header-cell", i)
    })
  )

  data_table <- tags$table(
    class = "grid-table grid-table-inner",
    tags$tbody(
      lapply(seq_len(n), function(i) {
        tags$tr(
          lapply(seq_len(n), function(j) {
            border_class <- snail_cell_border_classes(i, j, n)
            tags$td(
              class = if (border_class == "") NULL else border_class,
              cell_input(i, j)
            )
          })
        )
      })
    )
  )

  array_box_class <- "snail-array-box snail-array-box-even"

  div(
    class = "snail-grid-layout",
    style = sprintf("--snail-cols: %d; --snail-rows: %d;", n, n),
    div(class = "snail-corner"),
    col_headers,
    row_headers,
    div(class = array_box_class, data_table)
  )
}

ui <- fluidPage(
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "styles.css"),
    tags$script(src = "https://cdnjs.cloudflare.com/ajax/libs/html2canvas/1.4.1/html2canvas.min.js"),
    tags$script(src = "grid_capture.js"),
    uiOutput("background_style")
  ),
  div(
    id = "app",
    class = "app-container",
    titlePanel("RCLS Interactive Validator"),
    p(
      class = "intro",
      "Build an n x n Latin square interactively. The app checks whether your ",
      "partial grid violates any necessary condition for a row-complete Latin square (RCLS)."
    ),
    fluidRow(
      column(
        width = 3,
        numericInput(
          "n",
          label = "Order n",
          value = 6,
          min = 2,
          max = 12,
          step = 1
        ),
        radioButtons(
          "snail_method",
          label = "Build RCLS with Snail Method?",
          choices = c("No" = "no", "Yes" = "yes"),
          selected = "no"
        ),
        conditionalPanel(
          condition = "input.snail_method == 'yes' && (parseInt(input.n) % 4 == 2)",
          radioButtons(
            "wlog_upper_v",
            label = "WLOG Upper V",
            choices = c("No" = "no", "Yes" = "yes"),
            selected = "no"
          )
        ),
        checkboxInput(
          "check_completability",
          label = "Check completability (CP-SAT)?",
          value = FALSE
        ),
        helpText(
          "When on, tests after each edit whether any full RCLS completion exists ",
          "(+ snail symmetry if Snail Method = Yes). Requires Python 3 and ortools. ",
          "Pink background = no completion; light red = rule violation."
        ),
        actionButton("reset", "Reset grid", class = "btn-secondary"),
        actionButton("save_grid", "Save grid", class = "btn-secondary")
      )
    ),
    div(
      id = "grid_capture",
      class = "grid-capture-area",
      uiOutput("info_banner"),
      div(id = "grid", uiOutput("grid_ui")),
      uiOutput("status_footer")
    )
  )
)

server <- function(input, output, session) {
  reset_counter <- reactiveVal(0L)
  grid_snapshot <- reactiveVal(NULL)
  is_syncing <- reactiveVal(FALSE)

  observeEvent(input$reset, {
    reset_counter(reset_counter() + 1L)
    grid_snapshot(NULL)
    schedule_upper_v_fill()
  })

  apply_upper_v_fill <- function(n) {
    fills <- snail_upper_v_fill_cells(n)
    if (nrow(fills) == 0L) {
      return()
    }

    is_syncing(TRUE)
    grid_snapshot(NULL)
    for (k in seq_len(nrow(fills))) {
      updateTextInput(
        session,
        inputId = paste0("cell_", fills[k, 1], "_", fills[k, 2]),
        value = as.character(fills[k, 3])
      )
    }

    session$onFlushed(function() {
      if (!identical(isolate(input$n), n)) {
        is_syncing(FALSE)
        return()
      }
      grid_snapshot(isolate(read_grid_inputs(input, n)))
      is_syncing(FALSE)
    }, once = TRUE)
  }

  schedule_upper_v_fill <- function() {
    snail <- isolate(input$snail_method)
    wlog <- isolate(input$wlog_upper_v)
    n <- isolate(input$n)
    if (
      !identical(snail, "yes") ||
        !identical(wlog, "yes") ||
        is.null(n) ||
        n %% 4L != 2L
    ) {
      return()
    }
    session$onFlushed(function() {
      if (!identical(isolate(input$n), n)) {
        return()
      }
      apply_upper_v_fill(n)
    }, once = TRUE)
  }

  observeEvent(input$n, {
    n <- input$n
    if (!is.null(n) && n %% 4L != 2L && identical(input$wlog_upper_v, "yes")) {
      updateRadioButtons(session, "wlog_upper_v", selected = "no")
    }
    reset_counter(reset_counter() + 1L)
    grid_snapshot(NULL)
    schedule_upper_v_fill()
  }, ignoreInit = TRUE)

  observeEvent(input$snail_method, {
    if (!identical(input$snail_method, "yes") && identical(input$wlog_upper_v, "yes")) {
      updateRadioButtons(session, "wlog_upper_v", selected = "no")
    }
    reset_counter(reset_counter() + 1L)
    grid_snapshot(NULL)
  }, ignoreInit = TRUE)

  observeEvent(input$wlog_upper_v, {
    if (identical(input$wlog_upper_v, "yes")) {
      schedule_upper_v_fill()
    } else {
      reset_counter(reset_counter() + 1L)
      grid_snapshot(NULL)
    }
  }, ignoreInit = TRUE)

  observeEvent(reset_counter(), {
    grid_snapshot(NULL)
    is_syncing(FALSE)
  }, ignoreInit = TRUE)

  output$grid_ui <- renderUI({
    n <- input$n
    reset_counter()
    req(n)

    if (identical(input$snail_method, "yes")) {
      snail_grid(n)
    } else {
      classic_grid(n)
    }
  })

  validation <- reactive({
    n <- input$n
    req(n)
    snail_mode <- identical(input$snail_method, "yes")
    validate_from_inputs(input, n, snail_mode = snail_mode)
  })

  debounced_grid_state <- debounce(
    reactive({
      n <- input$n
      req(n)
      list(
        n = n,
        grid = read_grid_inputs(input, n),
        snail_mode = identical(input$snail_method, "yes"),
        enabled = isTRUE(input$check_completability),
        syncing = isTRUE(is_syncing())
      )
    }),
    millis = 500
  )

  feasibility <- reactive({
    state <- debounced_grid_state()
    if (!isTRUE(state$enabled)) {
      return(NULL)
    }
    if (isTRUE(state$syncing)) {
      return(list(status = "SKIP", message = NULL, wall_ms = NA_integer_))
    }

    n <- state$n
    converted <- grid_chars_to_matrix(state$grid, n)
    if (isTRUE(converted$invalid)) {
      return(list(status = "SKIP", message = NULL, wall_ms = NA_integer_))
    }

    partial <- validate_partial_rcls(converted$matrix, n, snail_mode = state$snail_mode)
    if (!isTRUE(partial$ok)) {
      return(list(status = "SKIP", message = NULL, wall_ms = NA_integer_))
    }

    check_completion_feasible(
      converted$matrix,
      n,
      snail_mode = state$snail_mode,
      timeout_sec = 2
    )
  })

  observe({
    if (!identical(input$snail_method, "yes")) {
      return()
    }

    n <- input$n
    req(n)

    if (isTRUE(is_syncing())) {
      return()
    }

    current <- read_grid_inputs(input, n)
    previous <- grid_snapshot()

    if (is.null(previous)) {
      grid_snapshot(current)
      return()
    }

    if (identical(current, previous)) {
      return()
    }

    if (!identical(dim(current), dim(previous))) {
      grid_snapshot(current)
      return()
    }

    diff_cells <- which(current != previous, arr.ind = TRUE)
    if (nrow(diff_cells) == 0L) {
      return()
    }

    # Ignore batched input updates from our own mirror sync; catch snapshot up.
    if (nrow(diff_cells) > 1L) {
      grid_snapshot(current)
      return()
    }

    source_row <- diff_cells[1, 1]
    source_col <- diff_cells[1, 2]
    new_value <- current[source_row, source_col]
    mirrors <- snail_mirror_cells(n, source_row, source_col)

    if (nrow(mirrors) == 0L) {
      grid_snapshot(current)
      return()
    }

    is_syncing(TRUE)
    did_update <- FALSE
    for (k in seq_len(nrow(mirrors))) {
      row_i <- mirrors[k, 1]
      col_j <- mirrors[k, 2]
      if (identical(current[row_i, col_j], new_value)) {
        next
      }
      updateTextInput(
        session,
        inputId = paste0("cell_", row_i, "_", col_j),
        value = new_value
      )
      did_update <- TRUE
    }

    finish_sync <- function() {
      current_n <- isolate(input$n)
      if (!identical(current_n, n)) {
        is_syncing(FALSE)
        return()
      }
      grid_snapshot(isolate(read_grid_inputs(input, n)))
      is_syncing(FALSE)
    }

    if (did_update) {
      session$onFlushed(finish_sync, once = TRUE)
    } else {
      finish_sync()
    }
  })

  output$background_style <- renderUI({
    result <- validation()
    feas <- feasibility()
    bg <- if (!isTRUE(result$ok)) {
      "#fde8e8"
    } else if (
      isTRUE(input$check_completability) &&
        !is.null(feas) &&
        identical(feas$status, "INFEASIBLE")
    ) {
      "#fce4ec"
    } else {
      "#ffffff"
    }
    tags$style(HTML(sprintf("#app.app-container { background-color: %s; }", bg)))
  })

  output$info_banner <- renderUI({
    result <- validation()
    feas <- feasibility()
    banner_msgs <- result$info[
      startsWith(result$info, "C1:") | startsWith(result$info, "D1:")
    ]
    if (
      isTRUE(input$check_completability) &&
        !is.null(feas) &&
        identical(feas$status, "UNKNOWN") &&
        !is.null(feas$message)
    ) {
      banner_msgs <- c(banner_msgs, feas$message)
    }
    if (length(banner_msgs) == 0L) {
      return(NULL)
    }
    banners <- lapply(banner_msgs, function(msg) {
      class_name <- if (startsWith(msg, "D1:")) {
        "info-banner conjecture"
      } else {
        "info-banner warning"
      }
      div(class = class_name, msg)
    })
    do.call(tagList, banners)
  })

  output$status_footer <- renderUI({
    result <- validation()
    feas <- feasibility()
    if (isTRUE(result$ok)) {
      primary <- if (result$complete) {
        c2 <- result$info[startsWith(result$info, "C2:")]
        if (length(c2) > 0L) c2[[1]] else "No violations so far."
      } else {
        incomplete <- result$info[startsWith(result$info, "Incomplete but OK")]
        if (length(incomplete) > 0L) incomplete[[1]] else "No violations so far."
      }
      extra <- NULL
      if (
        isTRUE(input$check_completability) &&
          !is.null(feas) &&
          !is.null(feas$message) &&
          feas$status %in% c("INFEASIBLE", "UNAVAILABLE")
      ) {
        extra <- div(class = "status-footer feasibility", feas$message)
      }
      tagList(div(class = "status-footer ok", primary), extra)
    } else {
      first <- result$violations[[1]]
      extra <- length(result$violations) - 1L
      suffix <- if (extra > 0L) {
        sprintf(" (+%d more violation%s)", extra, if (extra == 1L) " " else "s ")
      } else {
        ""
      }
      div(
        class = "status-footer error",
        strong("Violation: "),
        first,
        suffix
      )
    }
  })
}

shinyApp(ui, server)
