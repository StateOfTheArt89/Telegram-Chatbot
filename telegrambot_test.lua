-- Unit testing starts
require("telegrambot")
local LuaUnit = require('luaunit')

TestTelegramBot = {} --class

    function TestTelegramBot:testMagic8BallAction()
        assertEquals( Magic8BallAction.isActionTriggered("bla bla"), false)
        assertEquals( Magic8BallAction.isActionTriggered("magic 8ball"), true )
        assertEquals( Magic8BallAction.isActionTriggered("Magic 8Ball"), true )
    end

    function TestTelegramBot:testGoogleImageAction()
        assertEquals( GoogleImageAction.isActionTriggered("bla bla"), false)
        assertEquals( GoogleImageAction.isActionTriggered("gi blabla"), true )
        assertEquals( GoogleImageAction.isActionTriggered("gi bla bla bla"), true )

        assertEquals( GoogleImageAction.url_encode("bla bla"), "bla+bla")
        -- test if any image was found
        assertEquals( string.len(GoogleImageAction.find_image("blabla")) > 1, true )
    end

LuaUnit:run()
