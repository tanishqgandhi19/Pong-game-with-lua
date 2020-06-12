-- push is a library that will allow us to draw our game at a virtual
-- resolution, instead of however large our window is; used to provide
-- a more retro aesthetic
push = require 'push'

Class = require 'class'

require 'Paddle'
require 'Ball'

WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

-- size we're trying to emulate with push
VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243

PADDLE_SPEED = 200

function love.load()
    love.graphics.setDefaultFilter('nearest', 'nearest')

    love.window.setTitle('Pong')

    -- seed the RNG so that calls to random are always random
    math.randomseed(os.time())

    smallFont = love.graphics.newFont('font1.ttf', 8)
    scoreFont = love.graphics.newFont('font1.ttf', 32)
    victoryFont = love.graphics.newFont('font1.ttf', 20)
    love.graphics.setFont(smallFont)

    sounds = {
        ['paddlehit'] = love.audio.newSource('paddlehit.wav', 'static'),
        ['pointscore'] = love.audio.newSource('pointscore.wav', 'static'),
        ['wallhit'] = love.audio.newSource('wallhit.wav', 'static')
    }

    -- initialize our virtual resolution, which will be rendered within our
    -- actual window no matter its dimensions
    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        resizable = true,
        vsync = true
    })

    --player1 is on left side and player 2 is on right side
    
    player1 = Paddle(10, 30, 5, 20)
    player2 = Paddle(VIRTUAL_WIDTH - 10, VIRTUAL_HEIGHT - 30, 5, 20)

    ball = Ball(VIRTUAL_WIDTH / 2 - 2, VIRTUAL_HEIGHT / 2 - 2, 4, 4)
        
    player1Score = 0
    player2Score = 0

    servingPlayer = math.random(2) == 1 and 1 or 2
    winingplayer = 0
   
    --to make the ball move to the position of player who will serve
    if servingPlayer == 2 then
        ball.dx = 100
    else
        ball.dx = -100
    end

    gameState = 'start'
end


--called whenever we change the dimension of windows.
function love.resize(w,h)
    push:resize(w,h)
end


function love.update(dt)
    if gameState == 'play' then

       if ball:collides(player1) then
            ball.dx = -ball.dx * 1.03
            ball.x = player1.x + 5
            sounds['paddlehit']:play()
            
            -- keep velocity going in the same direction, but randomize it
            if ball.dy < 0 then
                ball.dy = -math.random(10, 150)
            else
                ball.dy = math.random(10, 150)
            end
        end
        
        if ball:collides(player2) then
            ball.dx = -ball.dx * 1.03
            ball.x = player2.x - 4
            sounds['paddlehit']:play()
            
            if ball.dy < 0 then
                ball.dy = -math.random(10, 150)
            else
                ball.dy = math.random(10, 150)
            end
        end

        -- if it hits the wall then reverse the direction and play the sound
        if ball.y <= 0 then
            ball.y = 0
            ball.dy = -ball.dy
            sounds['wallhit']:play()
        end

        if ball.y >= VIRTUAL_HEIGHT - 4 then
            ball.y = VIRTUAL_HEIGHT - 4
            ball.dy = -ball.dy
            sounds['wallhit']:play()
        end

        ball:update(dt)
    end

    --if ball crosses boundry on left side player 2 wins
    if ball.x < 0 then
        servingPlayer = 2
        --as the score to be shown of right side, it increments score 2
        player2Score = player2Score + 1
        sounds['pointscore']:play()

        ball:reset()
        ball.dx = 100
        if player2Score >= 3 then
            gameState = 'victory'
            winingplayer = 2
        else
            gameState = 'serve'
        end
    end
    
    --if ball crosses boundry on right side player 1 wins
    if ball.x > VIRTUAL_WIDTH then
        servingPlayer = 1
        player1Score = player1Score + 1
        sounds['pointscore']:play()
        ball:reset()
        ball.dx = -100
        if player1Score >=3 then
            gameState = 'victory'
            winingplayer = 1
        else
            gameState = 'serve'
        end
    end

    -- player 1 movement
    if love.keyboard.isDown('w') then
        player1.dy = -PADDLE_SPEED
    elseif love.keyboard.isDown('s') then
        player1.dy = PADDLE_SPEED
    else
        player1.dy = 0
    end

    -- player 2 movement
    if love.keyboard.isDown('up') then
        player2.dy = -PADDLE_SPEED
    elseif love.keyboard.isDown('down') then
        player2.dy = PADDLE_SPEED
    else
        player2.dy = 0
    end

    player1:update(dt)
    player2:update(dt)
end

function love.keypressed(key)
    
    if key == 'escape' then
        love.event.quit()
    
    elseif key == 'enter' or key == 'return' then
        if gameState == 'start' then
            gameState = 'serve'

        elseif gameState == 'victory' then
            gameState = 'start'
            player1Score = 0
            player2Score = 0
            -- decide serving player as the opposite of who won
            if winningPlayer == 1 then
                servingPlayer = 2
            else
                servingPlayer = 1
            end

        elseif gameState == 'serve' then
            gameState = 'play'
        end
    end
end


function love.draw()
    
    push:apply('start')

    love.graphics.clear(255 / 255, 255 / 255, 0 / 255 , 255 / 255)

    
    if gameState == 'start' then
        love.graphics.setFont(victoryFont)
        love.graphics.setColor(204 / 255, 0, 102 / 255 , 1)
        love.graphics.printf("Welcome to Pong!",  0, 100, VIRTUAL_WIDTH, 'center')
        love.graphics.printf("Press Enter to Play", 0, 140, VIRTUAL_WIDTH, 'center')
    elseif gameState == 'serve' then
        love.graphics.setFont(smallFont)
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.printf("Player ".. tostring(servingPlayer).."'s turn!", 0, 20, VIRTUAL_WIDTH, 'center')
        love.graphics.printf("Press enter to Serve!", 0, 32, VIRTUAL_WIDTH, 'center')
    elseif gameState == 'victory' then
        love.graphics.clear(255 / 255, 255 / 255, 0 / 255 , 255 / 255)
        love.graphics.setFont(victoryFont)
        love.graphics.setColor(204 / 255, 0, 102 / 255 , 1)
        love.graphics.printf("Player ".. tostring(winingplayer).." wins!", 0, 90, VIRTUAL_WIDTH, 'center')
        love.graphics.printf("Press Enter to Serve!", 0, 110, VIRTUAL_WIDTH, 'center')
    elseif gameState == 'play' then
        love.graphics.setColor(0, 0, 0, 1)
    end
    if gameState == 'serve' then
        love.graphics.setFont(scoreFont)
        love.graphics.print(tostring(player1Score), VIRTUAL_WIDTH / 2 - 50, 
            VIRTUAL_HEIGHT / 3)
        love.graphics.print(tostring(player2Score), VIRTUAL_WIDTH / 2 + 30,
            VIRTUAL_HEIGHT / 3)
    end

    -- render paddles, now using their class's render method
    player1:render()
    player2:render()

    -- render ball using its class's render method
    ball:render()

    -- new function just to demonstrate how to see FPS in LÖVE2D
    displayFPS()

    -- end rendering at virtual resolution
    push:apply('end')
end

--[[
    Renders the current FPS.
]]
function displayFPS()
    
    -- simple FPS display across all states
    love.graphics.setFont(smallFont)
    love.graphics.setColor(0, 0, 1, 1)
    love.graphics.print('FPS: ' .. tostring(love.timer.getFPS()), 10, 10)
end