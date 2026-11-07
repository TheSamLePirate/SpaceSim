	-- Common Functions
	function math.round(input_number, numDecimalPlaces) --if no number of decimals is specified then it defaults to 0

		numDecimalPlaces = numDecimalPlaces or 0

		if numDecimalPlaces > 0 then
			local mult = 10^numDecimalPlaces
			return math.floor(input_number * mult + 0.5) / mult
		else
			return math.floor(input_number + 0.5)
		end

	end

	function math.equalAny(num, array) --takes single level array for list of options to match whole value

		local result = false
		if array ~= nil and num ~= nil then
			if #array >= 1 then
				for i=1,#array do
					if num == array[i] then
						result = true
						break
					end
				end
			end
		end
		return result

	end

	function math.Number_to_Table_Index(num, tbl_len)

		-- for example
		--local tbl = {1,2,3,4,5}
		--local num = 7
		--Num_to_tlb(num, tbl_len) -> 2

		--negative is last entry
		--ie -1 is last entry in table
		--0 is 1

		if num <= 0 then return tbl_len end

		local tbl_index
		if tbl_len > 1 then
			--number longer then table
			if num > tbl_len then
				local rem = num % tbl_len
				if rem == 0 then
					tbl_index = tbl_len
				else
					tbl_index = rem
				end
			else
				--number is within table bounds so just look it up
				tbl_index = num
			end
		else
			--only 1 entry in table so just return that
			tbl_index = 1
		end

		return tbl_index

	end

	function math.MM_iTable(nlist, method) --returns either "max" or "min" of a flat i list of numbers

		local final = 1
		if type(nlist) == "number" then
			final = nlist
		end
		if type(nlist) == "table" and (method == "max" or method == "min") then
			if #nlist > 0 then
				table.sort(nlist)
				if method == "min" then
					final = nlist[1]
				end
				if method == "max" then
					final = nlist[#nlist]
				end
			end
		end
		return final

	end

	function math.GetEntryIndex_from_iTable(list, value_to_find, key_to_match)

		local existing_i
		for i,v in ipairs(list) do
			local current_val

			if key_to_match ~= nil then
				current_val = v[key_to_match]
			else
				key_to_match = v
			end

			if current_val == value_to_find then
				existing_i = i
				break
			end
		end

		return existing_i

	end

	function math.Table_Shuffle(t)

		---Takes an i-based table and returns a new table with the contents in random order.
		---param t table I-based table to shuffle 
		---return table new table with shuffled contents 

		local len_tbl = #t
		local tbl = {}

		--shortcuts 0
		if len_tbl == 0 then
			return tbl
		end

		for i = 1, len_tbl do
			tbl[i] = t[i]
		end

		--shortcut 1
		if len_tbl == 1 then
			return tbl
		end

		--long way
		for i = len_tbl, 2, -1 do
			local j = ba.rand32(1, i)
			tbl[i], tbl[j] = tbl[j], tbl[i]
		end
		return tbl

	end

	function math.Get_Random_iKeys(tbl, runs) --takes a table, gets the i-keys and spits out an array with them in a random order

		runs = runs or 20
		local randarray = {}
		local numrand= #tbl
		for i=1,numrand do
			randarray[i] = i
		end
		for _=1,runs do
			local random1 = ba.rand32(1, numrand)
			local random2 = ba.rand32(1, numrand)
			randarray[random1], randarray[random2] = randarray[random2], randarray[random1]
		end

		return randarray

	end

	function math.Random_Weighted(tbl)  --tbl is in form {{"thing1", 30}, {"thing2", 40}, {"thing3"}}

		--list weights should be in integer percent, ranging from 0 to 100, should not use decimals
		--if not present, weights are random uniform

		--validity checks
		if tbl == nil then
			print("Error: Random_Weighted() was given a nil value...\n")
			return nil
		end
		if type(tbl) ~= "table" then
			print("Error: Random_Weighted() was given a value ("..tostring(tbl)..") that was not a table...\n")
			return tbl
		end

		local num_tbl = #tbl
		if num_tbl < 0 then
			print("Error: Random_Weighted() was given a table with no values...\n")
			return nil
		end

		local sum_of_weights = 0

		--To select among weighted events, you compute a random value from 0 to the sum of the weights:
		--(Depending on how you generate your percent you could possibly skip this calculation step, if, for instance, you know it will always add up to one)

		local default_weight = math.round(1/num_tbl)*100
		for _,v in pairs(tbl) do
			if type(v) ~= "table" then
				print("Error: the table input for Random_Weighted() does not contain a sub table...\n")
				break
			end
			if #v <= 0 then
				print("Error: the table input for Random_Weighted() does not have a value...\n")
				break
			end
			local weight = v[2] or default_weight
			sum_of_weights = sum_of_weights + weight
		end

		--We then look at our list and can think of it as a number line. 
		--Each item 'owns' a portion of the line from 0 to total weight, and at is some random place in between. 
		--To find which place, we can do something like this:

		local selection = ba.rand32f() * sum_of_weights
		local selection_ikey = 0
		--print("sum_of_weights: "..sum_of_weights)
		--print("selection: "..selection)
		for i,v in ipairs(tbl) do
			local weight = v[2] or default_weight
			--local result = selection - math.ceil(weight)
			--print("weight of "..weight.." for "..v[1].." with result of "..result)
			if selection <= weight then
				selection_ikey = i
				break
			end
			selection = selection - weight
		end

		if selection_ikey <= 0 then
			print("Error: could not find a value for Random_Weighted(), picking the first one by default..\n")
			selection_ikey = 1
		end

		return tbl[selection_ikey][1]

	end

	function math.Random_fromTable(tbl) --takes a flat i-list and returns a random value in that list

		if type(tbl) == "table" then
			local randomi = ba.rand32(1, #tbl)
			return tbl[randomi]
		else
			return tbl
		end

	end

	function math.Random_Magnitude(low, high)

		if type(low) == "number" and type(high) == "number" then
			local min = math.min(low, high)
			local max = math.max(low, high)
			local sign = 1
			if ba.rand32(1,2) == 1 then sign = -1 end
			return ba.rand32(min,max)*sign
		else
			print("RandomMagnitude given non number values, returning 0...\n")
			return nil
		end

	end

	function math.Random_Sign()

		---Pick random sign
		---@return number either -1 or 1

		return (ba.rand32(0, 1)*2) - 1

	end

	function math.Number_Sign(n)

		-- get sign of number
		-- -1 if negative, 1 if positive, and 0 if 0
		return n > 0 and 1 or (n < 0 and -1 or 0)

	end

	function math.Calculate_Percentage(val_current, val_start, val_end)

		---Calculates percent progress from start number to the end number given current number
		---param val_current number Current value to get percentage of
		---param val_start number Starting/minimum value of range 
		---param val_end number Ending/maximum value of range 
		---return number percent number, decimal

		return (val_current - val_start) / (val_end - val_start)

	end

	function math.Lerp(val_start, val_end, delta)

		---Performs a linear interpolation from the start number to the end number
		---param val_start number Starting value (value if delta = 0)
		---param val_end number Ending value (value if delta = 1)
		---param delta number Percentage to lerp from starting to end value
		---return number lerped number

		if ( delta > 1 ) then return val_end end
		if ( delta < 0 ) then return val_start end

		return val_start + ( val_end - val_start ) * delta

	end

	function math.Clamp(value, min, max)

		---Clamps number between min and max
		---param value number Value to clamp
		---param min number Minimum value allowed
		---param max number Maximum value allowed
		---return number clamped number

		if value < min then
			return min
		end
		if value > max then
			return max
		end
		return value

	end

	function string.findAny(str, array) --takes single level array for list of options to match within string

		local result = false
		if array ~= nil and str ~= nil then
			if #array >= 1 then
				for i=1,#array do
					if string.find(str, tostring(array[i])) ~= nil then
						result = true
						break
					end
				end
			end
		end
		return result

	end

	function string.equalAny(str, array) --takes single level array for list of options to match whole string

		local result = false
		if array ~= nil and str ~= nil then
			if #array >= 1 then
				for i=1,#array do
					if str == tostring(array[i]) then
						result = true
						break
					end
				end
			end
		end
		return result

	end

	function string.filterInvisible(str, chr, extra_find_arg, extra_offset)

		chr = chr or "#"

		if extra_find_arg == nil then
			extra_find_arg = true
		end

		if extra_offset == nil then
			extra_offset = 1
		end

		local index = str:find(chr, 0, extra_find_arg)
		if (index ~= nil) then
			str = str:sub(1, index - extra_offset)
		end
		return str

	end

	function string.List_Table_as_String(list_tbl, tbl_uses_str_keys)

		local list
		if tbl_uses_str_keys then
			list = {}
			local i = 0
			for _,v in pairs(list_tbl) do
				i = i + 1
				list[i] = v
			end
		else
			list = list_tbl
		end

		local n = #list
		if n == 0 then
			return ""
		elseif n == 1 then
			return (list[1])
		elseif n == 2 then
			return (list[1] .. " and " .. list[2])
		else
			local str = ""
			for i = 1, n - 1 do
				str = str .. list[i] .. ", "
			end
			str = str .. "and " .. list[n]
			return (str)
		end

	end
