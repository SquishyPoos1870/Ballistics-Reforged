local lib = require("prototypes.lib")

if not lib.setting("br-arcing-cannon-shells") then return end

local shell_speed = 0.8
local shell_range = 50
local use_smoke = lib.setting("br-cannon-smoke-trails")

local shell_smoke = use_smoke and {{
  name = "br-cannon-smoke-trail",
  deviation = {0.10, 0.10},
  frequency = lib.fx_smoke_frequency(1),
  position = {0, 0},
  starting_frame = 2,
  starting_frame_deviation = 1
}} or {}

local function expand_shell_action(projectile)
  local actions = {}
  for _, action in pairs(lib.as_list(lib.copy(projectile.action))) do
    if action.type == "direct" then
      action.type = "area"
      action.radius = 1.5
      local ground = lib.copy(action)
      ground.target_entities = false
      if ground.action_delivery and ground.action_delivery.target_effects then
        for _, effect in pairs(lib.as_list(ground.action_delivery.target_effects)) do
          effect.show_in_tooltip = false
        end
      end
      table.insert(actions, action)
      table.insert(actions, ground)
    else
      table.insert(actions, action)
    end
  end

  for _, action in pairs(lib.as_list(lib.copy(projectile.final_action))) do
    table.insert(actions, action)
  end

  local fx_action = lib.make_direct_effect_action(lib.impact_effects("heavy"))
  if fx_action then table.insert(actions, fx_action) end

  return actions
end

local function make_shell_stream(projectile_name, projectile)
  if not projectile then return nil end
  local stream_name = lib.safe_name("br-arc-", projectile_name, "-cannon-stream")
  local shadow = projectile.shadow or lib.copy(projectile.animation)
  if shadow then shadow.draw_as_shadow = true end

  lib.define_once("stream", {
    type = "stream",
    name = stream_name,
    particle = lib.copy((projectile.animation and projectile.animation[1]) or projectile.animation),
    shadow = lib.copy((shadow and shadow[1]) or shadow),
    smoke_sources = shell_smoke,
    particle_buffer_size = 1,
    particle_spawn_interval = 0,
    particle_spawn_timeout = 1,
    particle_vertical_acceleration = 0.981 / 150,
    particle_horizontal_speed = shell_speed,
    particle_horizontal_speed_deviation = shell_speed * 0.05,
    particle_start_alpha = 1,
    particle_end_alpha = 1,
    particle_start_scale = 1,
    particle_loop_frame_count = 1,
    particle_fade_out_threshold = 1,
    particle_loop_exit_threshold = 1,
    oriented_particle = true,
    stream_light = lib.copy(projectile.light),
    action = expand_shell_action(projectile),
    progress_to_create_smoke = 0
  })

  return stream_name
end

local function convert_shell_ammo_type(ammo_type)
  ammo_type.target_type = "direction"
  ammo_type.clamp_position = true

  lib.find_projectile_delivery(ammo_type, function(action, delivery, projectile)
    if not projectile then return end
    local stream_name = make_shell_stream(delivery.projectile, projectile)
    if not stream_name then return end
    delivery.type = "stream"
    delivery.stream = stream_name
    delivery.projectile = nil
    delivery.starting_speed = nil
    delivery.direction_deviation = 0.05
    delivery.range_deviation = 0.05
    delivery.max_range = shell_range
    delivery.min_range = 10
    action.action_delivery = delivery
  end)
end

local function looks_like_cannon_ammo(ammo)
  if not ammo then return false end
  if ammo.ammo_category == "cannon-shell" then return true end
  if ammo.name and ammo.name:find("cannon") then return true end
  for _, ammo_type in pairs(lib.ammo_types(ammo)) do
    if ammo_type.category == "cannon-shell" then return true end
  end
  return false
end

for _, ammo in pairs(data.raw.ammo or {}) do
  if looks_like_cannon_ammo(ammo) then
    for _, ammo_type in pairs(lib.ammo_types(ammo)) do
      convert_shell_ammo_type(ammo_type)
    end
  end
end
