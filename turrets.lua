local lib = require("prototypes.lib")

if not lib.setting("br-shotgun-rework") then return end

local dynamic_spread = lib.setting("br-shotgun-dynamic-spread")
local autoaim = lib.setting("br-shotgun-autoaim")
local magazine_size = lib.setting("br-shotgun-magazine-size") or 10
local use_smoke = lib.setting("br-shotgun-pellet-smoke")
local shotgun_range = lib.setting("br-shotgun-range") or 20
local fire_rate = lib.setting("br-shotgun-fire-rate") or 1.0
local player_shotgun_category = "br-player-shotgun-shell"

lib.define_once("ammo-category", {type = "ammo-category", name = player_shotgun_category})

local function tune_projectile(projectile_name)
  local projectile = data.raw.projectile and data.raw.projectile[projectile_name]
  if not projectile then return end

  projectile.hit_at_collision_position = true
  projectile.force_condition = "not-same"
  projectile.hit_collision_mask = projectile.hit_collision_mask or lib.collision_mask()

  local fx = lib.impact_effects("shotgun")
  if next(fx) then
    projectile.final_action = projectile.final_action or lib.make_direct_effect_action(fx)
  else
    projectile.final_action = projectile.final_action or {
      type = "direct",
      action_delivery = {
        type = "instant",
        target_effects = {{type = "create-entity", entity_name = "explosion-hit"}}
      }
    }
  end

  if use_smoke then
    lib.append_smoke(projectile, lib.smoke_source("br-shotgun-pellet-smoke", 1, {0.03, 0.03}))
  end

  if projectile.animation and projectile.animation.filename == "__base__/graphics/entity/bullet/bullet.png" then
    projectile.animation.draw_as_glow = true
    projectile.shadow = {
      filename = "__base__/graphics/entity/bullet/bullet.png",
      frame_count = 1,
      width = 3,
      height = 50,
      priority = "high",
      scale = 0
    }
  end
end

local function player_shotgun_projectile(projectile_name)
  local projectile = data.raw.projectile and data.raw.projectile[projectile_name]
  if not projectile then return projectile_name end

  local clone_name = lib.safe_name("br-", projectile_name, "-player-shotgun-projectile")
  if not (data.raw.projectile and data.raw.projectile[clone_name]) then
    local clone = lib.copy(projectile)
    clone.name = clone_name
    clone.force_condition = "all"
    clone.hit_collision_mask = clone.hit_collision_mask or lib.collision_mask()
    lib.define_once("projectile", clone)
  end

  return clone_name
end

local function tune_shotgun_ammo(ammo)
  local ammo_types = lib.ammo_types(ammo)
  local player_variants = {}

  for _, ammo_type in pairs(ammo_types) do
    ammo_type.target_type = autoaim and "entity" or "direction"
    ammo_type.clamp_position = true

    for _, action in pairs(lib.actions(ammo_type)) do
      for _, delivery in pairs(lib.deliveries(action)) do
        if delivery.type == "projectile" and delivery.projectile then
          if dynamic_spread then
            action.type = "area"
            action.target_entities = false
            action.radius = 1.35
            delivery.direction_deviation = 0.008
          else
            delivery.direction_deviation = 0.30
          end
          delivery.starting_speed_deviation = 0.075
          delivery.max_range = shotgun_range
          delivery.min_range = 5
          tune_projectile(delivery.projectile)
        end
      end
    end

    local player_ammo_type = lib.copy(ammo_type)
    player_ammo_type.category = player_shotgun_category
    for _, action in pairs(lib.actions(player_ammo_type)) do
      for _, delivery in pairs(lib.deliveries(action)) do
        if delivery.type == "projectile" and delivery.projectile then
          delivery.projectile = player_shotgun_projectile(delivery.projectile)
        end
      end
    end
    table.insert(player_variants, player_ammo_type)
  end

  for _, player_variant in pairs(player_variants) do
    table.insert(ammo_types, player_variant)
  end
  if next(player_variants) then ammo.ammo_type = ammo_types end

  ammo.magazine_size = magazine_size
  ammo.reload_time = math.max(1, 60 / fire_rate)
end

local function looks_like_shotgun_ammo(ammo)
  if not ammo then return false end
  if ammo.ammo_category == "shotgun-shell" then return true end
  if ammo.name and ammo.name:find("shotgun") then return true end
  for _, ammo_type in pairs(lib.ammo_types(ammo)) do
    if ammo_type.category == "shotgun-shell" then return true end
  end
  return false
end

for _, ammo in pairs(data.raw.ammo or {}) do
  if looks_like_shotgun_ammo(ammo) then
    tune_shotgun_ammo(ammo)
  end
end

local function tune_shotgun_gun(gun)
  local attack = gun and gun.attack_parameters
  if not attack then return end
  if attack.ammo_category ~= "shotgun-shell" and not (gun.name and gun.name:find("shotgun")) then return end

  if attack.ammo_category == "shotgun-shell" then
    attack.ammo_category = player_shotgun_category
  end

  if attack.cooldown then
    attack.cooldown = math.max(1, attack.cooldown * 0.66 / fire_rate)
  end
  attack.min_range = attack.min_range or 2
end

for _, gun in pairs(data.raw.gun or {}) do
  tune_shotgun_gun(gun)
end
