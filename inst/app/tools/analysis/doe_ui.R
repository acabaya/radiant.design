## list of function arguments
doe_args <- as.list(formals(doe))

## list of function inputs selected by user
doe_inputs <- reactive({
  ## loop needed because reactive values don't allow single bracket indexing
  # for (i in r_drop(names(doe_args)))
  for (i in names(doe_args))
    doe_args[[i]] <- input[[paste0("doe_", i)]]
  doe_args
})

output$ui_doe_int <- renderUI({
  req(!is_empty(input$doe_factors))
  vars <- gsub("[ ]{2,}", " ", input$doe_factors) %>%
    gsub("/", "", .) %>%
    gsub("\\\\n", "\n", .) %>%
    gsub("[ ]*;[ ]*", ";", .) %>%
    gsub(";{2,}", ";", .) %>%
    gsub("[;]+[ ]{0,}\n", "\n", .) %>%
    gsub("[ ]{1,}\n", "\n", .) %>%
    gsub("\n[ ]+", "\n", .) %>%
    gsub("[\n]{2,}", "\n", .) %>%
    gsub("[ ]+", "_", .) %>%
    strsplit(., "\n") %>%
    .[[1]] %>%
    strsplit(";") %>%
    sapply(function(x) x[1]) %>%
    unique()

  req(length(vars) > 1)
  choices <- iterms(vars, 2)

  selectInput(
    "doe_int", label = "Interactions:", choices = choices,
    selected = state_init("doe_int"),
    multiple = TRUE, size = min(3, length(choices)), selectize = FALSE
  )
})

output$ui_doe_levels <- renderUI({
  req(input$doe_max > 2)
  make_level <- function(nr) {
    textInput(
      paste0("doe_level", nr), paste0("Level ", nr, ":"),
      value = state_init(paste0("doe_level", nr))
    )
  }
  lapply(3:input$doe_max, make_level)
})

observe({
  ## dep on most inputs
  # for (i in r_drop(names(viz_args))) {
  #   cat(paste0("viz_", i, " = ", input[[paste0("viz_", i)]]), "\n")
  # }; cat("\n")
  # dep on most inputs
  # print(names(doe_args))
  sapply(names(doe_args), function(x) input[[paste0("doe_", x)]])

  ## tried with .visualize but didn't quite work
  # isolate({
  #   print(paste0(attr(.visualize, "observable")$.invalidated, " ", 
  #                attr(viz_inputs, "observable")$.invalidated))
  # })

  ## notify user when the plot needed to be updated
  ## based on https://stackoverflow.com/questions/45478521/listen-to-reactive-invalidation-in-shiny
  if (pressed(input$doe_run) && !is_empty(input$doe_factors)) {
    if (isTRUE(attr(doe_inputs, "observable")$.invalidated)) {
      updateActionButton(session, "doe_run", "Update design", icon = icon("refresh", class = "fa-spin"))
    } else {
      updateActionButton(session, "doe_run", "Create design", icon = icon("play"))
    }
  }
})

output$ui_doe <- renderUI({
  tagList(
    wellPanel(
      actionButton("doe_run", "Create design", width = "100%", icon = icon("play"), class = "btn-success")
    ),
    wellPanel(
      tags$table(
        tags$td(numericInput(
          "doe_max", label = "Max levels:", min = 2, max = 10,
          value = state_init("doe_max", init = 2), width = "80px"
        )),
        tags$td(numericInput(
          "doe_trials", label = "# trials:", min = 0,
          value = state_init("doe_trials", init = NA), width = "65px"
        )),
        tags$td(numericInput(
          "doe_seed", label = "Rnd. seed:", min = 0,
          value = state_init("doe_seed", init = 172110), width = "100%"
        ))
      ),
      HTML("<label>Variable name: <i id='doe_add' title='Add variable' href='#' class='action-button fa fa-plus-circle'></i>
            <i id='doe_del' title='Remove variable' href='#' class='action-button fa fa-minus-circle'></i></label>"),
      textInput("doe_name", NULL, value = state_init("doe_name", "")),
      textInput("doe_level1", "Level 1:", value = state_init("doe_level1")),
      textInput("doe_level2", "Level 2:", value = state_init("doe_level2")),
      uiOutput("ui_doe_levels"),
      uiOutput("ui_doe_int")
    ),
    wellPanel(
      HTML("<label>Download factorial design:</label></br>"),
      downloadButton("doe_download_part", "Partial"),
      downloadButton("doe_download_full", "Full"),
      HTML("</br><label>Download factors:</label></br>"),
      downloadButton("doe_download", "Factors", class = "btn-primary"),
      # fileInput("doe_upload", "Upload factors:", multiple = FALSE, accept = ".txt")
      file_upload_button("doe_upload", label = "Upload factors:", accept = ".txt", buttonLabel = "Factors", class = "btn-primary")
    ),
    help_and_report(
      modal_title = "Design of Experiments",
      fun_name = "doe",
      help_file = inclMD(file.path(getOption("radiant.path.design"), "app/tools/help/doe.md"))
    )
  )
})

observeEvent(input$doe_add, {
  req(input$doe_max)

  dup <- input$doe_name
  for (i in 1:input$doe_max) {
    dtmp <- input[[paste0("doe_level", i)]]
    if (!is_empty(dtmp)) dup <- c(dup, dtmp)
  }
  dup <- paste(dup, collapse = "; ")

  if (is_empty(input$doe_factors)) {
    val <- dup
  } else {
    val <- paste0(input$doe_factors, "\n", dup)
  }

  updateTextInput(session = session, "doe_factors", value = val)
})

observeEvent(input$doe_del, {
  input$doe_factors %>%
    strsplit("\n") %>%
    unlist() %>%
    head(., -1) %>%
    paste0(collapse = "\n") %>%
    updateTextInput(session = session, "doe_factors", value = .)
})

doe_maker <- function(id = "factors",
                      rows = 5,
                      pre = "doe_",
                      placeholder = "Upload an experimental design using the 'Upload factors' button or create a new design using the inputs on the left of the screen. For help, click the ? icon on the bottom left of the screen") {

  id <- paste0(pre, id)
  tags$textarea(
    state_init(id),
    id = id,
    type = "text",
    rows = rows,
    autocomplete = "off",
    autocorrect = "off",
    autocapitalize = "off",
    spellcheck = "false",
    placeholder = placeholder,
    class = "form-control"
  )
}

## output is called from the main radiant ui.R
output$doe <- renderUI({
  register_print_output("summary_doe", ".summary_doe")

  ## single tab with components stacked
  doe_output_panels <- tagList(
    tabPanel(
      "Summary",
      HTML("<label>Design factors:</label>"),
      doe_maker("factors", rows = 5),
      HTML("<br><label>Generated experimental design:</label>"),
      verbatimTextOutput("summary_doe")
    )
  )

  stat_tab_panel(
    menu = "Design > DOE",
    tool = "Design of Experiments",
    data = NULL,
    tool_ui = "ui_doe",
    output_panels = doe_output_panels
  )
})

.doe <- eventReactive(input$doe_run, {
  req(!is_empty(input$doe_factors))

  int <- ""
  if (length(input$doe_int) > 0) {
    int <- input$doe_int
  }

  withProgress(message = "Generating design", value = 1, {
    do.call(doe, doe_inputs())
  })
})

.summary_doe <- reactive({
  summary(.doe(), eff = TRUE, part = TRUE, full = TRUE)
})

output$doe_download_part <- downloadHandler(
  filename = function() {
    "part_factorial.csv"
  },
  content = function(file) {
    .doe() %>%
      {
        if (class(.)[1] == "character") . else .$part
      } %>%
      write.csv(file, row.names = FALSE)
  }
)

output$doe_download_full <- downloadHandler(
  filename = function() {
    "full_factorial.csv"
  },
  content = function(file) {
    .doe() %>%
      {if (class(.)[1] == "character") . else .$full} %>%
      write.csv(file, row.names = FALSE)
  }
)

output$doe_download <- downloadHandler(
  filename = function() {
    "design_factors.txt"
  },
  content = function(file) {
    cat(paste0(input$doe_factors, "\n"), file = file)
  }
)

observeEvent(input$doe_upload, {
  fct <- paste0(readLines(input$doe_upload$datapath), collapse = "\n")
  updateTextInput(session = session, "doe_factors", value = fct)

  ## cleaning out previous settings
  updateNumericInput(session = session, "doe_max", value = 2)
  updateNumericInput(session = session, "doe_trials", value = NA)
  updateTextInput(session = session, "doe_name", value = "")
  for (i in 1:10) {
    r_state[[paste0("doe_level", i)]] <<- NULL
    updateTextInput(session = session, paste0("doe_level", i), value = "")
  }
})

observeEvent(input$doe_report, {
  if (getOption("radiant.local", default = FALSE)) {
    pdir <- getOption("radiant.write_dir", default = "~/")
    xcmd <- paste0("# write.csv(result$part, file = \"", pdir, "part_factorial.csv\")")
  } else {
    xcmd <- ""
  }
  inp_out <- list(list(eff = TRUE, part = TRUE, full = TRUE))

  inp <- clean_args(doe_inputs(), doe_args)
  if (!is_empty(inp[["factors"]])) {
    inp[["factors"]] <- strsplit(inp[["factors"]], "\n")[[1]]
  }

  update_report(
    inp_main = inp,
    fun_name = "doe",
    outputs = "summary",
    inp_out = inp_out,
    figs = FALSE,
    xcmd = xcmd
  )
})
