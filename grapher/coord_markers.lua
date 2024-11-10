yscale=read_var("yscale")
xscale=read_var("xscale")
xzero=read_var("x")
yzero=read_var("y")

local coords = {}

local function horizontal(x)
    if x == 0 then return end

    local len = 20
    if math.floor(x) ~= x then len = 5 end

    local real_x = (x/xscale + xzero)*256 + 340
    local real_y = yzero * 256 + 256

    table.insert(coords, real_x)
    table.insert(coords, real_y - len)
    table.insert(coords, real_x)
    table.insert(coords, real_y + len)
end

local function vertical(y)
    if y == 0 then return end

    local len = 20
    if math.floor(y) ~= y then len = 5 end

    local real_y = (y/yscale + yzero)*256 + 256
    local real_x = xzero * 256 + 340

    table.insert(coords, real_x - len)
    table.insert(coords, real_y)
    table.insert(coords, real_x + len)
    table.insert(coords, real_y)
end

for i = -20, 20 do
    horizontal(i / 2)
    vertical(i / 2)
end

if #coords == 0 then coords = {0,0} end
output_array(coords, 1)