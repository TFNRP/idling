Config = {
  --- Resources which will be managed by PMARP Idling.
  --- Supports RegExp strings.
  --- @example
  --- IdleResources = {
  ---   '*', -- will match all resources
  ---   '!(core)*', -- will match all resources except beginning with "core"
  ---   'core*', -- will only match resources beginning with "core"
  ---   'vMenu', -- matches the resources named "vMenu"
  --- }
  --- @type table<number, string>
  --- @default table<[1]: '*'>
  IdleResources = {
    '*'
  },

  Restrict = {
    --- Whether resources containing server scripts should not be managed by PMARP Idling.
    --- @type boolean|nil
    --- @default false
    Server = false,

    --- Whether resources containing client scripts should not be managed by PMARP Idling.
    --- @type boolean|nil
    --- @default false
    Client = false,

    --- Whether resources containing streamed assets should not be managed by PMARP Idling.
    --- @type boolean|nil
    --- @default true
    Stream = true,

    --- Whether resources containing data files should not be managed by PMARP Idling.
    --- @type boolean|nil
    --- @default true
    DataFile = true,

    --- Whether resources containing any server exports should not be managed by PMARP Idling.
    --- @type boolean|nil
    --- @default false
    ServerExport = false,

    --- Whether resources containing any client exports should not be managed by PMARP Idling.
    --- @type boolean|nil
    --- @default false
    ClientExport = false,
  },

  --- Whether to write additional info to stdout.
  --- @type boolean|nil
  --- @default false
  Verbose = true,
}