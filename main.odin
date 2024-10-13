package main

import rl "vendor:raylib"
import "core:math"
import "core:os"
import "core:encoding/json"
import "core:math/linalg"
import "core:math/rand"

//for DEBUG
import "core:fmt"

//Constants
SCREEN_WIDTH :: 1500
SCREEN_HEIGHT :: 1500
FRAME_RATE :: 60

GRID_WIDTH :: 900
GRID_HEIGHT :: 900
CELL_SIZE :: 50


GRID_OFFSET_X :: 100
GRID_OFFSET_Y :: 100

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
isGameOver: bool

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
      
                    game_input()
                    update()
                    if rl.IsKeyPressed(.G) || isGameOver {
                        currentLevel = Level.GameOver
                        break runningLevel
                    }
                    draw()
                }
            }
            case Level.GameOver: {
                game_over: for true {
                    if rl.WindowShouldClose() {break game_loop}
                    if rl.IsKeyPressed(.P) {
                        currentLevel = Level.PlainLevel
                        isGameOver = false
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
        {position=({4,5}), status = .Active},
        {position=({6,10}), status = .Active},
        {position=({8,7}), status = .Active},
        {position=({5,5}), status = .Active},
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

    if movement_timer > 0.15 {

        movement_timer -= 0.15

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
            if rl.CheckCollisionRecs({f.position.x*CELL_SIZE,f.position.y*CELL_SIZE,CELL_SIZE,CELL_SIZE},{snake.position.x*CELL_SIZE,snake.position.y*CELL_SIZE,CELL_SIZE,CELL_SIZE}) {
                snake.food += 1
                //f.status = .Inactive
                f.position = spawn_fruit_position()
            }
        }
    }

    if (snake.position.x*CELL_SIZE < GRID_OFFSET_X  || snake.position.x*CELL_SIZE > GRID_WIDTH + GRID_OFFSET_X) ||
       (snake.position.y*CELL_SIZE < GRID_OFFSET_Y || snake.position.y*CELL_SIZE > GRID_HEIGHT + GRID_OFFSET_Y) {
          isGameOver = true
       }

    for part in snake.tail {
        if (snake.position == part) {
            isGameOver = true
        }
    }

    


}

draw :: proc() {
    rl.BeginDrawing()
    rl.BeginMode2D(camera)
    defer rl.EndDrawing()
    rl.ClearBackground(rl.BLACK)   
    draw_layout()
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
            rl.DrawCircleV(f.position*CELL_SIZE+{CELL_SIZE/2,CELL_SIZE/2},25,rl.RED)
            rl.DrawRectangleLines(i32(f.position.x*CELL_SIZE),i32(f.position.y*CELL_SIZE),CELL_SIZE,CELL_SIZE,rl.GREEN)
        }
    }
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

spawn_fruit_position :: proc() -> Vec2 {
    new_position : = Vec2 {f32(rand.int31_max(GRID_WIDTH/CELL_SIZE)), f32(rand.int31_max(GRID_HEIGHT/CELL_SIZE))} + {GRID_OFFSET_X/CELL_SIZE,GRID_OFFSET_Y/CELL_SIZE}
    //fmt.println(new_position)
    return new_position
}