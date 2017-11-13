function love.conf(t)
    t.title = "DamasPPD"        -- The title of the window the game is in (string)
    t.author = "Ari"        -- The author of the game (string)
    t.window.width = 800        -- The window width (number)
    t.window.height = 600       -- The window height (number)
    t.modules.keyboard = true   -- Enable the keyboard module (boolean)
    t.modules.image = true      -- Enable the image module (boolean)
    t.modules.graphics = true   -- Enable the graphics module (boolean)
    t.modules.mouse = true      -- Enable the mouse module (boolean)
    t.modules.physics = false    -- Enable the physics module (boolean)
    t.console = true
end