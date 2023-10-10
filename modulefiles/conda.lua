help([[
]])

local pkgName = myModuleName()
local pkgVersion = myModuleVersion()
local shell=myShellType()

conflict(pkgName)

local mod_path, mod_file = splitFileName(myFileName())
local conda_loc_file = pathJoin(mod_path, "..", "conda_loc")
local base = capture("cat " .. conda_loc_file)
local conda_file = pathJoin(base, "etc", "profile.d", "conda." .. shell)
local command = "source " .. conda_file

local level


execute{cmd=command, modeA={"load", "unload"}}

if mode() == "unload" then

  level=tonumber(os.getenv("CONDA_SHLVL"))

  while (level > 0) do
    execute{cmd="conda deactivate", modeA={"unload"}}
    level = level - 1
  end


  if shell == "csh" then
    execute{cmd="unalias conda", modeA={"unload"}}
    command = "unsetenv CONDA_EXE CONDA_PYTHON_EXE CONDA_SHLVL _CE_CONDA"
  else
    execute{cmd="unset conda", modeA={"unload"}}
    command = "unset CONDA_EXE CONDA_PYTHON_EXE CONDA_SHLVL _CE_CONDA"
  end
  execute{cmd=command, modeA={"unload"}}
  remove_path("PATH", pathJoin(base, "condabin"))
  remove_path("MANPATH", pathJoin(base, "share", "man"))
end

prepend_path("PATH",            pathJoin(base, "bin"))
prepend_path("LD_LIBRARY_PATH", pathJoin(base, "lib"))
