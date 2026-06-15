local lib = require("prototypes.lib")

local function make_stream_from_projectile(projectile_name, projectile, speed, vertical)
  if not projectile then return nil end
  local stream_name = lib.safe_name("br-arc-", projectile_name, "-stream")

  lib.define_once("stream", {
    type = "stream",
    name = stream_name,
    particle = lib.copy((projectile.animation and projectile.animation[1]) or projectile.animation),
    shadow = lib.copy((projectile.shadow and projectile.shadow[1]) or projectile.shadow),
    smoke_sources = lib.copy(projectile.smoke) or {},
    particle_buffer_size = 1,
    particle_spawn_interval = 0,
    particle_spawn_timeout = 1,
    particle_vertical_acceleration = vertical,
    particle_horizontal_speed = speed,
    particle_horizontal_speed_deviation = speed * 0.10,
    particle_start_alpha = 1,
    particle_end_alpha = 1,
    particle_start_scale = 1,
    particle_loop_frame_count = 1,
    particle_fade_out_threshold = 1,
    particle_loop_exit_threshold = 1,
    action = lib.append_all(lib.as_list(lib.copy(projectile.action)), lib.make_direct_effect_action(lib.impact_effects("heavy")) and {lib.make_direct_effect_action(lib.impact_effects("heavy"))} or {}),
    oriented_particle = true,
    stream_light = lib.copy(projectile.light),
    progress_to_create_smoke = 0
  })

  return stream_name
end

local function convert_projectile_delivery(action, delivery, vertical)
  local projectile = data.raw.projectile and data.raw.projectile[delivery.projectile]
  if not projectile then return end

  local speed = delivery.starting_speed or 0.3
  if projectile.max_speed then speed = math.min(speed, projectile.max_speed) end
  speed = math.max(0.1, speed)

  local stream_name = make_stream_from_projectile(delivery.projectile, projectile, speed, vertical)
  if not stream_name then return end

  action.action_delivery = {
    type = "stream",
    stream = stream_name,
    source_offset = {0, -(projectile.height or 1)}
  }
end

if lib.setting("br-arcing-throwables") then
  for _, capsule in pairs(data.raw.capsule or {}) do
    local attack = capsule.capsule_action and capsule.capsule_action.attack_parameters
    if attack and attack.ammo_type then
      lib.find_projectile_delivery(attack.ammo_type, function(action, delivery)
        convert_projectile_delivery(action, delivery, 0.981 / 60)
      end)
    end
  end
end

if lib.setting("br-arcing-atomic-bomb") then
  local bomb = data.raw.ammo and data.raw.ammo["atomic-bomb"]
  if bomb then
    for _, ammo_type in pairs(lib.ammo_types(bomb)) do
      ammo_type.range_modifier = ammo_type.range_modifier or 3
      lib.find_projectile_delivery(ammo_type, function(action, delivery, projectile)
        if projectile then
          delivery.starting_speed = 0.5
          convert_projectile_delivery(action, delivery, 0.981 / 150)
        end
      end)
    end
  end
end
