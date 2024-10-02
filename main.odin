package main

import rl "vendor:raylib"
import "core:math"
import "core:os"
import "core:encoding/json"
import "core:math/linalg"

//for DEBUG
import "core:fmt"

//Constants
SCREEN_WIDTH :: 1500
SCREEN_HEIGHT :: 1500
FRAME_RATE :: 60

Vec2 :: [2]f32

Level :: enum {
    MainMenu,
    Dungeon,
    GameOver,
}

Status :: enum {
    Active,
    Inactive,
}

Fruit :: struct {
    position: Vec2,
    status: Status,
}

Snake :: struct {
    position: Vec2,
    speed: Vec2,
    direction: Direction,
    tail: [50]Vec2,
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
fruits: [4]Fruit

movement_timer : f32 = 0

main :: proc() {
    rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Multi Snakes!") 
    defer rl.CloseWindow()

    currentLevel = Level.MainMenu

    camera = rl.Camera2D{{ SCREEN_WIDTH/2, SCREEN_HEIGHT/2 }, { SCREEN_WIDTH/2, SCREEN_HEIGHT/2}, 0, 1}
    rl.SetTargetFPS(FRAME_RATE);

    game_loop: for !rl.WindowShouldClose() {
        switch currentLevel {
            case Level.MainMenu: {
                menu_selection: for true {
                    if rl.WindowShouldClose() {break game_loop}
                    if rl.IsKeyPressed(.P) {
                        currentLevel = Level.Dungeon
                        break menu_selection
                    }
                    rl.BeginDrawing()
                    rl.BeginMode2D(camera)
                    defer rl.EndDrawing()
                    rl.ClearBackground(rl.GREEN)   
                    rl.DrawText("PRESS P To start Game!", SCREEN_WIDTH/4, SCREEN_HEIGHT/2, 100, rl.BLACK);                 
                    rl.EndMode2D() 
   
                }
            }
            case Level.Dungeon: {
                init_game()
                runningLevel: for true {
                    if rl.WindowShouldClose() {break game_loop}
                    if rl.IsKeyPressed(.G) {
                        currentLevel = Level.GameOver
                        break runningLevel
                    }
                    game_input()
                    update()
                    draw()
                }
            }
            case Level.GameOver: {
                game_over: for true {
                    if rl.WindowShouldClose() {break game_loop}
                    if rl.IsKeyPressed(.P) {
                        currentLevel = Level.Dungeon
                        break game_over
                    }
                    rl.BeginDrawing()
                    defer rl.EndDrawing() 
                    rl.DrawText("GAME OVEEEER", SCREEN_WIDTH/4, SCREEN_HEIGHT/2, 100, rl.RED);                 

   
                }
            }
        }

    }
}

init_game :: proc() {
    snake = Snake {
        position = { SCREEN_WIDTH/2, SCREEN_HEIGHT/2 },
        speed = 500,
        direction = .O,
        len = 0,
        food = 0,
    }
    fruits = [?]Fruit { {position={200,200}, status = .Active},
                  {position={400,200}, status = .Active},
                  {position={100,100}, status = .Active},
                  {position={500,500}, status = .Active},
                }
}

update :: proc() {

    if snake.food > 0 {
        snake.len += snake.food
        snake.food = 0
    }

    current_direction: Vec2
    switch snake.direction {
        case .O: {
            current_direction = {-1,0}
        }
        case .E: {
            current_direction = {1,0}
        }
        case .N: {
            current_direction = {0,-1}
        }
        case .S: {
            current_direction = {0,1}
        }
    }
    frametime := rl.GetFrameTime() 

    movement_timer += frametime
    
    if movement_timer > 0.004
    {

    movement_timer = 0
    next_pos := snake.position
    snake.position += snake.speed * current_direction * frametime
    for i in 0..=snake.len-1 {
        current_pos := snake.tail[i] 
        snake.tail[i] = next_pos
        next_pos = current_pos     
    }}
    
    for &f in fruits {
        if f.status == .Active {
            if rl.CheckCollisionCircleRec(f.position,25,{snake.position.x,snake.position.y,50,50}) {
                snake.food += 1
                f.status = .Inactive
            }
        }
    }


}

draw :: proc() {
    rl.BeginDrawing()
    rl.BeginMode2D(camera)
    defer rl.EndDrawing()
    rl.ClearBackground(rl.BLACK)   
    //rl.DrawText("GAME ON", SCREEN_WIDTH/4, SCREEN_HEIGHT/2, 100, rl.ORANGE);  
    draw_fruits()
    draw_snake()
    rl.EndMode2D() 
}
clear_game:: proc() {}


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


draw_fruits :: proc() {
    for f in fruits {
        if f.status == .Active {
            rl.DrawCircleV(f.position,25,rl.RED)
        }
    }
}

draw_snake :: proc() {
    for i in 0..=snake.len - 1 {
        rl.DrawRectangleV(snake.tail[i],{50,50}, rl.ORANGE)  
    }
    rl.DrawRectangleV(snake.position,{50,50}, rl.ORANGE)
}