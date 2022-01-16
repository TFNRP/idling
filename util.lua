DefaultConfig = {
  IdleResources = {},
  Restrict = {
    Server = false,
    Client = false,
    Stream = true,
    DataFile = true,
    ServerExport = false,
    ClientExport = false,
  },
  Verbose = false,
}

--- @param item any
--- @param array table<any, any>
--- @return boolean
function IsInTable(item, array)
  for _, value in pairs(array) do
    if item == value then
      return true
    end
  end
  return false
end

--- @param item any
--- @param array table<number, any>
--- @return number|false
function FindInArray(item, array)
  for key, value in pairs(array) do
    if item == value then
      return key
    end
  end
  return false
end

--- @return table<number, string>
function GetResourceNames()
  local array = {}
  for i = 0, GetNumResources() do
    local name = GetResourceByFindIndex(i)
    if name and name ~= GetCurrentResourceName() then
      table.insert(array, name)
    end
  end
  return array
end

--- @param str string
--- @param globs table<any, string>
--- @return boolean
function StringMatchesGlobs(str, globs)
  for _, glob in pairs(globs) do
    if str:match(globtopattern(glob)) then
      return true
    end
  end
  return false
end

--- Get the keys of a table
--- @param tb table<any, any>
--- @return table<number, any>
function GetTableKeys(tb)
  local keys = {}
  for key in pairs(tb) do
    table.insert(keys, key)
  end
  return keys
end

--- Deep apply function to table values
--- @param tb table<any, any>
--- @param func function
--- @return table<any, any>
function ApplyTable(tb, func, path)
  if not path then path = {} end
  local built = {}
  for key, value in pairs(tb) do
    if type(value) == 'table' then
      local newPath = path
      table.insert(newPath, key)
      built[key] = ApplyTable(value, func, newPath)
    else
      built[key] = func(key, value, tb, path)
    end
  end
  return built
end

--- Slice an array, like JavaScript Array.slice
--- @param array table<number, any>
--- @param sliceStart number
--- @param sliceEnd number
--- @return table<number, any>
function SliceArray(array, sliceStart, sliceEnd)
  if not sliceStart then sliceStart = 1 end
  if not sliceEnd then sliceEnd = #array end
  local sliced = {}
  for i = 1, #array do
    if i >= sliceStart and i <= sliceEnd then
      table.insert(sliced, array[i])
    end
  end
  return sliced
end

--- Checks if the directory exists
--- @param directory string
--- @return boolean
function DirectoryExists(directory)
  -- very hefty workaround, but i prefer this over io.rename
  if IsWindows() then
    local _, exitcode, code = os.execute('if exist "' .. directory .. '/" (exit -2) else exit -3')
    if exitcode ~= 'exit' then
      error('Shell was terminated.')
    end
    if code == -3 then
      return false
    elseif code == -2 then
      return true
    else
      error('Shell exited with an unexpected code ' .. code .. '.')
    end
  else -- assume this os is linux
    local _, exitcode, code = os.execute('if [ -d "' .. directory .. '" ]; then exit -2; else exit -3; fi')
      if exitcode ~= 'exit' then
        error('Shell was terminated.')
      end
      if code == -3 then
        return false
      elseif code == -2 then
        return true
      else
        error('Shell exited with an unexpected code ' .. code .. '.')
      end
  end
end

--- Whether this OS is Windows-based
--- @return boolean
function IsWindows()
  local env = os.getenv('OS')
  return env and env:lower():match('windows') and true or false
end

function warn(message)
  print('[Warn] ' .. message)
end

--- Boolean with the value of false
--- @alias false boolean