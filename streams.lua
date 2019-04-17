-- Streams
-- Granular Sine Streams

engine.name = "SimpleSineGrainCloud"

-- dependencies
local StreamPool = include("lib/stream_pool")
local sp = {}

local Arcify = include("arcify/lib/arcify")
local my_arc = arc.connect()
local arcify = Arcify.new(my_arc, false)

local Billboard = include("billboard/lib/billboard")
local billboard = Billboard.new()

-- script vars
local clock = {}
local spawn_clock = {}
local spawn_counter = 1
local spawn_rate = 10
local diffusion_rate = 0
local gravity = 0

local function update()
    local w = params:get("wind")
    sp:apply_force(-w, 0)

    sp:apply_force(0, gravity)

    sp:apply_diffusion(diffusion_rate)
    sp:update()

    redraw()
end

local function spawn()
    spawn_counter = spawn_counter + 1
    if spawn_counter > spawn_rate then
        local d = math.random(10, 100)
        sp:spawn_only_dur(d)
        spawn_counter = 0
    end
end

function init()
    sp = StreamPool.new()

    clock = metro.init(update, 1 / 20, -1)
    clock:start()

    spawn_clock = metro.init(spawn, 0.1, -1)
    spawn_clock:start()

    params:add {
        type = "control",
        id = "wind",
        name = "wind amount",
        controlspec = controlspec.new(0, 5, "lin", 0.05, 0.05),
        action = function(value)
            local iv = 5 - value
            local scaled = util.linlin(0, 5, 1, 15, iv)
            spawn_rate = scaled
            arcify:redraw()
            billboard:display_param("wind", -1 * value)
        end
    }

    params:add {
        type = "control",
        id = "diffusion",
        name = "diffusion rate",
        controlspec = controlspec.new(0, 1, "lin", diffusion_rate, 0.01),
        action = function(value)
            diffusion_rate = value
            billboard:display_param("diffusion rate", value)
        end
    }

    params:add {
        type = "control",
        id = "gravity",
        name = "gravity amount",
        controlspec = controlspec.new(-0.15, 0.15, "lin", 0, 0.01),
        action = function(value)
            gravity = value
            billboard:display_param("gravity", util.round(gravity, 0.01))
        end
    }

    arcify:register("wind", 0.05)
    arcify:register("diffusion", 0.01)
    arcify:register("gravity", 0.01)
    arcify:add_params()

    -- TODO enable this one params are semi-stable
    params:default()
end

function redraw()
    screen.clear()

    sp:draw()
    billboard:draw()

    screen.update()
end
