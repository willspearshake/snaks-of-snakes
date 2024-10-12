package main

import rl "vendor:raylib"
import "core:math"
import "core:os"
import "core:encoding/json"
import "core:math/linalg"

//for DEBUG
import "core:fmt"

//Constants
SCREEN_WIDTH :: 800
SCREEN_HEIGHT :: 800
FRAME_RATE :: 60

GRID_WIDTH :: 400
GRID_HEIGHT :: 400

Vec2 :: [2]f32

Level :: enum {
    MainMenu,
    PlainLevel,
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

SnakeBlock :: struct {
    position: Vec2,
}

Snake :: struct {
    position: Vec2,
    speed: Vec2,
    direction: Direction,
    tail: [dynamic]Vec2,
    len: int,
    food: int,
    speed_direction: Vec2,
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
current_movement: Vec2

movement_timer : f32 = 0

Vec2i : [2]int

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
                        currentLevel = Level.PlainLevel
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
            case Level.PlainLevel: {
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
                        currentLevel = Level.PlainLevel
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
        position = { 10, 10 },
        speed = 1,
        direction = .O,
        len = 2,
        food = 0,
        tail = {
            { 11, 10 },
            { 12, 10 }
        }
    }
    fruits = [?]Fruit { 
        {position={200,200}, status = .Active},
        {position={400,200}, status = .Active},
        {position={100,100}, status = .Active},
        {position={500,500}, status = .Active},
    }
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

    if movement_timer > 0.13 {

        movement_timer -= 0.13

        next_pos := snake.position 

        snake.position += current_movement


        for i in 0..=snake.len-1 {
            current_pos := snake.tail[i] 
            snake.tail[i] = next_pos
            next_pos = current_pos
        }
    }

    for &f in fruits {
        if f.status == .Active {
            if rl.CheckCollisionCircleRec(f.position+{25,25},50,{snake.position.x*50,snake.position.y*50,50,50}) {
                fmt.println("qui")
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
    draw_fruits()
    draw_snake()
    rl.EndMode2D() 
    //fmt.println(snake.len)
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
        rl.DrawRectangleV(snake.tail[i]*50,{50,50}, rl.ORANGE)  
    }
    rl.DrawRectangleV(snake.position*50,{50,50}, rl.ORANGE)
}