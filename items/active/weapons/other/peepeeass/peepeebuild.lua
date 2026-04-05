require "/items/buildscripts/buildunrandweapon.lua"
local _build = build

function build(directory, config, parameters, level, seed)
  if _build then
    config, parameters = _build(directory, config, parameters, level, seed)
  end

  local upgradeParameters = config.upgradeParameters
  config.upgradeParameters = { upgraded = true }

  if parameters.upgraded then
    config = sb.jsonMerge(config, upgradeParameters)
    if upgradeParameters.level then parameters.level = upgradeParameters.level end
  end

  return config, parameters
end
