-- Plugins are provisioned by scripts/Install-YaziPlugins.ps1
require("git"):setup({ order = 1500 })
require("full-border"):setup({ type = ui.Border.ROUNDED })
