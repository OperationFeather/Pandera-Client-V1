local Link = 'https://raw.githubusercontent.com/OperationFeather/Pandera-Client-V1/main/Games/%s.lua'
local True,False = pcall(function()
    loadstring(game:HttpGet(Link:format(tostring(game.PlaceId)), true))
end) 
if True then 
    loadstring(game:HttpGet(Link:format(tostring(game.PlaceId)), true))()
    
else 
    warn('FEATHER ERROR: .. GAME UNSUPPORTED ..')
end 
