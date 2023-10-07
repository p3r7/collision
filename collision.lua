-- collision.
-- @eigen


-- -------------------------------------------------------------------------
-- consts

if seamstress then
  FPS = 60
elseif norns then
  FPS = 15
end

BANG_INTERVAL_S = 0.7

function screen_size()
  if seamstress then
    return screen.get_size()
  elseif norns then
    return 128, 64
  end
end


-- -------------------------------------------------------------------------
-- colors

COL_PARTICLE = {255, 165, 0}
COL_BARS = {253, 238, 0}
COL_MUON = {255, 0, 0}
COL_BORDER = {147, 112, 219}


-- -------------------------------------------------------------------------
-- state

screen_dirty = true

frame_count = 1

muons = {}
particles = {}
hadrons = {}

function pct_time_bang()
  local elapsed_s = frame_count * (1/FPS)
  return (elapsed_s % BANG_INTERVAL_S) / BANG_INTERVAL_S
end

function bang()
  local nb_muons = math.random(1, 4)
  local nb_particles = math.random(10, 25)

  hadrons = {}

  muons = {}
  for m=1,nb_muons do
    local angle = math.random(100) / 100
    table.insert(muons, angle)

    table.insert(hadrons, {angle, math.random(100) / 100})
  end

  particles = {}
  for m=1,nb_particles do
    local angle = math.random(100) / 100
    local angle2 = math.random(10) / 100
    local dir = (math.random(2) - 1.5) * 2
    table.insert(particles, {angle, angle2, dir})

    table.insert(hadrons, {angle, math.random(100) / 100})
  end
end

-- -------------------------------------------------------------------------
-- core

function cos(x)
  return math.cos(math.rad(x * 360))
end

function sin(x)
  return -math.sin(math.rad(x * 360))
end

-- base1 modulo
function mod1(v, m)
  return ((v - 1) % m) + 1
end

function color_scale(min_col, max_col, cursor)
  local r = min_col[1] + (max_col[1] - min_col[1]) * cursor
  local g = min_col[2] + (max_col[2] - min_col[2]) * cursor
  local b = min_col[3] + (max_col[3] - min_col[3]) * cursor
  return {r, g, b}
end


-- -------------------------------------------------------------------------
-- init

local clock_redraw
local clock_bang

function init()
  if norns then
    screen.aa(1)
  end

  clock_redraw = clock.run(function()
      while true do
        clock.sleep(1/FPS)
        -- if screen_dirty or pct_time_bang() < 0.5 then
        if true then
          redraw()
        end
        frame_count = frame_count + 1
      end
  end)

  clock_bang = clock.run(function()
      while true do
        clock.sleep(BANG_INTERVAL_S)
        bang()
        frame_count = 1
        screen_dirty = true
      end
  end)
end


-- -------------------------------------------------------------------------
-- screen

function redraw()
  local screen_w, screen_h = screen_size()

  screen.clear()

  local center_x, center_y = screen_w/2, screen_h/2
  local outer_r = (screen_h/2) * 3/4
  local inner_r = outer_r/2
  local bar_max = (screen_h/2) - outer_r

  local pct_bang = pct_time_bang()

  screen.move(center_x, center_y)

  screen.color(table.unpack(color_scale(COL_MUON, {0, 0, 0}, pct_bang)))
  for _, angle in pairs(muons) do
    local bx = center_x + (screen_w/2) * cos(angle) * -1
    local by = center_y + (screen_w/2) * sin(angle)
    screen.line(bx, by)
  end

  screen.color(table.unpack(color_scale(COL_PARTICLE, {0, 0, 0}, pct_bang)))
  for _, p in pairs(particles) do
    local angle, angle2, dir = table.unpack(p)
    local bx = center_x + outer_r * cos(angle) * -1
    local by = center_y + outer_r * sin(angle)

    local midx = center_x + outer_r/2 * cos(angle + angle2 * dir) * -1
    local midy = center_y + outer_r/2 * sin(angle + angle2 * dir)

    screen.curve(midx, midy, midx, midy, bx, by)
  end

  screen.color(table.unpack(color_scale(COL_BARS, {0, 0, 0}, pct_bang)))
  local offset = 0.01
  for _, h in pairs(hadrons) do
    local angle, amp = table.unpack(h)
    local ax = center_x + (outer_r + 2) * cos(angle - offset) * -1
    local ay = center_y + (outer_r + 2) * sin(angle - offset)

    local bx = center_x + (outer_r + 2) * cos(angle + offset) * -1
    local by = center_y + (outer_r + 2) * sin(angle + offset)

    local cx = center_x + (outer_r + amp * bar_max) * cos(angle - offset) * -1
    local cy = center_y + (outer_r + amp * bar_max) * sin(angle - offset)

    local dx = center_x + (outer_r + amp * bar_max) * cos(angle + offset) * -1
    local dy = center_y + (outer_r + amp * bar_max) * sin(angle + offset)

    -- screen.quad(bx, by, ax, ay, cx, cy, dx, dy)

    screen.move(bx, by)
    screen.line(ax, ay)
    screen.move(ax, ay)
    screen.line(cx, cy)
    screen.move(cx, cy)
    screen.line(dx, dy)
    screen.move(dx, dy)
    screen.line(bx, by)
  end

  screen.move(center_x, center_y)
  screen.color(table.unpack(COL_BORDER))
  screen.circle(outer_r)
  screen.circle(inner_r)

  if seamstress then
    screen.refresh()
  elseif norns then
    screen.update()
  end

  screen_dirty = false
end
