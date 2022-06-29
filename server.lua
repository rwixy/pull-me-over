ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

RegisterServerEvent('pullmeover:speedingticket')
AddEventHandler('pullmeover:speedingticket', function(src)
	local src = source
	local xPlayer = ESX.GetPlayerFromId(source)
	xPlayer.removeAccountMoney('bank', 500)
end)
