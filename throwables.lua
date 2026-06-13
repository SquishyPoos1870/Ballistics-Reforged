local lib = require("prototypes.lib")

if not lib.setting("br-physical-rockets") then return end

local rocket_speed = lib.setting("br-rocket-speed") or 0.10
local rocket_wobble = lib.setting("br-rocket-wobble") or 0.015
local rocket_smoke = lib.setting("br-rocket-smoke-trails")

local function tune_rocket_projectile(projectile)
  if not projectile then return end
  projectile.direction_only = false
  projectile.acceleration = math.max(0.002, rocket_speed / 10)
  projectile.collision_box = projectile.collision_box or {{-0.05, -0.25}, {0.05, 0.25}}
  projectile.hit_collision_mask = projectile.hit_collision_mask or lib.collision_mask()
  projectile.hit_at_collision_position = true
  projectile.force_condition = projectile.force_condition or "enemy"
  projectile.shadow = projectile.shadow or {
    filename = "__base__/graphics/entity/rocket/rocket.png",
    frame_count = 1,
    width = 9,
    height = 35,
    priority = "high",
    draw_as_shadow = true
  }

  if rocket_smoke then
    lib.append_smoke(projectile, lib.smoke_source("br-rocket-wake-smoke", 1, {0.08, 0.08}))
  end

  lib.add_final_effects(projectile, lib.impact_effects("heavy"), "br-heavy-impact-smoke")
end

local function tune_rocket_ammo_type(ammo_type)
  ammo_type.target_type = "position"
  ammo_type.clamp_position = true

  lib.find_projectile_delivery(ammo_type, function(_, delivery, projectile)
    delivery.starting_speed = rocket_speed
    delivery.direction_deviation = rocket_wobble
    delivery.range_deviation = rocket_wobble
    tune_rocket_projectile(projectile)
  end)
end

local function looks_like_rocket_ammo(ammo)
  if not ammo then return false end
  if ammo.ammo_category == "rocket" then return true end
  if ammo.name and ammo.name:find("rocket") then return true end
  for _, ammo_type in pairs(lib.ammo_types(ammo)) do
    if ammo_type.category == "rocket" then return true end
  end
  return false
end

for _, ammo in pairs(data.raw.ammo or {}) do
  if looks_like_rocket_ammo(ammo) and ammo.name ~= "atomic-bomb" then
    for _, ammo_type in pairs(lib.ammo_types(ammo)) do
      tune_rocket_ammo_type(ammo_type)
    end
  end
end
