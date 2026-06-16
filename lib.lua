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
local ammo_identity = lib.setting("br-ammo-identity-tracers") ~= false
local tracer_style = lib.setting("br-tracer-style") or "realistic"
local tracer_scale_setting = lib.setting("br-tracer-scale") or 0.70
local tracer_glow_setting = lib.setting("br-tracer-glow-strength") or 0.60
local realistic_smoke = lib.setting("br-tracer-smoke-realism") ~= false
local player_bullet_category = "br-player-bullet"

lib.define_once("ammo-category", {type = "ammo-category", name = player_bullet_category})

local function tracer_style_values()
  if tracer_style == "arcade" then
    return {scale = 1.00, light = 1.08, body_alpha = 1.00, glow = true}
  elseif tracer_style == "realistic" then
    return {scale = 0.76, light = 0.70, body_alpha = 0.94, glow = true}
  else
    return {scale = 0.95, light = 0.96, body_alpha = 1.00, glow = true}
  end
end

local function identity_for_ammo(name)
  local key = string.lower(name or "")
  local style = tracer_style_values()
  local body_scale = math.max(0.45, (style.scale or 0.95) * tracer_scale_setting)
  local light_mult = math.max(0.20, (style.light or 0.96) * tracer_glow_setting)
  local alpha = style.body_alpha or 1.00

  -- Tracer readability pass:
  -- clearer at night, but still controlled enough to avoid the old beam/laser look.
  if key:find("uranium") then
    return {
      tint = {r = 0.58, g = 0.98, b = 0.36, a = alpha},
      primary = {r = 0.34, g = 0.92, b = 0.22},
      secondary = {r = 0.12, g = 0.55, b = 0.12},
      light_intensity = 0.84 * light_mult,
      light_size = 4.7 * light_mult,
      glow_intensity = 0.060 * light_mult,
      glow_size = 2.9 * light_mult,
      body_scale = body_scale,
      draw_as_glow = style.glow
    }
  elseif key:find("piercing") or key:find("armor%-piercing") or key:find("armour%-piercing") then
    return {
      tint = {r = 1.00, g = 0.50, b = 0.20, a = alpha},
      primary = {r = 0.94, g = 0.38, b = 0.12},
      secondary = {r = 0.50, g = 0.18, b = 0.08},
      light_intensity = 0.80 * light_mult,
      light_size = 4.5 * light_mult,
      glow_intensity = 0.056 * light_mult,
      glow_size = 2.8 * light_mult,
      body_scale = body_scale,
      draw_as_glow = style.glow
    }
  else
    return {
      tint = {r = 1.00, g = 0.92, b = 0.24, a = alpha},
      primary = {r = 1.00, g = 0.80, b = 0.12},
      secondary = {r = 0.58, g = 0.32, b = 0.06},
      light_intensity = 0.82 * light_mult,
      light_size = 4.5 * light_mult,
      glow_intensity = 0.058 * light_mult,
      glow_size = 2.8 * light_mult,
      body_scale = body_scale,
      draw_as_glow = style.glow
    }
  end
end

local function make_bullet_projectile(name, effects, allow_same_force)
  local projectile_name = lib.safe_name("br-", name, allow_same_force and "-player-bullet-projectile" or "-bullet-projectile")
  local identity = identity_for_ammo(name)

  effects = lib.append_all(lib.copy(effects) or {}, lib.impact_effects("bullet"))

  local projectile = {
    type = "projectile",
    name = projectile_name,
    flags = {"not-on-map"},
    collision_box = {{-0.35, -0.16}, {0.35, 0.16}},
    hit_collision_mask = lib.collision_mask(),
    acceleration = 0,
    direction_only = true,
    hit_at_collision_position = true,
    -- Enemy-only for turrets/automation; player gun variants use "all" so force-fire can damage same-force buildings like vanilla.
    force_condition = allow_same_force and "all" or "not-same",
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
      draw_as_glow = use_glow and (identity.draw_as_glow or false),
      tint = identity.tint,
      scale = identity.body_scale or 0.86
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
        intensity = (identity.light_intensity or 0.56) * light_scale,
        size = (identity.light_size or 3.6) * light_scale,
        minimum_darkness = 0,
        color = identity.primary,
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
            scale = identity.body_scale or 0.86,
            tint = identity.tint
          }}
        }
      },
      {
        type = "oriented",
        intensity = (identity.glow_intensity or 0.042) * light_scale,
        size = (identity.glow_size or 2.5) * light_scale,
        minimum_darkness = 0,
        color = identity.secondary,
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
    local smoke_name = (tracer_style == "realistic" and realistic_smoke) and "br-realistic-tracer-smoke" or "br-bullet-tracer-smoke"
    local deviation = (tracer_style == "realistic" and realistic_smoke) and {0.01, 0.01} or {0.02, 0.02}
    projectile.smoke = {lib.smoke_source(smoke_name, 1, deviation)}
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

local function convert_ammo_type(ammo_type, source_name, make_player_variant)
  if not ammo_type then return nil end
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

  if not next(effects) then return nil end

  -- Keep the normal bullet category hostile-only so ammo turrets do not chew through the
  -- player's own walls and machines when firing physical projectiles across the base.
  table.insert(ammo_type.action, make_bullet_projectile(source_name, effects, false))

  if make_player_variant then
    -- Player-held bullet weapons use a duplicate ammo category with a same-force-capable
    -- projectile. Normal auto-targeting still selects enemies, but force-fire now works
    -- on your own chests/buildings again.
    local player_ammo_type = lib.copy(ammo_type)
    player_ammo_type.category = player_bullet_category
    local player_actions = lib.actions(player_ammo_type)
    player_actions[#player_actions] = make_bullet_projectile(source_name, effects, true)
    return player_ammo_type
  end

  return nil
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
    local ammo_types = lib.ammo_types(ammo)
    local player_variants = {}
    for _, ammo_type in pairs(ammo_types) do
      local player_variant = convert_ammo_type(ammo_type, ammo.name, true)
      if player_variant then table.insert(player_variants, player_variant) end
    end
    for _, player_variant in pairs(player_variants) do
      table.insert(ammo_types, player_variant)
    end
    if next(player_variants) then ammo.ammo_type = ammo_types end
    ammo.magazine_size = magazine_size
  end
end

-- Give hand-held / vehicle gun prototypes the player category so manual force-fire can hit same-force entities.
-- Ammo turrets keep the normal bullet category and therefore keep their hostile-only safety behaviour.
for _, gun in pairs(data.raw.gun or {}) do
  local attack = gun and gun.attack_parameters
  if attack and attack.ammo_category == "bullet" then
    attack.ammo_category = player_bullet_category
  end
end

-- Rampant Arsenal passive defense uses bullet-style attack parameters instead of an ammo item.
local equipment = data.raw["active-defense-equipment"] and data.raw["active-defense-equipment"]["bullets-passive-defense-rampant-arsenal"]
if equipment and equipment.attack_parameters and equipment.attack_parameters.ammo_type then
  convert_ammo_type(equipment.attack_parameters.ammo_type, equipment.name, false)
end

-- Defender robots also get physical tracer bullets when their attack is still instant damage.
local defender = data.raw["combat-robot"] and data.raw["combat-robot"].defender
if defender and defender.attack_parameters and defender.attack_parameters.ammo_type then
  convert_ammo_type(defender.attack_parameters.ammo_type, defender.name, false)
  defender.attack_parameters.lead_target_for_projectile_speed = projectile_speed
  defender.attack_parameters.projectile_center = {0, 0}
end
