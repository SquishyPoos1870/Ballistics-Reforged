local lib = require("prototypes.lib")

if not lib.setting("br-physical-bullets") then return end

local projectile_speed = lib.setting("br-bullet-speed") or 1.0
local light_scale = lib.fx_light_scale()
local inaccuracy = lib.setting("br-bullet-inaccuracy") or 0.07
local use_glow = lib.setting("br-bullet-glow")
local autoaim = lib.setting("br-gun-autoaim")
local magazine_size = lib.setting("br-bullet-magazine-size") or 20
local bullet_range = lib.setting("br-bullet-range") or 35
local use_smoke = lib.setting("br-bullet-smoke-trails")

local function make_bullet_projectile(name, effects)
  local projectile_name = lib.safe_name("br-", name, "-bullet-projectile")

  effects = lib.append_all(effects or {}, lib.impact_effects("bullet"))

  local projectile = {
    type = "projectile",
    name = projectile_name,
    flags = {"not-on-map"},
    collision_box = {{-0.35, -0.16}, {0.35, 0.16}},
    hit_collision_mask = lib.collision_mask(),
    acceleration = 0,
    direction_only = true,
    hit_at_collision_position = true,
    force_condition = "not-same",
    action = {
      type = "direct",
      action_delivery = {
        type = "instant",
        target_effects = effects
      }
    },
    animation = {
      filename = "__base__/graphics/entity/bullet/bullet.png",
      frame_count = 1,
      width = 3,
      height = 50,
      priority = "high",
      draw_as_glow = use_glow
    },
    shadow = {
      filename = "__base__/graphics/entity/bullet/bullet.png",
      frame_count = 1,
      width = 3,
      height = 50,
      priority = "high",
      scale = 0
    },
    light = use_glow and {
      {
        type = "oriented",
        intensity = 0.70 * light_scale,
        size = 4 * light_scale,
        minimum_darkness = 0,
        color = {r = 1.0, g = 0.92, b = 0.45},
        shift = {0, 2},
        picture = {
          layers = {{
            filename = "__base__/graphics/entity/bullet/bullet.png",
            priority = "high",
            width = 3,
            height = 50,
            shift = {0, -0.25},
            rotate_shift = false,
            add_perspective = false,
            scale = 1
          }}
        }
      },
      {
        type = "oriented",
        intensity = 0.06 * light_scale,
        size = 3 * light_scale,
        minimum_darkness = 0,
        color = {r = 1.0, g = 0.82, b = 0.35},
        picture = {
          layers = {{
            filename = "__core__/graphics/light-small.png",
            priority = "high",
            width = 150,
            height = 150,
            rotate_shift = false,
            add_perspective = false,
            scale = 1
          }}
        }
      }
    } or nil
  }

  if use_smoke then
    projectile.smoke = {lib.smoke_source("br-bullet-tracer-smoke", 1, {0.02, 0.02})}
  end

  lib.define_once("projectile", projectile)

  return {
    type = "direct",
    action_delivery = {
      {
        type = "projectile",
        projectile = projectile_name,
        starting_speed = projectile_speed,
        direction_deviation = inaccuracy,
        range_deviation = inaccuracy * 2,
        max_range = bullet_range
      }
    }
  }
end

local function convert_ammo_type(ammo_type, source_name)
  if not ammo_type then return end
  ammo_type.target_type = autoaim and "entity" or "direction"

  local effects = {}
  for _, action in pairs(lib.actions(ammo_type)) do
    for _, delivery in pairs(lib.deliveries(action)) do
      if delivery.target_effects then
        for _, effect in pairs(lib.as_list(delivery.target_effects)) do
          table.insert(effects, effect)
        end
        delivery.target_effects = nil
      end
    end
  end

  if next(effects) then
    table.insert(ammo_type.action, make_bullet_projectile(source_name, effects))
  end
end

local function ammo_is_bullet(ammo)
  if not ammo then return false end
  if ammo.ammo_category == "bullet" then return true end
  for _, ammo_type in pairs(lib.ammo_types(ammo)) do
    if ammo_type.category == "bullet" then return true end
  end
  return false
end

for _, ammo in pairs(data.raw.ammo or {}) do
  if ammo_is_bullet(ammo) then
    for _, ammo_type in pairs(lib.ammo_types(ammo)) do
      convert_ammo_type(ammo_type, ammo.name)
    end
    ammo.magazine_size = magazine_size
  end
end

-- Rampant Arsenal passive defense uses bullet-style attack parameters instead of an ammo item.
local equipment = data.raw["active-defense-equipment"] and data.raw["active-defense-equipment"]["bullets-passive-defense-rampant-arsenal"]
if equipment and equipment.attack_parameters and equipment.attack_parameters.ammo_type then
  convert_ammo_type(equipment.attack_parameters.ammo_type, equipment.name)
end

-- Defender robots also get physical tracer bullets when their attack is still instant damage.
local defender = data.raw["combat-robot"] and data.raw["combat-robot"].defender
if defender and defender.attack_parameters and defender.attack_parameters.ammo_type then
  convert_ammo_type(defender.attack_parameters.ammo_type, defender.name)
  defender.attack_parameters.lead_target_for_projectile_speed = projectile_speed
  defender.attack_parameters.projectile_center = {0, 0}
end
