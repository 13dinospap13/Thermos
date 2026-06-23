#' Launch the BIOMET GUI
#'
#' Starts a Shiny application that gathers inputs and calls the package's core
#' functions. The GUI does not implement the science itself.
#'
#' @return Invisibly returns the Shiny app object.
#' @export
biomet_gui <- function() {
  asset_dir <- system.file("app/www", package = "BIOMET")
  if (nzchar(asset_dir) && dir.exists(asset_dir)) {
    shiny::addResourcePath("biomet-assets", asset_dir)
  }

  path_input_ui <- function(text_id,
                            button_id,
                            label,
                            button_label = "Browse",
                            value = "") {
    shiny::tagList(
      shiny::fluidRow(
        shiny::column(
          width = 8,
          shiny::textInput(text_id, label, value = value)
        ),
        shiny::column(
          width = 4,
          shiny::tags$div(
            style = "margin-top: 25px;",
            shiny::actionButton(button_id, button_label)
          )
        )
      )
    )
  }

  ps_quote <- function(x) {
    paste0("'", gsub("'", "''", x, fixed = TRUE), "'")
  }

  windows_choose_file_path <- function(caption, filter) {
    script <- paste(
      "Add-Type -AssemblyName System.Windows.Forms",
      "$form = New-Object System.Windows.Forms.Form",
      "$form.TopMost = $true",
      "$form.StartPosition = 'CenterScreen'",
      "$form.WindowState = 'Minimized'",
      "$form.ShowInTaskbar = $false",
      "$dialog = New-Object System.Windows.Forms.OpenFileDialog",
      paste0("$dialog.Title = ", ps_quote(caption)),
      paste0("$dialog.Filter = ", ps_quote(filter)),
      "$dialog.Multiselect = $false",
      "$result = $dialog.ShowDialog($form)",
      "if ($result -eq [System.Windows.Forms.DialogResult]::OK) {",
      "  [Console]::OutputEncoding = [System.Text.Encoding]::UTF8",
      "  Write-Output $dialog.FileName",
      "}",
      sep = "; "
    )

    selected <- tryCatch(
      system2("powershell", c("-NoProfile", "-Command", script), stdout = TRUE, stderr = FALSE),
      error = function(e) character()
    )

    if (length(selected) == 0 || !nzchar(selected[1])) {
      return(NULL)
    }

    normalizePath(selected[1], winslash = "/", mustWork = FALSE)
  }

  choose_file_path <- function(caption, filter = "All files (*.*)|*.*") {
    if (.Platform$OS.type == "windows") {
      return(windows_choose_file_path(caption, filter))
    }

    selected <- tcltk::tk_choose.files(caption = caption, multi = FALSE)
    if (length(selected) == 0 || !nzchar(selected[1])) {
      return(NULL)
    }

    normalizePath(selected[1], winslash = "/", mustWork = FALSE)
  }

  windows_choose_directory_path <- function(caption, default_path) {
    script <- paste(
      "Add-Type -AssemblyName System.Windows.Forms",
      "$form = New-Object System.Windows.Forms.Form",
      "$form.TopMost = $true",
      "$form.StartPosition = 'CenterScreen'",
      "$form.WindowState = 'Minimized'",
      "$form.ShowInTaskbar = $false",
      "$dialog = New-Object System.Windows.Forms.OpenFileDialog",
      paste0("$dialog.Title = ", ps_quote(caption)),
      paste0("$dialog.InitialDirectory = ", ps_quote(normalizePath(default_path, winslash = "\\", mustWork = FALSE))),
      "$dialog.Filter = 'Folders|*.none'",
      "$dialog.CheckFileExists = $false",
      "$dialog.CheckPathExists = $true",
      "$dialog.ValidateNames = $false",
      "$dialog.FileName = 'Select Folder'",
      "$result = $dialog.ShowDialog($form)",
      "if ($result -eq [System.Windows.Forms.DialogResult]::OK) {",
      "  [Console]::OutputEncoding = [System.Text.Encoding]::UTF8",
      "  Write-Output (Split-Path $dialog.FileName -Parent)",
      "}",
      sep = "; "
    )

    selected <- tryCatch(
      system2("powershell", c("-NoProfile", "-Command", script), stdout = TRUE, stderr = FALSE),
      error = function(e) character()
    )

    if (length(selected) == 0 || !nzchar(selected[1])) {
      return(NULL)
    }

    normalizePath(selected[1], winslash = "/", mustWork = FALSE)
  }

  choose_directory_path <- function(caption, default_path = getwd()) {
    if (is.null(default_path) || !nzchar(default_path)) {
      default_path <- getwd()
    }

    if (.Platform$OS.type == "windows") {
      return(windows_choose_directory_path(caption, default_path))
    }

    if (!requireNamespace("tcltk", quietly = TRUE)) {
      stop("Directory selection requires 'tcltk' on non-Windows platforms.", call. = FALSE)
    }

    selected <- tcltk::tk_choose.dir(
      default = normalizePath(default_path, winslash = "/", mustWork = FALSE),
      caption = caption
    )
    if (is.na(selected) || !nzchar(selected)) {
      return(NULL)
    }
    normalizePath(selected, winslash = "/", mustWork = FALSE)
  }

  app <- shiny::shinyApp(
    ui = shiny::fluidPage(
      shiny::tags$head(
        shiny::tags$title("BIOMET Thermal Comfort Tool"),
        shiny::tags$link(
          rel = "icon",
          type = "image/svg+xml",
          href = "biomet-assets/biomet-icon.svg"
        ),
        shiny::tags$style(
          shiny::HTML(
            "
            .biomet-task-panel-wrap {
              display: flex;
              justify-content: flex-end;
              margin-bottom: 12px;
              pointer-events: none;
            }

            .biomet-task-panel {
              min-width: 320px;
              max-width: 520px;
              padding: 12px 14px 10px 14px;
              border-radius: 12px;
              background: rgba(255, 255, 255, 0.96);
              border: 1px solid #d8dee4;
              box-shadow: 0 10px 26px rgba(0, 0, 0, 0.10);
              color: #1f2a37;
              pointer-events: auto;
            }

            .biomet-task-panel-top {
              display: flex;
              align-items: center;
              justify-content: space-between;
              gap: 12px;
              margin-bottom: 10px;
            }

            .biomet-task-panel-left {
              display: flex;
              align-items: center;
              gap: 10px;
              min-width: 0;
            }

            .biomet-task-panel-left .fa {
              font-size: 18px;
              color: #1f77b4;
            }

            .biomet-task-title {
              font-weight: 600;
              line-height: 1.2;
            }

            .biomet-task-subtitle {
              font-size: 12px;
              color: #667085;
              line-height: 1.2;
              margin-top: 2px;
            }

            .biomet-task-progress {
              position: fixed;
              width: 100%;
              height: 8px;
              position: relative;
              overflow: hidden;
              border-radius: 999px;
              background: #eaf0f6;
            }

            .biomet-task-progress-bar {
              position: absolute;
              left: -35%;
              top: 0;
              height: 100%;
              width: 35%;
              border-radius: 999px;
              background: linear-gradient(90deg, #1f77b4, #4db6ac);
              animation: biomet-progress-slide 1.25s ease-in-out infinite;
            }

            @keyframes biomet-progress-slide {
              0% {
                left: -35%;
              }
              100% {
                left: 100%;
              }
            }

            .biomet-top-actions {
              display: flex;
              justify-content: flex-end;
              margin-bottom: 12px;
            }

            .biomet-advanced-box {
              margin-top: 10px;
              margin-bottom: 14px;
              padding: 8px 10px 2px 10px;
              border: 1px solid #d8dee4;
              border-radius: 8px;
              background: #fafbfc;
            }
            "
          )
        )
        ,
        shiny::tags$script(
          shiny::HTML(
            "
            (function() {
              let biometAlertInterval = null;

              function biometSingleBeep() {
                try {
                  const AudioCtx = window.AudioContext || window.webkitAudioContext;
                  if (!AudioCtx) return;
                  const ctx = new AudioCtx();
                  const osc = ctx.createOscillator();
                  const gain = ctx.createGain();
                  osc.type = 'sine';
                  osc.frequency.value = 880;
                  gain.gain.value = 0.05;
                  osc.connect(gain);
                  gain.connect(ctx.destination);
                  osc.start();
                  setTimeout(function() {
                    osc.stop();
                    if (ctx.close) ctx.close();
                  }, 180);
                } catch (e) {
                  console.log('BIOMET beep failed', e);
                }
              }

              Shiny.addCustomMessageHandler('biometStartAlert', function(message) {
                if (biometAlertInterval) {
                  clearInterval(biometAlertInterval);
                }
                biometSingleBeep();
                biometAlertInterval = setInterval(biometSingleBeep, 1400);
              });

              Shiny.addCustomMessageHandler('biometStopAlert', function(message) {
                if (biometAlertInterval) {
                  clearInterval(biometAlertInterval);
                  biometAlertInterval = null;
                }
              });

              Shiny.addCustomMessageHandler('biometSetTaskRunning', function(message) {
                return;
              });
            })();
            "
          )
        )
      ),
      shiny::titlePanel("BIOMET Thermal Comfort Tool"),
      shiny::sidebarLayout(
        shiny::sidebarPanel(
          shiny::h4("Input files"),
          path_input_ui("lc_path", "lc_path_browse", "Land cover GeoPackage"),
          path_input_ui("obs_path", "obs_path_browse", "Obstacles GeoPackage"),
          path_input_ui("dem_dir", "dem_dir_browse", "DEM folder"),
          path_input_ui("dsm_dir", "dsm_dir_browse", "DSM folder"),
          path_input_ui("met_xlsx", "met_xlsx_browse", "Meteorological Excel"),
          path_input_ui(
            "output_root",
            "output_root_browse",
            "Parent output folder",
            value = ""
          ),
          shiny::helpText("BIOMET will create a BIOMET_outputs folder inside the selected parent folder, with subfolders for rasters_for_modeling, svf, and results."),
          shiny::h4("Parameters"),
          shiny::selectInput(
            "plot_suffix",
            "Plot selection",
            choices = c(
              "Auto-detect (recommended)" = "__auto__",
              "All detected plots" = "__all__"
            ),
            selected = "__auto__"
          ),
          shiny::helpText("Choose one detected plot, let BIOMET auto-detect it, or run all detected plots."),
          shiny::tags$div(
            class = "biomet-advanced-box",
            shiny::tags$details(
              shiny::tags$summary("Advanced parameters"),
              shiny::numericInput("num_directions", "num_directions", value = 72, min = 8),
              shiny::numericInput("max_distance", "max_distance", value = 30, min = 1),
              shiny::numericInput("observer_height", "observer_height", value = 1.5, min = 0.1),
              shiny::numericInput("Met", "Met", value = 80, min = 1),
              shiny::numericInput("Clo", "Clo", value = 0.9, min = 0),
              shiny::numericInput("ht", "height", value = 1.75, min = 0.5),
              shiny::numericInput("mbody", "body mass", value = 75, min = 1),
              shiny::tags$details(
                shiny::tags$summary("Default fallback values used when surface data are missing"),
                shiny::tags$div(
                  shiny::tags$p("These defaults are applied only inside the DEM mask where required rasters are missing."),
                  shiny::tags$ul(
                    shiny::tags$li("Ground albedo = 0.15"),
                    shiny::tags$li("Ground emissivity = 0.95"),
                    shiny::tags$li("Aerodynamic roughness z0 = 0.5"),
                    shiny::tags$li("ET scaling factor = 0.0"),
                    shiny::tags$li("GAI = 0.0"),
                    shiny::tags$li("Canopy extinction k_ext = 0.5"),
                    shiny::tags$li("Wall emissivity = 0.92"),
                    shiny::tags$li("Wall albedo = 0.0"),
                    shiny::tags$li("Vegetation absence is treated as LAI = 0 and canopy_cover = 0")
                  )
                )
              )
            )
          ),
          shiny::actionButton("check", "Check inputs"),
          shiny::actionButton("run_raster", "Run rasterization"),
          shiny::actionButton("run_svf", "Run SVF"),
          shiny::actionButton("run_thermal", "Run thermal comfort"),
          shiny::actionButton("run_all", "Run full pipeline")
        ),
        shiny::mainPanel(
          shiny::uiOutput("task_panel_ui"),
          shiny::h4("Status"),
          shiny::verbatimTextOutput("status"),
          shiny::h4("Results"),
          shiny::tableOutput("results"),
          shiny::hr(),
          shiny::h4("Visualization"),
          shiny::fluidRow(
            shiny::column(
              width = 6,
              shiny::selectInput("viz_category", "Output group", choices = c(
                "Thermal results" = "results",
                "SVF" = "svf",
                "Rasterized layers" = "rasters_for_modeling"
              ))
            ),
            shiny::column(
              width = 6,
              shiny::selectInput("viz_file", "Raster to preview", choices = character(0))
            )
          ),
          shiny::textOutput("viz_info"),
          shiny::plotOutput("viz_plot", height = "520px")
        )
      )
    ),
    server = function(input, output, session) {
      status <- shiny::reactiveVal("Ready.")
      results <- shiny::reactiveVal(NULL)
      session_has_outputs <- shiny::reactiveVal(FALSE)
      current_task <- shiny::reactiveVal(NULL)

      stop_completion_alert <- function() {
        session$sendCustomMessage("biometStopAlert", list())
        shiny::removeModal()
      }

      show_completion_alert <- function(title, message) {
        session$sendCustomMessage("biometStartAlert", list())
        shiny::showModal(
          shiny::modalDialog(
            title = title,
            shiny::tags$p(message),
            shiny::tags$p("Click OK to stop the alert."),
            footer = shiny::tagList(
              shiny::actionButton("dismiss_completion_alert", "OK", icon = shiny::icon("check"))
            ),
            easyClose = FALSE
          )
        )
      }

      shiny::observeEvent(input$dismiss_completion_alert, {
        stop_completion_alert()
      })

      set_task_running <- function(is_running) {
        session$sendCustomMessage(
          "biometSetTaskRunning",
          list(running = isTRUE(is_running))
        )
      }

      ensure_output_dirs_exist <- function(fun_args) {
        candidate_dirs <- c(
          fun_args$output_root,
          fun_args$lc_dir,
          fun_args$svf_dir,
          fun_args$out_dir
        )
        candidate_dirs <- unique(candidate_dirs[nzchar(candidate_dirs)])

        for (dir_path in candidate_dirs) {
          dir.create(dir_path, showWarnings = FALSE, recursive = TRUE)
        }
      }

      start_background_task <- function(task_type,
                                        label,
                                        success_title,
                                        success_message,
                                        fun_name,
                                        fun_args) {
        if (!is.null(current_task())) {
          status("Another BIOMET task is already running. Stop it first or wait until it finishes.")
          return(invisible(FALSE))
        }

        stop_completion_alert()
        ensure_output_dirs_exist(fun_args)
        task <- list(
          job = callr::r_bg(
            func = function(task_payload) {
              .libPaths(task_payload$libpaths)
              if (!is.null(task_payload$wd) && nzchar(task_payload$wd)) {
                setwd(task_payload$wd)
              }
              candidate_dirs <- c(
                task_payload$fun_args$output_root,
                task_payload$fun_args$lc_dir,
                task_payload$fun_args$svf_dir,
                task_payload$fun_args$out_dir
              )
              candidate_dirs <- unique(candidate_dirs[nzchar(candidate_dirs)])
              for (dir_path in candidate_dirs) {
                dir.create(dir_path, showWarnings = FALSE, recursive = TRUE)
              }
              suppressPackageStartupMessages(library(BIOMET))
              do.call(
                get(task_payload$fun_name, envir = asNamespace("BIOMET")),
                task_payload$fun_args
              )
            },
            args = list(
              task_payload = list(
                libpaths = .libPaths(),
                wd = getwd(),
                fun_name = fun_name,
                fun_args = fun_args
              )
            ),
            stdout = "|",
            stderr = "|",
            supervise = TRUE,
            wd = getwd()
          ),
          task_type = task_type,
          label = label,
          success_title = success_title,
          success_message = success_message
        )

        current_task(task)
        set_task_running(TRUE)
        status(paste(label, "running... Use 'Stop current run' to cancel."))
        invisible(TRUE)
      }

      finish_background_task <- function(task, result_obj) {
        if (identical(task$task_type, "pipeline")) {
          results(result_obj$thermal)
        } else {
          results(result_obj)
        }

        session_has_outputs(TRUE)
        refresh_visualization_choices()
        refresh_plot_suffix_choices(input$plot_suffix)
        status(paste(task$label, "complete."))
        show_completion_alert(task$success_title, task$success_message)
      }

      safe_browse <- function(expr) {
        tryCatch(
          expr,
          error = function(e) {
            status(paste("Browse error:", conditionMessage(e)))
            invisible(NULL)
          }
        )
      }

      build_output_dirs <- function(root_dir) {
        if (is.null(root_dir) || !nzchar(root_dir)) {
          root_dir <- getwd()
        }
        project_root <- file.path(root_dir, "BIOMET_outputs")
        list(
          parent = root_dir,
          root = project_root,
          lc_dir = file.path(project_root, "rasters_for_modeling"),
          svf_dir = file.path(project_root, "svf"),
          out_dir = file.path(project_root, "results")
        )
      }

      list_raster_choices <- function(output_root, category) {
        if (!isTRUE(session_has_outputs())) {
          return(setNames(character(0), character(0)))
        }

        dirs <- build_output_dirs(output_root)
        folder <- switch(
          category,
          rasters_for_modeling = dirs$lc_dir,
          svf = dirs$svf_dir,
          results = dirs$out_dir,
          dirs$out_dir
        )

        if (!dir.exists(folder)) {
          return(setNames(character(0), character(0)))
        }

        files <- list.files(folder, pattern = "\\.tif$", full.names = TRUE)
        if (length(files) == 0) {
          return(setNames(character(0), character(0)))
        }

        labels <- basename(files)
        stats <- file.info(files)
        ord <- order(stats$mtime, labels, decreasing = TRUE)
        files <- files[ord]
        labels <- labels[ord]
        setNames(files, labels)
      }

      reset_visualization_state <- function() {
        session_has_outputs(FALSE)
        shiny::updateSelectInput(
          session,
          "viz_file",
          choices = character(0),
          selected = character(0)
        )
      }

      shiny::observe({
        task <- current_task()
        if (is.null(task)) {
          return()
        }

        shiny::invalidateLater(1000, session)

        if (task$job$is_alive()) {
          return()
        }

        current_task(NULL)
        set_task_running(FALSE)

        exit_status <- task$job$get_exit_status()
        stderr_text <- paste(task$job$read_all_error_lines(), collapse = "\n")
        stdout_text <- paste(task$job$read_all_output_lines(), collapse = "\n")

        if (!identical(exit_status, 0L)) {
          err_text <- trimws(stderr_text)
          if (!nzchar(err_text)) {
            err_text <- trimws(stdout_text)
          }
          if (!nzchar(err_text)) {
            err_text <- "The background BIOMET process ended unexpectedly."
          }
          status(paste(task$label, "error:", err_text))
          return()
        }

        result_obj <- tryCatch(
          task$job$get_result(),
          error = function(e) e
        )

        if (inherits(result_obj, "error")) {
          status(paste(task$label, "error:", conditionMessage(result_obj)))
          return()
        }

        finish_background_task(task, result_obj)
      })

      shiny::observeEvent(input$stop_task, {
        task <- current_task()
        if (is.null(task)) {
          status("No BIOMET task is currently running.")
          return()
        }

        if (task$job$is_alive()) {
          task$job$kill()
        }

        current_task(NULL)
        set_task_running(FALSE)
        status("Current BIOMET run was stopped by the user. Partial output files may remain in the output folder.")
      })

      session$onSessionEnded(function() {
        task <- current_task()
        if (!is.null(task) && task$job$is_alive()) {
          task$job$kill()
        }
      })

      refresh_visualization_choices <- function(preferred = NULL) {
        choices <- list_raster_choices(input$output_root, input$viz_category)
        selected <- preferred
        if (is.null(selected) || !nzchar(selected) || !(selected %in% unname(choices))) {
          selected <- if (length(choices) > 0) unname(choices)[1] else character(0)
        }
        shiny::updateSelectInput(
          session,
          "viz_file",
          choices = choices,
          selected = selected
        )
      }

      refresh_plot_suffix_choices <- function(preferred = NULL) {
        output_dirs <- build_output_dirs(input$output_root)
        detected <- biomet_detect_available_suffixes(
          dem_dir = input$dem_dir,
          dsm_dir = input$dsm_dir,
          svf_dir = output_dirs$svf_dir,
          lc_dir = output_dirs$lc_dir
        )

        choices <- c(
          "Auto-detect (recommended)" = "__auto__",
          "All detected plots" = "__all__"
        )

        if (length(detected) > 0) {
          detected_choices <- stats::setNames(detected, paste("Plot:", detected))
          choices <- c(choices, detected_choices)
        }

        selected <- preferred
        if (is.null(selected) || !nzchar(selected) || !(selected %in% unname(choices))) {
          selected <- "__auto__"
        }

        shiny::updateSelectInput(
          session,
          "plot_suffix",
          choices = choices,
          selected = selected
        )
      }

      shiny::observeEvent(input$lc_path_browse, {
        safe_browse({
          selected <- choose_file_path(
            "Select Land cover GeoPackage",
            "GeoPackage (*.gpkg)|*.gpkg|All files (*.*)|*.*"
          )
          if (!is.null(selected)) {
            shiny::updateTextInput(session, "lc_path", value = selected)
            status("Selected land-cover GeoPackage.")
          }
        })
      })

      shiny::observeEvent(input$obs_path_browse, {
        safe_browse({
          selected <- choose_file_path(
            "Select Obstacles GeoPackage",
            "GeoPackage (*.gpkg)|*.gpkg|All files (*.*)|*.*"
          )
          if (!is.null(selected)) {
            shiny::updateTextInput(session, "obs_path", value = selected)
            status("Selected obstacles GeoPackage.")
          }
        })
      })

      shiny::observeEvent(input$met_xlsx_browse, {
        safe_browse({
          selected <- choose_file_path(
            "Select Meteorological Excel",
            "Excel files (*.xlsx;*.xls)|*.xlsx;*.xls|All files (*.*)|*.*"
          )
          if (!is.null(selected)) {
            shiny::updateTextInput(session, "met_xlsx", value = selected)
            status("Selected meteorological Excel file.")
          }
        })
      })

      shiny::observeEvent(input$dem_dir_browse, {
        safe_browse({
          selected <- choose_directory_path("Select DEM folder", input$dem_dir)
          if (!is.null(selected)) {
            shiny::updateTextInput(session, "dem_dir", value = selected)
            status("Selected DEM folder.")
          }
        })
      })

      shiny::observeEvent(input$dsm_dir_browse, {
        safe_browse({
          selected <- choose_directory_path("Select DSM folder", input$dsm_dir)
          if (!is.null(selected)) {
            shiny::updateTextInput(session, "dsm_dir", value = selected)
            status("Selected DSM folder.")
          }
        })
      })

      shiny::observeEvent(input$output_root_browse, {
        safe_browse({
          selected <- choose_directory_path("Select parent output folder", input$output_root)
          if (!is.null(selected)) {
            shiny::updateTextInput(session, "output_root", value = selected)
            results(NULL)
            reset_visualization_state()
            status("Selected parent output folder. BIOMET will create a BIOMET_outputs subfolder automatically.")
            refresh_plot_suffix_choices(input$plot_suffix)
          }
        })
      })

      shiny::observeEvent(input$viz_category, {
        refresh_visualization_choices()
      }, ignoreInit = FALSE)

      shiny::observeEvent(input$output_root, {
        results(NULL)
        reset_visualization_state()
        refresh_plot_suffix_choices(input$plot_suffix)
      }, ignoreInit = FALSE)

      shiny::observeEvent(input$dem_dir, {
        refresh_plot_suffix_choices(input$plot_suffix)
      }, ignoreInit = FALSE)

      shiny::observeEvent(input$dsm_dir, {
        refresh_plot_suffix_choices(input$plot_suffix)
      }, ignoreInit = FALSE)

      get_args <- function() {
        output_dirs <- build_output_dirs(input$output_root)
        list(
          lc_path = input$lc_path,
          obs_path = input$obs_path,
          dem_dir = input$dem_dir,
          dsm_dir = input$dsm_dir,
          lc_dir = output_dirs$lc_dir,
          svf_dir = output_dirs$svf_dir,
          out_dir = output_dirs$out_dir,
          parent_output_root = output_dirs$parent,
          output_root = output_dirs$root,
          plot_suffix = input$plot_suffix,
          met_xlsx = input$met_xlsx,
          num_directions = input$num_directions,
          max_distance = input$max_distance,
          observer_height = input$observer_height,
          Met = input$Met,
          Clo = input$Clo,
          ht = input$ht,
          mbody = input$mbody
        )
      }

      shiny::observeEvent(input$check, {
        args <- get_args()
        res <- biomet_check_inputs(
          lc_path = args$lc_path,
          obs_path = args$obs_path,
          dem_dir = args$dem_dir,
          dsm_dir = args$dsm_dir,
          met_xlsx = args$met_xlsx
        )
        detected_plots <- biomet_detect_available_suffixes(
          dem_dir = args$dem_dir,
          dsm_dir = args$dsm_dir,
          svf_dir = args$svf_dir,
          lc_dir = args$lc_dir
        )
        status(
          paste(
            paste(res$messages, collapse = "\n"),
            "",
            paste(
              "Detected plots:",
              if (length(detected_plots) > 0) paste(detected_plots, collapse = ", ") else "none yet"
            ),
            paste("Selected parent output folder:", args$parent_output_root),
            paste("BIOMET project output folder:", args$output_root),
            paste("Rasterized outputs:", args$lc_dir),
            paste("SVF outputs:", args$svf_dir),
            paste("Thermal outputs:", args$out_dir),
            sep = "\n"
          )
        )
        results(as.data.frame(list(ok = res$ok)))
      })

      shiny::observeEvent(input$run_raster, {
        args <- get_args()
        start_background_task(
          task_type = "raster",
          label = "Rasterization",
          success_title = "Rasterization complete",
          success_message = "Rasterized land-cover layers have been written to the output folder.",
          fun_name = "biomet_rasterize_landcover",
          fun_args = list(
            lc_path = args$lc_path,
            obs_path = args$obs_path,
            dem_dir = args$dem_dir,
            out_dir = args$lc_dir
          )
        )
      })

      shiny::observeEvent(input$run_svf, {
        args <- get_args()
        start_background_task(
          task_type = "svf",
          label = "SVF calculation",
          success_title = "SVF calculation complete",
          success_message = "The SVF raster and summary file are ready.",
          fun_name = "biomet_calculate_svf",
          fun_args = list(
            dem_dir = args$dem_dir,
            dsm_dir = args$dsm_dir,
            svf_dir = args$svf_dir,
            num_directions = args$num_directions,
            max_distance = args$max_distance,
            observer_height = args$observer_height
          )
        )
      })

      shiny::observeEvent(input$run_thermal, {
        args <- get_args()
        start_background_task(
          task_type = "thermal",
          label = "Thermal comfort",
          success_title = "Thermal comfort complete",
          success_message = "Thermal rasters and summary outputs are ready.",
          fun_name = "biomet_thermal_comfort",
          fun_args = list(
            dem_dir = args$dem_dir,
            dsm_dir = args$dsm_dir,
            svf_dir = args$svf_dir,
            lc_dir = args$lc_dir,
            out_dir = args$out_dir,
            plot_suffix = args$plot_suffix,
            met_xlsx = args$met_xlsx,
            Met = args$Met,
            Clo = args$Clo,
            ht = args$ht,
            mbody = args$mbody
          )
        )
      })

      shiny::observeEvent(input$run_all, {
        args <- get_args()
        start_background_task(
          task_type = "pipeline",
          label = "Full pipeline",
          success_title = "Full pipeline complete",
          success_message = "All BIOMET outputs have been generated.",
          fun_name = "biomet_run_pipeline",
          fun_args = list(
            lc_path = args$lc_path,
            obs_path = args$obs_path,
            dem_dir = args$dem_dir,
            dsm_dir = args$dsm_dir,
            lc_dir = args$lc_dir,
            svf_dir = args$svf_dir,
            out_dir = args$out_dir,
            plot_suffix = args$plot_suffix,
            met_xlsx = args$met_xlsx,
            num_directions = args$num_directions,
            max_distance = args$max_distance,
            observer_height = args$observer_height,
            Met = args$Met,
            Clo = args$Clo,
            ht = args$ht,
            mbody = args$mbody
          )
        )
      })

      output$status <- shiny::renderText(status())
      output$task_panel_ui <- shiny::renderUI({
        task <- current_task()
        if (is.null(task)) {
          return(NULL)
        }

        shiny::tags$div(
          class = "biomet-task-panel-wrap",
          shiny::tags$div(
            class = "biomet-task-panel",
            shiny::tags$div(
              class = "biomet-task-panel-top",
              shiny::tags$div(
                class = "biomet-task-panel-left",
                shiny::icon("gear", class = "fa-spin"),
                shiny::tags$div(
                  shiny::tags$div(class = "biomet-task-title", paste(task$label, "running")),
                  shiny::tags$div(
                    class = "biomet-task-subtitle",
                    "The GUI remains usable while the background process runs."
                  )
                )
              ),
              shiny::actionButton("stop_task", "Stop current run", class = "btn-danger btn-sm")
            ),
            shiny::tags$div(
              class = "biomet-task-progress",
              shiny::tags$div(class = "biomet-task-progress-bar")
            )
          )
        )
      })
      output$results <- shiny::renderTable(results())
      output$viz_info <- shiny::renderText({
        viz_file <- input$viz_file
        if (is.null(viz_file) || !nzchar(viz_file)) {
          return("No raster available yet for the selected output group.")
        }
        paste("Previewing:", basename(viz_file))
      })
      output$viz_plot <- shiny::renderPlot({
        viz_file <- input$viz_file
        shiny::req(!is.null(viz_file), nzchar(viz_file))
        shiny::req(file.exists(viz_file))
        r <- terra::rast(viz_file)
        nm <- basename(viz_file)

        if (grepl("^UTCI_class_", nm)) {
          terra::plot(r, type = "classes", main = nm)
        } else if (grepl("^landcover_", nm)) {
          terra::plot(r, type = "classes", main = nm)
        } else if (grepl("^svf_", nm)) {
          terra::plot(r, col = hcl.colors(24, "YlGnBu"), main = nm)
        } else if (grepl("^(PET|mPET|PMV|SET|UTCI|Tmrt)_", nm)) {
          terra::plot(r, col = hcl.colors(32, "Inferno"), main = nm)
        } else {
          terra::plot(r, col = hcl.colors(24, "Viridis"), main = nm)
        }
      })
    }
  )

  shiny::runApp(app)
  invisible(app)
}
