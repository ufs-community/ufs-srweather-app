undef("pause")
procedure pause()
local temp
begin
  print("Program paused.  Press <Enter> to continue.")
;  temp := systemfunc("read ANS; echo $ANS")
  temp := systemfunc("read ANS")
  print("Continuing ...")
end


