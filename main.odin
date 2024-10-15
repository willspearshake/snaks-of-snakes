package main

import rl "vendor:raylib"
import "core:os"
import "core:math/rand"

//for DEBUG
import "core:fmt"

//Constants

GRID_OFFSET_X :: 100
GRID_OFFSET_Y :: 100

SCREEN_WIDTH :: 1500
SCREEN_HEIGHT :: 1500
FRAME_RATE :: 60

GRID_WIDTH :: SCREEN_WIDTH - GRID_OFFSET_X*2
GRID_HEIGHT :: SCREEN_HEIGHT - GRID_OFFSET_Y*2
CELL_SIZE :: 50

Vec2 :: [2]f32

Level :: enum {
    MainMenu,
    PlainLevel,
    GameOver,
}

Snake :: struct {
    position: Vec2,
    direction: Direction,
    tail: [dynamic]Vec2,
    len: int,
    food: int,
}

Direction :: enum {
    N,
    E,
    S,
    O,
}

currentLevel: Level
camera : rl.Camera2D
snake : Snake
fruit: Vec2
current_movement: Vec2
isGameOver: bool
isPaused: bool
game_speed : f32 = 0.2

movement_timer : f32 = 0


main :: proc() {
    rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Classic Snakes!") 
    defer rl.CloseWindow()

    currentLevel = Level.MainMenu

    camera = rl.Camera2D{{ SCREEN_WIDTH/2, SCREEN_HEIGHT/2 }, { SCREEN_WIDTH/2, SCREEN_HEIGHT/2}, 0, 1}
    rl.SetTargetFPS(FRAME_RATE);

    game_loop: for !rl.WindowShouldClose() {
        switch currentLevel {
            case Level.MainMenu: {
                menu_selection: for true {
                    if rl.WindowShouldClose() {break game_loop}
                    if rl.IsKeyPressed(.S) {
                        currentLevel = Level.PlainLevel
                        init_game()
                        break menu_selection
                    }
                    rl.BeginDrawing()
                    rl.BeginMode2D(camera)
                    defer rl.EndDrawing()
                    rl.ClearBackground(rl.GREEN)   
                    rl.DrawText("PRESS S To START!", (SCREEN_WIDTH - rl.MeasureText("PRESS S To START!", 100))/2, SCREEN_HEIGHT/4, 100, rl.BLACK);                 
                    rl.EndMode2D() 
   
                }
            }
            case Level.PlainLevel: {
                runningLevel: for true {
                    if rl.WindowShouldClose() {break game_loop}
                    
                    if !isPaused{
                        game_input()
                        update()
                        if rl.IsKeyPressed(.G) || isGameOver {
                            currentLevel = Level.GameOver
                            break runningLevel
                        }
                        if rl.IsKeyPressed(.P) && !isGameOver {
                            isPaused = true
                        }
                        draw_playing()
                    }
                    else {
                        if rl.IsKeyPressed(.P) && !isGameOver {
                            isPaused = false
                        }
                        draw_paused()
                    }
                }
            }
            case Level.GameOver: {
                game_over: for true {
                    if rl.WindowShouldClose() {break game_loop}
                    if rl.IsKeyPressed(.R) {
                        currentLevel = Level.PlainLevel
                        isGameOver = false
                        init_game()
                        break game_over
                    }
                    rl.BeginDrawing()
                    defer rl.EndDrawing() 
                    rl.DrawText("GAME OVEEEER", (SCREEN_WIDTH - rl.MeasureText("GAME OVEEEER",100))/2, SCREEN_HEIGHT/4, 100, rl.RED);
                    rl.DrawText("Press R to Restart", (SCREEN_WIDTH - rl.MeasureText("Press R to Restart",50))/2, SCREEN_HEIGHT/4 + 100, 50, rl.RED);                  

   
                }
            }
        }

    }
}

//GAME FUNCTIONS

init_game :: proc() {
    starting_offset : Vec2 = {GRID_OFFSET_X/CELL_SIZE,GRID_OFFSET_Y/CELL_SIZE}
    snake = Snake {
        position = { 3 + starting_offset.x, 1 + starting_offset.y } ,
        direction = .E,
        len = 2,
        food = 0,
        tail = {
            { 2 + starting_offset.x,  1 + starting_offset.y },
            { 1 + starting_offset.x,  1 + starting_offset.y },
        }
    }
    fruit = {
        (GRID_WIDTH + GRID_OFFSET_X)/(2*CELL_SIZE),
        (GRID_HEIGHT + GRID_OFFSET_Y)/(2*CELL_SIZE)
    }
    isPaused = false
}

update :: proc() {

    if snake.food > 0 {
        for n in 1..=snake.food {
            append(&snake.tail,snake.tail[len(snake.tail)-1])
        }

        snake.len += snake.food
        snake.food = 0
    }

    switch snake.direction {
        case .O: {
            current_movement = {-1,0}
        }
        case .E: {
            current_movement = {1,0}
        }
        case .N: {
            current_movement = {0,-1}
        }
        case .S: {
            current_movement = {0,1}
        }
    }

    frametime := rl.GetFrameTime() 

    movement_timer += frametime

    if movement_timer > game_speed {

        movement_timer -= game_speed

        next_pos := snake.position 

        snake.position += current_movement


        for i in 0..=snake.len-1 {
            current_pos := snake.tail[i] 
            snake.tail[i] = next_pos
            next_pos = current_pos
        }
    }

    if rl.CheckCollisionRecs({fruit.x*CELL_SIZE,fruit.y*CELL_SIZE,CELL_SIZE,CELL_SIZE},{snake.position.x*CELL_SIZE,snake.position.y*CELL_SIZE,CELL_SIZE,CELL_SIZE}) {
        snake.food += 1
        if (game_speed > 0.08) {game_speed -= 0.01}
        fruit = spawn_fruit_position()
    }   

    if (snake.position.x*CELL_SIZE < GRID_OFFSET_X  ||
        snake.position.x*CELL_SIZE >= GRID_WIDTH + GRID_OFFSET_X ||
        snake.position.y*CELL_SIZE < GRID_OFFSET_Y || 
        snake.position.y*CELL_SIZE >= GRID_HEIGHT + GRID_OFFSET_Y) {
        isGameOver = true
    }

    for part in snake.tail {
        if (snake.position == part) {
            isGameOver = true
        }
    }
}

game_input :: proc() {
    if rl.IsKeyPressed(.RIGHT) {
        if snake.direction != .O {
            snake.direction = .E
        }
    }
    if rl.IsKeyPressed(.LEFT) {
        if snake.direction != .E {
            snake.direction = .O
        }
    }
    if rl.IsKeyPressed(.UP) {
        if snake.direction != .S {
            snake.direction = .N
        }
    }
    if rl.IsKeyPressed(.DOWN) {
        if snake.direction != .N {
            snake.direction = .S
        }
    }     
}

spawn_fruit_position :: proc() -> Vec2 {
    new_position : = Vec2 {f32(rand.int31_max(GRID_WIDTH/CELL_SIZE)), f32(rand.int31_max(GRID_HEIGHT/CELL_SIZE))} + {GRID_OFFSET_X/CELL_SIZE,GRID_OFFSET_Y/CELL_SIZE}
    return new_position
}


//DRAWS
draw_paused :: proc() {
    rl.BeginDrawing()
    rl.BeginMode2D(camera)
    defer rl.EndDrawing()
    rl.ClearBackground(rl.BLACK)   
    draw_layout()
    draw_fruit()
    draw_snake()
    draw_header()
    rl.DrawText("GAME IS PAUSED", (SCREEN_WIDTH - rl.MeasureText("GAME IS PAUSED",100))/2, SCREEN_HEIGHT/4 + 100, 100, rl.RED); 
    rl.DrawText("Press P to Continue", (SCREEN_WIDTH - rl.MeasureText("Press P to Continue",50))/2, SCREEN_HEIGHT/2, 50, rl.RED);                  
    rl.EndMode2D()
}

draw_playing :: proc() {
    rl.BeginDrawing()
    rl.BeginMode2D(camera)
    defer rl.EndDrawing()
    rl.ClearBackground(rl.BLACK)   
    draw_layout()
    draw_fruit()
    draw_snake()
    draw_header()
    rl.EndMode2D()
}

draw_fruit :: proc() {
    rl.DrawCircleV(fruit*CELL_SIZE+{CELL_SIZE/2,CELL_SIZE/2},25,rl.RED)
    //rl.DrawRectangleLines(i32(fruit.x*CELL_SIZE),i32(fruit.y*CELL_SIZE),CELL_SIZE,CELL_SIZE,rl.GREEN)
}

draw_snake :: proc() {
    for i in 0..=snake.len - 1 {
        rl.DrawRectangleV(snake.tail[i]*CELL_SIZE,{CELL_SIZE,CELL_SIZE}, rl.ORANGE)  
    }
    rl.DrawRectangleV(snake.position*CELL_SIZE,{CELL_SIZE,CELL_SIZE}, rl.ORANGE)
}

draw_layout :: proc() {
    rl.DrawRectangleLines(GRID_OFFSET_X,GRID_OFFSET_Y,GRID_WIDTH, GRID_HEIGHT, rl.RED)
}

draw_header :: proc() {
    rl.DrawText("SNAKE", (SCREEN_WIDTH - rl.MeasureText("SNAKE",50))/2, 25, 50, rl.RED);  
}