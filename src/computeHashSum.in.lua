#!@path_to_lua@
-- -*- lua -*-

--------------------------------------------------------------------------
-- Fixme
-- @script computeHashSum

--------------------------------------------------------------------------
-- Lmod License
--------------------------------------------------------------------------
--
--  Lmod is licensed under the terms of the MIT license reproduced below.
--  This means that Lmod is free software and can be used for both academic
--  and commercial purposes at absolutely no cost.
--
--  ----------------------------------------------------------------------
--
--  Copyright (C) 2008-2018 Robert McLay
--
--  Permission is hereby granted, free of charge, to any person obtaining
--  a copy of this software and associated documentation files (the
--  "Software"), to deal in the Software without restriction, including
--  without limitation the rights to use, copy, modify, merge, publish,
--  distribute, sublicense, and/or sell copies of the Software, and to
--  permit persons to whom the Software is furnished to do so, subject
--  to the following conditions:
--
--  The above copyright notice and this permission notice shall be
--  included in all copies or substantial portions of the Software.
--
--  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
--  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
--  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
--  NONINFRINGEMENT.  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
--  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
--  ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
--  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
--  THE SOFTWARE.
--
--------------------------------------------------------------------------

------------------------------------------------------------------------
-- Use command name to add the command directory to the package.path
------------------------------------------------------------------------
local sys_lua_path = "@sys_lua_path@"
if (sys_lua_path:sub(1,1) == "@") then
   sys_lua_path = package.path
end

local sys_lua_cpath = "@sys_lua_cpath@"
if (sys_lua_cpath:sub(1,1) == "@") then
   sys_lua_cpath = package.cpath
end

package.path   = sys_lua_path
package.cpath  = sys_lua_cpath

local arg_0    = arg[0]
_G._DEBUG      = false
local posix    = require("posix")
local readlink = posix.readlink
local stat     = posix.stat

local st       = stat(arg_0)
while (st.type == "link") do
   local lnk = readlink(arg_0)
   if (arg_0:find("/") and (lnk:find("^/") == nil)) then
      local dir = arg_0:gsub("/[^/]*$","")
      lnk       = dir .. "/" .. lnk
   end
   arg_0 = lnk
   st    = stat(arg_0)
end

local ia,ja = arg_0:find(".*/")
local LuaCommandName_dir = "./"
if (ia) then
   LuaCommandName_dir = arg_0:sub(1,ja)
end

package.path  = LuaCommandName_dir .. "../tools/?.lua;"      ..
                LuaCommandName_dir .. "../tools/?/init.lua;" ..
                LuaCommandName_dir .. "../shells/?.lua;"     ..
                LuaCommandName_dir .. "?.lua;"               ..
                sys_lua_path
package.cpath = LuaCommandName_dir .. "../lib/?.so;"..
                sys_lua_cpath

function cmdDir()
   return LuaCommandName_dir
end

Version = "1.0"
require("strict")
require("myGlobals")
require("utils")
require("fileOps")
require("capture")
MainControl   = require("MainControl")
MCPQ          = false
MCP           = false
mcp           = false
require("modfuncs")
require("cmdfuncs")
require("parseVersion")

BaseShell         = require("BaseShell")
Hub            = require("Hub")

local FrameStk    = require("FrameStk")
local MT          = require("MT")
local MName       = require("MName")
local Optiks      = require("Optiks")
local cosmic      = require("Cosmic"):singleton()
local concatTbl   = table.concat
local dbg         = require("Dbg"):dbg()
local fh          = nil
local getenv      = os.getenv
local s_optionTbl = {}

function optionTbl()
   return s_optionTbl
end


function main()
   __removeEnvMT()  -- Wipe the ModuleTable in the environment so that it doesn't pollute isloaded()!
   local hub       = Hub:singleton(false)
   local frameStk  = FrameStk:singleton()
   local shellNm   = "bash"
   _G.Shell        = BaseShell:build(shellNm)
   local tmpfn     = os.tmpname()
   fh              = io.open(tmpfn,"w")
   local i         = 1
   local optionTbl = optionTbl()

   options()

   if (optionTbl.debug) then
      dbg:activateDebug(1, tonumber(optionTbl.indentLevel))
   end
   dbg.start{"computeHashSum()"}

   ------------------------------------------------------------------
   -- initialize lmod with SitePackage and /etc/lmod/lmod_config.lua
   initialize_lmod()

   MCP           = MainControl.build("computeHash","load")
   MCPQ          = MainControl.build("computeHash","load")
   mcp           = MainControl.build("computeHash","load")

   local fn     = optionTbl.pargs[1]
   local entryT = {sn = optionTbl.sn, userName = optionTbl.userName, fn = fn,
                   version = extractVersion(optionTbl.fullName, optionTbl.sn)}
   local mname = MName:new("entryT", entryT)
   dbg.print{"fullName: ",mname:fullName(),", userName: ",mname:userName()," optionTbl.fullName: ", optionTbl.fullName,"\n"}

   frameStk:push(mname)
   loadModuleFile{file=fn, shell=shellNm, reportErr=true, forbiddenT = {}}
   frameStk:pop()
   local s = concatTbl(ShowResultsA,"")
   dbg.textA{name="Text to Hash for: "..optionTbl.fullName, a=ShowResultsA}

   if (optionTbl.verbose) then
      io.stderr:write(s)
   end
   fh:write(s)
   fh:close()
   local HashSum = cosmic:value("LMOD_HASHSUM_PATH")

   if (HashSum == nil) then
      LmodSystemError{msg="e_Failed_Hashsum"}
   end

   local result = capture(HashSum .. " " .. tmpfn)
   os.remove(tmpfn)
   ia = result:find(" ")
   dbg.print{"hash value: ",result:sub(1,ia-1),"\n"}
   print (result:sub(1,ia-1))
   dbg.fini("computeHashSum")
end

function options()
   local optionTbl = optionTbl()
   local usage         = "Usage: computeHashSum [options] file"
   local cmdlineParser = Optiks:new{usage=usage, version=Version}

   cmdlineParser:add_option{
      name   = {'-v','--verbose'},
      dest   = 'verbosityLevel',
      action = 'count',
   }
   cmdlineParser:add_option{
      name   = {'--fullName'},
      dest   = 'fullName',
      action = 'store',
      help   = "Full name of the module file"
   }


   cmdlineParser:add_option{
      name   = {'--userName'},
      dest   = 'userName',
      action = 'store',
      help   = "User name of the module file"
   }

   cmdlineParser:add_option{
      name   = {'--MODULEPATH'},
      dest   = 'mpath',
      action = 'store',
      help   = "The current MODULEPATH"
   }

   cmdlineParser:add_option{
      name   = {'--sn'},
      dest   = 'sn',
      action = 'store',
      help   = "shortname of the module file"
   }

   cmdlineParser:add_option{
      name   = {'-D','-d','--debug'},
      dest   = 'debug',
      action = 'store_true',
      default = false,
      help    = "debug flag"
   }
   cmdlineParser:add_option{
      name   = {'--indentLevel'},
      dest   = 'indentLevel',
      action = 'store',
      default = "0",
      help    = "indent level for Dbg"
   }



   local optTbl, pargs = cmdlineParser:parse(arg)

   for v in pairs(optTbl) do
      optionTbl[v] = optTbl[v]
   end
   optionTbl.pargs = pargs

end

main()
