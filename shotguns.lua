local lib = require("prototypes.lib")

local fx_scale = lib.fx_scale()

local function smoke(name, scale, duration, fade, animation_speed)
  lib.define_once("trivial-smoke", {
    type = "trivial-smoke",
    name = name,
    animation = {
      filename = "__base__/graphics/entity/smoke-fast/smoke-fast.png",
      priority = "high",
      width = 50,
      height = 50,
      frame_count = 16,
      animation_speed = animation_speed or 16 / 60,
      scale = scale * fx_scale
    },
    duration = math.floor(duration * fx_scale),
    fade_away_duration = math.floor(fade * fx_scale),
    show_when_smoke_off = true
  })
end

-- Small custom FX used by generated projectile actions. Presets scale them up/down without changing balance.
-- 0.6.0 trims the small-impact smoke slightly so big turret fights stay readable.
smoke("br-bullet-tracer-smoke", 0.13, 14, 9, 22 / 60)
smoke("br-bullet-impact-smoke", 0.18, 22, 14, 20 / 60)
smoke("br-shotgun-pellet-smoke", 0.17, 18, 11, 22 / 60)
smoke("br-shotgun-impact-smoke", 0.23, 26, 16, 20 / 60)
smoke("br-rocket-wake-smoke", 0.46, 48, 30, 13 / 60)
smoke("br-heavy-impact-smoke", 0.66, 68, 40, 11 / 60)
smoke("br-cannon-smoke-trail", 0.44, 52, 26, 17 / 60)

smoke("br-structure-impact-smoke", 0.26, 26, 16, 18 / 60)
smoke("br-ground-impact-dust", 0.30, 30, 18, 16 / 60)
smoke("br-bug-hit-mist", 0.19, 22, 13, 20 / 60)
smoke("br-acid-impact-smoke", 0.30, 36, 20, 18 / 60)

