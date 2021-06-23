ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

Citizen.CreateThread(function()
	Citizen.Wait(1000)
	local players = ESX.GetPlayers()

	for _,playerId in ipairs(players) do
		local xPlayer = ESX.GetPlayerFromId(playerId)

		MySQL.Async.fetchAll('SELECT status, health, armor FROM users WHERE identifier = @identifier', {
			['@identifier'] = xPlayer.identifier
		}, function(result)
			local data = {}

			if result[1].status then
				data = json.decode(result[1].status)
			end
			if result[1].health then
				health = result[1].health
			end
			if result[1].armor then
				armor = result[1].armor
			end

			xPlayer.set('status', data)
			TriggerClientEvent('esx_status:load', playerId, data, armor, health)
		end)
	end
end)

AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
	MySQL.Async.fetchAll('SELECT status, health, armor, identifier, citizenid FROM users WHERE identifier = @identifier', {
		['@identifier'] = xPlayer.identifier
	}, function(result)
		local data = {}

		if result[1].status then
			data = json.decode(result[1].status)
		end
		if result[1].health then
			health = result[1].health
		end
		if result[1].armor then
			armor = result[1].armor
		end
		if result[1].citizenid then
			cid = result[1].citizenid
		else
			cid = GenerateCid()
			CreateCid(cid, xPlayer.identifier)
		end

		xPlayer.set('status', data)
		TriggerClientEvent('esx_status:load', playerId, data, armor, health, cid)
	end)
end)

AddEventHandler('esx:playerDropped', function(playerId, reason)
	local xPlayer = ESX.GetPlayerFromId(playerId)
	local status = xPlayer.get('status')

	MySQL.Async.execute('UPDATE users SET status = @status WHERE identifier = @identifier', {
		['@status']     = json.encode(status),
		['@identifier'] = xPlayer.identifier
	})
end)

AddEventHandler('esx_status:getStatus', function(playerId, statusName, cb)
	local xPlayer = ESX.GetPlayerFromId(playerId)
	local status  = xPlayer.get('status')

	for i=1, #status, 1 do
		if status[i].name == statusName then
			cb(status[i])
			break
		end
	end
end)

RegisterServerEvent('esx_status:update')
AddEventHandler('esx_status:update', function(status, updateArmour, updateHealth)
	local xPlayer = ESX.GetPlayerFromId(source)

	if xPlayer then
		xPlayer.set('status', status)

		MySQL.Async.execute("UPDATE users SET health = @health, armor = @armor WHERE identifier = @identifier", { 
			['@identifier'] = xPlayer.identifier,
			['@health'] = tonumber(updateHealth),
			['@armor'] = tonumber(updateArmour)
			armor = ['@armor']
		})	
	end
			
	if armor >=100 then
	--Mysql.Async.FetchAll("SELECT playername, armor FROM users WHERE @armor >= 100")
			print("Ban")
		else		
			print("failed")
		end	
end)


local NumberCharset = {}
local Charset = {}

for i = 48,  57 do table.insert(NumberCharset, string.char(i)) end

for i = 65,  90 do table.insert(Charset, string.char(i)) end
for i = 97, 122 do table.insert(Charset, string.char(i)) end

function CreateCid(citizenid,identifier)
	MySQL.Async.execute("UPDATE users SET citizenid = @citizenid WHERE identifier = @identifier", {
		['@citizenid'] = citizenid,
		['@identifier'] = identifier
	})
end

function GenerateCid()
    local citizenid = tostring(GetRandomLetter(3)) .. tostring(GetRandomNumber(5))
    MySQL.Async.fetchAll("SELECT * FROM users WHERE citizenid = @citizenid", {
		["@citizenid"] = citizenid
	}, function(result)
        while (result[1] ~= nil) do
            citizenid = tostring(GetRandomLetter(3)) .. tostring(GetRandomNumber(5))
        end
        return citizenid
    end)
    return string.upper(citizenid)
end

function GetRandomNumber(length)
	Citizen.Wait(1)
	math.randomseed(GetGameTimer())
	if length > 0 then
		return GetRandomNumber(length - 1) .. NumberCharset[math.random(1, #NumberCharset)]
	else
		return ''
	end
end

function GetRandomLetter(length)
	Citizen.Wait(1)
	math.randomseed(GetGameTimer())
	if length > 0 then
		return GetRandomLetter(length - 1) .. Charset[math.random(1, #Charset)]
	else
		return ''
	end
end

function SaveData()
	local xPlayers = ESX.GetPlayers()

	for i=1, #xPlayers, 1 do
		local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
		local status  = xPlayer.get('status')

		MySQL.Async.execute('UPDATE users SET status = @status WHERE identifier = @identifier', {
			['@status']     = json.encode(status),
			['@identifier'] = xPlayer.identifier
		})
	end

	SetTimeout(10 * 60 * 1000, SaveData)
end

SaveData()
