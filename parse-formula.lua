--This parses a graphing formula into a valid Math Node expression.
--E.g. "2x+pi" -> "2*#v1#+3.14159"

---@diagnostic disable-next-line
if not V1 then
    V1 = '+-sqrt(1-x^2)'
    output = function(text, _) print(text) end
end

---@diagnostic disable-next-line
local FORMULA = V1:lower()

local PLUS_MINUS = false

local variables = {
    x = 'x',
    t = 't',
    pi = 3.1415926536,
    e  = 2.7182818284,
}

local functions = {
    sin = true,
    cos = true,
    tan = true,
    sqrt = true,
    asin = true,
    acos = true,
    atan = true,
    log = function(func, param)
        local base = 10
        if func.base then base = func.base end
        return '(math.log('..param.output()..')/math.log('..base..'))'
    end,
    ln = function(func, param) return 'math.log('..param.output()..')' end,
    floor = true,
    ceil = true,
    round = true,
    abs = true,
    sinc = function(func, param) return 'sinc('..param.output()..')' end
}

local TOK = {
    value = 0,
    func = 1,
    mult = 2,
    add = 3,
    sub = 4,
    div = 5,
    mod = 6,
    pow = 7,
    lparen = 8,
    rparen = 9,
    bar = 10,
    neg = 12,
}

local patterns = {
    --Be generally forgiving with numbers
    {'%d+%.%d*', function(text) return {id = TOK.value, value = tonumber(text..'0')} end},
    {'%.%d+', function(text) return {id = TOK.value, value = tonumber('0'..text)} end},
    {'%d+', function(text) return {id = TOK.value, value = tonumber(text)} end},

    --Log of an arbitrary base
    {'log%d+', function(text)
        return {id = TOK.func, value = 'log', base = text:sub(4, #text)}
    end},

    --Identifiers can be functions or variables.
    {'[a-zA-Z]+', function(text)
        if type(variables[text]) == 'number' then
            return {id = TOK.value, value = variables[text]}
        end

        if functions[text] then return {id = TOK.func, value = text} end
        if variables[text] then return {id = TOK.value, value = variables[text]} end

        print('Invalid symbol "'..text..'".')
        return nil
    end},

    --Special +- operator, that means to show two graphs
    {'%+%-', function(text) return {id = TOK.plusminus, value = text, negative = false} end},
    {'%-%+', function(text) return {id = TOK.plusminus, value = text, negative = true} end},

    --Operators
    {'[%*/]', function(text) return {id = TOK.mult, value = text} end},
    {'/', function(text) return {id = TOK.div, value = text} end},
    {'%%', function(text) return {id = TOK.mod, value = text} end},
    {'%+', function(text) return {id = TOK.add, value = text} end},
    {'%-', function(text) return {id = TOK.sub, value = text} end},
    {'%^', function(text) return {id = TOK.pow, value = text} end},
    {'%(', function(text) return {id = TOK.lparen, value = text} end},
    {'%)', function(text) return {id = TOK.rparen, value = text} end},
    {'%|', function(text) return {id = TOK.bar, value = text} end},
}

--This is ordered by precedence from first to last.
--First the capture group is defined, then the function to call when it's captured. Third is optional, and means "do NOT capture if the previous token was one of these".
local syntax = {
    --Plus/minus operator
    {{TOK.plusminus, TOK.value}, function(op, value)
        PLUS_MINUS = true

        op.children = {value}
        op.output = function()
            op.negative = not op.negative
            local result = value.output()
            if not op.negative then result = '(-'..result..')' end
            return result
        end
        return {id = TOK.value, children = {op}}
    end, {TOK.value, TOK.rparen}},

    --Negation
    {{TOK.sub, TOK.value}, function(op, value)
        op.id = TOK.neg
        op.children = {value}
        op.output = function() return '(-'..value.output()..')' end
        return {id = TOK.value, children = {op}}
    end, {TOK.value, TOK.rparen}},
    --Parentheses
    {{TOK.lparen, TOK.value, TOK.rparen}, function(_, value, _) return {id = TOK.value, children = {value}} end},
    --Function calls
    {{TOK.func, TOK.value}, function(func, param)
        func.children = {param}
        if functions[func.value] == true then
            func.output = function() return 'math.'..func.value..'('..param.output()..')' end
        else
            func.output = function() return functions[func.value](func, param) end
        end
        return {id = TOK.value, children = {func}}
    end},
    --Multiplication of the form "2x" or "sin2pi" etc.
    {{TOK.value, TOK.value}, function(lhs, rhs)
        return {id = TOK.value, children = {{
            id = TOK.mult, children = {lhs, rhs},
            output = function()
                return '('..lhs.output()..'*'..rhs.output()..')'
            end,
        }}}
    end},
    --Exponentiation
    {{TOK.value, TOK.pow, TOK.value}, function(lhs, op, rhs)
        --Do we need this?? Or is "A^B" valid syntax?
        return {id = TOK.value, children = {{
            id = TOK.func, value = 'math.pow', children = {lhs, rhs},
            output = function() return 'math.pow('..lhs.output()..','..rhs.output()..')' end
        }}}
    end},
    --Multiplication
    {{TOK.value, {TOK.mult, TOK.div, TOK.mod}, TOK.value}, function(lhs, op, rhs)
        op.children = {lhs, rhs}
        op.output = function() return '('..lhs.output()..op.value..rhs.output()..')' end
        return {id = TOK.value, children = {op}}
    end},
    --Addition
    {{TOK.value, {TOK.add, TOK.sub}, TOK.value}, function(lhs, op, rhs)
        op.children = {lhs, rhs}
        op.output = function() return '('..lhs.output()..op.value..rhs.output()..')' end
        return {id = TOK.value, children = {op}}
    end},

    --Plus/minus addition (A+-B or A-+B)
    {{TOK.value, TOK.plusminus, TOK.value}, function(lhs, op, rhs)
        PLUS_MINUS = true

        op.children = {lhs, rhs}
        op.output = function()
            op.negative = not op.negative
            local oper = '+'
            if not op.negative then oper = '-' end
            return '('..lhs.output()..oper..rhs.output()..')'
        end
        return {id = TOK.value, children = {op}}
    end},

    --Absolute value
    {{TOK.bar, TOK.value, TOK.bar}, function(op, value, _)
        op.children = {value}
        op.output = function() return 'math.abs('..value.output()..')' end
        return {id = TOK.value, children = {op}}
    end},
}

--Split text into tokens
local function tokenize(text)
    local tokens = {}
    while #text > 0 do
        local found_match = false
        for i = 1, #patterns do
            local m = text:match('^'..patterns[i][1])
            if m then
                found_match = true
                text = text:sub(#m+1, #text)
                local token = patterns[i][2](m)
                if not token then return nil end

                if token.value then
                    token.output = function() return tostring(token.value) end
                else
                    token.output = function() return '' end
                end
                table.insert(tokens, token)
                break
            end
        end

        if not found_match then
            local m = text:match(' +')
            if not m then
                print('Invalid Character "'..text[1]..'"')
                return nil
            end

            text = text:sub(#m+1, #text)
        end
    end

    return tokens
end
local token_list = tokenize(FORMULA)
if not token_list then error() end

--DEBUG FUNCTION
local function print_ast(ast, indent)
    if not indent then indent = 0 end

    local msg = (' '):rep(indent)
    for name, id in pairs(TOK) do
        if ast.id == id then
            msg = msg..name
            break
        end
    end

    if ast.value then msg = msg..': '..ast.value end
    if not ast.output then msg = msg ..'!!!' end
    print(msg)

    if ast.children then
        for i = 1, #ast.children do
            print_ast(ast.children[i], indent + 2)
        end
    end
end

--Single syntax check
local function syntax_match(tokens, index, group)
    local rules, func, not_after = group[1], group[2], group[3]

    --Make sure that the "not after" nodes don't exist before this token
    if not_after and index > 1 then
        for i = 1, #not_after do
            if tokens[index - 1].id == not_after[i] then return end
        end
    end

    --Check that we have a perfect match for this group
    for i = 1, #rules do
        local ix = index + i - 1
        if ix > #tokens then return end

        local found_match = false
        if type(rules[i]) == 'table' then
            for k = 1, #rules[i] do
                if rules[i][k] == tokens[ix].id then
                    found_match = true
                    break
                end
            end
        else
            found_match = tokens[ix].id == rules[i]
        end
        if not found_match then return end
    end

    --If we have a perfect match, reduce it.
    local mytok = {}
    for i = 1, #rules do
        local t = tokens[index + i - 1]
        if t.id == TOK.value and t.children then t = t.children[1] end
        table.insert(mytok, t)
    end

    ---@diagnostic disable-next-line
    local u = unpack
    if not u then u = table.unpack(u) end
    return func(u(mytok)), #rules
end

--Parse tokens into a syntax tree
local function parse(tokens)
    while #tokens > 1 do
        local reduced = false
        for i = 1, #syntax do
            local nodes = {}
            local k = 1
            while k <= #tokens do
                local node, len = syntax_match(tokens, k, syntax[i])
                if node then
                    table.insert(nodes, node)
                    k = k + len
                    reduced = true
                else
                    table.insert(nodes, tokens[k])
                    k = k + 1
                end
            end
            tokens = nodes
        end

        if not reduced then
            print('Syntax Error')
            return nil
        end
    end

    local t = tokens[1]
    if t and t.id == TOK.value and t.children then t = t.children[1] end
    return t
end
local tree = parse(token_list)
if not tree then error() end

local lua_code = [[
t=V1
yscale=read_var("yscale")
xscale=read_var("xscale")
xzero=read_var("x")
yzero=read_var("y")

function sinc(x)
    if x == 0 then return 1 end
    return math.sin(x) / x
end

first_i = nil

precision = 2
i_max = math.ceil(680/precision)*precision+precision

coords={}
for i=-precision, i_max, precision do
    x=((i-340)/256 - xzero)*xscale
    y=]]..tree.output()..[[

    if y == y then --if number is undefined, skip it.
        y=(y/yscale + yzero)*256 + 256
        table.insert(coords, i)
        table.insert(coords, y)
        if not first_i then first_i = i end
    end
end

]]

if PLUS_MINUS then
lua_code = lua_code..[[
last_i, last_y = nil, nil
for i=i_max, -precision, -precision do
    x=((i-340)/256 - xzero)*xscale
    y=]]..tree.output()..[[

    if y == y then --if number is undefined, skip it.
        last_y = y
        last_i = i
        y=(y/yscale + yzero)*256 + 256
        table.insert(coords, i)
        table.insert(coords, y)
    end
end

--Try to attach last y value to first y value
if first_i and last_i and first_i == last_i then
    i=first_i
    x=((i-340)/256 - xzero)*xscale
    y=]]..tree.output()..[[

    --if math.abs(y - last_y) < 10 then
        y=(y/yscale + yzero)*256 + 256
        table.insert(coords, i)
        table.insert(coords, y)
    --end
end
]]
end

lua_code = lua_code..[[
if #coords == 0 then
    output_array({0,0}, 1)
else
    output_array(coords, 1)
end
]]
output(lua_code, 1)
