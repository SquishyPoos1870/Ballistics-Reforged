local function startup_bool(name, order, default)
  return {
    type = "bool-setting",
    name = name,
    order = order,
    setting_type = "startup",
    default_value = default
  }
end

local function startup_int(name, order, default, minimum, maximum)
  return {
    type = "int-setting",
    name = name,
    order = order,
    setting_type = "startup",
    default_value = default,
    minimum_value = minimum,
    maximum_value = maximum
  }
end

local function startup_double(name, order, default, minimum, maximum)
  return {
    type = "double-setting",
    name = name,
    order = order,
    setting_type = "startup",
    default_value = default,
    minimum_value = minimum,
    maximum_value = maximum
  }
end

local function startup_string(name, order, default, allowed_values)
  return {
    type = "string-setting",
    name = name,
    order = order,
    setting_type = "startup",
    default_value = default,
    allowed_values = allowed_values
  }
end

data:extend({
  startup_string("br-combat-fx-preset", "a0", "balanced", {"subtle", "balanced", "cinematic"}),

  startup_bool("br-physical-bullets", "aa", true),
  startup_bool("br-bullet-glow", "ab", true),
  startup_double("br-bullet-inaccuracy", "ac", 0.07, 0, 1),
  startup_int("br-bullet-range", "ad", 35, 10, 100),
  startup_double("br-bullet-speed", "ae", 1.0, 0.25, 3.0),
  startup_bool("br-gun-autoaim", "af", false),
  startup_int("br-bullet-magazine-size", "ag", 20, 1, 500),
  startup_bool("br-bullet-smoke-trails", "ah", true),
  startup_bool("br-impact-fx", "ai", true),
  startup_bool("br-enemy-hit-fx", "aj", true),
  startup_bool("br-structure-hit-fx", "ak", true),
  startup_bool("br-ground-impact-dust", "al", true),
  startup_bool("br-spitter-impact-fx", "am", true),
  startup_string("br-impact-layering", "an", "balanced", {"clean", "balanced", "full"}),
  startup_int("br-big-fight-fx-cap", "ao", 2, 1, 4),
  startup_bool("br-ammo-identity-tracers", "ap", true),
  startup_string("br-tracer-style", "aq", "enhanced", {"realistic", "enhanced", "arcade"}),
  startup_double("br-tracer-scale", "ar", 1.05, 0.35, 1.25),
  startup_double("br-tracer-glow-strength", "as", 1.00, 0.20, 1.50),
  startup_bool("br-tracer-smoke-realism", "at", true),

  startup_bool("br-shotgun-rework", "ba", true),
  startup_bool("br-shotgun-autoaim", "bb", false),
  startup_bool("br-shotgun-dynamic-spread", "bc", true),
  startup_int("br-shotgun-magazine-size", "bd", 10, 1, 500),
  startup_int("br-shotgun-range", "be", 20, 10, 40),
  startup_double("br-shotgun-fire-rate", "bf", 1.0, 0.5, 2.0),
  startup_bool("br-shotgun-pellet-smoke", "bg", true),

  startup_bool("br-physical-rockets", "ca", true),
  startup_double("br-rocket-speed", "cb", 0.10, 0.01, 2),
  startup_double("br-rocket-wobble", "cc", 0.015, 0, 0.20),
  startup_bool("br-rocket-smoke-trails", "cd", true),
  startup_bool("br-heavy-impact-fx", "ce", true),

  startup_bool("br-arcing-throwables", "da", true),
  startup_bool("br-arcing-cannon-shells", "db", true),
  startup_bool("br-cannon-smoke-trails", "dc", true),
  startup_bool("br-arcing-atomic-bomb", "dd", true),

  startup_bool("br-walls-block-spitters", "ea", true),
  startup_bool("br-turret-leading", "fa", true),
  startup_int("br-turret-ammo-buffer", "fb", 3, 1, 10)
})
