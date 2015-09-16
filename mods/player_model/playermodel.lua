--[[
Copyright (c) 2015, Robert 'Bobby' Zenz
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--]]


--- PlayerModel is a system that adds a player model complete with animations.
playermodel = {
	--- The animation for when the player is digging.
	animation_digging = settings.get_pos2d("playermodel_animation_digging", { x = 189, y = 199 }),
	
	--- The animation for when the player is laying on the ground.
	animation_laying = settings.get_pos2d("playermodel_animation_laying", { x = 162, y = 167 }),
	
	--- The animation for when the player is sitting.
	animation_sitting = settings.get_pos2d("playermodel_animation_sitting", { x = 81, y = 161 }),
	
	--- The animation for when the player is standing still.
	animation_standing = settings.get_pos2d("playermodel_animation_standing", { x = 0, y = 80 }),
	
	--- The animation for when the player is walking.
	animation_walking = settings.get_pos2d("playermodel_animation_walking", { x = 168, y = 188 }),
	
	--- The animation for when the player is walking and digging.
	animation_walking_digging = settings.get_pos2d("playermodel_animation_walking_digging", { x = 200, y = 220 }),
	
	--- The frame speed of the animations, will be halved for sneaking.
	frame_speed = settings.get_number("playermodel_frame_speed", 30),
	
	--- The name of the model that will be used.
	model = settings.get_string("playermodel_model_name", "character.x"),
	
	--- A cache so that animations are not needlessly set.
	player_information = {},
	
	--- The texture of the model that is used.
	texture = { settings.get_string("playermodel_model_texture", "character.png") },
	
	--- The size of the model.
	size = settings.get_pos2d("playermodel_model_size", { x = 1, y = 1 })
}


--- Activates the system, if it is not disabled by the configuration.
function playermodel.activate()
	if settings.get_bool("playermodel_activate", true) then
		minetest.register_globalstep(playermodel.perform_animation_updates)
		minetest.register_on_joinplayer(playermodel.activate_model_on_player)
	end
end

--- Activates the model on the given player.
--
-- @param player The Player object on which to activate the model.
function playermodel.activate_model_on_player(player)
	player:set_properties({
		mesh = playermodel.model,
		textures = playermodel.texture,
		visual = "mesh",
		visual_size = playermodel.size,
	})
	
	playermodel.player_information[player:get_player_name()] = {
		current_animation = nil,
		current_frame_speed = nil
	}
end

--- Determines the animation and frame speed for the current state of
-- the given player.
--
-- @param player The Player Object.
-- @return The animation and the frame speed.
function playermodel.determine_animation(player)
	local controls = player:get_player_control()
	
	local animation = nil
	
	if player:get_hp() == 0 then
		animation = playermodel.animation_laying
	elseif controls.up or controls.down or controls.left or controls.right then
		if controls.LMB then
			animation = playermodel.animation_walking_digging
		else
			animation = playermodel.animation_walking
		end
	elseif controls.LMB then
		animation = playermodel.animation_digging
	else
		animation = playermodel.animation_standing
	end
	
	local frame_speed = playermodel.frame_speed
	
	if controls.sneak then
		frame_speed = frame_speed / 2
	end
	
	return animation, frame_speed
end

--- Performs animation updates on all players.
function playermodel.perform_animation_updates()
	for index, player in ipairs(minetest.get_connected_players()) do
		playermodel.update_player_animation(player)
	end
end

--- Sets the player information on the given player, but only if it has changed.
--
-- @param player The Player object on which to set the animation.
-- @param animation The animation.
-- @param frame_speed The frame speed.
function playermodel.set_player_animation(player, animation, frame_speed)
	local info = playermodel.player_information[player:get_player_name()]
	
	if info.animation ~= animation or info.frame_speed ~= frame_speed then
		player:set_animation(
			animation,
			frame_speed,
			0,
			true)
		
		info.animation = animation
		info.frame_speed = frame_speed
	end
end

--- Updates the animation of the given player.
--
-- @param player The Player object which to update.
function playermodel.update_player_animation(player)
	local animation, frame_speed = playermodel.determine_animation(player)
	
	playermodel.set_player_animation(player, animation, frame_speed)
end
