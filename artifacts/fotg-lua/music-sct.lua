
--Dynamic Music Script for generalized set-and-forget purposes
--by wookieejedi

--SETUP
	--Steps to setup in a mission (needed for each mission):
		--1. In the Event Editor and event called "EnableDynamicMusic". The contents do not matter.
		--2. Save the file, and when the mission starts the script will automatically turn off any music tracks saved in the Mission Specs Editor and use the scripted music.
	--Steps to setup the script to use music tracks (only need to do this once):
		--1. Examine example tracks in the tables DMusic_Track and DMusic_Flourish. Each entry consists of:
			--track_filename = {
				--t_length = <length of track in seconds (decimals supported)>
				--epic_score = <number between 0 and 5 (check comments in GetEpicIndex() for more details)>
			--}
		--2. Add music tracks using this format to DMusic_Track and add flourishes to DMusic_Flourish
		--3. Add flourishes to lists in the section of the table that lists f_types. The script will pick from that list randomly when that flourish is called. 

--

DMusic = { 
	--options here are those that do not change, for options that do change go to :Reset_Everything() function
	print_debug = false,

	hostile_default_distance = 4000,

	num_many_default_ships = {
		Friendly = 10,
		Hostile = 10
	},

	buffer_switch_time = {DMusic_Track = -2.7, DMusic_Flourish = -0.7}, --give some cross fade
	check_changes_interval = 0.30,
	fade_interval_update = 0.05,
	fade_minimum_volume = 0.1,
	event_enable_name = "EnableDynamicMusic",
	music_info_variable_keys = {"DMusic_Track", "DMusic_Flourish"},
	DMusic_Track = {
		--t_length: in decimal seconds
		--epic_score: value from 1-5, 5 most epic: check GetEpicIndex() for more details
			--1 ambient
			--2-3 buildup/tense
			--4 battle
			--5 war

		--Silence
			Silence = {
				t_length = 25,
				epic_score = 1
			},

		--Alderaan
			Alderaan_Alert = {
				t_length = 78,
				epic_score = 3
			},
			Alderaan_Battle = {
				t_length = 159,
				epic_score = 4
			},
		
		--Bespin
			Bespin_Alert = {
				t_length = 77,
				epic_score = 3
			},
			Bespin_Battle = {
				t_length = 229,
				epic_score = 4
			},

		--Dagobah
			Dagobah_Normal = {
				t_length = 90,
				epic_score = 1
			},
			Dagobah_Battle = {
				t_length = 167,
				epic_score = 4
			},

		--Dantooine
			Dantooine_Battle = {
				t_length = 197,
				epic_score = 5
			},
			Dantooine_Normal = {
				t_length = 137,
				epic_score = 2
			},
		
		--Hoth
			Hoth_Alert = {
				t_length = 110,
				epic_score = 3
			},
			Hoth_Battle = {
				t_length = 198,
				epic_score = 4
			},

		--Ord Mantell
			OrdMantell_Battle = {
				t_length = 163,
				epic_score = 5
			},
			OrdMantell_Normal = {
				t_length = 54,
				epic_score = 1
			},

		--Sullust
			Sullust_Alert = {
				t_length = 72,
				epic_score = 3
			},
			Sullust_Battle = {
				t_length = 167,
				epic_score = 5
			},
			Sullust_Normal = {
				t_length = 85,
				epic_score = 1
			},

		--Tatooine
			Tatooine_Alert = {
				t_length = 65,
				epic_score = 2
			},
			Tatooine_Battle = {
				t_length = 167,
				epic_score = 4
			},

		--Yavin
			Yavin_Alert = {
				t_length = 72,
				epic_score = 2
			},
			Yavin_Battle = {
				t_length = 291,
				epic_score = 5
			},
			Yavin_Normal = {
				t_length = 85,
				epic_score = 2
			}			

	},
	DMusic_Flourish = {
		Allied_Arrive = {
			t_length = 10-3,
			epic_score = 4
		},
		Allied_Arrive_A = {
			t_length = 5-3,
			epic_score = 2
		},
		Allied_Arrive_B = {
			t_length = 5-3,
			epic_score = 2
		},
		Allied_Arrive_C = {
			t_length = 5-3,
			epic_score = 2
		},
		Allied_Arrive_D = {
			t_length = 5-3,
			epic_score = 2
		},
		Allied_Arrive_E = {
			t_length = 5-3,
			epic_score = 2
		},
		Allied_Arrive_F = {
			t_length = 5-3,
			epic_score = 2
		},
		Enemy_Arrive = {
			t_length = 11-3,
			epic_score = 4
		},
		Alderaan_End = {
			t_length = 7,
			epic_score = 4
		},
		OrdMantell_End = {
			t_length = 7,
			epic_score = 4
		},
		Dagobah_End = {
			t_length = 11,
			epic_score = 3
		},
		Dantooine_End = {
			t_length = 4,
			epic_score = 4
		},
		Tatooine_End = {
			t_length = 14,
			epic_score = 4
		},
		Yavin_End = {
			t_length = 2,
			epic_score = 3
		},
		Sullust_End = {
			t_length = 6,
			epic_score = 4
		},															
		Debrief_Traitor = {
			t_length = 51,
			epic_score = 4
		},
		Failure = {
			t_length = 16,
			epic_score = 3
		},
		Victory_1 = {
			t_length = 25,
			epic_score = 4
		},
		Victory_2 = {
			t_length = 57,
			epic_score = 5
		}
	},

	radius_size_large = 650, -- >650 is Liberty, ISD, and larger
	radius_size_medium = 300, -- >300 is dread/MC40 and larger
	radius_size_small = 15,

	--recall that override only affects other flourish interruptions (flourish will only play if > current flourish epic i)
	--will also not play if < current main music epic i
	--note: new f_types should not be added until wookieejedi adds them to code functions Get_FlourishString(
	ftype_arrive_small_f =    {foptions={"Allied_Arrive_A", "Allied_Arrive_B", "Allied_Arrive_C"}, override_epic_i=3},
	ftype_arrive_medium_f =   {foptions={"Allied_Arrive_D", "Allied_Arrive_E", "Allied_Arrive_F"}, override_epic_i=4},
	ftype_arrive_large_f =    {foptions={"Allied_Arrive"}, override_epic_i=10},
	ftype_death_large_f =     {foptions={"Tatooine_End"}, override_epic_i=7},
	ftype_arrive_small_h =    {foptions={"Yavin_End"}, override_epic_i=3},
	ftype_arrive_medium_h =   {foptions={"Dagobah_End", "Sullust_End"}, override_epic_i=5},
	ftype_arrive_large_h =    {foptions={"Enemy_Arrive"}, override_epic_i=11},
	ftype_death_large_h =     {foptions={"Alderaan_End", "OrdMantell_End", "Dantooine_End"}, override_epic_i=8},

	ftype_death_all_f =       {foptions={"Failure"}, override_epic_i=9},
	ftype_death_all_h =       {foptions={"Victory_2", "Victory_1"}, override_epic_i=10},
	ftype_death_ply_f =       {foptions={"Debrief_Traitor"}, override_epic_i=15, override_flourish_length=99999}
}

--reminders:
	--do not preload all music b/c it is either 
	--  streamed from the compressed file, in which case they aren't actively loaded in their entirety at all, 
	--    so any "preloading" you do would just set up file handles, 
	--  or it'll be decoded to samples, in which case things'll blow up by a factor of 30 in their memory usage
---------

--Code
	function DMusic:Random_from_Table(tbl)

		if type(tbl) == "table" then
			local num = #tbl
			local randomi = ba.rand32(1,num)
			local choice = tbl[randomi]
			return choice
		else
			return tbl
		end

	end

	function DMusic:Reset_CurrentAudio_Variables(music_typ)

		if self.current_audio == nil then return end

		self.current_audio[music_typ] = nil

		self.current_audio[music_typ] = {
			self_type_name = music_typ,
			current_track_name = "", --must eventually be string key in tracks
			mtime_to_music_end = 0, --should be music length + all pause lengths
			is_paused = false,
			mtime_to_unpause = 0,
			current_epic_i = 0,
			volume_current = self.ad_master_volume_level
		}

	end

	function DMusic:Reset_FadeFlourish()

		if self.current_audio == nil then return end

		self.current_audio.fade_flourish = nil

		self.current_audio.fade_flourish = {
			--boolean for if fade flourish combo is occurring
			effect_is_ongoing = false,

			last_time_check = 0,

			--fade out the current track
			trackfade_out_starttime = 0,
			trackfade_out_endtime = 0,

			--keep the current track volume low
			trackfade_hold_starttime = 0,
			trackfade_hold_endtime = 0,
			
			--play the current flourish
			flourish_started_playing = false,
			flourishplay_go_starttime = 0,
			flourishplay_trackname = "",
			flourishplay_epic_override = 0,
			flourishplay_use_pausetrack = false,
			flourishplay_pausetrack_length = -1,
			flourish_trackpause_started = false,

			--as flourish is completing/completed fade in the current track
			trackfade_finish_startime = 0,
			trackfade_in_endtime = 0
		}

	end

	function DMusic:Update_ADMasterVolumer()

		if ba.MultiplayerMode then 
			if self.ad_master_volume_level == nil then
				self.ad_master_volume_level = 1 --not used in multi, but set just in case
			end 
			return 
		end

		self.ad_master_volume_level = math.round(ad.MasterEventMusicVolume, 4)

	end

	function DMusic:Set_CombatTrackDistance(distance_val)

		if type(distance_val) == "number" then
			self.hostile_distance_threshold = distance_val
		end

	end

	function DMusic:Reset_Everything(fade)

		self:Update_ADMasterVolumer()

		--reset all variables
		self.is_active = false
		self.last_mtime_check = 0
		self.battle_epic_i_current = 0

		self.num_ships = nil
		self.num_ships = {
			Friendly = 0,
			Hostile = 0
		}

		self.num_many_ships = nil
		self.num_many_ships = {
			Friendly = self.num_many_default_ships.Friendly,
			Hostile = self.num_many_default_ships.Hostile
		}

		self.hostile_distance_threshold = self.hostile_default_distance

		self.always_hostile_music_if_present = false

		self.current_audio = nil
		self.current_audio = {}

		--set values
		for _,v_musictyp in ipairs(self.music_info_variable_keys) do
			self:Reset_CurrentAudio_Variables(v_musictyp)
		end

		self:Reset_FadeFlourish()

		--close out tracks with optional fade
		if fade == nil then 
			fade = false
		end

		--set actual audio streams
		self:AudioStop("DMusic_Track", fade)
		self:AudioStop("DMusic_Flourish", fade)

		if self.print_debug then
			ba.print("DMusic: variables have been cleared and reset...\n")
		end

	end

	function DMusic:Change_Soundtrack(snd_trck_name)

		if snd_trck_name ~= nil then
			mn.evaluateSEXP("( change-soundtrack !"..snd_trck_name.."! )")
		end

	end

	function DMusic:AudioPlay(music_typ, track_filename, epic_i_override, fadeout_if_already_playing)

		--update metadata variables
		local mtime = mn.getMissionTime() or 0
		local master_music_info = self[music_typ][track_filename]

		if fadeout_if_already_playing == nil then
			fadeout_if_already_playing = true
		end

		self.current_audio[music_typ].current_track_name = track_filename --must be string key in tracks
		--end of music also includes slight buffer time for switching...
		--...if we want longer times then just make this value higher then default
		self.current_audio[music_typ].mtime_to_music_end = mtime + master_music_info.t_length + self.buffer_switch_time[music_typ]
		self.current_audio[music_typ].is_paused = false
		self.current_audio[music_typ].mtime_to_unpause = mtime
		self.current_audio[music_typ].current_epic_i = epic_i_override or master_music_info.epic_score
		self.current_audio[music_typ].volume_current = self.ad_master_volume_level

		--actually run playing code
		track_filename = track_filename ..".ogg"
		if music_typ == "DMusic_Track" then
			--if previously playing music, stop it
			if DMusic_AS_Track ~= nil and DMusic_AS_Track:isValid() and DMusic_AS_Track:isPlaying() then
				DMusic_AS_Track:close(fadeout_if_already_playing)
			end
			--open stream and save it to this variable
			DMusic_AS_Track = ad.openAudioStream(track_filename, AUDIOSTREAM_EVENTMUSIC)
			if DMusic_AS_Track ~= nil and DMusic_AS_Track:isValid() then
				--play stream
				DMusic_AS_Track:play()
				if self.print_debug then
					ba.print("DMusic starting to play track "..tostring(track_filename).."\n")
				end
			else
				ba.warning("DMusic could not open audio stream "..tostring(track_filename).."\n")
			end
		elseif music_typ == "DMusic_Flourish" then
			--if previously playing music, stop it
			if DMusic_AS_Flourish ~= nil and DMusic_AS_Flourish:isValid() and DMusic_AS_Flourish:isPlaying() then
				DMusic_AS_Flourish:close(fadeout_if_already_playing)
			end
			--open stream and save it to this variable
			DMusic_AS_Flourish = ad.openAudioStream(track_filename, AUDIOSTREAM_EVENTMUSIC)
			if DMusic_AS_Flourish ~= nil and DMusic_AS_Flourish:isValid() then
				--play stream
				DMusic_AS_Flourish:play()
				if self.print_debug then
					ba.print("DMusic starting to play flourish "..tostring(track_filename).."\n")
				end
			else
				ba.warning("DMusic could not open audio stream "..tostring(track_filename).."\n")
			end
		else
			ba.warning("DMusic Error: play function provided with invalid music type "..tostring(music_typ).."\n")
		end

		--sexp: play-music
			---- if we were previously playing music on this handle, stop it
			-- audiostream_close_file(Sexp_music_handles[index], fade);
			---- open the stream and save the handle in our list
			-- Sexp_music_handles[index] = audiostream_open(filename, type);
			---- start playing
			-- if (!audiostream_is_playing(music_handle))
				-- audiostream_play(music_handle, (Master_event_music_volume * aav_music_volume), loop);

	end

	function DMusic:AudioPause(music_typ, pause_bool, time_to_add_to_pause)

		--set pause_bool: true is pause, false is unpause/play
		if pause_bool == nil then 
			pause_bool = true 
		end

		--update metadata variables
		--get music table
		local cmusic = self.current_audio[music_typ]

		--run pause or unpause
		self.current_audio[music_typ].is_paused = pause_bool

		--this should be 0 if we are unpausing track
		time_to_add_to_pause = time_to_add_to_pause or 0

		--following is just for pausing music
		if pause_bool and time_to_add_to_pause <= 0 then 
			return 
		end

		--update pause related time
		local mtime = mn.getMissionTime()
		local old_time_to_unpause_last_trk = cmusic.mtime_to_unpause
		local new_time_to_unpause_last_trk = mtime + time_to_add_to_pause
		self.current_audio[music_typ].mtime_to_unpause = new_time_to_unpause_last_trk
		--^this should work well since each time a flourish is played it adds more time since mtime is cumulative

		local new_extra_pause_time = new_time_to_unpause_last_trk - old_time_to_unpause_last_trk

		self.current_audio[music_typ].mtime_to_music_end = cmusic.mtime_to_music_end + new_extra_pause_time 
		--^if cumulative pauses got through from closely jumping in ships then this adds too much track length
			--20 second track, started at 5, no unpausing will be done at 25
			--ship jumps in at 10 seconds, says new unpause time 15
				--music to end time is 30
			--another ship jumps in at 11 seconds, says new unpause time is 16
				--music to end time is 30+5 = 35, though it should just be 31
		--so we used new_extra_time between pauses
		--if pauses are not overlapping this will == time_to_add_to_pause
			--because mtime_to_unpause = mtime of track playing start when track is first played
			--so 20 second track starts at 5, no unpausing will be done at 25
			--ship jumps in at 10 seconds, new unpause is 15
				--extra time pause is 15(new) - 10(old) = 5
				--music to end time is 25(og val) + 5(extra time pause) = 30(new val)
			--ship jumps in at 11 seconds, new unpause is 16
				--extra time pause is 16(new) - 15(old) = 1
				--music to end time is 30(og val) + 1(extra time pause) = 31(new val)				


		--actually run pausing code
		if music_typ == "DMusic_Track" then
			if DMusic_AS_Track ~= nil and DMusic_AS_Track:isValid() then
				if pause_bool then
					DMusic_AS_Track:pause()
				else
					DMusic_AS_Track:unpause()
				end
			end
		elseif music_typ == "DMusic_Flourish" then
			if DMusic_AS_Flourish ~= nil and DMusic_AS_Flourish:isValid() then
				if pause_bool then
					DMusic_AS_Flourish:pause()
				else
					DMusic_AS_Flourish:unpause()
				end
			end
		else
			ba.warning("DMusic Error: pause function provided with invalid music type "..tostring(music_typ).."\n")
		end

		--sexp: pause-music
			-- if (pause && !audiostream_is_paused(music_handle))
				-- audiostream_pause(music_handle, true); ->runs stop
			-- else if (!pause && audiostream_is_paused(music_handle))
				-- audiostream_unpause(music_handle, true); ->runs play

		--audiostream_pause() has internal check if audiostream is playing, if so then runs audiostream_stop()
		--audiostream_unpause() has internal check if audiostream is paused, if so then runs audiostream_play()

	end

	function DMusic:AudioStop(music_typ, fade_bool) --same as close_file()

		--set fade_bool: true is fade, false is no fade
		if fade_bool == nil then fade_bool = false end

		--update metadata variables
		self:Reset_CurrentAudio_Variables(music_typ)

		--run actual stopping/closing code
		if music_typ == "DMusic_Track" then
			if DMusic_AS_Track ~= nil then
				if DMusic_AS_Track:isValid() then
					DMusic_AS_Track:close(fade_bool)
				end
				DMusic_AS_Track = nil
			end
		elseif music_typ == "DMusic_Flourish" then
			if DMusic_AS_Flourish ~= nil then
				if DMusic_AS_Flourish:isValid() then
					DMusic_AS_Flourish:close(fade_bool)
				end
				DMusic_AS_Flourish = nil
			end
		else
			ba.warning("DMusic Error: stop function provided with invalid music type "..tostring(music_typ).."\n")
		end

		--sexp: close-music
			-- if (music_handle >= 0)
				-- audiostream_close_file(music_handle, fade);

		--also `ad.stopMusic()` should be `ad.closeMusic()` since it runs `audiostream_close_file()`

	end


	function DMusic:PickRandomBackupTrack()

		local ply = FotG:GetPlayerShip()
		if ply ~= nil and ply:isValid() and ply:getBreedName() == "Ship" then
			local pspecies = ply.Class.Species.Name
			local trk_tlb = {
				Rebel={"Tatooine", "Yavin", "Dagobah", "Endor"},
				Pirate={"Tatooine", "Yavin", "Dagobah", "Endor"}, --for Y-wing and Z95
				Republic={"Tatooine", "Yavin", "Dagobah", "Endor"}, --just as a failsafe
				Imperial={"Alderaan", "Hoth", "Bespin", "Dantooine"}
			}
			local ftbl = trk_tlb[pspecies]
			if ftbl ~= nil then
				local ntracks = #ftbl
				local itrk = ba.rand32(1, ntracks)
				local snd_trck_name = ftbl[itrk]
				self:Change_Soundtrack(snd_trck_name)
			end
		end

	end

	function DMusic:Mission_Setup()

		self:Reset_Everything()

		--no playing in multi ATM
		if ba.MultiplayerMode then return end

		--not using in OT test
		if OTMod_music then
			--pick random music track based on faction
			self:PickRandomBackupTrack()
			return
		end

		--does this mission use dynamic music?
		if mn.Events[self.event_enable_name]:isValid() then
			--yes, so we should use and setup rest of dynamic music
			self.is_active = true
		else
			--nope, hop out 
			return
		end

		ba.print("DMusic has been enabled, setting everything up...\n")

		--change soundtrack to none
		self:Change_Soundtrack("<No Music>")

		--add all ships at start of mission
		for ship in mn.getShipList() do
			self:UpdateShip(ship, 1, "arrive", true) --true for on mission start
		end

		--verify all music files exist and show error for those that do not
		local tracks_list = self.DMusic_Track
		for k_trackname, _ in pairs(tracks_list) do
			if not cf.fileExists(k_trackname..".ogg", "data/music", false) then
				ba.warning("DMusic found that there is no file called "..k_trackname.."! Remove from DMusic.DMusic_Track table in music-sct.lua or add as file in music folder.")
			end
		end

		ba.print("DMusic setup completed...\n")

	end

	function DMusic:Get_FlourishString(method_name, ship_radius, shipteamname, isplyship)

		if isplyship == nil then
			isplyship = false
		end

		local team_convert = {Friendly="f", Hostile="h"}
		local team_shorthand = team_convert[shipteamname] or ""

		local size

		--recall that num_ships was updated right before this function runs..
		--..so don't have to worry about updating values for all dead checks

		--special death cases
		if method_name == "death" then

			--special cases of player death
			if isplyship then
				size = "ply" 
			end

			if size == nil then
				if shipteamname == "Hostile" then
					--special case of all hostiles dead
					if self.num_ships.Hostile <= 0 then
						size = "all"
					end 
				elseif shipteamname == "Friendly" then
					--special case of all friendlies dead
					if self.num_ships.Friendly <= 1 then --1 b/c ply still alive
						size = "all"
					end 
				end
			end

		end

		--rest based on size, team, etc
		if size == nil then
			if ship_radius >= self.radius_size_large then
				--large
				size = "large"
			elseif ship_radius >= self.radius_size_medium then
				--medium
				size = "medium"
			else
				--small
				size = "small"
			end
		end

		--compile into string
		local fourish_str_key = "ftype_"..method_name.."_"..size.."_"..team_shorthand

		return fourish_str_key

	end

	function DMusic:FadeFlourish_Start(method_name, ship_radius, ship_team_name, is_ply_ship, effect_start_delay)

		--get flourish string
		--is it a valid string key?
		--if so then pick track and check overrides
		--check if flourish already playing
			--if playing see if we can override it
			--if not playing just go ahead
		--if good then play it and pause main track

		--print("D-music_Play_Flourish got update amount of "..tostring(method_name)..", with "..tostring(ship_radius).." and team "..tostring(ship_team_name).."...\n")

		--get flourish string
		local fstring = self:Get_FlourishString(method_name, ship_radius, ship_team_name, is_ply_ship)
		--is it a valid string key?
		local f_info = self[fstring]

		--early out if not a valid flourish
		if f_info == nil then 
			return 
		end

		--are there options listed?
		local options = f_info.foptions or {}
		local num_options = #options

		--early out if no options
		if num_options <= 0 then 
			return 
		end

		--choose random choice from options
		local selection_name = self:Random_from_Table(options)
		local master_flourish_list = self.DMusic_Flourish
		local flourish_selection_info = master_flourish_list[selection_name]

		--is that option valid?
		--early out if no selection
		if flourish_selection_info == nil then 
			return 
		end

		--check if fade flourish already playing
		local cflourish = self.current_audio.DMusic_Flourish
		local mtime = mn.getMissionTime()
		local is_playing = false
		if self.current_audio.fade_flourish.effect_is_ongoing then
			is_playing = true
			if self.print_debug then
				ba.print("DMusic fade flourish already playing...\n")
			end
		end

		--get epic value of this flourish
		--check if we are using a custom epic i override	
		local new_epic = f_info.override_epic_i or master_flourish_list[selection_name].epic_score
		local current_epic = cflourish.current_epic_i
		local main_track_epic_i = self.current_audio.DMusic_Track.current_epic_i

		if self.print_debug then
			ba.print("DMusic new_epic "..new_epic.."...\n")
			ba.print("DMusic main_track_epic_i "..main_track_epic_i.."...\n")
			ba.print("DMusic current_epic "..current_epic.."...\n")
		end

		--check if flourish is < current main music epic i
		--if another flourish is playing, only interrupt if this is a higher epic level
		local play_new = false
		if new_epic > main_track_epic_i then
			if is_playing then
				if new_epic > current_epic then
					play_new = true
				end
			else
				--flourish not playing, so we can safely play any flourish
				play_new = true
			end
		end

		--leave if cannot play
		if not play_new then 
			return 
		end

		--start fade flourish if we can

		--get fade duration and set as fade duration or end time
		--save if fading out or fading in
		--save that a fade is running

		--time variables for flourish fade
		local trackfade_out_starttime = mtime + effect_start_delay
		local trackfade_out_endtime = trackfade_out_starttime + 2.5
		local flourishplay_go_starttime = trackfade_out_endtime - 1.0 --give time to load
		local flourish_duration = f_info.override_flourish_length or flourish_selection_info.t_length
		local trackfade_in_starttime = flourishplay_go_starttime + flourish_duration - 1.0
		local trackfade_in_endtime = trackfade_in_starttime + 2.5
		local flourishplay_pausetrack_length = trackfade_in_starttime - (flourishplay_go_starttime + 0.1)

		if self.print_debug then
			ba.print("DMusic overriding fade flourish at current time  "..mtime.."...\n")
			ba.print("DMusic trackfade_out_starttime "..trackfade_out_starttime.."...\n")
			ba.print("DMusic trackfade_out_endtime "..trackfade_out_endtime.."...\n")
			ba.print("DMusic fstring "..fstring.."...\n")
			ba.print("DMusic flourishplay_go_starttime "..flourishplay_go_starttime.."...\n")
			ba.print("DMusic flourish_duration "..flourish_duration.."...\n")
			ba.print("DMusic trackfade_in_starttime "..trackfade_in_starttime.."...\n")
			ba.print("DMusic trackfade_in_endtime "..trackfade_in_endtime.."...\n")
		end

		self.current_audio.fade_flourish = nil

		self.current_audio.fade_flourish = {
			--boolean for if fade flourish combo is occurring
			effect_is_ongoing = true,

			last_time_check = mtime,

			--fade out the current track
			trackfade_out_starttime = trackfade_out_starttime,
			trackfade_out_endtime = trackfade_out_endtime,

			--play the current flourish and maybe pause main track instead of just make really quiet (not using pause ATM)
			flourish_started_playing = false,
			flourishplay_go_starttime = flourishplay_go_starttime,
			flourishplay_trackname = selection_name,
			flourishplay_epic_override = new_epic,
			flourishplay_use_pausetrack = false,
			flourishplay_pausetrack_length = flourishplay_pausetrack_length,
			flourish_trackpause_started = false,

			--as flourish is completing/completed fade in the current track
			trackfade_finish_startime = trackfade_in_starttime,
			trackfade_in_endtime = trackfade_in_endtime
		}

	end

	function DMusic:FadeTrack(time_start, time_end, current_time, fade_type)

		--get percentage of time that fade needs to be completed
		--  in other words, what was the fade start time, what was the fade end time, and what is the current time
		--  also check and use value if volume is increasing or decreasing

		local percent_time_complete = (current_time - time_start) / (time_end - time_start)
		--by default this goes from 0->1, which is a fade in/crescendo

		local min_vol = self.fade_minimum_volume

		--change to 1->0 if fade out
		local volume_multiplier
		if fade_type == "FadeIn" then
			volume_multiplier = percent_time_complete
		elseif fade_type == "FadeOut" then
			volume_multiplier = 1 - percent_time_complete
		elseif fade_type == "FadeHold" then
			volume_multiplier = min_vol
		end

		--clamp between min_vol and 1.0
		if volume_multiplier < min_vol then
			volume_multiplier = min_vol
		elseif volume_multiplier > 1.0 then
			volume_multiplier = 1.0
		end

		--set volume of track
		if DMusic_AS_Track ~= nil and DMusic_AS_Track:isValid() then
			--get current volume
			local track_info = self.current_audio.DMusic_Track
			local new_volume = math.round(self.ad_master_volume_level * volume_multiplier, 4)
			--if different then set and save
			if track_info.volume_current ~= new_volume then
				self.current_audio.DMusic_Track.volume_current = new_volume
				DMusic_AS_Track:setVolume(new_volume)
			end
		end

	end

	function DMusic:FadeFlourish_Run(mtime) --runs every x seconds and changes volume

		--if a fade is running, check every x seconds
		--calculate new track volume by multiplying original amount with percent fade, then set and save value 
		--if time over then run fade end

		local ff = self.current_audio.fade_flourish

		--only run if effect is ongoing
		if ff.effect_is_ongoing and (mtime > ff.last_time_check + self.fade_interval_update) then

			--save last time check
			self.current_audio.fade_flourish.last_time_check = mtime

			--fade out the current track
			if mtime >= ff.trackfade_out_starttime and mtime <= ff.trackfade_out_endtime then
				--run fade out
				self:FadeTrack(ff.trackfade_out_starttime, ff.trackfade_out_endtime, mtime, "FadeOut")
			end

			--play the current flourish
			if not ff.flourish_started_playing and (mtime >= ff.flourishplay_go_starttime) then
				self.current_audio.fade_flourish.flourish_started_playing = true
				self:AudioPlay("DMusic_Flourish", ff.flourishplay_trackname, ff.flourishplay_epic_override)

				if ff.flourishplay_use_pausetrack and not ff.flourish_trackpause_started and (ff.flourishplay_pausetrack_length > 0) and (mtime >= ff.flourishplay_go_starttime + 0.2) then
					--pause current track and update times so that it will get caught in CheckCurrentTrack()
					--need to do pause timing update down here since we need the flourish length
					self:AudioPause("DMusic_Track", true, ff.flourishplay_pausetrack_length)
					self.current_audio.fade_flourish.flourish_trackpause_started = true
				end
			end

			--as flourish is completing/completed fade in the current track
			if mtime >= ff.trackfade_finish_startime and mtime <= ff.trackfade_in_endtime then
				--unpause if needed 
				if ff.flourishplay_use_pausetrack then
					if ff.flourish_trackpause_started and (ff.flourishplay_pausetrack_length > 0) and (mtime >= self.current_audio.DMusic_Track.mtime_to_unpause) then
						self:AudioPause("DMusic_Track", false)
						self.current_audio.fade_flourish.flourish_trackpause_started = false
					end
				end
				--run fade in
				self:FadeTrack(ff.trackfade_finish_startime, ff.trackfade_in_endtime, mtime, "FadeIn")
			end

			--finish up 
			if mtime > ff.trackfade_in_endtime then
				self:FadeFlourish_End()
			end
		end

	end

	function DMusic:FadeFlourish_End()

		--resets all fade values
		--for example save that fade checking is no longer needed after setting final volume
		--volume of music should have ended correctly, but just double check
		self:Reset_FadeFlourish()

		local c_track = self.current_audio.DMusic_Track
		if c_track.volume_current ~= self.ad_master_volume_level then
			self.current_audio.DMusic_Track.volume_current = self.ad_master_volume_level
			if DMusic_AS_Track ~= nil and DMusic_AS_Track:isValid() then
				DMusic_AS_Track:setVolume(self.ad_master_volume_level)
				if self.print_debug then
					ba.print("DMusic Warning: current volume is not equal to volume max after completion of fade flourish, setting to max...\n")
					ba.print("   Extra information: volume-current = "..tostring(c_track.volume_current)..", and volume-max = "..tostring(self.ad_master_volume_level).."\n")
				end
			end
		end

	end

	function DMusic:UpdateShip(Ship, amount_update, method_name, isatmission_start)

		--update total number of friendly or hostile ships 
		if self.is_active and Ship ~= nil and Ship:isValid() and Ship:getBreedName() == "Ship" then

			local class = Ship.Class
			if FotG:IsDummyClass(class.Name) then return end

			--special early out if player respawning
			if amount_update == -1 and Respawner:RespawnAllowed() and Ship:isPlayer() then
				return
			end

			local team = string.filterInvisible(Ship.Team.Name)
			if team == "Friendly" or team == "Hostile" then

				if isatmission_start == nil then
					isatmission_start = false
				end

				--only update value if an actual threat class ship
				--don't want to add this for things like nav buoys, etc
				local no_update_typs = {"navbuoy", "escape pod", "cargo"}

				local stop_early = false
				local stype_name = class.Type.Name
				for _,v_typ in ipairs(no_update_typs) do
					if string.find(stype_name, v_typ) then
						stop_early = true
						break
					end
				end

				if stop_early then 
					return 
				end

				if self.print_debug then
					ba.print("DMusic: preparing ship "..Ship.Name.." with amount of "..amount_update.." and arrival at mission start of "..tostring(isatmission_start).."...\n")
				end

				--set amount to update variables by
				amount_update = amount_update or 1

				--will always update amount, but may not play flourish
				self.num_ships[team] = self.num_ships[team] + amount_update

				--also update track possibly and play entrance if possible
				--if arriving (update amount >= 1) check if arrival music disabled
				if amount_update >= 1 then
					--if ship or wing has music disabled then do not play
					local s_wing = Ship:getWing()
					local parsed_ship = Ship:getParsedShip()
					if ( parsed_ship ~= nil and parsed_ship:getFlag("no-arrival-music") ) or ( s_wing ~= nil and s_wing:isValid() and s_wing:getFlag("no-arrival-music") ) then 
						return
					end
				end

				if not isatmission_start and mn.getMissionTime() > 5 then

					local start_delay = 1.5 --also recall there is some fade time of main track before flourish starts
					--do not update amount until ship has fully arrived/departed/died, otherwise there is the following effect
					--hostile comes in from hyperspace, so very far away and hostile far tune starts, then 1 second later when closer hostile close starts
					--flourish needs to be >=1 second long, so that the following happens...
						--hostile ships appears very far away
						--3 seconds later it is still far away but track is updated and decides to play hostile far
						--1 second later hostile is close is it changes again
						--but if flourish is playing then main is paused, and main will not update/play when paused

					--check/set if ply
					local is_pship = false
					if Ship:isPlayer() then
						is_pship = true
					end

					self:FadeFlourish_Start(method_name, Ship.Radius, team, is_pship, start_delay)
				end

			end
		end

	end

	function DMusic:GetEpicIndex()

		--if only friendly then
			--if few friendlies->epic 0-1
			--if many friendlies->epic 1-2
		--if hostile then 
			--if hostile far away
				--if few hostiles->epic 2
				--if many hostiles->epic is 3
			--if hostile close 
				--few hostiles->epic is 3-4
				--many hostiles->epic 4-5

		local nships = self.num_ships
		local num_many = self.num_many_ships

		local hostiles_present = nships.Hostile > 0

		local many_hostiles = nships.Hostile >= num_many.Hostile
		local many_friendlies = nships.Friendly >= num_many.Friendly

		--find how far away hostiles are to player ship
		local hostiles_are_close = false

		if hostiles_present then
			if nships.Hostile >= (num_many.Hostile * 2.5) then
				--early out for massive missions
				hostiles_are_close = true
			else
				--otherwise check distances
				local hostile_distance_threshold = self.hostile_distance_threshold
				if hostile_distance_threshold <= 0 then
					--early out for always close
					hostiles_are_close = true
				else
					--even one hostile that's visible and nearby can be a good fight (setting as variable so configurable though)
					local ply = FotG:GetPlayerShip()
					if ply ~= nil and ply:isValid() then
						local ply_pos = ply.Position
						for ship in mn.getShipList() do
							if string.find(ship.Team.Name, "Hostile") ~= nil and not ship.Stealthed and not ship.HiddenFromSensors and ship:checkVisibility() > 0 then
								--recall check visibility returns: 0 - not visible, 1 - partially visible, 2 - fully visible
								if ply_pos:getDistance(ship.Position) < hostile_distance_threshold then
									--one nearby hostile is enough, so stop looking
									hostiles_are_close = true
									break
								end
							end
						end
					end
				end
			end
		end


		local l_epic_i
		if not hostiles_present then
			--only friendlies
			if many_friendlies then
				l_epic_i = 2
			else
				l_epic_i = 1
			end
		else
			--friendlies and hostiles
			if hostiles_are_close then
				if many_hostiles then
					l_epic_i = 5 --could be 4-5? now using +-1 range, so that we are not only hearing only 5s in larger battles
				else
					l_epic_i = 4 --could be a 3-4? now using +-1 range, so that we are not only hearing only 4s in smaller battles
				end
			else
				if many_hostiles then
					l_epic_i = 3
				else
					l_epic_i = 2
				end
			end
		end

		return l_epic_i or 0

	end


	function DMusic:UpdateTrack(new_epic_i) --choose new track based on epic i and play it

		self.battle_epic_i_current = new_epic_i

		--make a list of tracks that matches this epic level
		local match_tbl = {}
		local match_i = 1
		--go through all tracks and see if close epic i
		for k_trkname, v_trkinfo in pairs(self.DMusic_Track) do

			--get range of epic i options
			local low_opt = v_trkinfo.epic_score - 1
			local high_opt = v_trkinfo.epic_score + 1

			--clamp range
			if low_opt < 1 then low_opt = 1 end
			if high_opt > 5 then high_opt = 5 end

			if (new_epic_i >= low_opt) and (new_epic_i <= high_opt) then
				match_tbl[match_i] = k_trkname
				match_i = match_i + 1
			end
		end

		--how many options do we have?
		local num_options = #match_tbl
		--if none then return
		if num_options <= 0 then 
			ba.warning("DMusic error: no tracks available for epic_i of "..tostring(new_epic_i).."\n")
			return 
		end

		--if we do have some then pick a random one
		local chosen_trk_name = match_tbl[ba.rand32(1, num_options)]

		--now update values and play the track
		self:AudioPlay("DMusic_Track", chosen_trk_name, new_epic_i)

	end

	function DMusic:CheckCurrentTrack(mtime)

		--check every x interval, return early if interval not passed
		if mtime <= self.last_mtime_check + self.check_changes_interval then
			return
		end

		--save time check
		self.last_mtime_check = mtime

		--examine total numbers list and currently playing main track to see if it should be changed
		--main track might have been paused to play arrival flourish
		--if it is paused then don't do anything since the unpause function will also run this function

		--early out if flourish fade playing
		if self.current_audio.fade_flourish.effect_is_ongoing then 
			return
		end

		local current_track = self.current_audio.DMusic_Track

		--if this track it paused, see if unpause time is up
		if current_track.is_paused then 
			--should we finally unpause it?
			local mtime = mn.getMissionTime()
			if mtime > current_track.mtime_to_unpause then
				--pause time has passed, so unpause!
				self:AudioPause("DMusic_Track", false)
			else
				--pause still on going, so just jump out
				return
			end
		end

		--update track each time:
			--ship enters or gone, should probably check what it was before?
				--ie was it just another friendly ship doing something
				--was it a hostile ship but we are already playing battle music?
			--is our time up/track finish, and should we switch to another track?

		local new_epic_i = self:GetEpicIndex()

		--epic i changed or track is done, so force an update
		if self.battle_epic_i_current ~= new_epic_i or (mtime > current_track.mtime_to_music_end) then
			--change track
			self:UpdateTrack(new_epic_i)
		end

	end

	function DMusic:IntervalCheck()

		if self.is_active then

			local mtime = mn.getMissionTime()

			--run and check any fade flourishes
			self:FadeFlourish_Run(mtime)

			--check if we need to update, such as if we are within distance or other things
			self:CheckCurrentTrack(mtime)

			--debug print current track and epic index
			if self.print_debug then
				local y_start = 120
				local trk = self.current_audio.DMusic_Track
				gr.drawString("Current DMusic Epic Index: "..self.battle_epic_i_current, 10, y_start)
				gr.drawString("Current DMusic Flourish: "..self.current_audio.DMusic_Flourish.current_track_name, 10, y_start+20)
				gr.drawString("Current DMusic Track: "..trk.current_track_name.." with current volume of "..trk.volume_current, 10, y_start+40)
				gr.drawString("Current DMusic Track Is Paused: "..tostring(trk.is_paused), 10, y_start+60)
				gr.drawString("Current DMusic status of fade flourish: "..tostring(self.current_audio.fade_flourish.effect_is_ongoing), 10, y_start+80)
				gr.drawString("Current number of friendly ships in the mission: "..tostring(self.num_ships.Friendly), 10, y_start+120)
				gr.drawString("Current number of hostile ships in the mission: "..tostring(self.num_ships.Hostile), 10, y_start+140)
			end

		end

	end

	function DMusic:Debriefing_SetTrack(track_entry_name)

		if ba.MultiplayerMode then return end

		--this uses the entry name in the music.tbl file, not a file name!!

		if type(track_entry_name) ~= "string" then
			ba.print("Warning for Music Set Debrief Track, track name is not a string for "..tostring(track_entry_name).."\n")
			return 
		end

		mn.setMusicScore(SCORE_DEBRIEFING_SUCCESS, track_entry_name)
		mn.setMusicScore(SCORE_DEBRIEFING_AVERAGE, track_entry_name)
		mn.setMusicScore(SCORE_DEBRIEFING_FAILURE, track_entry_name)

	end

	mn.LuaSEXPs["set-dmusic-hostile-distance"].Action = function (number)

		DMusic:Set_CombatTrackDistance(number)

	end

	mn.LuaSEXPs["set-debriefing-music"].Action = function (trackname)

		DMusic:Debriefing_SetTrack(trackname)

	end

--

--Hooks
if not IS_STANDALONE then
	engine.addHook("On Gameplay Start", function() 
			DMusic:Mission_Setup()
		end
	)

	engine.addHook("On Mission About To End", function() 
			--only fade music when going to debrief
			DMusic:Reset_Everything(false)
		end
	)

	engine.addHook("On State Start", function() 
			--run each time coming back to game in-case player is updating their music levels
			DMusic:Update_ADMasterVolumer()
		end,
		{State="GS_STATE_GAME_PLAY"}
	)

	engine.addHook("On Frame", function() 
			DMusic:IntervalCheck()
		end,
		{State="GS_STATE_GAME_PLAY"}
	)

	engine.addHook("On Ship Arrive", function() 
			DMusic:UpdateShip(hv.Ship, 1, "arrive")
		end,
		{State="GS_STATE_GAME_PLAY"}
	)

	engine.addHook("On Ship Depart", function() 
			DMusic:UpdateShip(hv.Ship, -1, "depart")
		end,
		{State="GS_STATE_GAME_PLAY"}
	)

	engine.addHook("On Ship Death Started", function() 
			DMusic:UpdateShip(hv.Ship, -1, "death")
		end,
		{State="GS_STATE_GAME_PLAY"}
	)
end