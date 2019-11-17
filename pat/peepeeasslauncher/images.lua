function init()
	localAnimator.clearDrawables()
end

function update()
	if animationConfig.animationParameter("death") ~= nil then
		if animationConfig.animationParameter("pain") == 1 then
			localAnimator.clearDrawables()
		end
		img = animationConfig.animationParameter("death")
		localAnimator.addDrawable({image = img, position = activeItemAnimation.ownerAimPosition(), size = 0.05, fullbright = true}, "overlay")
	end
end
