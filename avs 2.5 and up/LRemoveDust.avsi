# LRemoveDust by Didée
# 2020.05.20 HBD update
function LRemoveDust(clip input, int "mode", int "limit", int "climit")
{
limit=default(limit,4)
repmode = 2
clensed = Clense(input)
rep=Repair(clensed, input, mode=repmode)
rg = RemoveGrain(rep, mode=mode)
rd=TemporalRepair(rg, rep)
return sh_LimitChange(rd, input, limit, climit)
}