pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
--islander by carson kompon
function _init()
	menuitem(1,"return to title",init_menu)
	reset_pal()
	init_game()
	init_menu()
	music(0,5000)
	started=false
	gamever = "V1.0.0"
end

function _update60()
	if(gamestate==1) update_game()
	if gamestate==0 then
		local xxx=camx+cammove[1]
		local yyy=camy+cammove[2]
		if(xxx > 896 or xxx < 0) cammove[1]*=-1
		if(yyy > 128 or yyy < 0) cammove[2]*=-1
		camx+=cammove[1]
		camy+=cammove[2]
		cx=camx
		cy=camy
		if btnp(⬆️) then
			mmenusel-=1
			if(mmenusel<1)mmenusel=3
			mmenux[mmenusel]=4
		elseif btnp(⬇️) then
			mmenusel+=1
			if(mmenusel>3)mmenusel=1
			mmenux[mmenusel]=4
		end
		if btnp(🅾️) then
			if loading then
				load_game()
				loading=false
			elseif options then
				if(mmenusel==1) enableshake= not enableshake
				if mmenusel==2 then
					waves=not waves
					if waves then music(0,5000)
					else music(-1) end
				end
				if(mmenusel==3) options=false;mmenusel=1
			else
				if(mmenusel==1) starting=true;started=true
				if(mmenusel==2) loading=true
				if(mmenusel==3) options=true;mmenusel=1
			end
		end
		guiy=lerp(guiy,128,0.0325)
	end
	
	for i=1,3 do
		if i==mmenusel then
			mmenux[i] = lerp(mmenux[i],-4,0.125)
		else
			mmenux[i] = lerp(mmenux[i],0,0.125)
		end
	end
	if starting then
		mmenuy = lerp(mmenuy,128,0.125)
		if(ceil(mmenuy)==128) gamestate=1menuitem(2,"save game",save_game)
	else
		mmenuy = lerp(mmenuy,0,0.125)
	end
end

function _draw()
	draw_game()
	if gamestate == 0 then
		local my = flr(mmenuy)
		spr(68,camx+28,camy+14-my,9,2)
		if loading then
			local st="pRESS ctrl+v, THEN PRESS z/c"
			print_outline(st,camx+64-#st*2,camy+my+90,7)
		else
			local st =""
			st = "sTART gAME"
			if(started) st="rETURN TO gAME"
			if(options)st="sCREENSHAKE: "..onoff(enableshake)
			if(mmenusel==1)st="➡️ "..st
			print_outline(st,camx+64-#st*2+flr(mmenux[1]),camy+my+80,7)
			st = "lOAD gAME"
			if(options)st="wAVES: "..onoff(waves)
			if(mmenusel==2)st="➡️ "..st
			print_outline(st,camx+64-#st*2+flr(mmenux[2]),camy+my+90,7)
			st = "oPTIONS"
			if(options)st="bACK"
			if(mmenusel==3)st="➡️ "..st
			print_outline(st,camx+64-#st*2+flr(mmenux[3]),camy+my+100,7)
		end
		print_outline(gamever,camx+2,camy+my+121,7)
		local txt="bY cARSON kOMPON"
		print_outline(txt,camx+127-#txt*4,camy+my+121,7)
	end
end

--[[todo:
screenshake option in main menu
]]

--main menu--

function init_menu()
	gamestate=0
	win=false
	won=false
	leaving=0
	boats={}
	camx=0
	camy=0
	loading=false
	starting=false
	options=false
	cammove={0.5,0.25}
	mmenuy=128
	mmenux=split"0,0,0"
	mmenusel=1
	menuitem(2)
end

function onoff(i)
	if(i) return "oN"
	return "oFF"
end
-->8
--game functions--

function init_game()
	gamestate=1
	init_recipies()
	init_player()
	init_goals()
	cx=0
	cy=0
	camx=cx
	camy=cy
	shake=0
	shakedec=0
	prompty=-128
	craftx=128
	contx=128
	craftprompty=11
	craftselect=1
	guiy=128
	enableshake=true
	waves=true
	foragry={}
	craftq={}
	tcrafts={}
	containers={}
	drops={}
	scores={}
	ground={}
	savetime=0
	switchitem=0
	tm=0
	
	for i=0,127 do
		for j=0,63 do
			if not (i==119 and j==7) and not (i==71 and j==24) and not (i==25 and j==25) and i*8 != ply.x and j*8 != ply.y and mget(i,j)==64 and flr(rnd(100))<50 then
				spawn_nature(i,j)
			end
		end
	end
	spawn_foragry(38,119,7)
	spawn_foragry(38,25,25)
	spawn_foragry(38,71,24)
	containers={{x=119*8,y=7*8,inv={split"44,1",split"61,2",split"59,4",split"51,12"}},{x=25*8,y=25*8,inv={split"35,12",split"42,32",split"21,8"}},{x=71*8,y=24*8,inv={split"51,5",split"41,12",split"59,2",split"49,20"}}}
end

function update_game()
	tm+=1
	
	if(savetime>0)savetime-=1
	if(switchitem>0)switchitem-=1
	
	if(not win and crafting==0 and container==0) update_player()
	update_drops()
	update_crafting(recipies[crafting])
	update_containers()
	update_ctables()
	update_foragry()
	update_scorenums()
	update_goals()
	
	if tm%(60*5)==0 then
		spawn_nature(flr(camx/8)+flr(rnd(16)),flr(camy/8)+flr(rnd(16)))
		--spawn_nature(flr(ply.x/8)*8,flr(ply.y/8)*8)
	end
	
	--❎ prompt
	if btn(❎) and not caninteract and crafting==0 then
		prompty=lerp(prompty,0,0.325)
	else
		prompty=lerp(prompty,-128,0.125)
	end
	if crafting>0 then
		craftx=lerp(craftx,0,0.325)
	else
		craftx=lerp(craftx,128,0.125)
	end
	if container>0 then
		contx=lerp(contx,0,0.325)
	else
		contx=lerp(contx,128,0.125)
	end
	
	--screenshake
	if(shake > 0) shake -= shakedec
	if(shake < 0) shake = 0
	
	for b in all(boats) do
		if not win and coll(ply,b) then
			win=true
			mset(b.x/8,b.y/8,0)
			sfx(1,3)
		end
	end
	
	--camera
	if not win then
		cx = lerp(cx,ply.x-60,0.125)
		cy = lerp(cy,ply.y-60,0.125)
		camx=cx
		camy=cy
		guiy = lerp(guiy,0,0.125)
	else
		if leaving == 0 then
			guiy = lerp(guiy,128,0.0325)
			ply.x = lerp(ply.x,boats[1].x,0.0325)
			ply.y = lerp(ply.y,boats[1].y-4,0.0325)
			if round(ply.x)==boats[1].x and round(ply.y)==boats[1].y-4 then
				leaving=120
			end
		else
			if won then
				camx=lerp(camx,0,0.0325)
				camy=lerp(camy,0,0.0325)
				if round(camx)==0 and round(camy)==0 then
					ply.x=64
					ply.y=64
					init_menu()
				end
			else
				if(leaving>1)leaving-=1
				if(leaving==2)sfx(2,3)
				if leaving==1 then
					boats[1].x += ply.lh/4
					boats[1].y += ply.lv/4
					ply.x = boats[1].x
					ply.y = boats[1].y-4
				else
					ply.x = lerp(ply.x,boats[1].x,0.0325)
					ply.y = lerp(ply.y,boats[1].y-4,0.0325)
				end
				if ply.x+32 < camx or ply.y+32 < camy or ply.x-32 > camx+128 or ply.y-32 > camy+128 then
					won=true
					goal=#goals+1
				end
			end
		end
	end
	
	if enableshake then
		camx+=rnd(shake)-shake/2
		camy+=rnd(shake)-shake/2
	end
	
	if btnp(🅾️,1) then
		save_game()
	end
end

function draw_game()
	cls(12)
	camera(camx,camy)
	
	draw_map()
	
	if(gamestate==1 and not win)spr_outline(16,cursorx,cursory,false,0)
	
	draw_foragry(false)
	
	draw_drops()
	
	if gamestate==1 then
		draw_player()
		draw_held_item()
		draw_foragry(true)
	end
	
	for b in all(boats) do
		spr(43,b.x,b.y)
	end
	
	if caninteract then
		print_outline("❎",cursorx+1,cursory-6,7,0)
	end
	
	draw_foragry_bars()
	
	draw_scorenums()
	
	draw_gui(camx,camy+ceil(guiy))
	
	if(ceil(craftx)<128)draw_crafting(camx+craftx,camy,recipies[max(crafting,1)])
	if(ceil(contx)<128)draw_container(camx+contx,camy,container)
	
	if(savetime>0) print_outline("sAVED TO cLIPBOARD!",camx+2,camy+2,7)
end

function draw_gui(x,y)
	--inventory bar
	for i=0,9 do
		local col=5
		if(ininv and ply.held==i+1) col=6
		local ii=i*11
		rectfill(x+9+ii,y+114,x+20+ii,y+125,col)
		rect(x+9+ii,y+114,x+20+ii,y+125,0)
	end
	if switchitem>0 and ply.held <= #ply.inv then
		local itemname = item_name(ply.inv[ply.held][1])
		print_outline(itemname,x+64-#itemname*2,y+107,7)
	end
	--inventory items
	for i=1,#ply.inv do
		local j = i-1
		local cnt = ply.inv[i][2]
		spr(ply.inv[i][1],x+11+j*11,y+116)
		if cnt>1 then
			print_outline(cnt,x+11+j*11+10-#tostr(cnt)*4,y+116+4,7,0)
		end
	end
	
	--❎ prompts
	if flr(prompty)>-128 then
		local yyy=y+prompty
		if(savetime==0)print_outline("tab - sAVE gAME",x+2,yyy+3,7)
		local st = [[
  ⬆️  
⬅️  ➡️
  ⬇️  ]]
		print_outline(st,x+52,yyy+24,7,0)
		st = "iNV lEFT"
		print_outline(st,x+40-#st*3,yyy+30,7,0)
		st = "iNV rIGHT"
		print_outline(st,x+80,yyy+30,7,0)
		st = "cRAFTING"
		print_outline(st,x+64-#st*2,yyy+14,7,0)
		st = "dROP iTEM"
		print_outline(st,x+64-#st*2,yyy+44,7,0)
		if goal <= #goals then
			st= "cURRENT gOAL:"
			print_outline(st,x+64-#st*2,yyy+70,7)
			st= goals[goal].str
			print_outline(st,x+64-#st*2,yyy+80,7)
		end
	end
end

--draw faux 3d map
function draw_map()
	local cxx = flr(camx/8)
	local cyy = flr(camy/8)
	for i=cxx,cxx+16 do
		local wy = round(sin((t()/10)+i/100)*4)-2
		for j=cyy-2,cyy+16 do
			pal(11,get_biome(i))
			local tile = mget(i,j)
			if tile > 0 and tile~=66 then
				local ii = i*8
				local jj = j*8
				if mget(i,j+1)==0 or mget(i,j+1)==66 then
					rectfill(ii,jj+8,ii+7,jj+16-wy,4)
					line(ii,jj+16-wy,ii+7,jj+16-wy,7)
				end
				spr(tile,ii,jj)
				if(mget(i-1,j)==0 or mget(i-1,j)==66)line(ii,jj,ii,jj+7,0)
				if(mget(i+1,j)==0 or mget(i+1,j)==66)line(ii+7,jj,ii+7,jj+7,0)
				if(mget(i,j-1)==0 or mget(i,j-1)==66)line(ii,jj,ii+7,jj,0)
				if mget(i,j+1)==0 or mget(i,j+1)==66 then
					line(ii,jj+7,ii+7,jj+7,0)
					--line(i*8,j*8+8,i*8+7,j*8+8,5)
				end
			end
		end
	end
	pal(11,11)
end

function add_score(n,xx,yy)
	add(scores,{
	x=xx,y=yy,ey=yy-8,str="+"..tostr(n)
	})
end

function popup(st)
	add(scores,{
	x=ply.x+3,y=ply.y-4,ey=ply.y-12,str=st
	})
end

function update_scorenums()
	for s in all(scores) do
		s.y = lerp(s.y,s.ey,0.0425)
		if flr(s.y) == flr(s.ey) then
			del(scores,s)
		end
	end
end

--draw score fx
function draw_scorenums()
	for s in all(scores) do
		print_outline(s.str,s.x-#s.str*2,s.y,7,0)
	end
end
-->8
--player controller--

function init_player()
	ply={
	x=64,y=64,hs=0,vs=0,spd=1,
	flp=false,lanim=0,lh=1,lv=0,
	inv={split"48,1"},held=1,use=0,used=100,
	step=0,
	box=split"1,3,6,7"
	}
	pressingx=false
	caninteract=false
	ininv=true
	crafting=0
	container=0
	heldx=0
	heldy=0
	cursorx=0
	cursory=0
	fric=0.1
end

--player update
function update_player()

	--movement
	local btnx = btn(❎)
	if btn(➡️) and not btnx then
		ply.flp = false
		if(ply.hs < ply.spd) ply.hs += fric
		ply.lh=1
		ply.lv=0
	elseif btn(⬅️) and not btnx then
		ply.flp = true
		if(ply.hs > -ply.spd) ply.hs -= fric
		ply.lh=-1
		ply.lv=0
	else
		if(abs(ply.hs) > 0) ply.hs -= fric*sgn(ply.hs)
	end
	if btn(⬇️) and not btnx then
		if(ply.vs < ply.spd) ply.vs += fric
		ply.lh=0
		ply.lv=1
	elseif btn(⬆️) and not btnx then
		if(ply.vs > -ply.spd) ply.vs -= fric
		ply.lh=0
		ply.lv=-1
	else
		if(abs(ply.vs) > 0) ply.vs -= fric*sgn(ply.vs)
	end
	
	--place cursor
	cursorx=round(ply.x/8)*8+ply.lh*8
	cursory=round(ply.y/8)*8+ply.lv*8
	
	local cblock = get_foragry(cursorx,cursory)
	caninteract = get_foragry_interact(cblock)
	
	if caninteract and btnp(❎) then
		local cctype = crafting_type(cblock)
		if cctype == 0 then
			open_container(cursorx,cursory)
		else
			init_crafting(cctype)
		end
	end
	
	--swap items
	if btnx and not caninteract then
		if btnp(⬅️) then
			inv_nav(-1)
		elseif btnp(➡️) then
			inv_nav(1)
		elseif btnp(⬆️) then
			init_crafting(1)
		elseif btnp(⬇️) then
			if ply.held <= #ply.inv then
				local heldid = ply.inv[ply.held][1]
				local heldcnt = ply.inv[ply.held][2]
				take_item(heldid,heldcnt)
				drop_item(ply.x,ply.y,heldid,heldcnt)
			end
		end
	end
	
	--use item
	if ply.use == 0 and ply.held <= #ply.inv and btn(🅾️) then
		local itemid = ply.inv[ply.held][1]
		sfx(10,2)
		screenshake(1,0.1)
		if(item_canhit(itemid)) hit_foragry(cursorx,cursory,item_dmg(itemid))
		if(item_canplace(itemid)) place_foragry(itemid,cursorx,cursory)
		if(item_candig(itemid)) hit_ground(cursorx,cursory,item_dmg(itemid))
		ply.use = item_usetime(itemid)
		ply.used = ply.use
	elseif ply.use > 0 then
		ply.use-=1
	end
	
	--get unstuck
	while cmap(ply,ply.x,ply.y) do
		ply.x-=ply.lh
		ply.y-=ply.lv
	end
	
	while cmap(ply,ply.x+ply.hs,ply.y) do
		ply.hs-=fric*sgn(ply.hs)
	end
	while cmap(ply,ply.x+ply.hs,ply.y+ply.vs) do
		ply.vs-=fric*sgn(ply.vs)
	end
	
	--step sounds
	if (ply.hs!=0 or ply.vs!=0) and tm%10==0 then
		sfx(8+ply.step,1)
		if ply.step==0 then ply.step=1
		else ply.step=0 end
	end
	
	ply.x+=ply.hs
	ply.y+=ply.vs
end

--inventory navigation
function inv_nav(d)
	sfx(14,1)
	switchitem=120
	if d<0 then
		ply.held-=1
		if(ply.held<1)ply.held=10
	else
		ply.held+=1
		if(ply.held>10)ply.held=1
	end
end

function draw_player()
	if ply.hs != 0 or ply.vs != 0 then
		anim_outline(ply,1,3,5,ply.flp,ply.x,ply.y)
	else
		spr_outline(1,ply.x,ply.y,ply.flp,0)
	end
	if #craftq>0 then
		draw_healthbar(ply.x,ply.y-3,ply.x+7,ply.y,craftq[1].ct/item_craft_time(craftq[1].id),9)
	end
end

function draw_held_item()
	local xoff = -5
	local yoff = 0
	if(ply.flp) xoff*=-1
	local xflp = ply.flp
	local yflp = false
	if ply.use > ply.used/2 then
		xflp = not xflp
		--yflp = not yflp
		xoff-=8*sgn(xoff)
		yoff=2
	end
	heldx=lerp(heldx,xoff,0.325)
	heldy=lerp(heldy,yoff,0.325)
	if(ply.held<=#ply.inv) spr(ply.inv[ply.held][1],ply.x+heldx,ply.y+heldy,1,1,xflp,yflp)
end
-->8
--useful functions--

--collision box
function abs_box(s)
	local box = {}
	box[1] = s.box[1] + s.x
	box[2] = s.box[2] + s.y
	box[3] = s.box[3] + s.x
	box[4] = s.box[4] + s.y
	return box
end

--collision
function coll(a,b)
	local box_a = abs_box(a)
	local box_b = {b.x,b.y,b.x+7,b.y+7}
	
	if box_a[1] > box_b[3] or
	   box_a[2] > box_b[4] or
	   box_b[1] > box_a[3] or
	   box_b[2] > box_a[4] then
	   return false
	end
	
	return true
end

--map collision
function cmap(o,x,y)
  local ct=false

  -- if no map tile
  local x1=(x+o.box[1])/8
  local y1=(y+o.box[2])/8
  local x2=(x+o.box[3])/8
  local y2=(y+o.box[4])/8
  local a=mget(x1,y1)==0
  local b=mget(x1,y2)==0
  local c=mget(x2,y2)==0
  local d=mget(x2,y1)==0
  ct=a or b or c or d
  
  if(not ct) ct=cmapf(x1,y1,x2,y2)
  
  return ct
end

--map collision
function cmapf(x1,y1,x2,y2)
  local ct=false

  -- if colliding with map tile
  local a=fget(mget(x1,y1),0)
  local b=fget(mget(x1,y2),0)
  local c=fget(mget(x2,y2),0)
  local d=fget(mget(x2,y1),0)
  ct=a or b or c or d

  return ct
end

--outline sprite
function spr_outline(sp,x,y,flp,col)
	for i=0,15 do
		pal(i,col)
	end
	for i=-1,1 do
		for j=-1,1 do
			if not(i==0 and j==0) then
				spr(sp,x+i,y+j,1,1,flp)
			end
		end
	end
	reset_pal()
	spr(sp,x,y,1,1,flp)
end

function reset_pal()
	pal()
	palt(0,false)
	palt(1,true)
end

--object, start frame,
--num frames, speed, flip
function anim(o,sf,nf,sp,fl,x,y)
	if o.lanim ~= sf then
		o.a_ct=0
		o.a_st=0
		o.lanim=sf
	end
	
	o.a_ct+=1
	
	if(o.a_ct%(30/sp)==0) then
		o.a_st+=1
		if(o.a_st==nf) o.a_st=0
	end
	
	o.a_fr=sf+o.a_st
	spr(o.a_fr,x,y,1,1,fl)
end

--object, start frame,
--num frames, speed, flip
function anim_outline(o,sf,nf,sp,fl,x,y,col)
	if o.lanim ~= sf then
		o.a_ct=0
		o.a_st=0
		o.lanim=sf
	end
	
	o.a_ct+=1
	
	if(o.a_ct%(30/sp)==0) then
		o.a_st+=1
		if(o.a_st==nf) o.a_st=0
	end
	
	o.a_fr=sf+o.a_st
	spr_outline(o.a_fr,x,y,fl,col)
end

--print outline
function print_outline(str,x,y,incol,outcol)
	for i=-1,1 do
		for j=-1,1 do
			if(i~=0 or j~=0) print(str,x+i,y+j,outcol)
		end
	end
	print(str,x,y,incol)
end

--linear interpolation
function lerp(pos,tar,perc)
 return pos+((tar-pos)*perc)
end

--round
function round(x)
	if(x-flr(x) < 0.5) return flr(x)
	return ceil(x)
end

--draw healthbar
function draw_healthbar(x1,y1,x2,y2,am,col)
	rectfill(x1,y1,x2,y2,0)
	rectfill(x1,y1,x1+(x2-x1)*am,y2,col)
	rect(x1,y1,x2,y2,0)
end

--choose random array
function choose(t)
	return t[flr(rnd(#t))+1]
end

--screenshake
function screenshake(am,dc)
	shake=am
	shakedec=dc
end
-->8
--items--

--get item name
function item_name(id)
	if id==20 then return "mULCH"
	elseif id==21 then return "gROUND"
	elseif id==32 then return "sTONE"
	elseif id==33 then return "wOOD"
	elseif id==34 then return "fLOWER"
	elseif id==35 then return "bRIDGE"
	elseif id==36 then return "wORKBENCH"
	elseif id==37 then return "fURNACE"
	elseif id==38 then return "cHEST"
	elseif id==39 then return "aNVIL"
	elseif id==48 then return "sTN. pICK"
	elseif id==49 then return "cOAL"
	elseif id==50 then return "iRON"
	elseif id==51 then return "iRON iNG."
	elseif id==52 then return "iRON pICK"
	elseif id==53 then return "iRON sHV."
	elseif id==54 then return "gOLD pICK"
	elseif id==55 then return "gOLD sHV."
	elseif id==56 then return "dIA. pICK"
	elseif id==57 then return "dIA. sHV."
	elseif id==58 then return "gOLD"
	elseif id==59 then return "gOLD iNG."
	elseif id==60 then return "dIAMOND"
	elseif id==61 then return "rEF. dIA."
	elseif id==40 then return "dEAD bUSH"
	elseif id==41 then return "wALL"
	elseif id==42 then return "bRICK"
	elseif id==62 then return "oBSIDIAN"
	elseif id==43 then return "bOAT"
	elseif id==44 then return "fLAG"
	end
	return "nil"
end

--get crafting time
function item_craft_time(id)
	if id>=52 and id <=57 then return 900
	elseif id==36 or id==37 or id==39 then return 600
	elseif id==38 or id==21 or id==41 then return 300
	elseif id==49 or id==20 or id==42 then return 120
	elseif id==51 or id==59 or id==61 then return 180
	elseif id==43 then return 1800
	end
	return 60
end

--get crafting time
function item_craft_amount(id)
	return 1
end

--give player items
function give_item(id,am,inv)
	inv = inv or ply.inv
	if(inv == ply.inv)add_score(am,ply.x+3,ply.y-4)
	for i=1,#inv do
		if id==inv[i][1] and inv[i][2]<100-am then
			inv[i][2]+=am
			return
		end
	end
	if inv == ply.inv and #ply.inv == 10 then
		drop_item(ply.x,ply.y,id,am)
		return
	end
	add(inv,{id,am})
end

--take items from player
function take_item(id,am,inv)
	inv = inv or ply.inv
	for i=1,#inv do
		if id==inv[i][1] then
			if(inv[i][2] < am) return false
			inv[i][2]-=am
			if inv[i][2] == 0 then
				deli(inv,i)
				return true
			end
			return true
		end
	end
end

--player has items
function has_items(id,am,inv)
	inv = inv or ply.inv
	for i=1,#inv do
		if id==inv[i][1] then
			if(inv[i][2] < am) return false
			return true
		end
	end
	return false
end

--item use timer
function item_usetime(i)
	if(i==48 or i==53) return 35
	if(i==52 or i==55) return 28
	if(i==54 or i==57) return 23
	if(i==56) return 15
	return 30
end

--item can hit
function item_canhit(i)
	if(i==48 or i==52 or i==54 or i==56) return true
	return false
end

function item_candig(i)
	if(i==53 or i==55 or i==57) return true
	return false
end

function item_dmg(i)
	return 1
end

--item can place
function item_canplace(i)
	if(i==21 or i==43 or i==34 or i==35 or (i>=36 and i<=41)) return true
	return false
end
-->8
--foragry--

function get_biome(x)
	if(x>=96) return 6
	if(x>=48) return 15
	return 11
end

function get_biome_stuff(b)
	local tilid = nil
	local chance = rnd(100)
	if b==11 or b==15 then
		if chance >= 55 then
			tilid=choose(split"32,33")
			if(b==15) tilid=choose(split"32,40")
		elseif chance >= 45 then
			tilid=34
		elseif chance >= 30 then
			tilid=49
		elseif chance >= 20 then
			tilid=50
		elseif chance >= 15 and b==15 then
			tilid=58
		end
	elseif b==6 then
		tilid=choose(split"32,49,50,58,60,40,40")
		if(rnd(100) < 10) tilid=62
	end
	return tilid
end

function get_foragry_id(id)
	if(id==33) return 47
	if(id==49) return 31
	if(id==50) return 30
	if(id==58) return 29
	if(id==60) return 28
	if(id==62) return 27
	return id
end

function get_foragry_height(id)
	if(id==33) return 2
	return 1
end

function get_foragry_hp(id)
	if id==50 then return 5
	elseif id==32 or id==49 then return 4
	elseif id==33 or id==35 then return 3
	elseif (id>=36 and id<=39) or id==41 or id==58 then return 6
	elseif id==21 or id==60 then return 8
	elseif id==62 then return 14
	end
	return 1
end

function get_foragry_drops(id)
	if id==32 or id==62 then return flr(rnd(2))+1
	elseif id==33 then return flr(rnd(3))+2
	elseif id==49 or id==50 or id==58 or id==60 then return flr(rnd(3))+1
	end
	return 1
end

function get_foragry_solid(id)
	if(id==34 or id==40) return false
	return true
end

function get_foragry_interact(id)
	if(id>=36 and id<=39) return true
	return false
end

function crafting_type(id)
	if(id==36) return 2
	if(id==37) return 3
	if(id==39) return 4
	return 0
end

function craft_station(x,y,idd)
	for f in all(tcrafts) do
		if f.x==x and f.y==y then
			if not f.craftq then
				f.craftq={}
			end
			add(f.craftq,{
			id=idd,ct=item_craft_time(idd)
			})
		end
	end
end

function get_foragry(x,y)
	for f in all(foragry) do
		if f.x == x and f.y == y then
			return f.id
		end
	end
	return 0
end

function foragry_placetile(id)
	if id==35 or id==21 or id==43 then return 0
	end
	return 64
end

function foragry_tile(id)
	if id==35 or id==43 then return 66
	elseif id==34 or id==40 then return 67
	elseif id==21 then return 64
	end
	return 80
end

function foragry_isbelow(id)
	if id==35 then return true
	end
	return false
end

function spawn_nature(xx,yy)
	--choose({32,33,34,49})
	local tilid = get_biome_stuff(get_biome(xx))
	if(tilid and mget(xx,yy)==64) spawn_foragry(tilid,xx,yy)
end

function spawn_foragry(i,xx,yy,placed)
	placed = placed or false
	if(xx<0 or yy<0 or xx>128 or yy>64) return false
	local ptile=foragry_placetile(i)
	local tile=foragry_tile(i)
	if mget(xx,yy)==ptile then
		local frg = {id=i,x=xx*8,y=yy*8,hp=get_foragry_hp(i),maxhp=get_foragry_hp(i),above=false,cooldown=0}
		mset(xx,yy,tile)
		local canadd=true
		if get_foragry_solid(i) and not placed then
			if cmap(ply,ply.x,ply.y) then
				canadd=false
				mset(xx,yy,ptile)
			end
		end
		if(canadd and tile ~= 64) add(foragry,frg)
		if i==43 then
			add(boats,{x=xx*8,y=yy*8})
		end
		if get_foragry_interact(i) then
			local cctype = crafting_type(i)
			if cctype == 0 then
				add(containers,{x=xx*8,y=yy*8,inv={}})
			else
				add(tcrafts,{x=xx*8,y=yy*8,craftq={}})
			end
		end
		sort_foragry()
		return true
	end
	return false
end

function hit_foragry(x,y,dmg)
	for f in all(foragry) do
		if f.x == x and f.y == y then
			f.hp-=dmg
			f.cooldown = 60*5
			sfx(12,1)
		end
	end
end

function hit_ground(xx,yy,dmg)
	if mget(xx/8,yy/8)==64 then
		local isground=false
		sfx(12,1)
		for f in all(ground) do
			if f.x == xx and f.y == yy then
				isground=true
				f.hp-=dmg
				f.cooldown = 60*5
			end
		end
		if not isground then
			add(ground,{x=xx,y=yy,hp=8,cooldown=300})
			ground[#ground].hp-=dmg
		end
	end
end

function place_foragry(id,xx,yy)
	if spawn_foragry(id,xx/8,yy/8,true) then
		take_item(id,1)
	end
end

function update_foragry()
	--ground check
	for f in all(ground) do
		if f.cooldown > 0 then
			f.cooldown-=1
			if(f.cooldown==0) f.hp+=1f.cooldown=300
			if(f.hp == 8) del(ground,f)
		end
		if f.hp <= 0 then
			sfx(11,2)
			mset(f.x/8,f.y/8,0)
			give_item(21,1)
			del(ground,f)
		end
	end
	--foragry check
	for f in all(foragry) do
		if f.x>=camx-8 and f.x<=camx+128 and f.y>=camy-8 and f.y<=camy+128 then
			--depth check
			if foragry_isbelow(f.id) then
				f.above=false
			else
				if ply.y < f.y then
					f.above=true
				else f.above=false end
			end
			
			if f.cooldown and f.cooldown > 0 then
				f.cooldown-=1
				if f.cooldown==0 then
					f.hp+=1
					if(f.hp < f.maxhp) f.cooldown=60
				end
			end
			
			--destroy foragry
			if f.hp <= 0 then
				sfx(11,2)
				mset(f.x/8,f.y/8,foragry_placetile(f.id))
				screenshake(3,0.2)
				give_item(f.id,get_foragry_drops(f.id))
				for tb in all(containers) do
					if tb.x==f.x and tb.y==f.y then
						for i=1,#tb.inv do
							drop_item(f.x+rnd(8)-4,f.y+rnd(8)-4,tb.inv[i][1],tb.inv[i][2])
						end
						del(containers,tb)
					end
				end
				for tb in all(tcrafts) do
					if tb.x == f.x and tb.y == f.y then
						del(tcrafts,tb)
					end
				end
				del(foragry,f)
			end
		end
	end
end

function update_ctables()
	for f in all(tcrafts) do
		if #f.craftq > 0 then
			f.craftq[1].ct-=1
			if f.craftq[1].ct <= 0 then
				give_item(f.craftq[1].id,item_craft_amount(f.craftq[1].id))
				deli(f.craftq,1)
				sfx(17,2)
			end
		end
	end
end

function draw_foragry(ab)
	for f in all(foragry) do
		if f.id ~= 43 and (f.above == ab or gamestate==0) then
			local hh = get_foragry_height(f.id)
			spr(get_foragry_id(f.id),f.x,f.y-(hh-1)*8,1,hh)
		end
	end
end

function draw_foragry_bars()
	--ground bars
	for f in all(ground) do
		if f.hp < 8 then
			draw_healthbar(f.x,f.y-3,f.x+7,f.y,f.hp/8,8)
		end
	end
	--foragry bars
	for f in all(foragry) do
		if f.hp < f.maxhp then
			draw_healthbar(f.x,f.y-3,f.x+7,f.y,f.hp/f.maxhp,8)
		elseif get_foragry_interact(f.id) then
			for g in all(tcrafts) do
				if g.x==f.x and g.y==f.y then
					if #g.craftq>0 then
						draw_healthbar(f.x,f.y-3,f.x+7,f.y,g.craftq[1].ct/item_craft_time(g.craftq[1].id),9)
					end
				end
			end
		end
	end
end

function sort_foragry()
	for i=1,#foragry do
		local j=i
		while j>1 and foragry[j-1].y > foragry[j].y do
			foragry[j],foragry[j-1] = {x=foragry[j-1].x,y=foragry[j-1].y,hp=foragry[j-1].hp,maxhp=foragry[j-1].maxhp,id=foragry[j-1].id,cooldown=foragry[j-1].cooldown},{x=foragry[j].x,y=foragry[j].y,hp=foragry[j].hp,maxhp=foragry[j].maxhp,id=foragry[j].id,cooldown=foragry[j].cooldown}
			j-=1
		end
	end
end
-->8
--crafting--

function init_crafting(i)
	poke(0x5f43,1)
	crafting=i
	pressingx=true
	craftselect=1
	if(i==1)craftselect=2
	sfx(18,2)
end

function init_recipies()
	recipies={}
	recipies[1]={}
	recipies[2]={}
	recipies[3]={}
	recipies[4]={} --6127
	add_recipie(1,36,{split"33,10",split"32,10"})
	add_recipie(1,33,{split"40,2"})
	add_recipie(1,35,{split"33,4"})
	add_recipie(1,20,{split"34,4"})
	add_recipie(2,37,{split"32,10",split"49,10"})
	add_recipie(2,38,{split"33,15"})
	add_recipie(2,39,{split"32,20",split"51,4"})
	add_recipie(2,41,{split"42,4",split"51,1"})
	add_recipie(2,21,{split"20,4"})
	add_recipie(3,49,{split"33,4"})
	add_recipie(3,42,{split"32,4",split"49,1"})
	add_recipie(3,51,{split"50,3",split"49,1"})
	add_recipie(3,59,{split"58,3",split"49,1"})
	add_recipie(3,61,{split"60,3",split"49,1"})
	add_recipie(4,52,{split"48,1",split"51,6"})
	add_recipie(4,53,{split"51,4"})
	add_recipie(4,54,{split"52,1",split"59,8"})
	add_recipie(4,55,{split"53,1",split"59,4"})
	add_recipie(4,56,{split"54,1",split"61,10"})
	add_recipie(4,57,{split"55,1",split"61,4"})
	add_recipie(4,43,{split"44,1",split"62,30",split"33,50",split"42,20"})
end

function add_recipie(j,i,itms)
	add(recipies[j],{
	id=i,items=itms
	})
end

function update_crafting(recipies)
	if crafting>0 then
		--exit crafting
		if not pressingx and btnp(❎) then
			crafting=0
			craftselect=1
			sfx(19,2)
			poke(0x5f43,0)
		end
		--navigate recipies
		if btnp(⬆️) then
			sfx(14,1)
			craftselect-=1
			if(craftselect<1) craftselect=#recipies
		elseif btnp(⬇️) then
			sfx(14,1)
			craftselect+=1
			if(craftselect>#recipies) craftselect=1
		end
		--craft item
		if btnp(🅾️) then
			local cancraft=true
			for i=1,#recipies[craftselect].items do
				if(not has_items(recipies[craftselect].items[i][1],recipies[craftselect].items[i][2])) cancraft=false
			end
			if cancraft then
				sfx(15,1)
				for i=1,#recipies[craftselect].items do
					take_item(recipies[craftselect].items[i][1],recipies[craftselect].items[i][2])
				end
				local idd = recipies[craftselect].id
				if crafting == 1 then
					add(craftq,{
					id=idd,ct=item_craft_time(idd)
					})
				else
					craft_station(cursorx,cursory,idd)
				end
			else
				sfx(16,1)
			end
		end
		pressingx=btn(❎)
	end
	
	if #craftq > 0 then
		craftq[1].ct-=1
		if craftq[1].ct <= 0 then
			give_item(craftq[1].id,item_craft_amount(craftq[1].id))
			deli(craftq,1)
			sfx(17,2)
		end
	end
end

function draw_crafting(x,y,recipies)
	--draw header
	rectfill(x-1,y,x+128,y+6,5)
	print("🅾️ - sELECT | ❎ - bACK TO gAME",x+1,y+1,7)
	line(x-1,y+7,x+127,y+7,0)
	--draw all recipies
	for i=1,#recipies do
		local col = 5
		local bcol = 6
		if craftselect==i then
			col=6
			bcol=7
		end
		local ii=11*i
		rectfill(x+70,y+ii,x+120,y+ii+11,col)
		if crafting == 1 then
			local cq1 = craftq[1]
			if #craftq>0 and recipies[i].id==cq1.id then
				local am = 50*(cq1.ct/item_craft_time(cq1.id))
				rectfill(x+70,y+ii,x+70+am,y+ii+11,bcol)
			end
		else
			for f in all(tcrafts) do
				if f.x==cursorx and f.y==cursory then
					local ff = f.craftq[1]
					if f.craftq and #f.craftq>0 and recipies[i].id==ff.id then
						local am = 50*(ff.ct/item_craft_time(ff.id))
						rectfill(x+70,y+ii,x+70+am,y+ii+11,bcol)
					end
					break
				end
			end
		end
		rect(x+70,y+ii,x+120,y+ii+11,0)
		spr(recipies[i].id,x+72,y+ii+2)
		print(item_name(recipies[i].id),x+82,y+ii+4)
	end
	
	--draw recipie
	local crr = recipies[craftselect]
	local rh = 16+8*#crr.items
	local toy = 11*craftselect-4
	local yyy=y+craftprompty
	if(toy < 11) toy=11
	while toy+rh > 110 do toy-=1 end
	rectfill(x+66,yyy,x+8,yyy+rh,6)
	rect(x+66,yyy,x+8,yyy+rh,0)
	spr(crr.id,x+33,yyy+4)
	for i=1,#crr.items do
		local st = item_name(crr.items[i][1]) .. " X" .. crr.items[i][2]
		print(st,x+37-#st*2,yyy+14+8*(i-1))
	end
	craftprompty = lerp(craftprompty,toy,0.125)
end
-->8
--containers--
function is_container(id)
	if(id==38)return true
	return false
end

function open_container(xx,yy)
	pressingx=true
	ininv=true
	conselect=1
	poke(0x5f43,1)
	sfx(18,2)
	for i=1,#containers do
		if containers[i].x==xx and containers[i].y==yy then
			container=i
		end
	end
end

function update_containers()
	if container > 0 then
		--container navigation
		if btnp(⬅️) then
			if ininv then inv_nav(-1)
			else conselect-=1 sfx(14,1) end
			if(conselect<1)conselect+=9
		elseif btnp(➡️) then
			if ininv then inv_nav(1)
			else conselect+=1 sfx(14,1) end
			if(conselect>9) ininv=true
		elseif btnp(⬆️) and not ininv then
			sfx(14,1)
			conselect-=3
			if(conselect<1)conselect+=9
		elseif btnp(⬇️) and not ininv then
			sfx(14,1)
			conselect+=3
			if(conselect>9) ininv=true
		end
		--swap items
		if btnp(🅾️) then
			if ininv and ply.held <= #ply.inv and #containers[container].inv<9 then
				sfx(20,2)
				local heldid = ply.inv[ply.held][1]
				local heldcnt = ply.inv[ply.held][2]
				take_item(heldid,heldcnt)
				give_item(heldid,heldcnt,containers[container].inv)
			elseif not ininv and #containers[container].inv >= conselect then
				local heldid = containers[container].inv[conselect][1]
				local canadd=true
				if #ply.inv == 10 then
					canadd=false
					for i=1,10 do
						if(ply.inv[i][1]==heldid)canadd=true
					end
				end
				if canadd then
					sfx(20,2)
					local heldcnt = containers[container].inv[conselect][2]
					take_item(heldid,heldcnt,containers[container].inv)
					give_item(heldid,heldcnt)
				else sfx(16,2)
				end
			else
				sfx(16,2)
			end
		end
		if(ininv and btnp(⬆️))ininv=false;conselect=1sfx(14,1)
		
		--exit container
		if(not pressingx and btnp(❎))container=0ininv=true;sfx(19,2)poke(0x5f43,0)
		pressingx = btn(❎)
	end
end

function draw_container(x,y,id)
	--draw header
	rectfill(x-1,y,x+128,y+6,5)
	print("🅾️ - aDD/tAKE | ❎ - eXIT cHEST",x+1,y+1,7)
	line(x-1,y+7,x+127,y+7,0)
	--draw container
	local iid=0
	for j=0,2 do
		for i=0,2 do
			iid+=1
			local col=5
			if(not ininv and iid==conselect)col=6
			--draw container ui
			local ii = i*11
			local jj = j*11
			rectfill(x+46+ii,y+24+jj,x+46+ii+11,y+24+jj+11,col)
			rect(x+46+ii,y+24+jj,x+46+ii+11,y+24+jj+11,0)
			--draw items
			if container>0 then
				local cni = containers[container].inv
				if #cni >= iid then
					spr(cni[iid][1],x+46+ii+2,y+24+jj+2)
					local cnt = cni[iid][2]
					if cnt>1 then
						print_outline(cnt,x+46+ii+12-#tostr(cnt)*4,y+24+jj+6,7,0)
					end
				end
			end
		end
	end
end
-->8
--item drops--

function drop_item(xx,yy,idd,am)
	add(drops,{
	x=xx,y=yy,id=idd,cnt=am,col=true
	})
end

function update_drops()
	for d in all(drops) do
		if coll(ply,d) then
			if not d.col then
				local canadd=true
				if #ply.inv == 10 then
					canadd=false
					for i=1,10 do
						if(ply.inv[i][1]==d.id)canadd=true
					end
				end
				if canadd then
					give_item(d.id,d.cnt)
					del(drops,d)
				end
			end
		else
			d.col = false
		end
	end
end

function draw_drops()
	for d in all(drops) do
		spr(d.id,d.x,d.y)
		if d.cnt > 1 then
			print_outline(d.cnt,d.x+10-#tostr(d.cnt)*4,d.y+4,7)
		end
	end
end
-->8
--goals--

function init_goals()
	goals={}
	goal=1
	add_goal(split"cOLLECT X12 wOOD,33,12")
	add_goal(split"cRAFT X3 bRIDGES,35,3")
	add_goal(split"mINE X20 sTONE,32,20")
	add_goal(split"cRAFT A wORKBENCH,36,1")
	add_goal(split"mINE X10 cOAL,49,10")
	add_goal(split"cRAFT A fURNACE,37,1")
	add_goal(split"sMELT X4 iRON iNGOTS,51,4")
	add_goal(split"cRAFT AN aNVIL,39,1")
	add_goal(split"cRAFT AN iRON pICK,52,1")
	add_goal(split"cRAFT AN iRON sHOVEL,53,1")
	add_goal(split"cRAFT X4 wALLS,41,4")
	add_goal(split"cOLLECT/cRAFT X8 gROUND,21,8")
	add_goal(split"sMELT X8 gOLD iNGOTS,59,8")
	add_goal(split"cRAFT A gOLD pICK,54,1")
	add_goal(split"sMELT X10 rEFINED dIAMOND,61,8")
	add_goal(split"cRAFT A dIAMOND pICK,56,1")
	add_goal(split"mINE X30 oBSIDIAN,62,30")
	add_goal(split"cRAFT THE bOAT,43,1")
	add_goal(split"eSCAPE THE iSLANDS,43,99")
end

function add_goal(i)
	add(goals,{
	str=i[1],id=i[2],am=i[3]
	})
end

function update_goals()
	if goal <= #goals then
		local gl = goals[goal]
		if has_items(gl.id,gl.am) then
			sfx(21,3)
			popup("gOAL cOMPLETE!")
			goal+=1
		end
	end
end
-->8
--saving/loading--

function save_game()
	savetime=60*2
	--goal
	sav=goal.."|"..ply.x.."|"..ply.y..","
	--tiles
	for i=0,127 do
		for j=0,63 do
			local bid = mget(i,j)
			local bb = 64
			if(bid==0 or bid==66) bb = 0
			sav=sav..bb.."-"
		end
	end
	sav=sav..","
	--foragry
	for f in all(foragry) do
		sav=sav..f.id.."|"..f.x.."|"..f.y.."|"
	end
	sav=sav..","
	--inventory
	for i=1,#ply.inv do
		sav=sav..ply.inv[i][1].."|"..ply.inv[i][2].."|"
	end
	sav=sav..","
	--containers
	for f in all(containers) do
		sav=sav..f.x.."-"..f.y.."-"
		for i=1,#f.inv do
			sav=sav..f.inv[i][1].."|"..f.inv[i][2].."|"
		end
		sav=sav.."-"
	end
	printh(sav,"@clip")
end

function load_game()
	sv = stat(4)
	if sv ~= "" then
		sav = split(sv)
		if #sav==5 then
			--goal
			plyinf=split(sav[1],"|")
			goal = plyinf[1]
			ply.x=plyinf[2]
			ply.y=plyinf[3]
			--tiles
			local mtiles=split(sav[2],"-")
			local k=0
			for i=0,127 do
				for j=0,63 do
					k+=1
					mset(i,j,mtiles[k])
				end
			end
			--foragry
			k=1
			foragry={}
			local mfor=split(sav[3],"|")
			while k < #mfor do
				spawn_foragry(mfor[k],mfor[k+1]/8,mfor[k+2]/8)
				k+=3
			end
			--inventory
			k=1
			ply.inv={}
			local pinv=split(sav[4],"|")
			while k < #pinv do
				add(ply.inv,{pinv[k],pinv[k+1]})
				k+=2
			end
			--containers
			k=1
			containers={}
			local cnts=split(sav[5],"-")
			while k < #cnts do
				local iv = split(cnts[k+2],"|")
				local j=1
				local i={}
				while j < #iv do
					add(i,{iv[j],iv[j+1]})
					j+=2
				end
				add(containers,{x=cnts[k],y=cnts[k+1],inv=i})
				k+=3
			end
			started=true
		end
	end
end
__gfx__
00000000111111111111111111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000011fffff111fffff111fffff1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
007007001ff0f0f11ff0f0f11ff0f0f1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000770001ff0f0f11ff0f0f11ff0f0f1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700014fffff114fffff114fffff1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700114444111144441111444411000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000011cccc1111cdcc1111cccc11000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000011d11c111111c111111cd111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77111177000000000000000000000000000000000000000000000000000000000000000000000000000000001000001110000011100000111000001110000011
71111117000000000000000000000000044444400bbbbbb000000000000000000000000000000000000000000025700100cd700100a570010067700100677001
11111111000000000000000000000000004344000bbbbbb00000000000000000000000000000000000000000025667000cd667000a5667000fd6670000566700
11111111000000000000000000000000104434010bbbbbb00000000000000000000000000000000000000000056565200d6d6dc0056656500d6d6df005656500
1111111100000000000000000000000010f444010bbbbbb000000000000000000000000000000000000000000652565006dcd6d00665a5a006dfd6d006505650
1111111100000000000000000000000000ff440000000000000000000000000000000000000000000000000005522560055ccd60055aa550055ffd6005500560
71111117000000000000000000000000044ff4400444444000000000000000000000000000000000000000000005550000055500000555000005550000055500
77111177000000000000000000000000000000000000000000000000000000000000000000000000000000001100000111000001110000011100000111000001
10000011111000001100011100000000111111111100000111111111111111111111111100000000111100011100111111001111000000000000000011111111
0067700111004940107770110f4f4f40111111111105550100000000111111111111000104444040111002001107011111070111000000000000000011000011
066667001004944010797011044f4f4011111111000dd5000f4444f011111000100004010000000011002420110770111107701100000000000000001003b001
0666666000444900107770110f4f444000000000055555500f0000f00000006010404001040444401002442000000000110701110000000000000000003bb300
066666600f049001110301110f4f4f400ffffff00dd5ddd00009900006666600104400110202222000244200044444401100111100000000000000000bbbbb30
0555666009f00011110301110f4f4f4005555550055555500f0000f000666601100401110000000002442001044444201101111100000000000000000bbbbbb0
0005550000000111111111110f444f400044440005d000d00f4444f01005500111040111022220200022001100222200110111110000000000000000033bb330
11000001111111111111111100000000104004010550905000000000105555011111111100000000100001111000000111111111000000000000000000333300
1000000111111111111111111111000110000001000001111000000100000111100000010000011111111111111100011111111111000011111111110bb3bbb0
00666601110000111100001111100600007777010777001100aaaa010aaa001100cccc010ccc0011110001111110090011100011100c60011100001103bbb330
0646000110055001110ff0011100676007470001074770110a4a00010a4aa0110c4c00010c4cc011100a000111009a901000c00110ccc6011002200100333300
0664011100555501100fff011006776007740111077400110aa401110aa400110cc401110cc4001110aaaa011009aa9010cccc0110cddc01002220010bbbbbb0
060040110555500110fff4010067760007004011007040110a00401100a040110c00401100c0401110aaa901009aa90010cccd0110cddc01022200010333bb30
0601040100550001100440010677600107010401100004010a010401100004010c010401100004011009900109aa9001100dd00110cccc010000000100344300
00011040000000011100001100660011000110401111104000011040111110400001104011111040110000110099001111000011100cc0011000001110044001
11111100100000111111111110000111111111001111110011111100111111001111110011111100111111111000011111111111110000111111111111111111
bbbbbbbb5555555511111111bbbbbbbb111111111111111111111111111111111111111111111111111111111111111111111111000000000000000000000000
bbbbbbbb5555555511111111bbbbbbbb111000000000000000000000000000000000000000000000000000000000000000000111000000000000000000000000
bbbbbbbb5555555511111111bbbbbbbb111077707777777707770000777777770777777770777777770777777770777777770111000000000000000000000000
bbbbbbbb5555555511111111bbbbbbbb111077707777777707770000777777770777777770777777770777777770777777770111000000000000000000000000
bbbbbbbb5555555511111111bbbbbbbb111077707777777707770000777777770777777770777777770777777770777777770111000000000000000000000000
bbbbbbbb5555555511111111bbbbbbbb111077707776666607770000777666770677766770677666770777666660777666770111000000000000000000000000
bbbbbbbb5555555511111111bbbbbbbb111077707770000007770000777000770077700770077000770777000000777000770111000000000000000000000000
bbbbbbbb5555555511111111bbbbbbbb111077707777777707770000777000770077700770077000770777777770777000770111000000000000000000000000
bbbbbbbb444444440000000000000000111077707777777707770000777777770077700770077000770777777770777777770111000000000000000000000000
bbbbbbbb444444440000000000000000111077706666667707770000777777770077700770077000770777666660777777770111000000000000000000000000
bbbbbbbb444444440000000000000000111077700000007707770000777666770077700770077000770777000000777677760111000000000000000000000000
bbbbbbbb444444440000000000000000111077707777777707777770777000770077700770777777770777777770777067770111000000000000000000000000
bbbbbbbb444444440000000000000000111077707777777707777770777000770077700770777777770777777770777006770111000000000000000000000000
bbbbbbbb444444440000000000000000111066606666666606666660666000660066600660666666660666666660666000660111000000000000000000000000
bbbbbbbb444444440000000000000000111000000000000000000000000000000000000000000000000000000000000000000111000000000000000000000000
bbbbbbbb444444440000000000000000111111111111111111111111111111111111111111111111111111111111111111111111000000000000000000000000
__label__
00000bbb00000bbb00000bbbbbbbbbbb00000b044444444cccccccccccccccccccccccccccccccccccccccccccccccc44444444444444440bbbbbbbb00000bbb
067700b0067700b0067700bbbbbbbbb0067700044444444cccccccccccccccccccccccccccccccccccccccccccccccc44444444444444440bbbbbbb0067700bb
66667000666670000566700bbbbbbbb0056670044444444cccccccccccccccccccccccccccccccccccccccccccccccc44444444444444440bbbbbbb00566700b
66666600666666005656500bbbbbbbb0565650044444444cccccccccccccccccccccccccccccccccccccccccccccccc44444444444444440bbbbbbb05656500b
66666600666666006505650bbbbbbbb0650565044444444cccccccccccccccccccccccccccccccccccccccccccccccc44444444444444440bbbbbbb06505650b
55566600555666005500560bbbbbbbb0550056044444444cccccccccccccccccccccccccccccccccccccccccccccccc44444444444444440bbbbbbb05500560b
00555000005550000055500bbbbbbbb0005550044444444cccccccccccccccccccccccccccccccccccccccccccccccc44444444444444440bbbbbbb00055500b
00000000000000000000000000000000000000044444444cccccccccccccccccccccccccccccccccccccccccccccccc444444444444444400000000000000000
44444444444444444444444444444444444444444444444cccccccccccccccccccccccccccccccccccccccccccccccc444444444444444444444444444444444
44444444444444444444444444444444444444444444444cccccccccccccccccccccccccccccccccccccccccccccccc444444444444444444444444444444444
44444444444444444444444444444444444444444444444cccccccccccccccccccccccccccccccccccccccccccccccc444444444444444444444444444444444
44444444444444444444444444444444444444444444444cccccccccccccccccccccccccccccccccccccccccccccccc444444444444444444444444444444444
44444444444444444444444444444444444444477777777cccccccccccccccccccccccccccccccccccccccccccccccc444444444444444444444444444444444
444444444444444444444444444444444444444cccccccccccccccccccccccccccccccccccccccccccccccccccccccc777777777777777744444444444444444
444444444444444444444444444444444444444cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc44444444444444444
4444444444444444444444444444444000000000000000000000000000000000000000000000000000000000000000000cccccccccccccc44444444444444444
4444444444444444444444444444444077707777777707770000777777770777777770777777770777777770777777770cccccccccccccc44444444444444444
4444444444444444444444444444444077707777777707770000777777770777777770777777770777777770777777770cccccccccccccc44444444444444444
4444444444444444444444444444444077707777777707770000777777770777777770777777770777777770777777770cccccccccccccc44444444444444444
7777777777777777777777777777777077707776666607770000777666770677766770677666770777666660777666770cccccccccccccc44444444444444444
ccccccccccccccccccccccccccccccc077707770000007770000777000770077700770077000770777000000777000770cccccccccccccc44444444444444444
ccccccccccccccccccccccccccccccc077707777777707770000777000770077700770077000770777777770777000770cccccccccccccc77777777444444444
ccccccccccccccccccccccccccccccc077707777777707770000777777770077700770077000770777777770777777770cccccccccccccccccccccc777777777
ccccccccccccccccccccccccccccccc077706666667707770000777777770077700770077000770777666660777777770ccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccc077700000007707770000777666770077700770077000770777000000777677760ccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccc077707777777707777770777000770077700770777777770777777770777067770ccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccc077707777777707777770777000770077700770777777770777777770777006770ccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccc066606666666606666660666000660066600660666666660666666660666000660ccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccc000000000000000000000000000000000000000000000000000000000000000000ccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
0000000000000000000000000000000000000000000000000000000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000b0ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb003b000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb003bb300ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0bbbbb30ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0bbbbbb0ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb033bb330ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00333300ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
00000bbb00000bbbb000bbbbbbbbbbbbbbbbbbbbbbbbbbb0bb3bbb000000000cccccccccccccccccccccccccccccccccccccccccccccccc00000000000000000
067700b0067700bb07770bbbbbbbbbbbbbbbbbbbbbbbbbb03bbb330bbbbbbb0cccccccccccccccccccccccccccccccccccccccccccccccc0bbbbbbbbbbbbbbb0
fd6670006666700b07970bbbbbbbbbbbbbbbbbbbbbbbbbb00333300bbbbbbb0cccccccccccccccccccccccccccccccccccccccccccccccc0bbbbbbbbbbbbbbb0
d6d6df006666660b07770bbbbbbbbbbbbbbbbbbbbbbbbbb0bbbbbb0bbbbbbb0cccccccccccccccccccccccccccccccccccccccccccccccc0bbbbbbbbbbbbbbb0
6dfd6d006666660bb030bbbbbbbbbbbbbbbbbbbbbbbbbbb0333bb30bbbbbbb0cccccccccccccccccccccccccccccccccccccccccccccccc0bbbbbbbbbbbbbbb0
55ffd6005556660bb030bbbbbbbbbbbbbbbbbbbbbbbbbbb00344300bbbbbbb0cccccccccccccccccccccccccccccccccccccccccccccccc0bbbbbbbbbbbbbbb0
005550000055500bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb004400bbbbbbbb0cccccccccccccccccccccccccccccccccccccccccccccccc0bbbbbbbbbbbbbbb0
000000000000000000000000000000000000000bbbbbbbbbbbbbbbbbbbbbbb0cccccccccccccccccccccccccccccccccccccccccccccccc0bbbbbbbbbbbbbbbb
4444444444444444444444444444444444444440bbbbbbbb00000bbb00000b0cccccccccccccccccccccccccccccccccccccccc00000000b00000bbb00000bbb
4444444444444444444444444444444444444440bbbbbbb0067700b00677000cccccccccccccccccccccccccccccccccccccccc0bbbbbbb0067700b0067700bb
4444444444444444444444444444444444444440bbbbbbb0fd667000fd66700cccccccccccccccccccccccccccccccccccccccc0bbbbbbb066667000fd66700b
4444444444444444444444444444444444444440bbbbbbb0d6d6df00d6d6df0cccccccccccccccccccccccccccccccccccccccc0bbbbbbb066666600d6d6df0b
4444444444444444444444444444444444444440bbbbbbb06dfd6d006dfd6d0cccccccccccccccccccccccccccccccccccccccc0bbbbbbb0666666006dfd6d0b
4444444444444444444444444444444444444440bbbbbbb055ffd60055ffd60cccccccccccccccccccccccccccccccccccccccc0bbbbbbb05556660055ffd60b
4444444444444444444444444444444444444440bbbbbbb0005550000055500cccccccccccccccccccccccccccccccccccccccc0bbbbbbb0005550000055500b
44444444444444444444444444444444444400000000000b000000bbb000000ccccccccc0000ccccccccccccccccccccccccccc0bbbbbbbbb00000bbb00000bb
44444444444444444444444444444444444007777700444007700000000000000000ccc00770000000000000ccccccc00000000bbbbbbbbbbbbbbbbb00000bbb
44444444444444444444444444444444444077007770444070007770077077007770ccc07000077077707770ccccccc0067700bbbbbbbbbbbbbbbbb0067700bb
44444444444444444444444444444444444077000770444077700700707070700700ccc07000707077707700ccccccc06666700bbbbbbbbbbbbbbbb00566700b
7777777777777777777777777777777444407700777044400070070077707700070cccc07070777070707000ccccccc06666660bbbbbbbbbbbbbbbb05656500b
ccccccccccccccccccccccccccccccc777700777770044407700070070707070070cccc07770707070700770ccccccc06666660bbbbbbbbbbbbbbbb06505650b
cccccccccccccccccccccccccccccccccccc000000044440000b000000000000000cccc00000000000000000ccccccc05556660bbbbbbbbbbbbbbbb05500560b
ccccccccccccccccccccccccccccccccccccccc44444444033bb33000055500cccccccccccccccccccccccccccccccc00055500bbbbbbbbbbbbbbbb00055500b
ccccccccccccccccccccccccccccccccccccccc4444444400333300bb000000cccccccccccccccccccccccccccccccc0b00000bbbbbbbbbbbbbbbbbbb00000bb
ccccccccccccccccccccccccccccccccccccccc444444440bb3bbb0bbbbbbb0cccccccccccccccccccccccc00000000bbbbbbbbbbbbbbbbbbbbbbbbb00000bbb
ccccccccccccccccccccccccccccccccccccccc4444440003bbb330bbbbbbb0ccc0000ccccccccccccccccc0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000bb
ccccccccccccccccccccccccccccccccccccccc4444440700300000000000b0cc00770000000000000ccccc0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0003b000b
ccccccccccccccccccccccccccccccccccccccc444444070b00770077077000cc07000077077707770ccccc0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb003bb300b
ccccccccccccccccccccccccccccccccccccccc777777070307070707070700cc07000707077707700ccccc0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0bbbbb30b
ccccccccccccccccccccccccccccccccccccccccccccc070007070777070700cc07070777070707000ccccc0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0bbbbbb0b
ccccccccccccccccccccccccccccccccccccccccccccc077707700707077000cc07770707070700770ccccc0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb033bb330b
ccccccccccccccccccccccccccccccccccccccccccccc0000000000000000b0cc00000000000000000ccccc0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00333300b
00000000000000000000000cccccccccccccccccccccccc0bbbbbbbbb000bb0cccccccccccccccccccccccc0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0bb3bbb0b
bbbbbbbbbbbbbbbbbbbbbb0cccccccccccccccccccccccc0bbbbbbbb07770b0cccccccccccccccccccccccc0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb03bbb330b
bbbbbbbbbbbbbbbbbbbbbb0cccccccccccccccccccccccc0bbbbbbbb07970b0cccccccccccccccccccccccc0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00333300b
bbbbbbbbbbbbbbbbbbbbbb0cccccccccccccccccccccccc0bb0000bb07770b0cccccccccccccccccccccccc0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0bbbbbb0b
bbbbbbbbbbbbbbbbbbbbbb0cccccccccccccccccccccccc0b007700000000000000000000c0000ccccccccc0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0333bb30b
bbbbbbbbbbbbbbbbbbbbbb0cccccccccccccccccccccccc0b07070077077707770077077000770ccccccccc0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00344300b
bbbbbbbbbbbbbbbbbbbbbb0cccccccccccccccccccccccc0b07070707007000700707070707000ccccccccc0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb004400bb
bbbbbbbbbbbbbbbbbbbbbb0cccccccccccccccccccccccc0b07070777007000700707070700070ccccccccc0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbb0cccccccccccccccccccccccc0007700700007007770770070707700ccccccccc0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b0000bb00000000bbbbbbb0cccccccccccccccccccccccc000000000bb0000000000000000000cccccccccc0bbbbbbbbbbbbbbbbb0000bbbbbbbbbbbbbbbbbb0
003b00b0f4444f0bbbbbbb0cccccccccccccccccccccccc0fd66700bbbbbbb0cccccccccccccccccccccccc0bbbbbbbbbbbbbbbb003b00bbbbbbbbbbbbbbbbb0
03bb3000f0000f0bbbbbbb0cccccccccccccccccccccccc0d6d6df0bbbbbbb0cccccccccccccccccccccccc0bbbbbbbbbbbbbbb003bb300bbbbbbbbbbbbbbbb0
bbbbb3000099000bbbbbbb0cccccccccccccccccccccccc06dfd6d0bbbbbbb0cccccccccccccccccccccccc0bbbbbbbbbbbbbbb0bbbbb30bbbbbbbbbbbbbbbb0
bbbbbb00f0000f0bbbbbbb0cccccccccccccccccccccccc055ffd60bbbbbbb0cccccccccccccccccccccccc0bbbbbbbbbbbbbbb0bbbbbb0bbbbbbbbbbbbbbbb0
33bb3300f4444f0bbbbbbb0cccccccccccccccccccccccc00055500bbbbbbb0cccccccccccccccccccccccc0bbbbbbbbbbbbbbb033bb330bbbbbbbbbbbbbbbb0
033330000000000bbbbbbb0cccccccccccccccccccccccc0b00000bbbbbbbb0cccccccccccccccccccccccc0bbbbbbbbbbbbbbb00333300bbbbbbbbbbbbbbbbb
bb3bbb0b00000bbbbbbbbb0cccccccccccccccccccccccc0bbbbbbbbbbbbbb0cccccccccccccccccccccccc0bbbbbbbb00000bb0bb3bbb0b00000bbbbbbbbbbb
3bbb3300067700bbbbbbbb0cccccccccccccccccccccccc0bbbbbbbbbbbbbb0cccccccccccccccccccccccc0bbbbbbb0067700b03bbb3300067700bbbbbbbbbb
033330000566700bbbbbbb0cccccccccccccccccccccccc0bbbbbbbbbbbbbb0cccccccccccccccccccccccc0bbbbbbb066667000033330000566700bbbbbbbbb
bbbbbb005656500bbbbbbb0cccccccccccccccccccccccc0bbbbbbbbbbbbbb0cccccccccccccccccccccccc0bbbbbbb066666600bbbbbb005656500bbbbbbbbb
333bb3006505650bbbbbbb0cccccccccccccccccccccccc0bbbbbbbbbbbbbb0cccccccccccccccccccccccc0bbbbbbb066666600333bb3006505650bbbbbbbbb
034430005500560bbbbbbb0cccccccccccccccccccccccc0bbbbbbbbbbbbbb0cccccccccccccccccccccccc0bbbbbbb055566600034430005500560bbbbbbbbb
004400b00055500bbbbbbb0cccccccccccccccccccccccc0bbbbbbbbbbbbbb0cccccccccccccccccccccccc0bbbbbbb00055500b004400b00055500bbbbbbbbb
00000000000000000000000cccccccccccccccccccccccc0bbbbbbbbbbbbbb0cccccccccccccccccccccccc0bbbbbbbbb00000bbbbbbbbbbb00000bbbbbbbbbb
44444000044440000044400000ccccccccccccccccccccc000000bbbbbbbbb00000cccccccc0000cccccccc000000bbbbbbbbb0000000bbb00000bbbbbbbbbbb
40000077044440777044407770ccccccccccccccccccccc0067700bbbbbbbb077700000ccc007700000000c00000000000bbbb070700000000000000000000b0
40707007044440707044407070ccccccccccccccccccccc00566700bbbbbbb070707070ccc0700007707700077007707700bbb07070077077700770077077000
40707007044440707044407070ccccccccccccccccccccc05656500bbbbbbb077007770ccc070c070707070700070707070bbb07700707077707070707070700
40777007000000707000007070ccccccccccccccccccccc06505650bbbbbbb070700070ccc0700077707700007070707070bbb07070707070707770707070700
40070077700700777007007770ccccccccccccccccccccc05500560bbbbbbb077707700ccc0077070707070770077007070bbb07070770070707000770070700
44000000000000000000000000ccccccccccccccccccccc00055500bbbbbbb00000000ccccc000000000000000000000000bbb00000000000000000000000000
44444444444444444444444cccccccccccccccccccccccc0b00000bbbbbbbb0cccccccccccccccccccccccc00000000bbbbbbbbbb00000bbb00000bbbbbbbbb0

__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000040404040400000000000000000000000000000000000000000000000000000000000004040400000000000000000000000000040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000004040404040404040400000000000000000004040400000000000000000000000004040404040404040400000000000000000404040404040000000000000000000004040404040000000000000000000000040404040400000000000000000000000000000000000000000000000000000000040404040000000000000
0000004040404040404040404000000000000000404040404040400000000000000000404040404040404040400000000000000040404040404040400000000000000040404040404040404040000000000000004040404040404000000000000000000000000000000000000000000000000000004040404040404000000000
0000004040404040404040404040000000000040404040404040404000000000000040404040404040404040400000000000004040404040404040400000000000000040404040404040404040400000000000004040404040404040000000000000000000404040404000000000000000000000404040404040404000000000
0000404040404040404040404040400000004040404040404040404040000000000040404040404040404040404000000000004040404040404040404000000000000040404040404040404040400000000000004040404040404040000000000000000040404040404040000000000000000000404000000040404000000000
0000404040404040404040404040400000004040404040404040404040400000000040404040404040404040404000000000004040404040404040404000000000000040404040404040404040400000000000004040404040404040404000000000000040404040404040000000000000000000404000400040404000000000
0000404040404040404040404040400000004040404040404040404040400000000040404040404040404040400000000000004040404040404040404000000000000040404040404040404040400000000000004040404040404040404000000000004040404040404000000000000000000000404000000040400000000000
0000404040404040404040404040400000004040404040404040404040400000000000404040404040404040400000000000004040404040404040404000000000000000404040404040404040400000000000000040404040404040404000000000004040404040400000000000000000000000404040404040000000000000
0000404040404040404040404040400000000040404040404040404040400000000000004040404040404040000000000000000040404040404040404000000000000000004040404040404040000000000000000000404040404040404000000000000040404000000000000000000000000000004040404040000000000000
0000404040404040404040404040400000000040404040404040404040400000000000004040404040404040000000000000000000404040404040000000000000000000000000000000000000000000000000000000004040404040404000000000000000000000000000000000000000000000000040404000000000000000
0000004040404040404040404040000000000000404040404040404040000000000000000000404040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000040404040400000000000000000000000000000000000000000000000000000000000000000000000
0000004040404040404040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000040404040000000000000000000000000000000000000000000000000000000000000000000000000
0000000040404040404000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000404040404040404040404000000000000000000000000000000000000000000000404040404000000000000000000000000000000000000000000000000000000000404040404040000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000040404040400000000000000040404040404040404040404040000000000000404040404040400000000000000040404040404040000000000000000000000000000000000000000000000000000040404040404040400000000000000000004040404040000000000000000000000000404040000000000000
0000000000404040404040404000000000000040404000000000000000404040000000000040404040404040404000000000004040404040404040400000000000000000000000000000000000000000000000004040404040404040404000000000000000404040404040400000000000000000000040404040000000000000
0000000040404040404040404040000000000040400000000000000000004040000000004040404040404040404000000000404040404040404040404040000000000000000040404000000000000000000000404040404040404040404040000000000000404040404040400000000000000000004040404040000000000000
0000000040404040404040404040400000000040400000000000000000004040000000404040404040404040404040000000404040404040404040404040000000000000004040404040000000000000000000404040404040404040404040000000000000404040404040400000000000000000004040404040400000000000
0000004040404040404040404040400000000040400000004040400000004040000000404040404040404040404040000040404040404040404040404000000000000000004040404040000000000000000000404040404040404040404040000000000000404040404040000000000000000000404040404040404000000000
0000004040404040404040404040400000000040400000004040400000004040000000404040404040404040404000000040404040404040404040404000000000000000004040404040000000000000000000404040404040404040404040000000000000404040404040000000000000000000404040404040404000000000
0000004040404040404040404040400000000040400000004040400000004040000000404040404040404040404000000000404040404040404040400000000000000000000040404000000000000000000000404040404040404040404040000000000000004040404040400000000000000000404040404040400000000000
0000004040404040404040404040000000000040400000000000000000004040000000404040404040404040400000000000404040404040404040400000000000000000000000000000000000000000000000004040404040404040404000000000000000000040404040400000000000000000404040404000000000000000
0000004040404040404040404040000000000040400000000000000000004040000000004040404040404040000000000000000040404040404040400000000000000000000000000000000000000000000000000040404040404040404000000000000000000000404040000000000000000000404040400000000000000000
0000000040404040404040404000000000000040404000000000000000404040000000000000404040404000000000000000000000000040404040000000000000000000000000000000000000000000000000000000404040404040400000000000000000000000000000000000000000000000000000000000000000000000
0000000000004040404040000000000000000040404040404040404040404040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000404040404040404040404000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
001d00200f6101061010610106101061010610106100d6100a6100a6100a6100b6100c6100e610106101161011610116101161011610106100f6100e6100d6100c6100b6100c6100d6100d6100d6100c6100d610
01030000246502463024610000000000000000000000000018650186301861000000000000000000000000000c6500c6300c61000000000000000000000000000065000630006100000000000000000000000000
011b0000137550e755137550e75515755107551575510755137450e745137450e74515745107451574510745137350e735137350e73515735107351573510735137250e725137250e72515725107250cb200cb25
01030000127501875021750267502d750127401874021740267402d740127301873021730267302d730127201872021720267202d720127101871021710267102d71000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010100000e61013610176101e61028610006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
00010000256101d610176101e6101f610006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
01010000286101e61017610136100e610006000060000600286001e60017600136000e60000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
010200001205318610166100a6100a610000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01020000120511361116621096410365101651036510b6310d6210a61109611096110960109601000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001
010200001205330613166100a6100a610000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300000a0300f0301c0400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400002675000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
000300001005013050150501c05027750297500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000705507055000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005
000300001a750180500f0500f05013750000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00030000096100d610176301a640276402b610276100a610096100861006610056100561005610036100261000610006100000000000000000000000000000000000000000000000000000000000000000000000
01030000176301a6400e640086600f6100a6100961008610066100561005610056100361002610006100061000000000000000000000000000000000000000000000000000000000000000000000000000000000
0003000000610036200c0730000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0103000023050270502c05023040270402c04023030270302c03023020270202c02023010270102c0100000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
03 00424344

