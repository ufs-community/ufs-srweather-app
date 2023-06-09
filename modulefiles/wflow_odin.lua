help([[
This module loads python environement for running the UFS SRW App on
the NSSL machine Odin
]])

whatis([===[Loads libraries needed for running the UFS SRW App on Odin ]===])

load("set_pythonpath")

if mode() == "load" then
  -- >>> conda initialize >>>
  -- !! Contents within this block are managed by 'conda init' !!
  local shell=myShellType()
  local conda_path="/scratch/software/Odin/python/anaconda2"
  local conda_file
  if shell == "csh" then
    conda_file=pathJoin(conda_path,"conda.csh")
  else
    conda_file=pathJoin(conda_path,"conda.sh")
  end

  local exit_code = os.execute('test -f'..conda_file)
  if exit_code == 0 then
    local mcmd="source " .. conda_file
    execute{cmd=mcmd, modeA={"load"}}
  else
    prepend_path("PATH", pathJoin(conda_path,"bin"))
  end
  -- <<< conda initialize <<<

  LmodMsgRaw([===[Please do the following to activate conda:
      > conda config --set changeps1 False
      > conda activate workflow_tools
  ]===])
end
