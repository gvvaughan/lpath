-- Higher level file operations in Lua.
--
-- Copyright (C) 2011 Gary V. Vaughan
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.

local M = require'path'

M.sep = package.config:sub (1, 1)

M.is_windows = M.sep == '\\'


-- Return the path of the current directory.
function M.getcwd ()
  return M.cd'.'
end


-- Create an empty file.
function M.touch (p)
  -- FIXME: Don't clobber atime, ctime *and* mtime with touch!
  local f, e = io.open (p, 'w')
  if f then
    f:close ()
    return true
  end
  return nil, e
end


-- Is P an absolute directory?
function M.isabs (p)
  if M.is_windows and
      (p:find ('^\\') or p:find ('^[A-Z]:\\')) then
    return true
  elseif p:sub (1, 1) == M.sep then
    return true
  end
  return false
end


-- Make an absolute path from the current directory.
function M.absname (p)
  if M.isabs (p) then
    return p
  end
  return M.join (M.getcwd (), p)
end


-- Split P into a table of directory (and file) components.
function M.split (p)
  r = {}
  if M.isabs (p) then
    r[1+ #r] = M.sep
  end
  p:gsub ('([^'..M.sep..']+)'..M.sep..'?',
      function (x) r[1+ #r] = x end)
  return r
end


-- Join argument list into a path.
-- To get a correct absolute path returned, use:
--   M.join (M.sep, p1, ...pN)
function M.join (...)
  local prefix = ''
  local t = {...}
  -- passing a single table of path components is valid, such as
  -- the output from M.split.
  if #t == 1 and type (t[1]) == "table" then t = t[1] end

  local r = {}
  for _, d in ipairs (t) do
    -- reset when an absolute path component is encountered
    if M.isabs (d) then
      if d == M.sep then prefix = M.sep end
      r = {}
    end
    r[1 +#r] = d
  end
  while r[1] == M.sep do
    table.remove (r, 1)
  end
  if r[1]:sub (1, 1) == M.sep then
    prefix = ''
  end
  return prefix..table.concat (r, M.sep)
end


-- Return the relative path from NEW to OLD.
function M.relative (old, new)
  local function common_dir (l1, l2, common)
    common = common or {}
    if #l1 < 1 then return common, l1, l2 end
    if #l2 < 1 then return common, l1, l2 end
    if l1[1] ~= l2[1] then return common, l1, l2 end
    common[1+ #common] = l1[1]
    table.remove (l1, 1)
    table.remove (l2, 1)
    return common_dir (l1, l2, common)
  end

  if not M.isabs (old) then old = M.join (M.getcwd (), old) end
  if not M.isabs (new) then new = M.join (M.getcwd (), new) end

  local r = {}
  local common, l1, l2 = common_dir (M.split (new), M.split (old))
  for i = 1, #l1 -1 do r[i] = '..' end
  for _, i in ipairs (l2) do r[1+ #r] = i end
  return M.join (unpack (r))
end


function M.ln (old, new, symlink)
  if symlink then
    old = M.relative (old, new)
  end
  return M.link (old, new, symlink)
end


-- Recursively remove a directory and its contents.
function M.remover (p)
  if not os.remove (p) then
    -- not a file or empty directory, so delete all contents...
    for file in M.dir (p) do
      if file ~= '.' and file ~= '..' then
        f = M.join (p, file)
        M.remover (f)
      end
    end
    -- ...and then remove it
    return os.remove (p)
  end

  -- initial remove attempt worked
  return true
end

return M
