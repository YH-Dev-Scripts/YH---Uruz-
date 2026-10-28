local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "YH HUB",
   LoadingTitle = " Loader",
   LoadingSubtitle = "by YH Dev & Studio",
   ConfigurationSaving = {
      Enabled = false,
      FolderName = "YHHub",
      FileName = "Loader"
   },
   Discord = {
      Enabled = false,
      Invite = "noinvite",
      RememberJoins = true
   },
   KeySystem = false,
})

local Tab = Window:CreateTab("Home", 4483362458)

Tab:CreateParagraph({Title = "Prison Life Script", Content = "Click the button below to launch the protected script."})

Tab:CreateButton({
   Name = "Prison Life",
   Callback = function()
      Rayfield:Notify({Title = "YH Hub", Content = "Starting Prison Life Script...", Duration = 2})
      pcall(function() Window:Destroy() end)
      
      task.spawn(function()
          loadstring(game:HttpGet("https://pastefy.app/5blpeW77/raw"))()
      end)
   end,
})

