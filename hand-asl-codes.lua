--rot/tilt, joint1 j2 j3
local S = {0, 0, 0, 0} --straight
local B = {0, 90, 90, 90} --bent
local H = {0, 45, 45, 45} --half-bent
local R = {0, 60, 60, 60} --two-thirds bent
local I = {0, 30, 90, 90} --high-bent
local F = {0, 90, 0, 0} --forwards
local X = {0, 0, 60, 90} --x-like hook
local Y = {-30, 0, 0, 0} --pinky out!

local SIX = {
    index = {20, 0, 0, 0},
    middle = S,
    ring = {-20, 0, 0, 0},
    pinky = {-45, 60, 60, 60},
}
local SEVEN = {
    index = {20, 0, 0, 0},
    middle = S,
    ring = {-20, 60, 60, 60},
    pinky = {-45, 0, 0, 0},
}
local EIGHT = {
    index = {20, 0, 0, 0},
    middle = {0, 60, 60, 60},
    ring = {-20, 0, 0, 0},
    pinky = {-45, 0, 0, 0},
}
local NINE = {
    index = {20, 35, 60, 60},
    middle = S,
    ring = {-20, 0, 0, 0},
    pinky = {-45, 0, 0, 0},
    thumb = {60, -80, 25, 90},
}

local R_index = {-10, 20, 0, 0}
local R_middle = {10, 0, 0, 0}

--thumb
local T = {
    up = {60, 0, 90, 0},
    up2 = {60, -60, 90, 0},
    bent = {0, -60, 90, 90},
    bent2 = {0, -60, 60, 60},
    angle = {60, -90, 0, 90},
    angle2 = {60, -90, 35, 90},
    out = {60, -90, 0, 0},
}

--wrist
local W = {
    left = {60, 0},
    right = {-60, 0},
    fwd_right = {-60, 30},
    fwd_left = {60, 30},
}

local asl_words = {
    --index middle ring pinky thumb wrist
    ['a'] = {B, B, B, B, T.up, S},
    ['b'] = {S, S, S, S, T.bent, S},
    ['c'] = {H, H, H, H, T.angle, W.left},
    ['d'] = {S, R, R, R, T.bent2, S},
    ['e'] = {I, I, I, I, T.bent, S},
    ['f'] = {NINE.index, NINE.middle, NINE.ring, NINE.pinky, NINE.thumb, S},
    ['g'] = {F, B, B, B, T.out, W.left},
    ['h'] = {F, F, B, B, T.bent, W.left},
    ['i'] = {B, B, B, S, T.bent, S},
    ['j'] = {B, B, B, S, T.bent, W.fwd_right},
    ['k'] = {S, F, B, B, T.up2, W.left},
    ['l'] = {S, B, B, B, S, S},
    ['m'] = {R, R, R, B, T.bent, S},
    ['n'] = {R, R, B, B, T.bent, S},
    ['o'] = {R, R, R, R, T.angle2, S},
    ['p'] = {S, F, B, B, T.up2, W.fwd_left},
    ['q'] = {F, B, B, B, T.out, W.fwd_left},
    ['r'] = {R_index, R_middle, B, B, T.bent, S},
    ['s'] = {B, B, B, B, T.bent, S},
    ['t'] = {R, B, B, B, T.bent, S},
    ['u'] = {S, S, B, B, T.bent, S},
    ['v'] = {SIX.index, S, B, B, T.bent, S},
    ['w'] = {SIX.index, SIX.middle, SIX.ring, B, T.bent, S},
    ['x'] = {X, B, B, B, T.bent, S},
    ['y'] = {B, B, B, Y, S, S},
    ['z'] = {X, X, B, B, T.bent, S},
    ['0'] = {R, R, R, R, T.angle2, S},
    ['1'] = {S, B, B, B, T.bent, S},
    ['2'] = {SIX.index, S, B, B, T.bent, S},
    ['3'] = {SIX.index, S, B, B, S, S},
    ['4'] = {SIX.index, SIX.middle, SIX.ring, NINE.pinky, T.bent, S},
    ['5'] = {SIX.index, SIX.middle, SIX.ring, NINE.pinky, S, S},
    ['6'] = {SIX.index, SIX.middle, SIX.ring, SIX.pinky, T.bent2, S},
    ['7'] = {SEVEN.index, SEVEN.middle, SEVEN.ring, SEVEN.pinky, T.bent2, S},
    ['8'] = {EIGHT.index, EIGHT.middle, EIGHT.ring, EIGHT.pinky, T.bent2, S},
    ['9'] = {NINE.index, NINE.middle, NINE.ring, NINE.pinky, NINE.thumb, S},
    ['10'] = {B, B, B, B, S, S},
    ['~'] = {S, S, S, S, S, S}, --reset hand
}

local this_letter = V1:sub(1,1)
local asl = asl_words[this_letter]
if asl then
    for i = 1, #asl do
        ---@diagnostic disable-next-line
        output_array(asl[i], i)
    end
end
