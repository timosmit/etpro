-- idiots.lua by x0rnn, custom troll measures against etadmin level -2 and -3 (idiot) players
-- level -2 players get automuted on connect (they cannot callvote mute/unmute/kick or get callvote unmuted by others, they cannot use /m, /pm either)
-- level -3 players get handicaps such as weapons taken from them, their skill stays 0, their kills don't count, they end with 69 deaths, health halved, ammo halved, they emit a beacon sound to the enemy team, they can't selfkill, they get randomly gibbed or teleported into their death on respawn, they don't have spawn protection, etc. (can be set unique for each player by guid)
-- also added a !teleport id X Y Z command for level 6+ players to teleport players to input coordinates (/viewpos to see your location)
-- modify etadmin_mod/bin/shrub_management.pl line 161 to:
-- if ( !defined($level) || $level < -1000 || !$guid || ( !$name && $level != 0 ) || length($guid) != 32 )

filename = "shrubbot.cfg"
unmute_tries = {}
goons = {}
idiots = {}
idiots2 = {}
idiots_id = {}
beacon = {} -- true by default; beacon[clientNum] = false to disable
random_gib = {} -- same
flag = false
soundindex = ""
mapname = ""
ps_origin = {}

function et_InitGame(levelTime, randomSeed, restart)
	et.RegisterModname("idiots.lua "..et.FindSelf())

	soundindex = et.G_SoundIndex("sound/misc/cry.wav")
	mapname = et.trap_Cvar_Get("mapname")

	local fd, len = et.trap_FS_FOpenFile(filename, et.FS_READ)
	if len > -1 then
		local content = et.trap_FS_Read(fd, len)
		for guid, level in string.gfind(content, "[Gg]uid%s*=%s*(%x+)%s*\n[Ll]evel\t%= %-(%d)") do
			if tonumber(level) == 2 then
				goons[guid] = true
			elseif tonumber(level) == 3 then
				idiots[guid] = true
			end
		end
		content = nil
	end
	et.trap_FS_FCloseFile(fd)
end

function et_ClientBegin(clientNum)
	name = et.Info_ValueForKey(et.trap_GetUserinfo(clientNum), "name")
	cl_guid = et.Info_ValueForKey(et.trap_GetUserinfo(clientNum), "cl_guid")
	if goons[cl_guid] == true then
		et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^1automuted for being a Goon.\"\n")
		et.gentity_set(clientNum, "sess.muted", 1)
	end
	if idiots[cl_guid] == true then
		idiots2[cl_guid] = true
		table.insert(idiots_id, clientNum)
		beacon[clientNum] = true
		random_gib[clientNum] = true
		flag = true
	end
end

function et_ClientDisconnect(clientNum)
	cl_guid = et.Info_ValueForKey(et.trap_GetUserinfo(clientNum), "cl_guid")
	if idiots2[cl_guid] == true then
		idiots2[cl_guid] = nil
		beacon[clientNum] = nil
		if random_gib[clientNum] ~= nil then
			random_gib[clientNum] = nil
		end
		table.remove(idiots_id, clientNum)
		if next(idiots2) == nil then
			flag = false
		end
	end
end

function et_ClientSpawn(clientNum, revived)
	if flag == true then
		cl_guid = et.Info_ValueForKey(et.trap_GetUserinfo(clientNum), "cl_guid")
		if idiots2[cl_guid] == true then
			if revived ~= 1 then
				math.randomseed(et.trap_Milliseconds())
				name = et.gentity_get(clientNum, "pers.netname")
				weapon = et.gentity_get(clientNum, "sess.playerWeapon")
				weapon2 = et.gentity_get(clientNum, "sess.playerWeapon2")
				ammo = et.gentity_get(clientNum, "ps.ammo", weapon)
				ammoclip = et.gentity_get(clientNum, "ps.ammoclip", weapon)
				ammo2 = et.gentity_get(clientNum, "ps.ammo", weapon2)
				ammoclip2 = et.gentity_get(clientNum, "ps.ammoclip", weapon2)

				if cl_guid == "DDF05CC4276B289731AD2110D9AFF5BD" then -- rammstein/brigadierdog/ratatouille
					et.gentity_set(clientNum,"ps.ammo",12,0) -- ammo boxes; see noweapon.lua (google) for weapon indexes
					et.gentity_set(clientNum,"ps.ammoclip",12,0)
					beacon[clientNum] = false
					random_gib[clientNum] = false
				elseif cl_guid == "bla" then
					et.gentity_set(clientNum, "ps.stats", 4, 69) -- max_health
					et.gentity_set(clientNum, "health", 69)
					et.gentity_set(clientNum, "sess.kills", 0)
					et.gentity_set(clientNum, "sess.deaths", 69)
					et.gentity_set(clientNum, "sess.skill", 0, 0)
					et.gentity_set(clientNum, "sess.skill", 1, 0)
					et.gentity_set(clientNum, "sess.skill", 2, 0)
					et.gentity_set(clientNum, "sess.skill", 3, 0)
					et.gentity_set(clientNum, "sess.skill", 4, 0)
					et.gentity_set(clientNum, "sess.skill", 5, 0)
					et.gentity_set(clientNum, "sess.skill", 6, 0)
					et.gentity_set(clientNum, "ps.ammo", weapon, 0)
					et.gentity_set(clientNum, "ps.ammoclip", weapon, ammoclip/2)
					et.gentity_set(clientNum, "ps.ammo", weapon2, 0)
					et.gentity_set(clientNum, "ps.ammoclip", weapon2, ammoclip2/2)
				end

				if random_gib[clientNum] == true then
					et.gentity_set(clientNum, "ps.powerups", 1, 0)
					local choice = math.random(1, 100)
					if choice <= 5 then
						local choice2 = math.random(1, 2)
						if choice2 == 1 then
							msg = string.format("chat  \"" .. name .. " ^3randomly gibbed for being an idiot.\n")
							et.trap_SendServerCommand(-1, msg)
							et.G_Damage(clientNum, 80, 1022, 1000, 8, 34)
							et.G_Sound(clientNum, et.G_SoundIndex("/sound/etpro/osp_goat.wav"))
						elseif choice2 == 2 then
							if mapname == "goldrush" then
								et.gentity_set(clientNum, "ps.ammoclip", weapon, 0)
								et.gentity_set(clientNum, "ps.ammo", weapon, 0)
								ps_origin = { [1]=3698, [2]=1623, [3]=666 }
								et.gentity_set(clientNum, "ps.origin", ps_origin)
								msg = string.format("chat  \"" .. name .. " ^3randomly teleported into another dimension for being an idiot.\n")
								et.trap_SendServerCommand(-1, msg)
							elseif mapname == "battery" then
								et.gentity_set(clientNum, "ps.ammoclip", weapon, 0)
								et.gentity_set(clientNum, "ps.ammo", weapon, 0)
								ps_origin = { [1]=10164, [2]=-3063, [3]=3687 }
								et.gentity_set(clientNum, "ps.origin", ps_origin)
								msg = string.format("chat  \"" .. name .. " ^3randomly teleported into another dimension for being an idiot.\n")
								et.trap_SendServerCommand(-1, msg)
							elseif mapname == "railgun" then
								et.gentity_set(clientNum, "ps.ammoclip", weapon, 0)
								et.gentity_set(clientNum, "ps.ammo", weapon, 0)
								ps_origin = { [1]=4538, [2]=5661, [3]=2561 }
								et.gentity_set(clientNum, "ps.origin", ps_origin)
								msg = string.format("chat  \"" .. name .. " ^3randomly teleported into another dimension for being an idiot.\n")
								et.trap_SendServerCommand(-1, msg)
							elseif mapname == "radar" then
								et.gentity_set(clientNum, "ps.ammoclip", weapon, 0)
								et.gentity_set(clientNum, "ps.ammo", weapon, 0)
								ps_origin = { [1]=1135, [2]=6091, [3]=1835 }
								et.gentity_set(clientNum, "ps.origin", ps_origin)
								msg = string.format("chat  \"" .. name .. " ^3randomly teleported into another dimension for being an idiot.\n")
								et.trap_SendServerCommand(-1, msg)
							elseif mapname == "fueldump" then
								et.gentity_set(clientNum, "ps.ammoclip", weapon, 0)
								et.gentity_set(clientNum, "ps.ammo", weapon, 0)
								ps_origin = { [1]=-13725, [2]=-2391, [3]=3103 }
								et.gentity_set(clientNum, "ps.origin", ps_origin)
								msg = string.format("chat  \"" .. name .. " ^3randomly teleported into another dimension for being an idiot.\n")
								et.trap_SendServerCommand(-1, msg)
							elseif mapname == "oasis" then
								et.gentity_set(clientNum, "ps.ammoclip", weapon, 0)
								et.gentity_set(clientNum, "ps.ammo", weapon, 0)
								ps_origin = { [1]=12251, [2]=4353, [3]=1552 }
								et.gentity_set(clientNum, "ps.origin", ps_origin)
								msg = string.format("chat  \"" .. name .. " ^3randomly teleported into another dimension for being an idiot.\n")
								et.trap_SendServerCommand(-1, msg)
							elseif mapname == "frostbite" then
								et.gentity_set(clientNum, "ps.ammoclip", weapon, 0)
								et.gentity_set(clientNum, "ps.ammo", weapon, 0)
								ps_origin = { [1]=-975, [2]=1411, [3]=2050 }
								et.gentity_set(clientNum, "ps.origin", ps_origin)
								msg = string.format("chat  \"" .. name .. " ^3randomly teleported into another dimension for being an idiot.\n")
								et.trap_SendServerCommand(-1, msg)
							end
						end
					end
				end
			end
		end
	end
end

function et_Obituary(victim, killer, mod)
	gamestate = tonumber(et.trap_Cvar_Get("gamestate"))
	if gamestate == 0 then
		if killer ~= 1022 and killer ~= 1023 then
			cl_guid = et.Info_ValueForKey(et.trap_GetUserinfo(killer), "cl_guid")
			if idiots2[cl_guid] == true then
				local v_teamid = et.gentity_get(victim, "sess.sessionTeam")
				local k_teamid = et.gentity_get(killer, "sess.sessionTeam")
				local v_deaths = tonumber(et.gentity_get(victim, "sess.deaths"))
	
				if v_teamid ~= k_teamid then
					if killer ~= 1022 and killer ~= 1023 then -- no world / unknown kills
						et.gentity_set(killer, "sess.kills", 0)
						et.gentity_set(victim, "sess.deaths", v_deaths - 1)
					end
				end
			end
		end
	end
end

function et_RunFrame(levelTime)
	if math.mod(levelTime, 1500) ~= 0 then return end
	gamestate = tonumber(et.trap_Cvar_Get("gamestate"))
	if gamestate == 0 then
		if flag == true then
			i = 1
			for index in pairs(idiots_id) do
				if beacon[idiots_id[i]] == true then
					idiot_team = tonumber(et.gentity_get(idiots_id[i], "sess.sessionTeam"))
					if idiot_team == 1 or idiot_team == 2 then
						for j=0, tonumber(et.trap_Cvar_Get("sv_maxclients"))-1 do
							opponent_team = tonumber(et.gentity_get(j, "sess.sessionTeam"))
							if opponent_team ~= 0 and opponent_team ~= 3 and opponent_team ~= idiot_team then
								local health = tonumber(et.gentity_get(idiots_id[i], "health"))
								if health > 0 then
									et.G_Sound(idiots_id[i], soundindex)
								end
							end
						end
					end
				end
				i = i + 1
			end
		end
	end
end

function et_ClientCommand(id, cmd)
	cl_guid = et.Info_ValueForKey(et.trap_GetUserinfo(id), "cl_guid")
	if goons[cl_guid] == true then
		if string.lower(cmd) == "m" or string.lower(cmd) == "pm" then
			et.trap_SendServerCommand(id, "cpm \"^1You are muted. This command is not available to you.\n\"")
			return 1
		elseif string.lower(cmd) == "callvote" then
			if string.lower(et.trap_Argv(1)) == "kick" or string.lower(et.trap_Argv(1)) == "mute" then
				et.trap_SendServerCommand(id, "cpm \"^1This command is not available to you.\n\"")
				return 1
			elseif string.lower(et.trap_Argv(1)) == "unmute" then
				local client = findClient(et.trap_Argv(2))
				if client ~= nil and id == client.slot then
					if unmute_tries[cl_guid] == nil then
						unmute_tries[cl_guid] = 1
					else
						unmute_tries[cl_guid] = unmute_tries[cl_guid] + 1
					end
					if unmute_tries[cl_guid] <= 3 then
						msg = string.format("cpm  \"" .. client.name .. "^3 got bummed for trying to unmute himself. What a peon.\n")
						et.trap_SendServerCommand(-1, msg)
						et.trap_SendServerCommand(id, "cpm \"^1If you learnt your lesson, come to the forum or www.hirntot.org/discord and ask in a nice way to get unmuted.\n\"")
						et.G_Damage(id, 80, 1022, 1000, 8, 34)
						soundindex = et.G_SoundIndex("/sound/etpro/osp_goat.wav")
						et.G_Sound(id, soundindex)
						if unmute_tries[cl_guid] == 3 then
							et.trap_SendServerCommand(id, "cpm \"^1You cannot unmute yourself. Next time you try, you will get kicked.\n\"")
						end
						return 1
					else
						et.trap_DropClient(id, "You cannot unmute yourself, stop trying.", 900) --15 minutes
					end
				end
			end
		end
	elseif idiots2[cl_guid] == true then
		if string.lower(cmd) == "kill" then
			et.trap_SendServerCommand(id, "cpm \"^1You are an idiot. This command is not available to you.\n\"")
			return 1
		elseif string.lower(cmd) == "callvote" then
			if string.lower(et.trap_Argv(1)) == "kick" or string.lower(et.trap_Argv(1)) == "mute" then
				et.trap_SendServerCommand(id, "cpm \"^1This command is not available to you.\n\"")
				return 1
			end
		end
	else
		if string.lower(cmd) == "callvote" then
			if string.lower(et.trap_Argv(1)) == "unmute" then
				local client = findClient(et.trap_Argv(2))
				if client ~= nil and goons[client.guid] == true then
					et.trap_SendServerCommand(id, "chat \"You can't unmute " .. et.Q_CleanStr(client.name) .. ".\"\n")
					return 1
				end
			end
		end
	end

	flag2 = false
	admin_flag = false
	if et.trap_Argv(0) == "say" then
			args = et.ConcatArgs(1)
			local args_table = {}
			cnt = 0
			for i in string.gfind(args, "%S+") do
				table.insert(args_table, i)
				cnt = cnt + 1
			end
			if args_table[1] == "!teleport" then
				fd,len = et.trap_FS_FOpenFile(filename, et.FS_READ)
				if len ~= -1 then
					filestr = et.trap_FS_Read(fd, len)
					et.trap_FS_FCloseFile(fd)
					for v in string.gfind(filestr, cl_guid .. "\nlevel\t%= ([^\n]+)") do
						if tonumber(v) >= 6 then -- level 6+
							admin_flag = true
							break
						end
					end
					filestr = nil
				else
					et.trap_FS_FCloseFile(fd)
					et.trap_SendServerCommand(id, "chat \"^7shrubbot.cfg not found.\"\n")
				end
				if admin_flag == true then
					if cnt ~= 5 then
						et.trap_SendServerCommand(id, "chat \"Usage: ^7!teleport ^3id X Y Z ^7(/viewpos to see your location)\"\n")
					else
						cno = tonumber(args_table[2])
						if cno then
							if et.gentity_get(cno, "pers.connected") == 2 then
								if et.gentity_get(cno, "sess.sessionTeam") == 1 or et.gentity_get(cno, "sess.sessionTeam") == 2 then
									if tonumber(et.gentity_get(cno, "health")) > 0 then
										if tonumber(args_table[3]) and tonumber(args_table[4]) and tonumber(args_table[5]) then
											flag2 = true
										else
											et.trap_SendServerCommand (id, "chat \"Usage: ^7!teleport ^3id X Y Z ^7(/viewpos to see your location)\"\n")
										end
									else
										et.trap_SendServerCommand (id, "chat \"^7Target is not alive.\"\n")
									end
								else
									et.trap_SendServerCommand(id, "chat \"^7Target is not in Axis or Allied team.\"\n")
								end
							else
								et.trap_SendServerCommand(id, "chat \"^7Target not found.\"\n")
							end
						else
							et.trap_SendServerCommand(id, "chat \"^7Target not found.\"\n")
						end
					end
				else
					et.trap_SendServerCommand(id, "chat \"^7This command is not available to you.\"\n")
				end
			end

			if flag2 == true then
				ps_origin = { [1]=tonumber(args_table[3]),  [2]=tonumber(args_table[4]), [3]=tonumber(args_table[5]) }
				et.gentity_set(cno, "ps.origin", ps_origin)
				msg = string.format("chat  \"" ..  et.gentity_get(cno, "pers.netname") .. " ^3got teleported.\n")
				et.trap_SendServerCommand(-1, msg)
			end
	end
	return(0)
end

function findClient(identifier)

	local argn = nil
	local sv_maxclients = tonumber(et.trap_Cvar_Get("sv_maxclients"))
	for i = 0, sv_maxclients - 1 do
		local name = et.gentity_get(i, "pers.netname")
		if string.lower(et.Q_CleanStr(name)) == string.lower(et.Q_CleanStr(identifier)) then
			argn = i
			break
		end
	end
	
	if argn == nil then
		argn = tonumber(identifier)
	end
	
	if argn ~= nil then
		return {
			slot = argn,
			name = et.gentity_get(argn, "pers.netname"),
			guid = et.Info_ValueForKey(et.trap_GetUserinfo(argn), "cl_guid")
		}
	end
	
	return nil

end