require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/interp.lua"

-- Base gun fire ability
GunFire = WeaponAbility:new()

function GunFire:init()
  self.weapon:setStance(self.stances.idle)

  self.cooldownTimer = self.fireTime
	
	hueshift = 0

  self.weapon.onLeaveAbility = function()
    self.weapon:setStance(self.stances.idle)
  end
end

function GunFire:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)
	
	if self.upgraded then
		animator.setSoundVolume("fire", math.random(1, 3))
	
		self.weapon.armAngularVelocity = -5
		self.weapon.weaponAngularVelocity = 10

		hueshift = hueshift + 12
	else
		hueshift = hueshift + 5
	end
  if hueshift >= 360 then
    hueshift = 0
  end
	
	animator.setGlobalTag("hueshift", "?hueshift="..hueshift)

  if animator.animationState("firing") ~= "fire" then
    animator.setLightActive("muzzleFlash", false)
  end

  if self.fireMode == (self.activatingFireMode or self.abilitySlot)
  and not self.weapon.currentAbility
  and (self.cooldownTimer == 0 or self.shiftHeld) then
		if not self.shiftHeld and self.upgraded then
			activeItem.setScriptedAnimationParameter("death", "/pat/peepeeasslauncher/images/"..math.random(1, 695)..".png")
		else
			activeItem.setScriptedAnimationParameter("death", nil)
		end
		
    if self.fireType == "auto" then
      self:setState(self.auto)
    elseif self.fireType == "burst" then
      self:setState(self.burst)
    end
  else
		activeItem.setScriptedAnimationParameter("death", nil)
	end
end

function GunFire:auto()
  self.weapon:setStance(self.stances.fire)

  self:fireProjectile()
  self:muzzleFlash()

  if self.stances.fire.duration then
    util.wait(self.stances.fire.duration)
  end

  self.cooldownTimer = self.fireTime
  self:setState(self.cooldown)
end

function GunFire:burst()
  self.weapon:setStance(self.stances.fire)

  local shots = self.burstCount
  while shots > 0 and status.overConsumeResource("energy", self:energyPerShot()) do
    self:fireProjectile()
    self:muzzleFlash()
    shots = shots - 1

    self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(1 - shots / self.burstCount, 0, self.stances.fire.weaponRotation))
    self.weapon.relativeArmRotation = util.toRadians(interp.linear(1 - shots / self.burstCount, 0, self.stances.fire.armRotation))

    util.wait(self.burstTime)
  end

  self.cooldownTimer = (self.fireTime - self.burstTime) * self.burstCount
end

function GunFire:cooldown()
  self.weapon:setStance(self.stances.cooldown)
  self.weapon:updateAim()

  local progress = 0
  util.wait(self.stances.cooldown.duration, function()
    local from = self.stances.cooldown.weaponOffset or {0,0}
    local to = self.stances.idle.weaponOffset or {0,0}
    self.weapon.weaponOffset = {interp.linear(progress, from[1], to[1]), interp.linear(progress, from[2], to[2])}

    self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(progress, self.stances.cooldown.weaponRotation, self.stances.idle.weaponRotation))
    self.weapon.relativeArmRotation = util.toRadians(interp.linear(progress, self.stances.cooldown.armRotation, self.stances.idle.armRotation))

    progress = math.min(1.0, progress + (self.dt / self.stances.cooldown.duration))
  end)
end

function GunFire:muzzleFlash()
  animator.setPartTag("muzzleFlash", "variant", math.random(1, self.muzzleFlashVariants or 3))
  animator.setAnimationState("firing", "fire")
  animator.burstParticleEmitter("muzzleFlash")
  animator.playSound("fire")

  animator.setLightActive("muzzleFlash", true)
end

function GunFire:fireProjectile(projectileType, projectileParams, inaccuracy, firePosition, projectileCount)
	if self.upgraded then
		mcontroller.setVelocity(vec2.rotate({math.random(51, 100), 0}, util.toRadians(math.random(1, 360))))
	else
		mcontroller.setVelocity(vec2.rotate({math.random(1, 50), 0}, util.toRadians(math.random(1, 360))))
	end

  local params = sb.jsonMerge(self.projectileParameters, projectileParams or {})
	params.processing = "?hueshift="..hueshift

  local projectileId = 0
  for i = 1, (projectileCount or self.projectileCount) do
    if params.timeToLive then
      params.timeToLive = util.randomInRange(params.timeToLive)
    end
		
		projectile = self.projectileType[math.random(#self.projectileType)]
		if projectile == "beachball" then
			for i = 1, 69 do
				projectileId = world.spawnProjectile(
					projectile,
					firePosition or self:firePosition(),
					activeItem.ownerEntityId(),
					self:aimVector(),
					true,
					params
				)
			end
		else
			projectileId = world.spawnProjectile(
				projectile,
				firePosition or self:firePosition(),
				activeItem.ownerEntityId(),
				self:aimVector(),
				true,
				params
			)
		end
  end
  return projectileId
end

function GunFire:firePosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(self.weapon.muzzleOffset))
end

function GunFire:aimVector(inaccuracy)
  local aimVector = vec2.rotate({1, 0}, util.toRadians(math.random(1, 360)))
  aimVector[1] = aimVector[1] * mcontroller.facingDirection()
  return aimVector
end

function GunFire:energyPerShot()
  return self.energyUsage * self.fireTime * (self.energyUsageMultiplier or 1.0)
end

function GunFire:damagePerShot()
  return (self.baseDamage or (self.baseDps * self.fireTime)) * (self.baseDamageMultiplier or 1.0) * config.getParameter("damageLevelMultiplier") / self.projectileCount
end

function GunFire:uninit()
end
