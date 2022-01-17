-- validate config
if type(Config) ~= 'table' then
  error('Config must be type of table, got "' .. type(Config) .. '".', 0)
end
ApplyTable(Config, function (key, _, _, path)
  local default = DefaultConfig
  for _, key in pairs(path) do
    default = default[key]
  end
  if type(key) ~= 'number' and default and type(default[key]) == 'nil' then
    error('Config' .. (path[1] and '.' .. table.concat(path, '.') or '') .. ' contains invalid key, "' .. key .. '".', 0)
  end
end)
if type(Config.IdleResources) ~= 'table' then
  error('Config.IdleResources must be type of table, got "' .. type(Config.IdleResources) .. '".', 0)
end
for key, value in pairs(Config.IdleResources) do
  if type(key) ~= 'number' then
    error('Config.IdleResources[k] must be type of number, got "' .. type(key) .. '".', 0)
  end
  if type(value) ~= 'string' then
    error('Config.IdleResources[' .. key .. '] must be type of string, got "' .. type(value) .. '".', 0)
  end
end
if not IsInTable(type(Config.Verbose), { 'boolean', 'nil' }) then
  error('Config.Verbose must be type of boolean or nil, got "' .. type(Config.Verbose) .. '".', 0)
end

-- set defaults
Config = ApplyTable(Config, function (_, value, _, path)
  if type(value) == 'nil' then
    local default = DefaultConfig
    for _, key in pairs(path) do
      default = default[key]
    end
    return default
  else
    return value
  end
end)

-- globals
--- The table of currently idling resources
--- @type table<number, string>
local idling = {}
local function info () end
if Config.Verbose then
  info = function (message)
    print('[Verbose] ' .. message)
  end
end

collectgarbage()

function StartIdling()
  info('Starting resource idling')
  local resources = GetResourceNames()
  local promises = {}
  for _, resource in pairs(resources) do
    if IsInTable(GetResourceState(resource), { 'started', 'starting' }) and StringMatchesGlobs(resource, Config.IdleResources) then
      if GetResourceMetadata(resource, 'idling_ignore') then
        info('Ignoring ' .. resource .. ' due to "idling_ignore" field in manifest.')
        goto continue
      end

      -- don't apply restrictions to explicit resources
      if not IsInTable(resource, Config.IdleResources) then
        if Config.Restrict.Client and GetResourceMetadata(resource, 'client_script') then
          info('Ignoring ' .. resource .. ' due to containing client scripts.')
          goto continue
        end
        if Config.Restrict.Server and GetResourceMetadata(resource, 'server_script') then
          info('Ignoring ' .. resource .. ' due to containing server scripts.')
          goto continue
        end
        if (Config.Restrict.Client or Config.Restrict.Server) and GetResourceMetadata(resource, 'shared_script') then
          info('Ignoring ' .. resource .. ' due to containing shared scripts.')
          goto continue
        end
        if Config.Restrict.DataFile and GetResourceMetadata(resource, 'data_file') then
          info('Ignoring ' .. resource .. ' due to containing data files.')
          goto continue
        end
        if Config.Restrict.Stream then
          local sucess, result = pcall(function ()
            return DirectoryExists(GetResourcePath(resource) .. '/stream')
          end)
          if not sucess then
            warn(
              'Couldn\'t figure out if resource contained streamed assets, ignoring ' .. resource
              .. ' anyway. Error: ' .. result and tostring(result) or '(No error)'
            )
            goto continue
          elseif result then
            info('Ignoring ' .. resource .. ' due to containing streamed assets.')
            goto continue
          end
        end
        if Config.Restrict.ClientExport and GetResourceMetadata(resource, 'export') then
          info('Ignoring ' .. resource .. ' due to containing client exports.')
          goto continue
        end
        if Config.Restrict.ServerExport and GetResourceMetadata(resource, 'server_export') then
          info('Ignoring ' .. resource .. ' due to containing server exports.')
          goto continue
        end
        if GetResourceMetadata(resource, 'loadscreen') then
          info('Ignoring ' .. resource .. ' due to being a loadscreen.')
          goto continue
        end
        if GetResourceMetadata(resource, 'this_is_a_map') then
          info('Ignoring ' .. resource .. ' due to being a map.')
          goto continue
        end
      end

      StopResource(resource)
      table.insert(promises, resource)
      table.insert(idling, resource)
    end
    ::continue::
  end

  -- await resources
  info('Awaiting ' .. #promises .. ' idled resources to fully stop')
  for _, promise in pairs(promises) do
    -- abort controller for 30 seconds
    local abort = 3e4
    while GetResourceState(promise) == 'stopping' do
      abort = abort - 10
      if abort <= 0 then break end
      Wait(10)
    end
    if abort <= 0 then
      warn('Resource ' .. promise .. ' took to long to idle (' .. GetResourceState(promise) .. ')')
    elseif GetResourceState(promise) ~= 'stopped' then
      warn('Resource ' .. promise .. ' did not stop when asked to idle (' .. GetResourceState(promise) .. ')')
    else
      info('Resource ' .. promise .. ' is now idle (' .. GetResourceState(promise) .. ')')
    end
  end
end

function StopIdling()
  local promises = {}
  for k, resource in pairs(idling) do
    StartResource(resource)
    table.insert(promises, resource)
    table.remove(idling, k)
  end
  for _, promise in pairs(idling) do
    -- abort controller for 30 seconds
    local abort = 3e4
    while GetResourceState(promise) == 'starting' do
      abort = abort - 10
      if abort <= 0 then break end
      Wait(10)
    end
    if abort <= 0 then
      warn('Resource ' .. promise .. ' took to long to start (' .. GetResourceState(promise) .. ')')
    elseif GetResourceState(promise) ~= 'started' then
      warn('Resource ' .. promise .. ' did not start when recovering (' .. GetResourceState(promise) .. ')')
    else
      info('Resource ' .. promise .. ' has been recovered (' .. GetResourceState(promise) .. ')')
    end
  end
end

Citizen.CreateThread(function()
  info('Waiting for resources to start...')
  for _, resource in pairs(GetResourceNames()) do
    while GetResourceState(resource) == 'starting' do
      Wait(10)
    end
  end
  info('All resources have started')

  if GetNumPlayerIndices() <= 0 then
    StartIdling()
  end

  AddEventHandler('onResourceStop', function (name)
    if GetCurrentResourceName() == name then
      if #idling > 0 then
        warn('Notice: Stopping PMARP Idling whilst resources are being managed by PMARP Idling is not recommended and will not be supported in the future.')
        StopIdling()
      end
    end
  end)

  AddEventHandler('onResourceStart', function (name)
    local index = FindInArray(name, idling)
    if index then
      table.remove(idling, index)
    end
  end)

  AddEventHandler('playerConnecting', function ()
    StopIdling()
  end)

  AddEventHandler('playerDropped', function ()
    if GetNumPlayerIndices() <= 0 then
      StartIdling()
    end
  end)

  RegisterCommand('idling_start', function (source, args)
    if GetNumPlayerIndices() > 0 and (type(args[0]) ~= 'string' or args[0]:lower() ~= 'force') then
      local message = 'Cannot start idling with a player count. Use `idling_start force` to ignore.'
      warn('idling_start: ' .. message)
      if type(source) == 'number' then
        TriggerClientEvent('chat:addMessage', source, { args = { message } })
      end
    else
      StartIdling()
    end
  end, true)

  RegisterCommand('idling_stop', function (source)
    if not (#idling > 0) then
      local message = 'No resources are idling.'
      warn('idling_stop: ' .. message)
      if type(source) == 'number' then
        TriggerClientEvent('chat:addMessage', source, { args = { message } })
      end
    else
      StopIdling()
    end
  end, true)

  RegisterCommand('idling_status', function (source)
    local message
    if not (#idling > 0) then
      message = 'No resources are idling.'
    else
      message = #idling .. ' resources are idling: ' .. table.concat(idling, ', ')
    end
    warn('idling_status: ' .. message)
    if type(source) == 'number' then
      TriggerClientEvent('chat:addMessage', source, { args = { message } })
    end
  end, true)
end)