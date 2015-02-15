name = "Server status"
description = "Writes info about players and server to external file for further processing"
author = "Dzindra"
version = "0.1"
api_version = 10
forumthread = "404"

all_clients_require_mod = false
dst_compatible = true

icon_atlas = "modicon.xml"
icon = "modicon.tex"

configuration_options =
{
  {
    name = "refreshRate",
    label = "File refresh rate",
    options =	{
      {description = "5 seconds", data = 5},
      {description = "15 seconds", data = 15},
      {description = "30 seconds", data = 30},
      {description = "1 minute", data = 60},
      {description = "2 minutes", data = 120},
      {description = "3 minutes", data = 180},
      {description = "4 minutes", data = 240},
      {description = "5 minutes", data = 300},
    },
    default = 60,
  },
  {
    name = "refreshAfterPlayerChange",
    label = "Refresh after players change",
    options =	{
      {description = "Yes", data = "true"},
      {description = "No", data = "false"},
    },
    default = "true",
  },
}