#!/usr/bin/env lua

os.path = require'lpath'

local tmp    = '/tmp'
local upper  = '..'
local OLDPWD = '.'

--print (os.path._VERSION)

ln    = os.path.ln
mkdir = os.path.mkdir
rm    = os.remove
stat  = os.path.attributes
touch = os.path.touch

dirsep = os.path.sep

function pwd () return os.path.cd'.' end

function cd (pathname)
  assert (pathname)
  if '-' == pathname then pathname = OLDPWD end
  OLDPWD = pwd ()
  return os.path.cd (pathname)
end

function attrdir (pathname)
  for file in os.path.dir (pathname) do
    if file ~= '.' and file ~= '..' then
      local f = pathname..dirsep..file
      print ('\t=> '..f..' <=')
      local attr = os.path.attributes (f)
      assert (type (attr) == 'table')
      if attr.mode == 'directory' then
        attrdir (f)
      else
        for name, value in pairs (attr) do
          print (name, value)
        end
      end
    end
  end
end


-- Checking changing directories.

local current = assert (pwd ())
assert (cd (upper), 'could not change to upper directory')
assert (cd '-', 'could not change back to current directory')
assert (pwd () == current, 'error trying to change directories')
assert (cd "this couldn't be an actual directory" == nil, 'could change to a non-existent directory')

-- Creating paths.
assert (os.path.join ('a') == 'a')
assert (os.path.join ('a', 'b') == 'a'..dirsep..'b')
assert (os.path.join ('a', 'b', 'c') == 'a'..dirsep..'b'..dirsep..'c')
assert (os.path.join (pwd (), 'a') == pwd ()..dirsep..'a')
assert (os.path.join (dirsep, pwd (), 'a') == pwd ()..dirsep..'a')
assert (os.path.join (dirsep, 'a') == dirsep..'a')
assert (os.path.join (dirsep, dirsep, 'a') == dirsep..'a')
assert (os.path.join ('a', dirsep, 'b') == dirsep..'b')
assert (os.path.join ('a', dirsep, dirsep, 'b') == dirsep..'b')
assert (os.path.join ('a', pwd ()) == pwd ())

-- splitting and joining

assert (os.path.join (os.path.split (current)) == current)


-- Creating and removing directories.

local tmpdir = os.path.join (current, 'tmp_dir')
local tmpsubdir = os.path.join (tmpdir, 'tmp_subdir')
local tmpfile = os.path.join (tmpdir, 'tmp_file')
-- Test for existence of a previous file_tmp_dir
if cd (tmpdir) then
  -- that may have resulted from an interrupted test execution and remove it
  assert (cd (upper), 'could not change to upper directory')
  assert (rm (tmpfile), 'could not remove file from previous test') 
  assert (rm (tmpdir), 'could not remove directory from previous test')
end
-- tries to create a directory
assert (mkdir (tmpdir), 'could not make a new directory')
local attrib, errmsg = os.path.attributes (tmpdir)
if not attrib then
  error ('could not get attributes of file `'..tmpdir.."':\n"..errmsg)
end
assert (touch (tmpfile), 'could not create an empty file')

-- Relative paths
assert (os.path.relative ('a', 'x') == 'a')
assert (os.path.relative ('a/b', 'x') == 'a/b')
assert (os.path.relative ('a', 'x/y') == '../a')
assert (os.path.relative ('a/b', 'x/y') == '../a/b')
assert (os.path.relative ('a/b', 'a/x') == 'b')

assert (os.path.relative ('../a', 'x') == '../a')
assert (os.path.relative ('../a/b', 'x') == '../a/b')
assert (os.path.relative ('../a', 'x/y') == '../../a')
assert (os.path.relative ('../a/b', 'x/y') == '../../a/b')
assert (os.path.relative ('../a/b', '../a/x') == 'b')

local here = pwd ():sub (2)
assert (os.path.relative ('a', '/x') == here..'/a')
assert (os.path.relative ('a/b', '/x') == here..'/a/b')
assert (os.path.relative ('a', '/x/y') == '../'..here..'/a')
assert (os.path.relative ('a/b', '/x/y') == '../'..here..'/a/b')
assert (os.path.relative ('/a/b', '/a/x') == 'b')

local there = pwd ():gsub(dirsep..'[^'..dirsep..']*', '..'..dirsep)
assert (os.path.relative ('/a', 'x') == there..'a')
assert (os.path.relative ('/a/b', 'x') == there..'a/b')
assert (os.path.relative ('/a', 'x/y') == there..'../a')
assert (os.path.relative ('/a/b', 'x/y') == there..'../a/b')

-- Checking symbolic link information
local symlink = '_a_link_for_test_'
rm (symlink)
assert (ln (tmpfile, symlink, true))
assert (stat (symlink).type == 'link')
assert (stat (os.path.readlink (symlink)).type == 'file')
assert (rm (symlink))

-- Remove new file and directory
assert (rm (tmpfile), 'could not remove new file')
assert (rm (tmpdir), 'could not remove new directory')
assert (mkdir (os.path.join (tmpdir, 'file_tmp_dir')) == nil, 'could create a directory inside a non-existent one')

-- Recursive removal.
assert (mkdir (tmpdir), 'could not create new directory')
assert (touch (tmpfile), 'could not create an empty file')
assert (os.path.remover (tmpfile), 'could not recursively remove file')
assert (touch (tmpfile), 'could not create an empty file')
assert (os.path.remover (tmpdir), 'could not recursively remove non-empty dir')
assert (os.path.mkdirr (tmpsubdir), 'could not recursively make directory')
assert (touch (tmpfile), 'could not create an empty file')
assert (os.path.remover (tmpdir), 'could not recursively remove subdir tree')

-- Trying to get attributes of a non-existent file
assert (stat "this couldn't be an actual file" == nil, 'could get attributes of a non-existent file')
assert (type (stat (upper)) == 'table', "couldn't get attributes of upper directory")

-- Stressing directory iterator
count = 0
for i = 1, 4000 do
  for file in os.path.dir (tmp) do
    count = 1+ count
  end
end

-- Stressing directory iterator, explicit version
count = 0
for i = 1, 4000 do
  local iter, dir = os.path.dir (tmp)
  local file = dir:next ()
  while file do
    count = 1+ count
    file = dir:next ()
  end
  assert (not pcall (dir.next, dir))
end

-- directory explicit close
local iter, dir = os.path.dir (tmp)
dir:close ()
assert (not pcall (dir.next, dir))

print'Ok!'
