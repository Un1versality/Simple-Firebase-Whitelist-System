local CurrentLicencee = ""


local FirebaseService = {};


local UseFirebase = true;


local defaultDatabase = ""; -- Set your database link


local authenticationToken = ""; -- Authentication Token


local HttpService = game:GetService("HttpService");


local DataStoreService = game:GetService("DataStoreService");



local GroupService = game:GetService("GroupService")



local FirebaseService = {}



function FirebaseService:SetUseFirebase(value)


	UseFirebase = value and true or false;


end



function FirebaseService:GetFirebase(name, database)


	database = database or defaultDatabase;


	local datastore = DataStoreService:GetDataStore(name);



	local databaseName = database..HttpService:UrlEncode(name);


	local authentication = ".json?auth="..authenticationToken;



	local Firebase = {};



	--[[**


		A method to get a datastore with the same name and scope.


		@returns GlobalDataStore GlobalDataStore


	**--]]


	function Firebase.GetDatastore()


		return datastore;


	end



	--[[**


		Returns the value of the entry in the database JSON Object with the given key.


		@param directory string Directory of the value that you are look for. E.g. "PlayerSaves" or "PlayerSaves/Stats".


		@returns FirebaseService FirebaseService


	**--]]


	function Firebase:GetAsync(directory)


		local data = nil;



		--== Firebase Get;


		local getTick = tick();


		local tries = 0; repeat until pcall(function() tries = tries +1;


			data = HttpService:GetAsync(databaseName..HttpService:UrlEncode(directory and "/"..directory or "")..authentication, true);


		end) or tries > 2;


		if type(data) == "string" then


			if data:sub(1,1) == '"' then


				return data:sub(2, data:len()-1);


			elseif data:len() <= 0 then


				return nil;


			end


		end


		return tonumber(data) or data ~= "null" and data or nil;


	end



	--[[**


		Sets the value of the key. This overwrites any existing data stored in the key.


		@param directory string Directory of the value that you are look for. E.g. "PlayerSaves" or "PlayerSaves/Stats".


		@param value variant Value can be any basic data types. It's recommened you HttpService:JSONEncode() your values before passing it through.


		@param header table Optional HTTPRequest Header overwrite. Default is {["X-HTTP-Method-Override"]="PUT"}.


	**--]]


	function Firebase:SetAsync(directory, value, header)


		if not UseFirebase then return end


		if value == "[]" then self:RemoveAsync(directory); return end;



		--== Firebase Set;


		header = header or {["X-HTTP-Method-Override"]="PUT"};


		local replyJson = "";


		if type(value) == "string" and value:len() >= 1 and value:sub(1,1) ~= "{" and value:sub(1,1) ~= "[" then


			value = '"'..value..'"';


		end


		local success, errorMessage = pcall(function()


			replyJson = HttpService:PostAsync(databaseName..HttpService:UrlEncode(directory and "/"..directory or "")..authentication, value,


				Enum.HttpContentType.ApplicationUrlEncoded, false, header);


		end);


		if not success then


			warn("FirebaseService>> [ERROR] "..errorMessage);


			pcall(function()


				replyJson = HttpService:JSONDecode(replyJson or "[]");


			end)


		end


	end



	--[[**


		Removes the given key from the data store and returns the value associated with that key.


		@param directory string Directory of the value that you are look for. E.g. "PlayerSaves" or "PlayerSaves/Stats".


	**--]]


	function Firebase:RemoveAsync(directory)


		if not UseFirebase then return end


		self:SetAsync(directory, "", {["X-HTTP-Method-Override"]="DELETE"});


	end



	--[[**


		Increments the value of a particular key and returns the incremented value.


		@param directory string Directory of the value that you are look for. E.g. "PlayerSaves" or "PlayerSaves/Stats".


		@param delta number The incrementation rate.


	**--]]


	function Firebase:IncrementAsync(directory, delta)


		delta = delta or 1;


		if type(delta) ~= "number" then warn("FirebaseService>> increment delta is not a number for key ("..directory.."), delta(",delta,")"); return end;


		local data = self:GetAsync(directory) or 0;


		if data and type(data) == "number" then


			data = data+delta;


			self:SetAsync(directory, data);


		else


			warn("FirebaseService>> Invalid data type to increment for key ("..directory..")");


		end


		return data;


	end



	--[[**


		Retrieves the value of a key from a data store and updates it with a new value.


		@param directory string Directory of the value that you are look for. E.g. "PlayerSaves" or "PlayerSaves/Stats".


		@param callback function Works similarly to Roblox's GlobalDatastore:UpdateAsync().


	**--]]


	function Firebase:UpdateAsync(directory, callback)


		local data = self:GetAsync(directory);


		local callbackData = callback(data);


		if callbackData then


			self:SetAsync(directory, callbackData);


		end


	end



	return Firebase;


end



local GameOwnerFunctions = {}


GameOwnerFunctions.GetOwnerUserId = function()


	if game.CreatorType == Enum.CreatorType.User then


		return game.CreatorId


	elseif game.CreatorType == Enum.CreatorType.Group then


		local Group


		local A,B = pcall(function()


			Group = GroupService:GetGroupInfoAsync(game.CreatorId)


		end)


		if B then


			if string.find(string.lower(B),"error") then


				for i,v in ipairs(game.Players:GetPlayers()) do


					v:Kick("[WhitelistSystem] HTTP Error detected. Please contact game owner to report the bug. May also be a roblox error.")


				end


				return


			end


		end


		local OwnerName = Group.Owner.Name


		local OwnerId = Group.Owner.Id


		return OwnerId


	end


end





local database = FirebaseService:GetFirebase("WhitelistSystemDatabaseLicences");


local database2 = FirebaseService:GetFirebase("UnlicensedDatabase")


local GainedUserId = GameOwnerFunctions.GetOwnerUserId()


local getData = database:GetAsync(GainedUserId)



local UnlicensedDetection = {}


UnlicensedDetection.Detect = function(Msg)


	local tosend = {


		UserId = GainedUserId,


		PlaceId = game.PlaceId,


		Message = Msg


	}


	database2:SetAsync("UNLICENSED_DETECTED_" .. tosend.UserId,HttpService:JSONEncode(tosend))


end



if getData == nil then


	warn("[WhitelistSystem] Unlicensed version detected!")


	UnlicensedDetection.Detect("No Licence")


	script.Parent.Parent.Parent.Parent:Destroy()


	return


elseif getData ~= nil then


	local decode = game:GetService("HttpService"):JSONDecode(getData)



	if decode.IsValid == true then


		game:GetService("LocalizationService"):SetAttribute("WhitelistSystem",decode.Licence)


		CurrentLicence = decode.Licence


		script.Parent.ECR.Value = decode.Licence


		CurrentLicencee = decode.Licence


	else


		warn("[WhitelistSystem] Unlicensed version detected!")


		UnlicensedDetection.Detect("No Licence")


		script.Parent.Parent.Parent.Parent:Destroy()


		return


	end


end



local Whitelist__RBX


if not game:GetService("ReplicatedStorage"):FindFirstChild("Whitelist__RBX") then


	repeat


		wait()


	until game:GetService("ReplicatedStorage"):FindFirstChild("Whitelist__RBX")


end


Whitelist__RBX = game:GetService("ReplicatedStorage"):FindFirstChild("Whitelist__RBX")


local RequesterRemote


local TranslatorModule


if not Whitelist__RBX:FindFirstChild("PublicModules") then


	repeat


		wait()


	until Whitelist__RBX:FindFirstChild("PublicModules")


end


if not Whitelist__RBX:FindFirstChild("PublicModules"):FindFirstChild("Translator") then


	repeat wait()


		


	until Whitelist__RBX:FindFirstChild("PublicModules"):FindFirstChild("Translator")


end


TranslatorModule = require(Whitelist__RBX:FindFirstChild("PublicModules"):FindFirstChild("Translator"))


if not Whitelist__RBX:FindFirstChild("RequesterRemote") then


	repeat


		wait()


	until Whitelist__RBX:FindFirstChild("RequesterRemote")


end


RequesterRemote = Whitelist__RBX:FindFirstChild("RequesterRemote")


RequesterRemote.OnServerInvoke = function(Player,SentInfo,SentInfo2)


	if string.lower(SentInfo) == "mmqkrrrrrrr" then


		if game:GetService("LocalizationService"):GetAttribute("WhitelistSystem") then


			local Value = game:GetService("LocalizationService"):GetAttribute("WhitelistSystem")


			if Value == CurrentLicencee then


				return true


			end


			if Value ~= CurrentLicencee then


				warn("[WhitelistSystem] Unlicensed version detected!")


				UnlicensedDetection.Detect("No Licence")


				script.Parent.Parent.Parent.Parent:Destroy()


				return


			end


		elseif not game:GetService("LocalizationService"):GetAttribute("WhitelistSystem") then


			warn("[WhitelistSystem] Unlicensed version detected!")


			UnlicensedDetection.Detect("No Licence")


			script.Parent.Parent.Parent.Parent:Destroy()


			return


		end


	end


end
