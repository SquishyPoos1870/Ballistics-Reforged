local lib = {}

function lib.setting(name)
  local item = settings.startup[name]
  return item and item.value
end

function lib.as_list(value)
  if not value then return {} end
  if value[1] then return value end
  return {value}
end

function lib.copy(value)
  if not value then return nil end
  return util.copy(value)
end

function lib.safe_name(prefix, name, suffix)
  local safe = tostring(name or "prototype"):gsub("[^%w_%-]", "-")
  return prefix .. safe .. (suffix or "")
end

function lib.ammo_types(ammo)
  if not ammo or not ammo.ammo_type then return {} end
  return lib.as_list(ammo.ammo_type)
end

function lib.actions(ammo_type)
  if not ammo_type or not ammo_type.action then return {} end
  local actions = lib.as_list(ammo_type.action)
  ammo_type.action = actions
  return actions
end

function lib.deliveries(action)
  if not action or not action.action_delivery then return {} end
  local deliveries = lib.as_list(action.action_delivery)
  action.action_delivery = deliveries
  return deliveries
end

function lib.prototype_exists(kind, name)
  return name and data.raw[kind] and data.raw[kind][name]
end

function lib.already_defined(kind, name)
  return name and data.raw[kind] and data.raw[kind][name]
end

function lib.define_once(kind, prototype)
  if not prototype or not prototype.name then return end
  if lib.already_defined(kind, prototype.name) then return end
  data:extend({prototype})
end

function lib.find_projectile_delivery(ammo_type, callback)
  for _, action in pairs(lib.actions(ammo_type)) do
    for _, delivery in pairs(lib.deliveries(action)) do
      if delivery and delivery.type == "projectile" and delivery.projectile then
        callback(action, delivery, data.raw.projectile and data.raw.projectile[delivery.projectile])
      end
    end
  end
end

function lib.find_instant_deliveries(ammo_type, callback)
  for _, action in pairs(lib.actions(ammo_type)) do
    for _, delivery in pairs(lib.deliveries(action)) do
      if delivery and delivery.type == "instant" then
        callback(action, delivery)
      end
    end
  end
end

function lib.collision_mask()
  return {
    layers = {
      object = true,
      player = true
    },
    not_colliding_with_itself = false
  }
end

function lib.append(list, value)
  if not value then return list end
  list = list or {}
  table.insert(list, value)
  return list
end

function lib.append_all(list, values)
  list = list or {}
  for _, value in pairs(values or {}) do
    table.insert(list, value)
  end
  return list
end

function lib.fx_preset()
  local value = lib.setting("br-combat-fx-preset") or "balanced"
  if value ~= "subtle" and value ~= "cinematic" then return "balanced" end
  return value
end

function lib.fx_scale()
  local preset = lib.fx_preset()
  if preset == "subtle" then return 0.65 end
  if preset == "cinematic" then return 1.35 end
  return 1.0
end

function lib.fx_light_scale()
  local preset = lib.fx_preset()
  if preset == "subtle" then return 0.75 end
  if preset == "cinematic" then return 1.20 end
  return 1.0
end

function lib.fx_smoke_frequency(base)
  local preset = lib.fx_preset()
  if preset == "subtle" then return math.max(1, math.floor((base or 1) * 0.75)) end
  if preset == "cinematic" then return math.max(1, math.floor((base or 1) * 1.25)) end
  return base or 1
end

function lib.smoke_source(name, frequency, deviation)
  return {
    name = name,
    deviation = deviation or {0, 0},
    frequency = lib.fx_smoke_frequency(frequency or 1),
    position = {0, 0},
    starting_frame = 1,
    starting_frame_deviation = 2
  }
end

function lib.append_smoke(prototype, source)
  if not prototype or not source then return end
  prototype.smoke = prototype.smoke or {}
  table.insert(prototype.smoke, source)
end

function lib.first_existing_entity(names)
  for _, name in pairs(names or {}) do
    for _, group in pairs(data.raw or {}) do
      if group[name] then return name end
    end
  end
  return nil
end

function lib.impact_layering()
  local value = lib.setting("br-impact-layering") or "balanced"
  if value ~= "clean" and value ~= "full" then return "balanced" end
  return value
end

function lib.big_fight_fx_cap()
  local value = tonumber(lib.setting("br-big-fight-fx-cap")) or 2
  if value < 1 then return 1 end
  if value > 4 then return 4 end
  return value
end

function lib.should_add_layer(style, layer, current_extra_count)
  local preset = lib.fx_preset()
  local layering = lib.impact_layering()
  local cap = lib.big_fight_fx_cap()

  -- Heavy ordnance keeps its punch; bullets/shotguns get capped hardest.
  if style == "heavy" or style == "spit" then
    if layering == "clean" and layer == "enemy" then return false end
    return true
  end

  if layering == "clean" then
    if layer == "enemy" or layer == "structure" then return false end
  elseif layering == "balanced" then
    if style == "bullet" and layer == "structure" then return false end
  end

  if preset == "subtle" and layer ~= "ground" then return false end
  if preset == "cinematic" and layering == "full" then return true end

  return current_extra_count < cap
end

function lib.impact_effects(style)
  if not lib.setting("br-impact-fx") then return {} end
  if style == "heavy" and lib.setting("br-heavy-impact-fx") == false then return {} end
  if style == "spit" and lib.setting("br-spitter-impact-fx") == false then return {} end

  local effects = {}
  local extra_count = 0

  local function smoke(name)
    table.insert(effects, {type = "create-trivial-smoke", smoke_name = name})
  end

  local function optional_smoke(setting_name, layer, smoke_name)
    if lib.setting(setting_name) == false then return end
    if not lib.should_add_layer(style, layer, extra_count) then return end
    smoke(smoke_name)
    extra_count = extra_count + 1
  end

  local function entity(names)
    local found = lib.first_existing_entity(names)
    if found then table.insert(effects, {type = "create-entity", entity_name = found}) end
  end

  if style == "bullet" then
    smoke("br-bullet-impact-smoke")
    optional_smoke("br-ground-impact-dust", "ground", "br-ground-impact-dust")
    optional_smoke("br-structure-hit-fx", "structure", "br-structure-impact-smoke")
    optional_smoke("br-enemy-hit-fx", "enemy", "br-bug-hit-mist")
    entity({"explosion-gunshot", "explosion-hit"})
  elseif style == "shotgun" then
    smoke("br-shotgun-impact-smoke")
    optional_smoke("br-ground-impact-dust", "ground", "br-ground-impact-dust")
    optional_smoke("br-structure-hit-fx", "structure", "br-structure-impact-smoke")
    optional_smoke("br-enemy-hit-fx", "enemy", "br-bug-hit-mist")
    entity({"explosion-gunshot-small", "explosion-gunshot", "explosion-hit"})
  elseif style == "heavy" then
    smoke("br-heavy-impact-smoke")
    optional_smoke("br-ground-impact-dust", "ground", "br-ground-impact-dust")
    optional_smoke("br-structure-hit-fx", "structure", "br-structure-impact-smoke")
    optional_smoke("br-enemy-hit-fx", "enemy", "br-bug-hit-mist")
    entity({"medium-explosion", "explosion", "explosion-hit"})
  elseif style == "spit" then
    smoke("br-acid-impact-smoke")
    optional_smoke("br-ground-impact-dust", "ground", "br-ground-impact-dust")
    entity({"acid-splash-fire-spitter-behemoth", "acid-splash-fire-spitter-big", "acid-splash-fire-spitter-medium", "acid-splash-fire-spitter-small", "explosion-hit"})
  end

  return effects
end

function lib.make_direct_effect_action(effects)
  if not next(effects or {}) then return nil end
  return {
    type = "direct",
    action_delivery = {
      type = "instant",
      target_effects = effects
    }
  }
end

local function action_has_smoke(action, smoke_name)
  for _, delivery in pairs(lib.as_list(action and action.action_delivery)) do
    for _, effect in pairs(lib.as_list(delivery and delivery.target_effects)) do
      if effect.type == "create-trivial-smoke" and effect.smoke_name == smoke_name then
        return true
      end
    end
  end
  return false
end

function lib.final_action_has_smoke(prototype, smoke_name)
  if not prototype or not prototype.final_action or not smoke_name then return false end
  for _, action in pairs(lib.as_list(prototype.final_action)) do
    if action_has_smoke(action, smoke_name) then return true end
  end
  return false
end

function lib.add_final_effects(prototype, effects, smoke_marker)
  if not prototype or not next(effects or {}) then return end
  if smoke_marker and lib.final_action_has_smoke(prototype, smoke_marker) then return end

  local fx_action = lib.make_direct_effect_action(effects)
  if not fx_action then return end

  local actions = lib.as_list(prototype.final_action)
  table.insert(actions, fx_action)
  prototype.final_action = actions
end

return lib
