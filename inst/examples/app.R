library(shiny)
library(shinyjs)
library(tablerDash)
library(shinyWidgets)
library(shinyEffects)
library(pushbar)
library(shinyMons)
library(waiter)

# source("pokeNames.R")

# main data
pokeMain <- readRDS("pokeMain")[1:5]
pokeNames <- names(pokeMain)
pokeDetails <- readRDS("pokeDetails")[1:5]

# subdata from main
pokeLocations <- readRDS("pokeLocations")[1:5]
pokeMoves <- readRDS("pokeMoves")[1:5]
pokeTypes <- readRDS("pokeTypes")[1:5]
pokeEvolutions <- readRDS("pokeEvolutions")[1:5]
pokeAttacks <- readRDS("pokeAttacks")
pokeEdges <- readRDS("pokeEdges")
pokeGroups <- readRDS("pokeGroups")[1:5]

# pokemon sprites
pokeSprites <- vapply(
  seq_along(pokeNames),
  FUN = function(i) {
    pokeMain[[i]]$sprites$front_default
  },
  FUN.VALUE = character(1)
)

# shiny app code
shiny::shinyApp(
  ui = tablerDashPage(
    enable_preloader = TRUE,
    loading_duration = 4,
    navbar = tablerDashNav(
      id = "mymenu",
      src = "https://www.ssbwiki.com/images/9/9c/Master_Ball_Origin.png",
      navMenu = tablerNavMenu(
        tablerNavMenuItem(
          tabName = "PokeInfo",
          icon = "home",
          "PokeInfo"
        ),
        tablerNavMenuItem(
          tabName = "PokeList",
          icon = "box",
          "PokeList"
        ),
        tablerNavMenuItem(
          tabName = "PokeAttacks",
          icon = "box",
          "PokeAttacks"
        ),
        tablerNavMenuItem(
          tabName = "PokeNetwork",
          icon = "box",
          "PokeNetwork"
        ),
        tablerNavMenuItem(
          tabName = "PokeFight",
          icon = "box",
          "PokeFight"
        ),
        tablerNavMenuItem(
          tabName = "PokeOther",
          icon = "box",
          "PokeOther"
        )
      ),

      pokeInputUi(id = "input"),

      tablerDropdown(
        tablerDropdownItem(
          title = NULL,
          href = "https://pokeapi.co",
          url = "https://pokeapi.co/static/logo-6221638601ef7fa7c835eae08ef67a16.png",
          status = "success",
          date = NULL,
          "This app use pokeApi by Paul Hallet and PokéAPI contributors."
        )
      )
    ),
    footer = tablerDashFooter(
      copyrights = "Disclaimer: this app is purely intended for learning purpose. @David Granjon, 2019"
    ),
    title = "Gotta Catch'Em (Almost) All",
    body = tablerDashBody(

      # load pushbar dependencies
      pushbar_deps(),
      # laad the waiter dependencies
      use_waiter(),
      # load shinyjs
      useShinyjs(),

      # custom jquery to hide some inputs based on the selected tag
      # actually tablerDash would need a custom input/output binding
      # to solve this issue once for all
      tags$head(
        tags$script(
          "$(function () {
            $('#mymenu .nav-item a').click(function(){
              var tab = $(this).attr('id');
              if (tab == 'tab-PokeInfo' || tab == 'tab-PokeList') {
                $('#input-pokeChoice').show();
              } else {
                $('#input-pokeChoice').hide();
              }
            });
           });"
        ),

        # test whether mobile or not
        tags$script(
          "$(document).on('shiny:connected', function(event) {
            var isMobile = /iPhone|iPad|iPod|Android/i.test(navigator.userAgent);
            Shiny.onInputChange('isMobile', isMobile);
          });
          "
        )
      ),

      # custom shinyWidgets skins
      chooseSliderSkin("Round"),

      # use shinyEffects
      setShadow(class = "galleryCard"),
      setZoom(class = "galleryCard"),

      tablerTabItems(
        tablerTabItem(
          tabName = "PokeInfo",
          fluidRow(
            column(
              width = 4,
              pokeInfosUi(id = "infos"),
              pokeTypeUi(id = "types"),
              pokeEvolveUi(id = "evol")
            ),
            column(
              width = 8,
              pokeStatsUi(id = "stats"),
              pokeMoveUi(id = "moves"),
              pokeLocationUi(id = "location")
            )
          )
        ),
        tablerTabItem(
          tabName = "PokeList",
          pokeGalleryUi(id = "gallery")
        ),
        tablerTabItem(
          tabName = "PokeAttacks",
          pokeAttackUi(id = "attacks")
        ),
        tablerTabItem(
          tabName = "PokeNetwork",
          pokeNetworkUi(id = "network")
        ),
        tablerTabItem(
          tabName = "PokeFight",
          pokeFightUi(id = "fights")
        ),
        tablerTabItem(
          tabName = "PokeOther",
          pokeOtherUi(id = "other")
        )
      )
    )
  ),
  server = function(input, output, session) {

    # determine whether we are on mobile or not
    # relies on a simple Shiny.onInputChange
    isMobile <- reactive(input$isMobile)


    # Network module: network stores xa potential selected node in the
    # network and pass it to the pickerInput function in the main
    # module to update its value
    network <- callModule(
      module = pokeNetwork,
      id = "network",
      mainData = pokeMain,
      details = pokeDetails,
      families = pokeEdges,
      groups = pokeGroups,
      mobile = isMobile
    )

    # main module (data)
    main <- callModule(
      module = pokeInput,
      id = "input",
      mainData = pokeMain,
      sprites = pokeSprites,
      details = pokeDetails,
      selected = network$selected
    )

    # infos module
    callModule(
      module = pokeInfos,
      id = "infos",
      mainData = pokeMain,
      details = pokeDetails,
      selected = main$pokeSelect,
      shiny = main$pokeShiny
    )

    # stats module
    callModule(module = pokeStats, id = "stats", mainData = pokeMain, details = pokeDetails, selected = main$pokeSelect)
    # types modules
    callModule(module = pokeType, id = "types", types = pokeTypes, selected = main$pokeSelect)
    # moves module
    callModule(module = pokeMove, id = "moves", selected = main$pokeSelect, moves = pokeMoves)

    # evolutions module
    # callModule(
    #   module = pokeEvolve,
    #   id = "evol",
    #   mainData = pokeMain,
    #   details = pokeDetails,
    #   selected = main$pokeSelect,
    #   shiny = main$pokeShiny,
    #   evolutions = pokeEvolutions
    # )

    # fights module
    # callModule(
    #   module = pokeFight,
    #   id = "fights",
    #   mainData = pokeMain,
    #   sprites = pokeSprites,
    #   attacks = pokeAttacks,
    #   types = pokeTypes
    # )

    # # location
    # callModule(module = pokeLocation, id = "location", selected = main$pokeSelect, locations = pokeLocations)
    # gallery module
    # callModule(module = pokeGallery, id = "gallery", mainData = pokeMain, details = pokeDetails, shiny = main$pokeShiny)
    # # pokemon attacks
    # callModule(module = pokeAttack, id = "attacks", attacks = pokeAttacks)
    # # other elements
    # callModule(module = pokeOther, id = "other", mainData = pokeMain, details = pokeDetails)

  }
)
