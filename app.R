library(shiny)

source("R/validate.R", local = TRUE)

ui <- fluidPage(
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "styles.css"),
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
        actionButton("reset", "Reset grid", class = "btn-secondary")
      )
    ),
    uiOutput("info_banner"),
    uiOutput("grid"),
    uiOutput("status_footer")
  )
)

server <- function(input, output, session) {
  reset_counter <- reactiveVal(0L)

  observeEvent(input$reset, {
    reset_counter(reset_counter() + 1L)
  })

  observeEvent(input$n, {
    reset_counter(reset_counter() + 1L)
  }, ignoreInit = TRUE)

  output$grid <- renderUI({
    n <- input$n
    reset_counter()
    req(n)

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
              tags$td(
                textInput(
                  inputId = paste0("cell_", i, "_", j),
                  label = NULL,
                  value = "",
                  width = "3em"
                )
              )
            })
          )
        })
      )
    )
  })

  validation <- reactive({
    n <- input$n
    req(n)
    validate_from_inputs(input, n)
  })

  output$background_style <- renderUI({
    result <- validation()
    bg <- if (isTRUE(result$ok)) "#ffffff" else "#fde8e8"
    tags$style(HTML(sprintf("#app.app-container { background-color: %s; }", bg)))
  })

  output$info_banner <- renderUI({
    result <- validation()
    c1_msgs <- result$info[startsWith(result$info, "C1:")]
    if (length(c1_msgs) == 0L) {
      return(NULL)
    }
    banners <- lapply(c1_msgs, function(msg) {
      div(class = "info-banner warning", msg)
    })
    do.call(tagList, banners)
  })

  output$status_footer <- renderUI({
    result <- validation()
    if (isTRUE(result$ok)) {
      primary <- if (result$complete) {
        c2 <- result$info[startsWith(result$info, "C2:")]
        if (length(c2) > 0L) c2[[1]] else "No violations so far."
      } else {
        incomplete <- result$info[startsWith(result$info, "Incomplete but OK")]
        if (length(incomplete) > 0L) incomplete[[1]] else "No violations so far."
      }
      div(class = "status-footer ok", primary)
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
