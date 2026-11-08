-- ======================================================================================
-- AURORE - EVASION : cinematic director (mission _SPT_Aurore_Evasion)
-- GR-75 "Aurore" takes off at the canyon entrance and must build speed through the whole
-- canyon while Red squadron destroys the Imperial ground defences (real targets, real hits).
-- In orbit: three Star Destroyers arrive, TIEs launch, the Death Star rises over the limb,
-- fires its superlaser and destroys the planet. The cargo, the wingmen and the player jump.
-- ======================================================================================
local V=ba.createVector
local C=V(0,-80000,0)
local R=80000
CINE={active=false}   -- global: read by spacesim-flight (player control) and spacesim-game (AI avoidance)
local function length(v) return math.sqrt(v.x*v.x+v.y*v.y+v.z*v.z) end
local function unit(v) local d=length(v);if not (d>1e-6) then return V(0,0,1) end;return V(v.x/d,v.y/d,v.z/d) end
local function dot(a,b) return a.x*b.x+a.y*b.y+a.z*b.z end
local function cross(a,b) return V(a.y*b.z-a.z*b.y,a.z*b.x-a.x*b.z,a.x*b.y-a.y*b.x) end
local function vlerp(a,b,t) return V(a.x+(b.x-a.x)*t,a.y+(b.y-a.y)*t,a.z+(b.z-a.z)*t) end
local function clamp(x,a,b) return math.max(a,math.min(b,x)) end
local function sstep(e0,e1,x) local t=clamp((x-e0)/(e1-e0),0,1);return t*t*(3-2*t) end
local function ok(o) return o and o:isValid() end
local function valleyX(z) return 650*math.sin(z/2700)+180*math.sin(z/730) end
local function isDead(name)
    if SPACESIM and SPACESIM.stream and SPACESIM.stream.list then
        for _,e in ipairs(SPACESIM.stream.list) do if e.name==name then return e.dead==true end end
    end
    local sh=mn.Ships[name];return not (sh and sh:isValid()) or sh:isDying()
end
local function log(m) if SPACESIM then SPACESIM.record('CINE '..m) end end

-- ---------------------------------------------------------------- spline (centripetal Catmull-Rom)
local function catmull(p0,p1,p2,p3,u)
    local function knot(ti,a,b) return ti+math.sqrt(math.max(length(b-a),1e-3)) end
    local t0=0;local t1=knot(t0,p0,p1);local t2=knot(t1,p1,p2);local t3=knot(t2,p2,p3)
    local t=t1+(t2-t1)*u
    local A1=p0*((t1-t)/(t1-t0))+p1*((t-t0)/(t1-t0))
    local A2=p1*((t2-t)/(t2-t1))+p2*((t-t1)/(t2-t1))
    local A3=p2*((t3-t)/(t3-t2))+p3*((t-t2)/(t3-t2))
    local B1=A1*((t2-t)/(t2-t0))+A2*((t-t0)/(t2-t0))
    local B2=A2*((t3-t)/(t3-t1))+A3*((t-t1)/(t3-t1))
    return B1*((t2-t)/(t2-t1))+B2*((t-t1)/(t2-t1))
end
local function buildPath(P)
    local tab={};local acc=0;local prev=P[1]
    local function pt(i) return P[math.max(1,math.min(#P,i))] end
    for i=1,#P-1 do
        local steps=math.max(8,math.floor(length(P[i+1]-P[i])/25))
        for k=0,steps-1 do
            local q=catmull(pt(i-1)+(i==1 and (P[1]-P[2]) or V(0,0,0)),P[i],P[i+1],pt(i+2)+(i+2>#P and (P[#P]-P[#P-1]) or V(0,0,0)),k/steps)
            acc=acc+length(q-prev);prev=q;tab[#tab+1]={s=acc,p=q,seg=i}
        end
    end
    tab[#tab+1]={s=acc+length(P[#P]-prev),p=P[#P],seg=#P-1}
    return {tab=tab,L=tab[#tab].s}
end
local function sample(path,sv)
    local tab=path.tab
    if sv<=0 then return tab[1].p end
    if sv>=path.L then local n=#tab;return tab[n].p+(tab[n].p-tab[n-1].p)*((sv-path.L)/math.max(1,tab[n].s-tab[n-1].s)) end
    local lo,hi=1,#tab
    while hi-lo>1 do local m=math.floor((lo+hi)/2);if tab[m].s<sv then lo=m else hi=m end end
    return vlerp(tab[lo].p,tab[hi].p,(sv-tab[lo].s)/math.max(1e-3,tab[hi].s-tab[lo].s))
end
local function segS(path,seg) local s0=0;for _,e in ipairs(path.tab) do if e.seg<seg then s0=e.s end end;return s0 end

-- ---------------------------------------------------------------- subtitles
local SUBS={
    {1.0,8.0,'ECHO BASE','Aurore, ici Echo. Trois destroyers stellaires viennent de sortir de l\'hyperespace. Evacuez immediatement.'},
    {8.5,5.0,'AURORE','Bien recu, Echo. Reacteurs chauds... on decolle.'},
    {13.5,5.5,'ROUGE 1','Escadron Rouge, on ouvre la route ! Je prends les cibles au centre.'},
    {21.0,5.0,'ECHO BASE','Aurore, prenez de la vitesse dans le canyon, sinon vous n\'atteindrez jamais l\'orbite.'},
    {29.0,4.5,'ROUGE 3','Je prends la batterie de gauche !'},
    {38.0,5.0,'AURORE','On encaisse ! Boucliers avant a soixante pour cent...'},
    {46.0,4.5,'ROUGE 2','Les AT-AT ! Torpilles a protons parees.'},
    {58.0,5.0,'ROUGE 1','Le canyon est degage. Aurore, plein gaz, on vous couvre !'},
    {68.0,5.0,'AURORE','Vitesse de liberation dans trente secondes... tenez bon.'},
}
local function drawSubs(T)
    for _,sb in ipairs(CINE.subs) do
        if sb[2]>0 and T>=sb[1] and T<sb[1]+sb[2] then
            local a=math.min(1,(T-sb[1])/0.4,(sb[1]+sb[2]-T)/0.4)
            local w,h=gr.getScreenWidth(),gr.getScreenHeight()
            local line=sb[4]
            local tw=gr.getStringWidth(line)
            local nw=gr.getStringWidth(sb[3])
            local y=h-118
            gr.setColor(0,0,0,math.floor(140*a));gr.drawRectangle((w-tw)/2-18,y-26,(w+tw)/2+18,y+20,true)
            gr.setColor(255,205,90,math.floor(255*a));gr.drawString(sb[3],(w-nw)/2,y-20)
            gr.setColor(235,240,245,math.floor(255*a));gr.drawString(line,(w-tw)/2,y)
        end
    end
end

-- ---------------------------------------------------------------- setup
local TARGET_HP=260      -- one well-placed torpedo (500) or a short laser burst destroys a target
local function isTargetName(n)
    return n:find('^Batterie') or n:find('^AT%-AT') or n:find('^Bunker') or n:find('^Hangar') or n:find('^Caserne') or n:find('^Tour de') or n:find('^Reservoirs') or n=='Lambda Ombre'
end
function CINE.init()
    local T0=mn.getMissionTime()
    local c={t0=T0,phase='camp',s=0,stats={},targets={},shots=0,nextShot=T0+2,boom=0,xs={{},{},{},{}},frags={}}
    CINE.c=c;CINE.active=true
    -- gameplay mode (mission _SPT_Aurore_Evasion_Jeu*): 10 s intro, then the player flies; jeubot flag = scripted player
    local fname=mn.getMissionFilename():lower()
    c.play=fname:find('_jeu')~=nil
    c.bot=c.play and cf.fileExists('spacesim-jeubot.flag','data',true)
    c.cargo=mn.Ships['Aurore']
    -- multiplayer: the server directs (cargo, targets, AI, mission phases); clients mirror it from the synced cargo
    c.server=(not ba.MultiplayerMode) or multi.isServer()
    c.netPhase=0
    -- mn.Ships[missing] is an INVALID HANDLE (truthy), not nil: test it with ok()
    local names=ok(mn.Ships['Rouge 1']) and {'Rouge 1','Rouge 2','Rouge 3','Rouge 4'} or {'Red 1','Rouge 2','Rouge 3','Rouge 4'}
    c.names=names;c.xw={};for k,n in ipairs(names) do c.xw[k]=mn.Ships[n] end
    c.cargoStart=c.cargo.Position;c.cargoStartOri=c.cargo.Orientation
    c.subs={};for _,sb in ipairs(SUBS) do c.subs[#c.subs+1]=sb end;CINE.subs=c.subs
    SPACESIM.state.cine=true
    local vig=mn.Ships['Vigilance'];if ok(vig) then vig:vanish() end
    for i=1,#mn.Ships do
        local sh=mn.Ships[i]
        if ok(sh) and sh.Team.Name=='Hostile' and isTargetName(sh.Name) then c.targets[#c.targets+1]={name=sh.Name,pos=sh.Position,z=sh.Position.z} end
    end
    table.sort(c.targets,function(a,b) return a.z<b.z end)
    -- cargo path: lift-off, canyon centre line 110 m above ground, climb, orbit escape
    local P={}
    P[#P+1]=c.cargoStart+unit(c.cargoStart-C)*70
    local ground={}
    for z=c.cargoStart.z+250,4400,150 do local x=valleyX(z);ground[#ground+1]=SPACESIM.surface(V(x,3000,z)) or V(x,700,z) end
    for i=1,#ground do
        local hi=-1e9
        for j=math.max(1,i-4),math.min(#ground,i+4) do hi=math.max(hi,ground[j].y) end
        P[#P+1]=V(ground[i].x,hi+110,ground[i].z)
    end
    for pass=1,3 do for i=3,#P-1 do P[i]=vlerp(P[i],(P[i-1]+P[i+1])*0.5,0.5) end end
    c.nCanyon=#P
    local last=P[#P];local d=unit(P[#P]-P[#P-1]);local up=unit(last-C)
    local climbPts={last+d*1500+up*350,last+d*4500+up*2600,last+d*9000+up*9000,V(4000,30000,6000),V(9000,62000,2000),V(14000,86000,-2000),V(17000,92500,1500)}
    -- gameplay: leave the valley steeply (the cinematic keeps its long, low exit)
    if c.play then climbPts[1]=last+d*1400+up*700;climbPts[2]=last+d*3800+up*3800 end
    for _,q in ipairs(climbPts) do P[#P+1]=q end
    c.nClimb=#P
    for _,q in ipairs({V(18800,93200,5200),V(19800,93600,9800),V(20200,93700,15500),V(20100,93500,22000),V(19500,93200,30000)}) do P[#P+1]=q end
    c.path=buildPath(P)
    c.Lc=segS(c.path,c.nCanyon);c.La=segS(c.path,c.nClimb)
    -- targets along the path: the player takes every other one, the wingmen share the rest
    local wing=2
    for k,tg in ipairs(c.targets) do
        local best,bs=0,1e18
        for _,e in ipairs(c.path.tab) do if e.seg<c.nCanyon then local dd=length(e.p-tg.pos);if dd<bs then bs=dd;best=e.s end end end
        tg.s=best
        if tg.name:find('^Batterie') then tg.who=1 else tg.who=wing;wing=wing+1;if wing>4 then wing=2 end end
    end
    if c.play then CINE.placeArrivals(c) end
    SPACESIM.setSun(0.085,0.12)
    hu.HUDDrawn=false
    c.cam=gr.createCamera('cine',c.cargo.Position,c.cargo.Orientation);gr.setCamera(c.cam)
    c.tex={glow=gr.loadTexture('ss_glow',true),orange=gr.loadTexture('ss_glow_orange',true),fire=gr.loadTexture('ss_glow_fire',true),blue=gr.loadTexture('ss_glow_blue',true),white=gr.loadTexture('ss_glow_white',true),boom=gr.loadTexture('Exp_Det_Shp_01_Gld',true)}
    for k,x in ipairs(c.xw) do if ok(x) then x:setFlag(true,'no-dynamic');c.xs[k].pos=x.Position;c.xs[k].vel=V(0,0,0) end end
    c.canyonOnly=cf.fileExists('spacesim-cinecanyon.flag','data',true)
    if cf.fileExists('spacesim-cinefin.flag','data',true) then c.t0=T0-10;c.s=c.La-4000;c.finOnly=true end
    log(string.format('START targets=%d path_km=%.1f canyon_km=%.1f climb_km=%.1f',#c.targets,c.path.L/1000,c.Lc/1000,c.La/1000))
end

local function cargoSpeed(c,s)
    if c.play then
        -- gameplay: slower in the canyon (X-wings ahead of it), the climb is capped by the players' envelope
        local v=40+120*math.pow(clamp(s/c.Lc,0,1),1.1)
        v=v+(4200-160)*sstep(c.Lc,c.Lc+(c.La-c.Lc)*0.18,s)
        v=v-(4200-110)*sstep(c.La-12000,c.La-300,s)
        local h=c.cargoAlt or 0
        return math.min(v,0.8*(200+4000*sstep(1000,16000,h)))
    end
    local v=40+260*math.pow(clamp(s/c.Lc,0,1),1.25)
    v=v+(4200-300)*sstep(c.Lc,c.Lc+(c.La-c.Lc)*0.18,s)
    v=v-(4200-110)*sstep(c.La-(c.La-c.Lc)*0.28,c.La,s)
    return v
end
local function isDead(name)
    if SPACESIM.stream and SPACESIM.stream.list then
        for _,e in ipairs(SPACESIM.stream.list) do if e.name==name then return e.dead==true end end
    end
    local sh=mn.Ships[name];return not (sh and sh:isValid()) or sh:isDying()
end
-- keeps a scripted ship alive: hull floor + invulnerable once damaged (a missile salvo can deal more
-- than the remaining hull within one frame, before any per-frame floor can react). Impacts stay visible.
local function guard(sh,frac)
    if not (ok(sh) and sh.HitpointsMax>0) then return end
    if sh.HitpointsLeft<sh.HitpointsMax*frac then sh.HitpointsLeft=sh.HitpointsMax*frac end
    if sh.HitpointsLeft<sh.HitpointsMax*(frac+0.1) and not sh:getFlag('invulnerable') then sh:setFlag(true,'invulnerable') end
end
local function setShip(sh,pos,fwd,up,vel)
    sh.Position=pos;sh.Physics.Velocity=vel;sh.Orientation=ba.createOrientationFromVectors(fwd,up)
end


-- Solid aim point: open-frame models (FotG Defense Satellite) are empty at their centre, so
-- cast rays at the hull from the shooter and keep the nearest point that is really solid.
local function solidAim(sh,from)
    local o=sh.Orientation;local cpos=sh.Position
    local r=math.max(10,sh.Radius*0.6)
    local cand={V(0,0,0),V(0,-0.45,0),V(0,0.35,0),V(0.4,0,0),V(-0.4,0,0),V(0,0,0.4),V(0,0,-0.4),V(0,-0.7,0),V(0.25,-0.25,0.25),V(-0.25,-0.25,-0.25)}
    for _,cdx in ipairs(cand) do
        local q=cpos+o:getRvec()*(cdx.x*r)+o:getUvec()*(cdx.y*r)+o:getFvec()*(cdx.z*r)
        local far=from+unit(q-from)*(length(q-from)+r*3)
        local hit=sh:checkRayCollision(from,far)
        if hit then return hit end
    end
    return nil
end


-- smallest height of the segment a->b above the terrain (ignores the last 60 m around the target)
local function fireClearance(a,b)
    local L=length(b-a);local n=math.max(6,math.floor(L/120));local best=1e9
    for i=1,n-1 do
        local q=a+(b-a)*(i/n)
        if length(b-q)>60 then
            local g=SPACESIM.surface(q)
            if g then local h=length(q-C)-length(g-C);if h<best then best=h end end
        end
    end
    return best
end
-- Real projectiles fired by the script: converged lasers from the 4 wingtip cannons and a guided
-- proton torpedo. (Fired through ship:firePrimary() a scripted X-wing shoots 4 parallel bolts
-- 11 m apart with no convergence: they straddle narrow targets.)
local GUNS={V(5.3,1.8,2.2),V(-5.3,-1.8,2.2),V(5.3,-1.8,2.2),V(-5.3,1.8,2.2)}
local function fireLasers(x,aim,pair)
    local cls=tb.WeaponClasses['T&B KX-9'];if not cls then return end
    local o=x.Orientation
    for i=(pair or 0)*2+1,(pair or 0)*2+2 do
        local g=GUNS[i]
        local gp=x.Position+o:getRvec()*g.x+o:getUvec()*g.y+o:getFvec()*g.z
        local d=unit(aim-gp)
        local w=mn.createWeapon(cls,ba.createOrientationFromVectors(d,o:getUvec()),gp,x,-1)
        if w and w:isValid() then w.Physics.Velocity=d*1600+x.Physics.Velocity end
    end
end
local function fireTorpedo(x,target,aim)
    local cls=tb.WeaponClasses['Krupx MG7-A#Pnk'];if not cls then return nil end
    local o=x.Orientation
    local lp=x.Position+o:getUvec()*(-1.2)+o:getFvec()*4
    local d=unit(aim-lp)
    local w=mn.createWeapon(cls,ba.createOrientationFromVectors(d,o:getUvec()),lp,x,-1)
    if w and w:isValid() then
        w.Physics.Velocity=d*280+x.Physics.Velocity
        w.Target=target;w.HomingObject=target;w.HomingPosition=aim
    end
    return w
end
-- ---------------------------------------------------------------- aircraft flight model (scripted X-wings)
-- Chases a moving goal point with limited acceleration; the nose follows the velocity and the
-- wings bank into the turn (coordinated turn), like an aircraft in the atmosphere.
local function fly(xs,goal,vgoal,dt,maxAcc,fallbackFwd,avoid)
    xs.vel=xs.vel or vgoal
    if avoid then
        -- terrain avoidance: never let the goal (or the aircraft) sink below 90 m above the ground
        xs.gT=(xs.gT or 0)-dt
        if xs.gT<=0 then
            xs.gT=0.25
            local look=xs.pos+xs.vel*1.2
            local g1=SPACESIM.surface(look);local g2=SPACESIM.surface(goal)
            xs.groundAhead=g1 and (length(g1-C)) or nil;xs.groundGoal=g2 and length(g2-C) or nil
        end
        local function lift(p,gr)
            if gr then local r=length(p-C);if r<gr+90 then return p+unit(p-C)*(gr+90-r) end end
            return p
        end
        goal=lift(goal,xs.groundGoal)
        local ahead=xs.pos+xs.vel*1.2
        if xs.groundAhead and length(ahead-C)<xs.groundAhead+90 then
            goal=goal+unit(xs.pos-C)*(xs.groundAhead+140-length(ahead-C))*2;vgoal=vgoal+unit(xs.pos-C)*120
        end
    end
    local acc=(goal-xs.pos)*1.1+(vgoal-xs.vel)*2.0
    local a=length(acc);if a>maxAcc then acc=acc*(maxAcc/a) end
    xs.vel=xs.vel+acc*dt;xs.pos=xs.pos+xs.vel*dt
    local sp=length(xs.vel)
    local fwd=sp>25 and unit(xs.vel) or (fallbackFwd or V(0,0,1))
    xs.fwd=xs.fwd and unit(vlerp(xs.fwd,fwd,1-math.exp(-dt*6))) or fwd
    local radial=unit(xs.pos-C)
    local lat=acc-xs.fwd*dot(acc,xs.fwd)
    local latH=lat-radial*dot(lat,radial)                 -- turning acceleration only (no push/pull)
    local bank=math.min(math.atan(length(latH)/9.81),math.rad(60))
    local upT=radial
    if length(latH)>0.2 then upT=unit(radial*math.cos(bank)+unit(latH)*math.sin(bank)) end
    xs.up=xs.up and unit(vlerp(xs.up,upT,1-math.exp(-dt*3.5))) or upT
end

-- ---------------------------------------------------------------- orbit actors
local function spawnISDs(c)
    local p=c.cargo.Position;local f=unit(sample(c.path,c.s+2000)-p);local u=unit(p-C);local r=unit(cross(u,f))
    c.isds={}
    for k=1,3 do
        local pos=p+f*(14000+k*2500)+r*((k-2)*7000)+u*(900*(k-2)+1500)
        local sh=mn.createShip('Destroyer '..({'Chimere','Tyran','Vengeance'})[k],tb.ShipClasses['Imperial Star Destroyer'],ba.createOrientationFromVectors(unit(p-pos),u),pos,mn.Teams['Hostile'],false)
        if ok(sh) then sh:warpIn();c.isds[#c.isds+1]=sh end
    end
    log('ARRIVAL isd='..#c.isds)
end
local function spawnTIEs(c)
    c.ties={}
    for k,isd in ipairs(c.isds or {}) do
        if ok(isd) then
            for j=1,4 do
                local cls=(j<=2) and 'TIE/ln Fighter' or 'TIE/In Interceptor'
                local pos=isd.Position+isd.Orientation:getUvec()*(-260)+isd.Orientation:getRvec()*((j-2.5)*120)+isd.Orientation:getFvec()*350
                local t=mn.createShip(string.format('TIE %d-%d',k,j),tb.ShipClasses[cls],isd.Orientation,pos,mn.Teams['Hostile'],false)
                if ok(t) then if j%2==0 then t:giveOrder(ORDER_ATTACK,c.cargo) else t:giveOrder(ORDER_ATTACK_ANY) end;c.ties[#c.ties+1]=t end
            end
        end
    end
    log('TIES launched='..#c.ties)
end
local function deathStarFrame(c,theta)
    local pos=C+(c.dsU1*math.cos(theta)+c.dsU2*math.sin(theta))*145000
    local t=unit(C-pos);local h=unit(cross(t,V(1,0,0)))
    local side=unit(cross(t,h));local upw=unit(cross(side,t))
    local a=math.rad(32)
    return pos,ba.createOrientationFromVectors(t*math.cos(a)-upw*math.sin(a),t*math.sin(a)+upw*math.cos(a))
end
local function superlaser(c,T)
    local ds=mn.Props['Etoile Noire'];if not ok(ds) then return end
    local o=ds.Orientation
    local dish=unit(o:getUvec()*0.53+o:getFvec()*0.85)
    local focus=ds.Position+dish*(15000*1.10)
    c.impact=c.impact or (C+unit(focus-C)*80500)
    local impact=c.impact
    local tc=T-c.tFire
    if tc<5.5 then
        local side=unit(cross(dish,o:getRvec()));local side2=unit(cross(dish,side))
        local w=sstep(0,1.2,tc)*(1-sstep(5.0,5.5,tc))
        for k=0,7 do
            local a=k*math.pi/4
            local rim=ds.Position+dish*(15000*0.94)+(side*math.cos(a)+side2*math.sin(a))*15000*0.17
            gr.setColor(math.floor(90*w),math.floor(255*w),math.floor(120*w),255)
            gr.draw3dLine(rim,focus,true,260*w+1,90*w+1)
        end
        if tc>2.0 then gr.createParticle(focus,V(0,0,0),0.08,2600*sstep(2,5.5,tc)+200,PARTICLE_BITMAP,-1,false,c.tex.glow) end
    end
    if tc>3.6 and tc<9.0 then
        local w=sstep(3.6,4.0,tc)*(1-sstep(8.4,9.0,tc))
        gr.setColor(math.floor(140*w),math.floor(255*w),math.floor(150*w),255)
        gr.draw3dLine(focus,impact,true,1500*w+1,1000*w+1)
        gr.setColor(math.floor(230*w),math.floor(255*w),math.floor(230*w),255)
        gr.draw3dLine(focus,impact,true,420*w+1,280*w+1)
        local dd=impact-focus
        for k=0,24 do gr.createParticle(focus+dd*((k+math.random())/25),V(0,0,0),0.06,2600*w,PARTICLE_BITMAP,-1,false,c.tex.glow) end
        gr.createParticle(impact,V(0,0,0),0.1,16000*w,PARTICLE_BITMAP,-1,false,c.tex.white)
        if not c.tImpact then c.tImpact=T;log('IMPACT') end
    end
end

-- ---------------------------------------------------------------- planet destruction
-- 0-6 s: heating (molten fissures in the shader). 6 s: blinding flash; the crust is replaced by
-- a fireball and ~180 irregular glowing fragments thrown outwards, embers and a shockwave ring.
local function breakup(c)
    c.broken=true;log('BREAKUP')
    local core=mn.Props['Noyau'];if ok(core) then core.Position=C end
    local hide={}
    for i=1,#mn.Props do
        local pr=mn.Props[i]
        if ok(pr) and pr.Name~='Noyau' and pr.Name~='Etoile Noire' then hide[#hide+1]=pr end
    end
    for _,pr in ipairs(hide) do pr.Position=V(0,9e7,0) end
    local gone={}
    for i=1,#mn.Ships do local sh=mn.Ships[i];if ok(sh) and length(sh.Position-C)<90000 then gone[#gone+1]=sh end end
    for _,sh in ipairs(gone) do if ok(sh) then sh:vanish() end end
    local n0=unit(c.impact-C)
    for i=1,140 do
        local d=unit(ba.createRandomVector()+n0*0.35)
        local size=(i<=24) and 0 or ((i<=80) and 1 or 2)
        local cls=tb.PropClasses[string.format('SpaceSim Frag %d%d',size,math.random(0,3))]
        local pos=C+d*(80000*(0.86+0.12*math.random()))
        local pr=mn.createProp('Fragment '..i,cls,ba.createRandomOrientation(),pos)
        if ok(pr) then
            c.frags[#c.frags+1]={pr=pr,vel=d*((size==0 and 1800 or 3200)+3800*math.random())+ba.createRandomVector()*900,
                                 ang={p=math.random()*6.28,b=math.random()*6.28,h=math.random()*6.28},spin={math.random()-0.5,math.random()-0.5,math.random()-0.5}}
        end
    end
end
local function destruction(c,T,dt)
    if not c.tImpact then return end
    local td=T-c.tImpact
    local heat=clamp(td/6,0,1)
    local red=c.broken and math.max(0,1-(td-6)/18) or heat
    mn.runSEXP(string.format('(set-ambient-light %d 20 20)',math.floor(20+230*red)))
    c.boom=heat
    if not c.broken and td<6 and math.random()<0.5 then
        local d=unit(unit(c.impact-C)+ba.createRandomVector()*(0.3+heat*0.7))
        -- animated particle with the fireball texture (not mn.createExplosion: under Vulkan, fireball_create's
        -- LOD computation (g3_get_bitmap_dims) crashed once on these huge, distant explosions)
        local tex=(c.tex.boom and c.tex.boom:isValid()) and c.tex.boom or c.tex.fire
        gr.createParticle(C+d*80300,V(0,0,0),2.2+math.random(),3000+9000*math.random(),PARTICLE_BITMAP,-1,false,tex)
    end
    if td>6 and not c.broken then breakup(c) end
    if not c.broken then return end
    local tb_=td-6
    -- flash
    if tb_<0.9 then gr.createParticle(C,V(0,0,0),0.08,(150000+160000*tb_)*(1-sstep(0.3,0.9,tb_))+1,PARTICLE_BITMAP,-1,false,c.tex.white) end
    -- fireball: churning orange glow growing then thinning
    local rf=82000+26000*tb_
    local fade=1-sstep(6,16,tb_)
    for k=1,3 do
        local q=C+ba.createRandomVector()*(rf*math.random()^0.5)
        gr.createParticle(q,V(0,0,0),0.35,(rf*0.22)*fade+1,PARTICLE_BITMAP,-1,false,c.tex.fire)
    end
    -- embers streaming outwards
    if tb_<5 then
        for k=1,12 do
            local d=ba.createRandomVector()
            gr.createParticle(C+d*80000,d*(9000+14000*math.random()),4+4*math.random(),700+1600*math.random(),PARTICLE_BITMAP,-1,false,c.tex.orange)
        end
    end
    -- shockwave ring (plane facing the Death Star)
    local n=unit(c.impact-C);local a1=unit(cross(n,V(0,0,1)));local a2=cross(n,a1)
    local rs=84000+16000*tb_;c.shockR=rs
    local ringFade=1-sstep(14,20,tb_)
    for k=0,239 do
        local ang=k*math.pi/120+tb_*0.04
        local q=C+(a1*math.cos(ang)+a2*math.sin(ang))*(rs*(1+0.012*math.sin(k*7.3)))
        gr.createParticle(q,V(0,0,0),0.05,rs*0.05*ringFade+1,PARTICLE_BITMAP,-1,false,c.tex.blue)
    end
    -- fragments
    for _,f in ipairs(c.frags) do
        if ok(f.pr) then
            f.pr.Position=f.pr.Position+f.vel*dt
            f.ang.p=f.ang.p+f.spin[1]*dt*0.4;f.ang.b=f.ang.b+f.spin[2]*dt*0.4;f.ang.h=f.ang.h+f.spin[3]*dt*0.4
            f.pr.Orientation=ba.createOrientation(f.ang.p,f.ang.b,f.ang.h)
            if math.random()<0.08 then gr.createParticle(f.pr.Position,f.vel*0.2,1.0,1800,PARTICLE_BITMAP,-1,false,c.tex.fire) end
        end
    end
    local core=mn.Props['Noyau']
    if ok(core) and tb_>9 then core.Position=V(0,9e7,0) end
end


-- camera point ~dist m from a wreck, behind it (opposite its last horizontal velocity) and above, clear of the terrain
local function wreckCamPoint(wp,vel,fwd,dist)
    local rad=unit(wp-C);local vh=vel-rad*dot(vel,rad)
    local back=(length(vh)>1 and unit(vh) or fwd)*-1
    local side=unit(cross(rad,back))
    for _,e in ipairs({{0.45,0.3},{0.7,0.3},{0.45,-0.3},{1.0,0},{1.6,0},{3,0}}) do
        local d=unit(back+rad*e[1]+side*e[2]);local q=wp+d*dist
        local g=SPACESIM.surface(q)
        if not g or length(q-C)>length(g-C)+25 then return q end
    end
    return wp+rad*dist
end
-- Real player death with a controlled FSO death view. FSO ignores the script camera once the player is dead:
--  * the death camera starts 100 m from the wreck, on the side opposite the killer -> an invisible witness
--    ship is credited with the kill, placed opposite the wanted camera point;
--  * during the death roll it drifts along (2*fvec + 2*rvec + uvec) of the dying ship -> the wreck is
--    oriented so that this vector points from the wreck towards the camera point (away from the ground).
-- Then the game runs its own procedure: death message, death popup (restart / briefing / main menu).
local function rotateTo(v,from,to)      -- rotate v by the rotation taking unit vector 'from' onto 'to'
    local k=cross(from,to);local s=length(k);local cth=dot(from,to)
    if s<1e-6 then return v end
    k=k*(1/s)
    return v*cth+cross(k,v)*s+k*(dot(k,v)*(1-cth))
end
SPACESIM_WRECK_CAM=function(wp,vel,fwd) return wreckCamPoint(wp,vel,fwd,100) end
function SPACESIM_REAL_DEATH(sh,wp,camP)
    if not ok(sh) then return end
    -- multiplayer: no local-only witness ship in a death packet; plain death (FSO respawn follows)
    if ba.MultiplayerMode then sh:kill(sh);return end
    local dir=unit(camP-wp);local rad=unit(wp-C)
    local o=ba.createOrientationFromVectors(dir,length(cross(dir,rad))>0.05 and rad or V(1,0,0))
    local f0,u0,r0=o:getFvec(),o:getUvec(),o:getRvec()
    local w0=unit(f0*2+r0*2+u0)
    local f1,u1=unit(rotateTo(f0,w0,dir)),unit(rotateTo(u0,w0,dir))
    sh.Position=wp;sh.Physics.Velocity=V(0,0,0);sh.Physics.RotationalVelocity=V(0,0,0)
    sh.Orientation=ba.createOrientationFromVectors(f1,u1)
    sh:setFlag(false,'invulnerable');sh.Target=nil
    local killer=sh
    local cls=tb.ShipClasses['Nav Buoy#real']
    local w=cls and mn.createShip('Temoin',cls,ba.createOrientationFromVectors(dir,rad),wp-dir*400,sh.Team,false)
    if w and w:isValid() then w:setFlag(true,'cloaked','hidden-from-sensors','invulnerable');w:setFlag(false,'collides');killer=w end
    log(string.format('PLAYER_DEATH cam=%s',tostring(wp+dir*100)))
    sh:kill(killer)
end

-- ---------------------------------------------------------------- camera (hero: the player's X-wing)
local function setCockpit(c,on)
    if on and not c.cockpit then c.cockpit=true;gr.setCamera();hu.HUDDrawn=true;log('COCKPIT on')
    elseif not on and c.cockpit and not c.finalCockpit then c.cockpit=false;hu.HUDDrawn=false;gr.setCamera(c.cam);c.cut=true;log('COCKPIT off') end
end
local function camera(c,T,dt)
    local hero=c.xw[1];local xs=c.xs[1]
    if not ok(hero) or xs.dead then
        -- the player's ship is gone: hold a fixed shot on the wreck (never swing to the targets)
        if not c.deathCam then
            local wp=c.crashPos or (ok(hero) and hero.Position) or xs.pos
            if not wp then return end
            c.deathCam=wreckCamPoint(wp,xs.vel or V(0,0,1),xs.fwd or V(0,0,1),100);c.deathPos=wp
            log(string.format('DEATHCAM wreck=%s cam=%s',tostring(wp),tostring(c.deathCam)))
            if c.cockpit then c.cockpit=false;c.finalCockpit=false;hu.HUDDrawn=false;gr.setCamera(c.cam);log('COCKPIT off (death)') end
        end
        -- the wreck burns where it hit the ground
        if ok(hero) then hero.Position=c.deathPos;hero.Physics.Velocity=V(0,0,0);hero.Physics.RotationalVelocity=V(0,0,0) end
        c.deathT=c.deathT or T
        if c.crashTest and T-c.deathT>20 and not c.crashEnd then c.crashEnd=true;SPACESIM.flush();c.pendingShot='cine_end' end
        -- after the hold: the real death -> the game's own procedure (message, restart popup)
        if c.crashPos and not c.realDeath and T-c.deathT>4 and ok(hero) then
            c.realDeath=true;SPACESIM_REAL_DEATH(hero,c.crashPos,c.deathCam)
        end
        -- secondary explosions on the burning wreck
        c.secondary=c.secondary or {0.7,1.4,2.2,3.1}
        if c.crashPos and c.secondary[1] and T-c.deathT>c.secondary[1] then
            table.remove(c.secondary,1)
            local rad=unit(c.crashPos-C);local o=V(math.random()-0.5,0,math.random()-0.5)*24
            SPACESIM.boom(c.crashPos+o+rad*(4+math.random()*8),18+math.random()*14,true)
        end
        c.cam:setPosition(c.deathCam)
        c.cam:setOrientation(ba.createOrientationFromVectors(unit(c.deathPos-c.deathCam),unit(c.deathCam-C)))
        return
    end
    local p=hero.Position;local o=hero.Orientation
    local f,u,r=o:getFvec(),o:getUvec(),o:getRvec()
    local radial=unit(p-C)
    local cargoP=ok(c.cargo) and c.cargo.Position or p
    local want,look,up
    local ph=c.phase
    if ph=='camp' then
        local base=c.cargoStart+radial*95+V(-260,0,-420)
        local g=SPACESIM.surface(base);if g and length(base-C)<length(g-C)+60 then base=g+radial*60 end
        want=base;look=vlerp(cargoP,p,0.3)+V(0,15,0);up=radial
    elseif ph=='canyon' then
        want=p-f*46+u*11+r*(7*math.sin(T*0.31))
        look=p+f*200
        if xs.tgt and ok(mn.Ships[xs.tgt.name]) then look=vlerp(look,mn.Ships[xs.tgt.name].Position,0.35) end
        up=radial
    elseif ph=='montee' then
        want=p+f*75+r*28+u*14;look=vlerp(p,cargoP,0.35);up=radial
    elseif ph=='orbite' then
        local tgt=(c.isds and ok(c.isds[2])) and c.isds[2].Position or p+f*4000
        want=p-f*55+u*14+r*10;look=vlerp(p+f*300,tgt,0.15);up=unit(vlerp(radial,u,0.5))
    else
        -- destruction: over the X-wing's shoulder towards the planet
        local toP=unit(C-p)
        want=p-toP*70+u*22+r*18;look=p+toP*30000;up=unit(vlerp(radial,u,0.5))
    end
    if c.cut or not c.camPos then c.camPos=want;c.camLook=unit(look-want);c.cut=false end
    c.camPos=vlerp(c.camPos,want,1-math.exp(-dt*(ph=='canyon' and 6 or 2.5)))
    c.camLook=unit(vlerp(c.camLook,unit(look-c.camPos),1-math.exp(-dt*5)))
    if not c.cockpit then c.cam:setPosition(c.camPos);c.cam:setOrientation(ba.createOrientationFromVectors(c.camLook,up)) end
end

-- ---------------------------------------------------------------- main update
function CINE.update()
    local c=CINE.c;if not c then return end
    for k=1,4 do if not ok(c.xw[k]) and c.names then c.xw[k]=mn.Ships[c.names[k]] end end
    local now=mn.getMissionTime();local T=now-c.t0;local dt=math.max(1e-3,math.min(ba.getMissionFrametime(),0.25))
    c.T=T
    local cargo=c.cargo
    -- cargo
    if not c.server then
        if ok(cargo) and T>=10 then c.s=CINE.projectS(c,cargo.Position);c.cargoV=length(cargo.Physics.Velocity) end
        c.cargoAlt=ok(cargo) and length(cargo.Position-C)-80000 or c.cargoAlt
    elseif not c.cargoJumped and ok(cargo) then
        if not c.play then guard(cargo,0.42)
        elseif not cargo:isDying() then
            local hp=CINE.cargoArmor(c,cargo.HitpointsLeft,dt)
            cargo.HitpointsLeft=hp;c.lastHull=hp
        end
        c.cargoAlt=length(cargo.Position-C)-80000
        if T<5 then
            setShip(cargo,c.cargoStart,c.cargoStartOri:getFvec(),unit(c.cargoStart-C),V(0,0,0))
        elseif T<10 then
            local w=sstep(5,10,T);local lift=c.cargoStart+unit(c.cargoStart-C)*(70*w)
            local tgtF=unit(sample(c.path,40)-sample(c.path,0))
            setShip(cargo,lift,unit(vlerp(c.cargoStartOri:getFvec(),tgtF,w)),unit(c.cargoStart-C),unit(c.cargoStart-C)*(14*(1-w)))
        else
            local v=cargoSpeed(c,c.s);c.s=c.s+v*dt
            local pos=sample(c.path,c.s);local fwd=unit(sample(c.path,c.s+math.max(40,v*0.4))-pos)
            c.cfwd=c.cfwd and unit(vlerp(c.cfwd,fwd,1-math.exp(-dt*4))) or fwd
            setShip(cargo,pos,c.cfwd,unit(pos-C),c.cfwd*v);c.cargoV=v
        end
    end
    if c.server then CINE.escorts(c,T,dt) end
    local s=c.s
    local prev=c.phase
    if T<10 then c.phase='camp' elseif s<c.Lc then c.phase='canyon' elseif s<c.La then c.phase='montee'
    elseif not c.tFire then c.phase='orbite' elseif not c.tImpact then c.phase='superlaser' else c.phase='destruction' end
    if prev~=c.phase then log('PHASE '..c.phase..string.format(' T=%.1f',T)) end
    if c.play then CINE.gameplay(c,T,dt);CINE.sideEvents(c,T,dt) end
    if c.phase=='canyon' and T-(c.canLogT or 0)>15 then c.canLogT=T;log(string.format('CANYON T=%.0f s=%.0f v=%.0f alt=%.0f',T,c.s,c.cargoV or 0,c.cargoAlt or 0)) end
    if c.phase=='montee' and T-(c.climbLogT or 0)>4 then c.climbLogT=T;log(string.format('CLIMB T=%.0f s=%.1f/%.1f km alt=%.1f km v=%.0f m/s',T,c.s/1000,c.La/1000,(c.cargoAlt or 0)/1000,c.cargoV or 0)) end
    -- ground targets: shields down, low hull (one good hit destroys) - re-applied after streaming
    if c.server and (c.phase=='camp' or c.phase=='canyon') then
        for _,tg in ipairs(c.targets) do
            local sh=mn.Ships[tg.name]
            if ok(sh) and not sh:isDying() then
                sh.Shields.CombinedLeft=0
                if sh:getSignature()~=tg.sig then tg.sig=sh:getSignature();if sh.HitpointsLeft>TARGET_HP then sh.HitpointsLeft=TARGET_HP end end
            end
        end
    end
    -- orbit events
    if c.phase=='orbite' and not c.tArrival then
        c.tArrival=T
        if c.play then c.netPhase=math.max(c.netPhase,3);c.isds={} else spawnISDs(c) end
        c.subs[#c.subs+1]={T+1,4.5,'ROUGE 4','Contact ! Trois destroyers... ils lancent leurs chasseurs !'}
        c.dsU1=unit(cargo.Position-C);c.dsU2=unit(sample(c.path,c.s+3000)-cargo.Position);c.dsU2=unit(c.dsU2-c.dsU1*dot(c.dsU2,c.dsU1))
    end
    if c.play and c.isds and #c.isds<3 then
        c.isds={};for _,n in ipairs({'Chimere','Tyran','Vengeance'}) do local d=mn.Ships['Destroyer '..n];if ok(d) then c.isds[#c.isds+1]=d end end
    end
    if c.tArrival and not c.ties and T>c.tArrival+6 then
        if c.play then c.netPhase=math.max(c.netPhase,4);c.ties={} else spawnTIEs(c) end
        for k=2,4 do local x=c.xw[k];if c.server and ok(x) and not x:isPlayer() then x:setFlag(false,'no-dynamic');x:clearOrders();x:giveOrder(ORDER_ATTACK_ANY) end end
        c.subs[#c.subs+1]={T+0.5,4.5,'ROUGE 1','Rouges, engagez les chasseurs ! Je m\'occupe du destroyer.'}
    end
    if c.tArrival then
        local tr=T-c.tArrival
        local ds=mn.Props['Etoile Noire']
        if ok(ds) then local pos,ori=deathStarFrame(c,math.pi*(0.82-0.58*sstep(8,34,tr)));ds.Position=pos;ds.Orientation=ori end
        if tr>22 and not c.dsLine then c.dsLine=true
            c.subs[#c.subs+1]={T,5,'AURORE','Par la Force... ce n\'est pas une lune.'}
            c.subs[#c.subs+1]={T+5.5,5,'ECHO BASE','C\'est une station de combat ! Aurore, calculez le saut, maintenant !'} end
        if tr>38 and not c.tFire then c.tFire=T;log('SUPERLASER');c.subs[#c.subs+1]={T+0.5,4,'ROUGE 1','Elle vise la planete !'} end
    end
    if c.tFire then superlaser(c,T);destruction(c,T,dt) end
    if c.tImpact and not c.jumpLines then c.jumpLines=true
        c.subs[#c.subs+1]={T+3,4.5,'AURORE','Non... Aurore... tout est perdu.'}
        c.subs[#c.subs+1]={T+9,4.5,'ECHO BASE','Onde de choc en approche ! Tout le monde saute, maintenant !'} end
    if c.tImpact then
        local tj=T-c.tImpact
        if tj>14 and not c.cargoJumped and ok(cargo) then c.cargoJumped=true;if c.server then cargo:clearOrders();cargo:warpOut() end;log('JUMP cargo') end
        for k=2,4 do local x=c.xw[k];if c.server and tj>15+k*0.5 and ok(x) and not x:isDying() and not x:isPlayer() and not c['j'..k] then c['j'..k]=true;x:warpOut() end end
        if tj>17 and not c.finalCockpit and not (c.play and c.handover) then setCockpit(c,true);c.finalCockpit=true end
        if tj>18.5 and not c.playerJump and (not c.play or c.bot) then
            c.playerJump=true;SPACESIM.state.cineJump=true
            local pl=c.xw[1];if ok(pl) then pl:setFlag(false,'no-departure-warp');pl:setFlag(false,'never-warp') end
            ba.postGameEvent(ba.GameEvents['GS_EVENT_PLAYER_WARPOUT_START']);log('JUMP player')
        end
    end
    -- X-wings
    local cp=ok(cargo) and cargo.Position or c.lastCP or V(0,0,0);c.lastCP=cp
    local co=ok(cargo) and cargo.Orientation or ba.createOrientation(0,0,0)
    local kF,kU,kR=co:getFvec(),co:getUvec(),co:getRvec()
    local cvel=(c.phase=='camp' and T<10) and V(0,0,0) or kF*(c.cargoV or 0)
    local slots={V(40,45,650),V(-70,30,260),V(130,14,130),V(-130,14,130)}
    local playerCockpitWanted=false
    for k=1,4 do
        local x=c.xw[k];local xs=c.xs[k]
        local scripted=(k==1 and not c.playerJump) or ((c.phase=='camp' or c.phase=='canyon' or c.phase=='montee') and not c.ties)
        if c.play and c.handover then scripted=(k==1 and c.bot and not c.playerJump) end
        if ba.MultiplayerMode and ok(x) then
            local mine=hv.Player and hv.Player:isValid() and hv.Player:getSignature()==x:getSignature()
            if x:isPlayer() then scripted=scripted and mine and not c.handover else scripted=scripted and c.server end
        end
        if ok(x) and x:isDying() then xs.dead=true end
        if ok(x) and scripted and not xs.dead then
            guard(x,0.55)
            local sl=slots[k]
            local weave=V(math.sin(T*0.7+k)*10,math.sin(T*0.9+k*2)*6,math.cos(T*0.5+k)*15)
            local goal=cp+kR*(sl.x+weave.x)+kU*(sl.y+weave.y)+kF*(sl.z+weave.z)
            local vgoal=cvel
            local low=(c.phase=='camp' or c.phase=='canyon')
            if c.phase=='camp' and T<10 then goal=goal+unit(cp-C)*25 end
            if low and T>=8 then
                -- track along the canyon: ahead of the cargo, safely above its path
                local lead=({1000,420,300,300})[k]
                local lat=({0,-70,70,0})[k]
                local hgt=({170,130,130,190})[k]
                local tp=sample(c.path,s+lead);local td=unit(sample(c.path,s+lead+60)-tp);local tu=unit(tp-C);local tr=unit(cross(tu,td))
                goal=tp+tu*(hgt+weave.y)+tr*(lat+weave.x);vgoal=td*math.max(c.cargoV or 0,120)
                xs.trackS=s+lead
            end
            -- "headshot" attack: lock the next visible target, put it in the crosshair, torpedo + lasers
            local aimDir=nil
            if c.phase=='canyon' or (c.phase=='camp' and T>8) then
                local tgt=xs.tgt
                if tgt and (tgt.done or isDead(tgt.name)) then
                    if not tgt.done then tgt.done=true;log(string.format('DESTROYED %s T=%.1f by %d torps=%d',tgt.name,T,k,tgt.torps or 0)) end
                    xs.tgt=nil;tgt=nil;xs.releaseT=T
                end
                if not tgt and T-(xs.pickT or 0)>0.4 and T-(xs.releaseT or -9)>0.6 then
                    xs.pickT=T
                    for _,tg in ipairs(c.targets) do
                        -- own targets, or (wingmen) a target whose owner is busy with another one
                        local owner=c.xs[tg.who]
                        local mine=tg.who==k or (k>1 and tg.who>1 and owner and (owner.dead or (owner.tgt and owner.tgt~=tg)))
                        if mine and not tg.done and not isDead(tg.name) and tg.s-(xs.trackS or s)<3200 and tg.s-(xs.trackS or s)>-500 then
                            local sh=mn.Ships[tg.name]
                            if ok(sh) and length(sh.Position-xs.pos)<3000 then
                                local los=mn.getLineOfSightFirstIntersect(xs.pos,sh.Position,{x,sh},false,true,5)
                                if los then tg.who=k;xs.tgt=tg;tgt=tg;tg.t0=T;log(string.format('LOCK %s by %d dist=%.0f',tg.name,k,length(sh.Position-xs.pos)));break end
                            end
                        end
                    end
                end
                if tgt then
                    local sh=mn.Ships[tgt.name]
                    if ok(sh) then
                        local tdir=unit(sh.Position-xs.pos);local dist=length(sh.Position-xs.pos)
                        local behind=dot(tdir,unit(vgoal))<-0.15
                        if behind or T-tgt.t0>(tgt.name:find('^Batterie') and k==1 and 40 or 16) then
                            xs.tgt=nil;xs.releaseT=T;log('LOST '..tgt.name)
                            -- still alive: hand it to the wingman furthest behind that has not passed it yet
                            local best,bs=nil,1e9
                            for j=2,4 do
                                local o=c.xs[j]
                                if j~=k and o and not o.dead and o.trackS and o.trackS<tgt.s-400 and o.trackS<bs then best,bs=j,o.trackS end
                            end
                            if best and not (k==1 and tgt.name:find('^Batterie')) then tgt.who=best;tgt.torps=0;log(string.format('HANDOVER %s %d->%d',tgt.name,k,best)) end
                        else
                            x.Target=sh
                            aimDir=tdir
                            -- drift a little towards the target, like lining up a shot
                            -- line up on it: strong sideways shift (horizontal, max 900 m) for targets off the canyon axis
                            local gu=unit(goal-C);local off=sh.Position-goal;off=off-gu*dot(off,gu)
                            local lat=off*0.45;if length(lat)>900 then lat=unit(lat)*900 end
                            goal=goal+lat
                            -- break formation and close in: attack from ~800 m (max 700 m ahead of the slot)
                            local fwdH=off-lat;local fl=length(fwdH)
                            if dist>800 and fl>1 then goal=goal+unit(fwdH)*math.min(dist-800,700) end
                            -- climb until the line of fire clears the ridges by 70 m (torpedoes are slower and curve)
                            if T-(xs.clrT or -9)>0.4 then
                                xs.clrT=T;local clr=fireClearance(xs.pos,sh.Position)
                                xs.climb=clamp((xs.climb or 0)+(70-clr)*0.8,0,700)
                            end
                            goal=goal+gu*(xs.climb or 0)
                            local w=xs.aimW or 0
                            if w>0.95 and dist<2300 and dist>300 and not c.wtest then
                                local los=(T-(xs.losT or 0)<0.25) and xs.los or mn.getLineOfSightFirstIntersect(xs.pos,sh.Position,{x,sh},false,true,5)
                                xs.los=los;xs.losT=T
                                if los then
                                    -- solid aim point on the hull (open-frame models are empty at their centre)
                                    if not tgt.aimL or T-(tgt.aimT or -9)>1.5 then
                                        local ap=solidAim(sh,xs.pos);tgt.aimT=T
                                        tgt.aimL=ap and sh.Orientation:rotateVector(ap-sh.Position) or V(0,0,0)
                                    end
                                    local aimP=sh.Position+sh.Orientation:unrotateVector(tgt.aimL)
                                    if dist<1600 and (tgt.torps or 0)<6 and T-(tgt.lastTorp or -9)>1.8 and fireClearance(xs.pos,aimP)>25 then
                                        CINE.trackTorp(fireTorpedo(x,sh,aimP),sh);tgt.torps=(tgt.torps or 0)+1;tgt.lastTorp=T
                                        log(string.format('TORPEDO %s by %d #%d dist=%.0f',tgt.name,k,tgt.torps,dist))
                                    end
                                    if dist<1300 and T-(xs.lastFire or 0)>0.12 then
                                        xs.pair=1-(xs.pair or 0);fireLasers(x,aimP,xs.pair);xs.lastFire=T
                                    end
                                end
                            end
                            if k==1 then playerCockpitWanted=true end
                        end
                    else xs.tgt=nil end
                end
                if k==1 and xs.releaseT and T-xs.releaseT<0.8 then playerCockpitWanted=true end
            end
            if not aimDir and xs.climb then xs.climb=xs.climb*math.exp(-dt*0.6) end
            local wT=aimDir and 1 or 0
            xs.aimW=(xs.aimW or 0)+(wT-(xs.aimW or 0))*(1-math.exp(-dt*(aimDir and 2.5 or 1.5)))
            xs.aimDir=aimDir or xs.aimDir
            local maxAcc=(c.phase=='montee') and 9000 or 95
            if c.phase=='montee' then xs.pos=goal;xs.vel=cvel end
            -- player: torpedo run on a Star Destroyer while the wingmen dogfight
            if k==1 and c.isds and not c.tFire then
                local isd=c.isds[2] or c.isds[1]
                if ok(isd) then
                    local tr=T-c.tArrival
                    local ww=sstep(6,10,tr)*(1-sstep(28,32,tr))
                    if ww>0.01 then
                        local away=unit(cp-isd.Position)
                        local rgoal=isd.Position+away*(2800-1900*sstep(10,26,tr))+unit(isd.Position-C)*500
                        goal=vlerp(goal,rgoal,ww);vgoal=vlerp(vgoal,unit(isd.Position-xs.pos)*180,ww)
                        x.Target=isd
                        local ang=dot(unit(isd.Position-xs.pos),xs.fwd or kF)
                        if ww>0.7 and ang>0.99 and T-(xs.lastFire or 0)>0.12 then xs.pair=1-(xs.pair or 0);fireLasers(x,isd.Position,xs.pair);xs.lastFire=T end
                        if ww>0.9 and ang>0.99 and not c.isdTorp and length(isd.Position-xs.pos)<2400 then c.isdTorp=true;fireTorpedo(x,isd,isd.Position);fireTorpedo(x,isd,isd.Position+isd.Orientation:getUvec()*40);log('TORPEDO isd') end
                        if tr>14 and tr<24 then playerCockpitWanted=true end
                    end
                    maxAcc=120
                end
            end
            if c.phase=='destruction' or c.phase=='superlaser' then goal=cp+kR*90+kU*40+kF*200;vgoal=cvel;maxAcc=120 end
            if k==1 and c.crashTest==nil then c.crashTest=cf.fileExists('spacesim-cinecrash.flag','data',true) end
            local avoid=c.phase=='camp' or c.phase=='canyon'
            if k==1 and c.crashTest and T>30 then
                if not xs.diving then xs.diving=true;log('CRASHTEST dive') end
                local rad=unit(xs.pos-C);local fh=xs.fwd-rad*dot(xs.fwd,rad)
                goal=xs.pos+unit(fh)*220-rad*260;vgoal=unit(goal-xs.pos)*230;maxAcc=160;avoid=false
                xs.tgt=nil;aimDir=nil;xs.aimW=0
            end
            fly(xs,goal,vgoal,dt,maxAcc,kF,avoid)
            local nose=xs.fwd
            if xs.aimDir and (xs.aimW or 0)>0.001 then nose=unit(vlerp(xs.fwd,xs.aimDir,xs.aimW)) end
            -- the physical velocity follows the nose: weapons inherit it (MG7: 100 %), so they fly down the line of fire
            setShip(x,xs.pos,nose,xs.up,nose*length(xs.vel))
        elseif ok(x) then xs.pos=x.Position;xs.vel=x.Physics.Velocity end
    end
    if not (c.play and c.handover) then
        if not c.finalCockpit then setCockpit(c,playerCockpitWanted) end
        camera(c,T,dt)
    end
    local st=c.stats[c.phase] or {dts={}};c.stats[c.phase]=st;st.dts[#st.dts+1]=ba.getRealFrametime()
    if c.captureOn==nil then c.captureOn=cf.fileExists('spacesim-capture.flag','data',true) end
    if c.captureOn and now>=c.nextShot and not c.pendingShot then
        c.shots=c.shots+1;c.nextShot=now+1.0;c.pendingShot=string.format('cine_%03d_%s',c.shots,c.phase)
    end
    local jumpedT=c.play and c.playerJumpT or (c.tImpact and c.tImpact+18.5)
    if (c.canyonOnly and c.phase=='montee' and not c.endShot) or (c.playerJump and not c.endShot and jumpedT and T-jumpedT>4.5) then
        c.endShot=true
        for name,stt in pairs(c.stats) do
            table.sort(stt.dts);local n=#stt.dts;local sum=0 for _,v in ipairs(stt.dts) do sum=sum+v end
            log(string.format('FPS phase=%s frames=%d fps_mean=%.1f fps_1pct_low=%.1f',name,n,n/sum,1/stt.dts[math.max(1,math.floor(n*0.99))]))
        end
        local done=0;for _,tg in ipairs(c.targets) do if tg.done or isDead(tg.name) then done=done+1 end end
        log(string.format('TARGETS destroyed=%d/%d',done,#c.targets))
        local alive={};for _,tg in ipairs(c.targets) do if not (tg.done or isDead(tg.name)) then alive[#alive+1]=tg.name end end
        log('TARGETS alive: '..table.concat(alive,', '))
        log(string.format('CARGO hull=%.0f%%',ok(c.cargo) and 100*c.cargo.HitpointsLeft/c.cargo.HitpointsMax or -1))
        SPACESIM.flush();c.pendingShot='cine_end'
    end
end

engine.addHook('On Gameplay Start',function()
    CINE.active=false;CINE.c=nil
    if mn.getMissionFilename():lower():find('_spt_aurore_evasion') then CINE.pending=true end
end)
engine.addHook('On Simulation',function()
    if CINE.pending and mn.getMissionTime()>0.6 and SPACESIM and SPACESIM.state.active then CINE.pending=false;CINE.init() end
    if CINE.active then CINE.update() end
end)
engine.addHook('On Frame',function()
    local c=CINE.c
    if not (CINE.active and c) then return end
    local heroDead=c.xs and c.xs[1] and c.xs[1].dead
    if c.T and not c.cockpit and not heroDead then drawSubs(c.T) end
    if c.pendingShot then SPACESIM.capture(c.pendingShot);c.pendingShot=nil end
end)
engine.addHook('On HUD Draw',function() local c=CINE.c;if CINE.active and c and c.T and c.cockpit and not (c.xs and c.xs[1] and c.xs[1].dead) then drawSubs(c.T) end end)
engine.addHook('On Mission About To End',function() local c=CINE.c;if c and c.playerJump then SPACESIM.record('CINE END_REQUESTED');SPACESIM.flush() end end)

CINE.trackTorp=function() end

-- ===================== weapons test bench (data/spacesim-cinetest.flag) =====================
local function aglOf(p) local g=SPACESIM.surface(p);return g and (length(p-C)-length(g-C)) or -1 end
local WT={list={'Batterie 1','Bunker imperial 4','AT-AT 3','Batterie 8','AT-AT 2','Batterie 10'},i=0}
local WT_TORP={['Batterie 8']=true,['AT-AT 2']=true,['Batterie 10']=true}
engine.addHook('On Simulation',function()
    if not (CINE.active and CINE.c) then return end
    local c=CINE.c
    if c.wtest==nil then c.wtest=cf.fileExists('spacesim-cinetest.flag','data',true) end
    if not c.wtest then return end
    local T=c.T or 0
    local x=c.xw[1]
    if not WT.cur or T-WT.t0>8 then
        if WT.cur then log(string.format('WTEST RESULT %s torp_closest=%.0f lasers hit=%d miss=%d (last miss: %s) | hull before=%.0f after_lasers=%.0f final=%s | torp hit=%d miss=%d',
            WT.cur,WT.minD or -1,WT.hit_laser or 0,WT.miss_laser or 0,WT.lastMiss or '-',WT.h0 or -1,WT.h1 or -1,
            ok(mn.Ships[WT.cur]) and string.format('%.0f',mn.Ships[WT.cur].HitpointsLeft) or 'DESTROYED',WT.hit_torp or 0,WT.miss_torp or 0)) end
        WT.i=WT.i+1;WT.cur=WT.list[WT.i];WT.t0=T;WT.pos=nil;WT.aim=nil
        WT.hit_laser=0;WT.miss_laser=0;WT.hit_torp=0;WT.miss_torp=0;WT.h0=nil;WT.h1=nil;WT.lastMiss=nil;WT.minD=nil;WT.tw=nil
        if not WT.cur then c.wtest=false;return end
    end
    local tgt=mn.Ships[WT.cur]
    if not ok(tgt) then return end
    if not WT.pos then
        local tp=tgt.Position;local up=unit(tp-C)
        local toV=V(valleyX(tp.z),tp.y,tp.z)-tp;toV=toV-up*dot(toV,up)
        local side=length(toV)>50 and unit(toV) or unit(cross(up,V(1,0,0)))
        WT.pos=tp+side*700+up*250
        for _=1,20 do if aglOf(WT.pos)<120 then WT.pos=WT.pos+up*60 else break end end
        WT.aim=solidAim(tgt,WT.pos) or tgt.Position
        log(string.format('WTEST %s radius=%.0f class=%s hull=%.0f shooter_dist=%.0f',WT.cur,tgt.Radius,tgt.Class.Name,tgt.HitpointsLeft,length(tgt.Position-WT.pos)))
    end
    local d=unit(WT.aim-WT.pos)
    x.Position=WT.pos;x.Physics.Velocity=V(0,0,0);x.Orientation=ba.createOrientationFromVectors(d,unit(WT.pos-C));x.Target=tgt
    local t=T-WT.t0
    if t>0.9 and not WT.h0 then WT.h0=tgt.HitpointsLeft end
    if t>5.4 and not WT.h1 then WT.h1=tgt.HitpointsLeft end
    local torpOnly=WT_TORP[WT.cur]
    if not torpOnly and t>1 and t<5 and T-(WT.lf or 0)>0.12 then WT.pair=1-(WT.pair or 0);fireLasers(x,WT.aim,WT.pair);WT.lf=T end
    if torpOnly and t>1 and WT.torp~=WT.cur then WT.tw=fireTorpedo(x,tgt,WT.aim);WT.torp=WT.cur;WT.tl=0 end
    local tw=WT.tw
    if tw and tw:isValid() and T-WT.tl>0.25 then
        WT.tl=T;local dd=length(tw.Position-tgt.Position);if dd<(WT.minD or 1e9) then WT.minD=dd end
    end
end)
engine.addHook('On Weapon Collision',function()
    if not (CINE.active and CINE.c and CINE.c.wtest and WT.cur) then return end
    local w=hv.Object;local o=hv.Self
    if hv.Prop and hv.Prop:isValid() and w and w:isValid() and dot(hv.Hitpos-w.Position,unit(w.Physics.Velocity))>1 then return end
    if w and w:isValid() and w.Parent and w.Parent:isValid() and w.Parent.Name=='Red 1' then
        local tgt=mn.Ships[WT.cur]
        local isT=o and o:isValid() and (tostring(o)==WT.cur or tostring(o)==WT.cur..' ship')
        local name=o and o:isValid() and tostring(o) or '?'
        local kind=w.Class.Name:find('MG7') and 'torp' or 'laser'
        if kind=='torp' then log(string.format('WTEST torp impact on %s dist_to_target=%.0f agl=%.1f',name,tgt and tgt:isValid() and length(hv.Hitpos-tgt.Position) or -1,aglOf(hv.Hitpos))) end
        if isT then WT['hit_'..kind]=(WT['hit_'..kind] or 0)+1 else WT['miss_'..kind]=(WT['miss_'..kind] or 0)+1;WT.lastMiss=name end
    end
end)


-- player crash during the cinematic: FSO's own death view ignores the script camera and drifts along the
-- dive (into the ground), so the crash is staged: the real X-wing is hidden and parked at the impact point,
-- an identical clone takes its place and is destroyed with the engine's real death sequence (fireball,
-- debris), and the cinematic camera holds on the wreck.
SPACESIM_PLAYER_CRASH=function(sh,hitpos)
    local c=CINE.c
    if not (CINE.active and c) or (c.play and c.handover) then return false end
    local xs=c.xs[1]
    local pos,ori,cls,team=sh.Position,sh.Orientation,sh.Class,sh.Team
    sh:setFlag(false,'collides');sh:setFlag(true,'cloaked','invulnerable','hidden-from-sensors')
    sh.Target=nil;sh.Physics.Velocity=V(0,0,0)
    local clone=mn.createShip('Rouge 1 epave',cls,ori,pos,team,false)
    if clone and clone:isValid() then
        clone.Physics.Velocity=V(0,0,0)
        clone:kill(clone)
    end
    xs.dead=true;c.crashPos=pos;c.wreck=clone
    log(string.format('CRASH staged clone=%s pos=%s',tostring(clone and clone:isValid()),tostring(pos)))
    return true
end

-- the Aurore cannot die while the cinematic flies it: a missile salvo can deal more than the remaining hull
-- within one frame (before the per-frame guard reacts). 'On Ship Death' is overridable at the very start of
-- ship_hit_kill (shiphit.cpp): cancel the death, back to 30 % hull, invulnerable. Gameplay: not active.
-- gameplay armour of the Aurore: 30 % of the damage, at most 8 % of the hull per second (no one-salvo kill;
-- sustained fire still destroys it = mission failure)
function CINE.cargoArmor(c,hp,dt)
    local last=c.lastHull
    if not last or hp>=last then return hp end
    -- share of the damage taken, by difficulty (1 very easy .. 5 insane)
    local share=({0.15,0.22,0.30,0.40,0.55})[clamp(ba.getGameDifficulty() or 3,1,5)]
    local loss=(last-hp)*share
    local cap=c.cargo.HitpointsMax*0.08*math.max(dt,0.02)
    c.armorBank=(c.armorBank or 0)
    loss=math.min(loss,cap+c.armorBank);c.armorBank=0
    return last-loss
end
engine.addHook('On Ship Death',function() end,{},function()
    local c=CINE.c
    if not (CINE.active and c and ok(c.cargo) and ok(hv.Ship)) then return false end
    if hv.Ship:getSignature()~=c.cargo:getSignature() then return false end
    local sh=c.cargo
    if c.play and c.handover then
        -- the death is real only if the armoured hull is exhausted
        local hp=CINE.cargoArmor(c,sh.HitpointsLeft,ba.getMissionFrametime())
        if hp>1 then sh.HitpointsLeft=hp;c.lastHull=hp;return true end
        return false
    end
    sh.HitpointsLeft=sh.HitpointsMax*0.30;sh:setFlag(true,'invulnerable')
    log('CARGO_SAVED (death cancelled during the cinematic)')
    return true
end)

-- ===================== gameplay mode (missions _SPT_Aurore_Evasion_Jeu*) =====================
-- 10 s intro (skippable: Espace / Entree / Echap), then the player flies. The wingmen are FSO AI with target
-- orders, TIE patrols in the canyon, the cargo can be lost (failure), the player jumps himself at the end.
-- arrival points, computed identically on every machine from the deterministic cargo path and written into the
-- parse objects before the ships arrive (the arrival is then created by the server and sent to the clients)
local PATROLS={{'Patrouille Noire',3,3700},{'Patrouille Grise',3,0}}
function CINE.placeArrivals(c)
    PATROLS[2][3]=c.Lc*0.5+2600
    local pos={}
    for _,pt in ipairs(PATROLS) do
        local base=sample(c.path,math.min(pt[3],c.Lc-200));local up=unit(base-C)
        local back=unit(sample(c.path,math.max(0,pt[3]-400))-base);local side=unit(cross(up,back))
        for k=1,pt[2] do pos[pt[1]..' '..k]={base+up*(320+k*30)+side*((k-(pt[2]+1)/2)*90),ba.createOrientationFromVectors(back,up)} end
    end
    local p=sample(c.path,c.La);local f=unit(sample(c.path,c.La+2000)-p);local u=unit(p-C);local r=unit(cross(u,f))
    for k,n in ipairs({'Chimere','Tyran','Vengeance'}) do
        local q=p+f*(14000+k*2500)+r*((k-2)*7000)+u*(900*(k-2)+1500)
        pos['Destroyer '..n]={q,ba.createOrientationFromVectors(unit(p-q),u)}
    end
    for _,tg in ipairs(c.targets) do
        if tg.name:find('^Tour de') then
            local b=tg.pos;local up=unit(b-C);local f=unit(sample(c.path,tg.s+600)-sample(c.path,tg.s))
            for k=1,4 do pos['Renfort '..k]={b+up*(900+k*40)+f*(1500+k*60),ba.createOrientationFromVectors(f*-1,up)} end
        end
    end
    local n=0
    for po in mn.getArrivalList() do
        local e=pos[po.Name]
        if e then po.Position=e[1];po.Orientation=e[2];n=n+1 end
    end
    log(string.format('ARRIVALS placed=%d',n))
end
-- progress of the cargo along its path from its (synced) position: multiplayer clients
function CINE.projectS(c,p)
    local tab=c.path.tab
    local i0=c.sIdx or 1
    local best,bd=i0,1e18
    for i=math.max(1,i0-3),math.min(#tab,i0+60) do local d=length(tab[i].p-p);if d<bd then best,bd=i,d end end
    c.sIdx=best
    return tab[best].s
end
-- mission events ask the server's director which phase it has reached (spacesim-sexp.tbm)
mn.LuaSEXPs['spacesim-phase-reached'].Action=function(n)
    local c=CINE.c
    return (c and (c.netPhase or 0)>=n) or false
end

local function myShip()
    local p=hv.Player
    return p and p:isValid() and mn.Ships[tostring(p)] or nil
end

function CINE.gameplay(c,T,dt)
    local cargo=c.cargo
    local me=myShip()
    local single=not ba.MultiplayerMode
    if c.skip and single and not c.handover and T<10 then c.t0=c.t0-(10-T);c.skip=false;log('INTRO skipped') end
    -- handover: my ship (and only mine) is mine to fly from now on
    if not c.handover and T>=10 then
        c.handover=true;c.handoverT=T
        if not c.bot then
            gr.setCamera();hu.HUDDrawn=true;c.cockpit=false
            if ok(me) then
                local up=unit(me.Position-C)
                local f=unit(sample(c.path,c.s+400)-sample(c.path,c.s));f=unit(f-up*dot(f,up))
                me.Orientation=ba.createOrientationFromVectors(f,up);me.Physics.Velocity=f*130
                me:setFlag(false,'no-dynamic')
                mn.runSEXP(string.format('( set-player-throttle-speed "%s" 75 )',me.Name))
            end
        end
        if c.server then
            for k=2,4 do local x=c.xw[k];if ok(x) and not x:isPlayer() then x:setFlag(false,'no-dynamic');x:clearOrders();x:giveOrder(ORDER_GUARD,cargo) end end
        end
        c.subs[#c.subs+1]={T+0.5,6,'ECHO BASE','Escadron Rouge, a vous ! Ouvrez la route a l\'Aurore : detruisez les batteries du canyon.'}
        log('HANDOVER player='..(c.bot and 'bot' or 'pilot'))
    end
    if not c.handover then return end
    -- server: AI wingmen (FSO AI) take the nearest live target ahead of the cargo; guard it during the climb
    if c.server and (c.phase=='canyon' or c.phase=='camp') and T-(c.aiT or 0)>1 then
        c.aiT=T
        local taken={}
        for k=2,4 do local t=c.xs[k].aiTarget;if t then taken[t]=true end end
        for k=2,4 do
            local x=c.xw[k];local xs=c.xs[k]
            if ok(x) and not x:isPlayer() and not x:isDying() and (not xs.aiTarget or isDead(xs.aiTarget)) then
                if xs.aiTarget then taken[xs.aiTarget]=nil;xs.aiTarget=nil end
                local best,bd=nil,1e9
                for _,tg in ipairs(c.targets) do
                    if not taken[tg.name] and not isDead(tg.name) and tg.s>c.s-400 and tg.s<c.s+4500 then
                        local sh=mn.Ships[tg.name]
                        if ok(sh) then local d=length(sh.Position-x.Position);if d<bd then best,bd=tg,d end end
                    end
                end
                if best then
                    xs.aiTarget=best.name;taken[best.name]=true;xs.guarding=nil
                    x:clearOrders();x:giveOrder(ORDER_ATTACK,mn.Ships[best.name])
                    log(string.format('AI %s -> %s (%.0f m)',x.Name,best.name,bd))
                elseif not xs.guarding then xs.guarding=true;x:clearOrders();x:giveOrder(ORDER_GUARD,cargo) end
            end
        end
    end
    if c.server and c.phase=='montee' and not c.climbOrders then
        c.climbOrders=true
        for k=2,4 do local x=c.xw[k];if ok(x) and not x:isPlayer() then x:clearOrders();x:giveOrder(ORDER_GUARD,cargo) end end
    end
    -- arrivals check (log once per group)
    local function count(prefix,n) local a=0;for k=1,n do local x=mn.Ships[prefix..' '..k];if ok(x) then a=a+1 end end;return a end
    for _,g in ipairs({{'Patrouille Noire',3,1},{'Patrouille Grise',3,2},{'Destroyer',0,3},{'Chimere',4,4},{'Tyran',4,4},{'Vengeance',4,4}}) do
        local key='arr_'..g[1]
        if c.netPhase>=g[3] and not c[key] then
            local a=g[2]>0 and count(g[1],g[2]) or #(c.isds or {})
            if a>0 then c[key]=true;log(string.format('ARRIVED %s x%d at T=%.0f',g[1],a,T)) end
        end
    end
    -- TIE patrols in the canyon from the start: mission arrivals (wings), triggered through the phase SEXP
    if T>c.handoverT+6 and c.netPhase<1 then c.netPhase=1;log('PHASE patrol 1') end
    if c.s>c.Lc*0.5 and c.netPhase<2 then c.netPhase=2;log('PHASE patrol 2') end
    -- the Aurore lost: failure (every machine shows it, the server ends the mission)
    if not c.failed and not c.cargoJumped and (not ok(cargo) or cargo:isDying()) then
        c.failed=T;log('FAILED cargo lost')
        c.subs[#c.subs+1]={T+1,7,'ECHO BASE','Nous avons perdu l\'Aurore... Mission echouee.'}
    end
    if c.server and c.failed and T-c.failed>9 and not c.ended then c.ended=true;mn.runSEXP('( end-mission )') end
    -- final jump: each pilot is allowed to jump his own ship; too late = caught by the shockwave (server)
    if c.tImpact and not c.jumpAllowed then
        c.jumpAllowed=T
        if ok(me) then me:setFlag(false,'never-warp');me:setFlag(false,'no-departure-warp') end
        if single then
            mn.runSEXP('( set-player-warp-status ( true ) )')
            if Respawner and Respawner.SetMission_Override then Respawner:SetMission_Override(-1) end
        end
        log('JUMP allowed')
    end
    -- test (data/spacesim-jeujump.flag): the pilot presses the jump key 3 s after the order
    if c.jumpAllowed and not c.playerJump and not c.testJump and T>c.jumpAllowed+3 and cf.fileExists('spacesim-jeujump.flag','data',true) then
        c.testJump=true;log('TEST jump key');ba.postGameEvent(ba.GameEvents['GS_EVENT_PLAYER_WARPOUT_START'])
    end
    if c.jumpAllowed and not c.playerJump and ok(me) and (me:isDepartingWarp() or (HyperspaceEnter and HyperspaceEnter.is_player_jumping_out)) then
        c.playerJump=true;c.playerJumpT=T;SPACESIM.state.cineJump=true;log('JUMP player (pilot)')
    end
    if c.server and c.tImpact and T-c.tImpact>26 and not c.shockKilled then
        c.shockKilled=true
        for k=1,4 do
            local x=c.xw[k]
            if ok(x) and not x:isDying() and not x:isDepartingWarp() and not (k==1 and c.bot) then log('SHOCKWAVE '..x.Name);x:kill(x) end
        end
    end
end

-- gameplay HUD: team objective and cargo hull, jump prompt
engine.addHook('On HUD Draw',function()
    local c=CINE.c
    if not (CINE.active and c and c.play and c.handover) or c.bot then return end
    local w,h=gr.getScreenWidth(),gr.getScreenHeight()
    local n,dead=0,0
    for _,tg in ipairs(c.targets) do if tg.name:find('^Batterie') then n=n+1;if isDead(tg.name) then dead=dead+1 end end end
    local cargo=c.cargo
    local hull=ok(cargo) and math.floor(100*cargo.HitpointsLeft/cargo.HitpointsMax) or 0
    gr.setColor(dead==n and 120 or 255,dead==n and 230 or 205,dead==n and 120 or 90,230)
    gr.drawString(string.format('BATTERIES  %d / %d',dead,n),w*0.035,h*0.30)
    local hc=hull>50 and {150,220,255} or (hull>25 and {255,200,80} or {255,80,60})
    gr.setColor(hc[1],hc[2],hc[3],230)
    gr.drawString(string.format('AURORE  coque %d %%',hull),w*0.035,h*0.30+22)
    if c.jumpAllowed and not c.playerJump and math.floor(mn.getMissionTime()*3)%2==0 then
        local t='SAUT HYPERSPATIAL : MAINTENANT !'
        gr.setColor(120,200,255,255);gr.drawString(t,(w-gr.getStringWidth(t))/2,h*0.22)
    end
end)
engine.addHook('On Key Pressed',function() end,{},function()
    local c=CINE.c
    if not (CINE.active and c and c.play and not c.handover) then return false end
    local k=hv.RawKey
    if k=='Spacebar' or k=='Enter' or k=='Esc' then c.skip=true;return true end
    return false
end)

-- ===================== content: rebel escorts, side objectives =====================
-- The Faucon de Brume (YT-1300) and the Lueur (GR-75) leave with the Aurore; the Lueur is shot down in the canyon.
local ESCORTS={{'Faucon de Brume',-260,-120,45},{'Lueur',-700,95,25}}
function CINE.escorts(c,T,dt)
    c.scripted=c.scripted or {}
    local cargo=c.cargo
    for _,e in ipairs(ESCORTS) do
        local sh=mn.Ships[e[1]]
        if ok(sh) and not sh:isDying() and not sh:isDepartingWarp() then
            c.scripted[e[1]]=true
            local pos,fwd,up
            if T<10 then
                if not c['start_'..e[1]] then c['start_'..e[1]]={sh.Position,sh.Orientation:getFvec()} end
                local st=c['start_'..e[1]];local w=sstep(5.5,10,T)
                up=unit(st[1]-C);pos=st[1]+up*(60*w);fwd=st[2]
            else
                local sv=math.max(0,c.s+e[2])
                local q=sample(c.path,sv);fwd=unit(sample(c.path,sv+80)-q);up=unit(q-C)
                local side=unit(cross(up,fwd))
                pos=q+side*e[3]+up*e[4]
            end
            local vel=ok(cargo) and cargo.Physics.Velocity or V(0,0,0)
            setShip(sh,pos,fwd,up,vel)
            if e[1]=='Lueur' and not c.lueurHit and c.s>2400 then
                c.lueurHit=T;sh:kill(sh);log('LUEUR shot down')
                c.subs[#c.subs+1]={T+0.5,5,'AURORE','La Lueur est touchee !... Non... ils etaient trente a bord.'}
                c.subs[#c.subs+1]={T+6,4.5,'ECHO BASE','Aurore, ne ralentissez pas. Rouges, ces batteries !'}
            end
            if c.cargoJumped and not c['jump_'..e[1]] then c['jump_'..e[1]]=true;sh:clearOrders();sh:warpOut() end
        end
    end
end

-- gameplay side objectives (server): the communication tower calls interceptors if it survives the
-- cargo's passage; the Lambda shuttle tries to escape to orbit to warn the fleet
CINE.flags={}
mn.LuaSEXPs['spacesim-flag'].Action=function(name) return CINE.flags[name]==true end
function CINE.sideEvents(c,T,dt)
    if not c.handover then return end
    for _,tg in ipairs(c.targets) do
        if tg.name:find('^Tour de') and not c.towerDone then
            if isDead(tg.name) then
                c.towerDone=true;c.subs[#c.subs+1]={T+0.5,4.5,'ROUGE 3','Tour de communication detruite : ils sont sourds !'}
            elseif c.s>tg.s+300 then
                c.towerDone=true;if c.server then CINE.flags.renforts=true end;log('FLAG renforts')
                c.subs[#c.subs+1]={T+0.5,5,'ECHO BASE','La tour a donne l\'alerte : intercepteurs en approche !'}
            end
        end
    end
    -- the Lambda: takes off when the cargo approaches the outpost, climbs away, jumps above 9 km
    local lam=mn.Ships['Lambda Ombre']
    local lt=nil;for _,tg in ipairs(c.targets) do if tg.name=='Lambda Ombre' then lt=tg end end
    if lt and not c.lambdaT and ok(lam) and not lam:isDying() and c.s>lt.s-2500 then
        c.lambdaT=T;c.lam={p=lam.Position,v=8,f=unit(sample(c.path,lt.s+1500)-sample(c.path,lt.s))}
        c.subs[#c.subs+1]={T+0.5,5,'ROUGE 2','Une navette decolle de l\'avant-poste ! Abattez-la avant qu\'elle ne saute !'}
        log('LAMBDA takes off')
    end
    if c.lambdaT and c.server and ok(lam) and not lam:isDying() and not c.lambdaGone then
        local L=c.lam;local t=T-c.lambdaT
        local up=unit(L.p-C);local fh=unit(L.f-up*dot(L.f,up))
        local g=SPACESIM.surface(L.p+fh*L.v*2);local clearance=g and (length(L.p+fh*L.v*2-C)-length(g-C)) or 999
        local climb=t<4 and 1.4 or clamp(0.18+0.006*t+(clearance<180 and 0.5 or 0),0,0.9)
        local dir=unit(fh*math.cos(climb)+up*math.sin(climb))
        L.v=math.min(260,L.v+(t<4 and 4 or 22)*dt)
        L.p=L.p+dir*L.v*dt
        c.scripted=c.scripted or {};c.scripted['Lambda Ombre']=true
        setShip(lam,L.p,unit(fh+up*0.15),up,dir*L.v)
        if length(L.p-C)-80000>9000 then
            c.lambdaGone=true;lam:clearOrders();lam:warpOut();log('LAMBDA escaped')
            c.subs[#c.subs+1]={T+0.5,5,'ECHO BASE','La navette est passee en hyperespace... la flotte sait ou nous allons.'}
        end
    end
    if c.lambdaT and not c.lambdaDown and isDead('Lambda Ombre') and not c.lambdaGone then
        c.lambdaDown=true;c.subs[#c.subs+1]={T+0.5,4,'ROUGE 4','Navette abattue ! Elle ne previendra personne.'}
    end
end
