AddCSLuaFile()

DEFINE_BASECLASS( "base_entity" )

ENT.Spawnable = true
ENT.PrintName = "HL2 Pistol"


ENT.CollisionsMin = Vector( -2.488817 , -0.721349 , -3.411153 )
ENT.CollisionsMax = Vector( 8.174237 , 0.719209 , 3.067022 )

ENT.MagazineOffset = {
	Pos = Vector( 0 , 0 , 0 ),
	Ang = Angle( 0 , 0 , 0 ),
}

function ENT:SpawnFunction( ply, tr, ClassName )

	if not tr.Hit then return end

	local SpawnPos = tr.HitPos + tr.HitNormal * 36

	local ent = ents.Create( ClassName )
	ent:SetPlayerOwner( ply ) --TEMPORARY AHHHHHHHHHHHHHHHHHHH
	ent:SetPos( SpawnPos )
	ent:Spawn()
	return ent

end

function ENT:SetupDataTables()
	self:NetworkVar( "Entity" , 0 , "PlayerOwner" )
	self:NetworkVar( "Entity" , 1 , "Magazine" )
	
	
	self:NetworkVar( "Int" , 1 , "ButtonsInput" )
	
	
	--these two are to check between auto and single fires
	self:NetworkVar( "Bool" , 0 , "TriggerHeld" ) --if the trigger is being pulled currently
	self:NetworkVar( "Bool" , 1 , "WasTriggerHeld" ) --if the trigger was pulled last frame
	self:NetworkVar( "Bool" , 2 , "HasMagazine" ) --if there's a magazine currently
	self:NetworkVar( "Bool" , 3 , "BulletChambered" ) --this is checked before firing
	
	self:NetworkVar( "Float" , 0 , "CurrentAccuracy" ) --this is a fraction going from 0 to 1
	self:NetworkVar( "Float" , 1 , "NextFire" )
	self:NetworkVar( "Float" , 2 , "FireRate" )
	self:NetworkVar( "Float" , 3 , "AccuracyRecover" ) --in seconds, when the accuracy should reset
	self:NetworkVar( "Float" , 4 , "NextAccuracyRecover" )
	self:NetworkVar( "Float" , 6 , "RechamberStartTime" )
	self:NetworkVar( "Float" , 7 , "RechamberTime" )
	self:NetworkVar( "Float" , 8 , "AnalogTrigger" )
	
	
	--these two are used for the lerp to decreace accuracy when spamming the trigger before letting it decay
	--as VR players don't really get recoil, we have to do this instead
	self:NetworkVar( "Vector" , 0 , "BaseAccuracy" ) --used for the LerpVector, good accuracy, VECTOR_CONE_1DEGREES
	self:NetworkVar( "Vector" , 1 , "WorstAccuracy" ) --used for the LerpVector, worst accuracy, VECTOR_CONE_6DEGREES
	
end

function ENT:Initialize()
	if SERVER then
		self:SetModel( "models/ugc/76561197995159516/mickyan/w_hdpistol.mdl" )

		self:SetBaseAccuracy( Vector( 0.00873, 0.00873, 00873 ) )
		--considering the spread from a VR perpheral is actually from the hands
		--don't actually increase the spread for now
		self:SetWorstAccuracy( self:GetBaseAccuracy() )
		--self:SetWorstAccuracy( Vector( 0.05234, 0.05234, 0 ) )
		
		self:CreateMagazine()
		self:SetMagazineBullets( 18 )
		self:SetFireRate( 0.1 )
		
		--this way, you should get max accuracy by the time you fire a bullet in auto
		self:SetAccuracyRecover( 0.4 )
		
		self:LoadBullet()
	else
		self:AddCallback( "BuildBonePositions" , function( self , nbones )
			self:BuildAnimationBones( nbones )
		end)
	end
	
	self:InitializePhysics()	
	
	self.GripBone = self:LookupBone( "Grip" )
	self.TriggerBone = self:LookupBone( "Trigger" )
	self.SlideBone = self:LookupBone( "Slide" )
	self.BulletCasingBone = self:LookupBone( "BulletCasing" )
	self.BulletBone = self:LookupBone( "Bullet" )
	self.HammerBone = self:LookupBone( "Hammer" )
	self.MagazineBone = self:LookupBone( "Magazine" )
end

function ENT:InitializePhysics()
	if SERVER then
		self:PhysicsInitBox( self.CollisionsMin , self.CollisionsMax )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		
				
		local phys = self:GetPhysicsObject()
		
		if IsValid( phys ) then
			phys:Wake()
		end
	end
	
	self:SetCollisionBounds( self.CollisionsMin , self.CollisionsMax )
end

function ENT:DestroyPhysics()
	if SERVER then
		self:PhysicsDestroy()
		self:SetMoveType( MOVETYPE_NONE )
		self:SetSolid( SOLID_NONE )
	end
	
end

function ENT:WeaponThink()
	self:DecayAccuracy()
	self:AutoRechamber()
	
	local triggerheld = self:GetAnalogTrigger() >= 0.5
	local wastriggerheld = self:GetTriggerHeld()
	
	if triggerheld and not wastriggerheld then
		self:WeaponFire()
	end
	
	self:SetWasTriggerHeld( wastriggerheld )
	self:SetTriggerHeld( triggerheld )
	
end

function ENT:SetMagazineBullets( bullets )
	if IsValid( self:GetMagazine() ) then
		self:GetMagazine():SetBullets( bullets )
	end
end

function ENT:GetMagazineBullets()
	if IsValid( self:GetMagazine() ) then
		return self:GetMagazine():GetBullets()
	end
	return 0
end

function ENT:GetTotalBullets()
	local bullets = self:GetMagazineBullets()
	if self:GetBulletChambered() then
		bullets = bullets + 1
	end
	
	return bullets
end

--bullet starts way earlier into the gun, right where the bullet bone is
function ENT:GetBulletPosAng()
	local pos , ang = LocalToWorld( Vector( 0.8 , 0 , 2.3 ) * self:GetModelScale() , Angle( 0 , 0 , 0 ) , self:GetPos() , self:GetAngles() )	
	return pos , ang
end

--the muzzle flash however starts where the end of the gun is, duh
function ENT:GetMuzzlePosAng()
	--local pos , ang = LocalToWorld( Vector( 2 , 0 , 2.3 ) * self:GetModelScale() , Angle( 0 , 0 , 0 ) , self:GetPos() , self:GetAngles() )	
	--return pos , ang
	return Vector( 8 , 0 , 2.3 ) * self:GetModelScale() , Angle( 0 , 0 , 0 )
end

function ENT:GetAccuracyVector()
	return LerpVector( self:GetCurrentAccuracy() , self:GetBaseAccuracy() , self:GetWorstAccuracy() )
end

function ENT:GetMagazinePosAng()
	return LocalToWorld( self.MagazineOffset.Pos , self.MagazineOffset.Ang , self:GetPos() , self:GetAngles() )
end

--called as a bullet is fired
function ENT:DecreaseAccuracy()

end

function ENT:DecayAccuracy()

end

function ENT:AutoRechamber()
	if self:GetRechamberTime() ~= 0 and self:GetRechamberTime() < CurTime() then
		self:LoadBullet()
		self:SetRechamberStartTime( 0 )
		self:SetRechamberTime( 0 )
	end
end

function ENT:LoadBullet()
	if self:GetBulletChambered() then
		return false
	end
	
	if self:GetMagazineBullets() == 0 then
		return false
	end
	
	self:SetMagazineBullets( self:GetMagazineBullets() - 1 )
	self:SetBulletChambered( true )
	return true
end

function ENT:WeaponReload()
	
	if SERVER then
		self:CreateMagazine()
	end
	
	self:SetRechamberStartTime( CurTime() )
	self:SetRechamberTime( CurTime() + self:GetFireRate() * 2 )
end

function ENT:WeaponFire()
	if self:GetNextFire() > CurTime() then
		return
	end
	
	self:WeaponFireBullet()
	self:SetNextFire( CurTime() + self:GetFireRate() )
end

function ENT:WeaponFireBullet()
	
	if not self:GetBulletChambered() then
		self:EmitSound( "Weapon_Pistol.Empty" )
		return false
	end
	
	--fire the bullet, remove the bullet from the chamber
	local bulletpos , bulletdir = self:GetBulletPosAng()
	local bullettable = {
		Num = 1,
		Damage = 12,
		Src = bulletpos,
		Dir = bulletdir:Forward(),
		Attacker = self,
		Spread = self:GetAccuracyVector(),
		HullSize = 0,
		Callback = nil,
		Force = 20,
		Distance = 56756,
		Tracer = 1,
		TracerName = "luatracer",
	
	}
	
	self:FireBullets( bullettable )
	
	--THESE ARE NOT ABSOLUTE POSITIONS
	local mpos , mang = self:GetMuzzlePosAng()
	
	local effectdata = EffectData()
	effectdata:SetOrigin( bulletpos )
	effectdata:SetAngles( bulletdir )
	util.Effect( "ShellEject", effectdata )
	
	if SERVER then
		effectdata:SetEntIndex( self:EntIndex() )
	else
		effectdata:SetEntity( self )
	end
	
	effectdata:SetOrigin( mpos )
	effectdata:SetAngles( mang )
	effectdata:SetScale( self:GetModelScale() )
	util.Effect( "luamuzzleflash", effectdata )
	

	
	self:EmitSound( "Weapon_Pistol.Single" )
	self:SetBulletChambered( false )
	
	self:DecreaseAccuracy()
	--don't bother with a rechambing if there's no more bullets to load
	if self:GetMagazineBullets() > 0 then
		self:SetRechamberStartTime( CurTime() )
		self:SetRechamberTime( CurTime() + self:GetFireRate() / 2 )
	end
	
	return true
end

function ENT:Think()
	if SERVER then
		--TEMPORARY AHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
		--a vr player would have this set from the actual analog trigger
		if IsValid( self:GetPlayerOwner() ) then
		
			local flag = 0
		
			if self:GetPlayerOwner():KeyDown( IN_SPEED ) then
				flag = IN_ATTACK
				self:SetAnalogTrigger( 1 )
			else
				self:SetAnalogTrigger( 0 )
			end
			
			
			self:SetButtonsInput( flag )
		end
		
		self:WeaponThink()
	end
	
	self:NextThink( CurTime() + engine.TickInterval() )
	return true
end

function ENT:OnRemove()
	if SERVER then
		if IsValid( self:GetMagazine() ) then
			self:GetMagazine():Remove()
		end
	end
end

if SERVER then

	function ENT:CreateMagazine()
		self:DropMagazine()
		local mag = ents.Create( self:GetClass() .. "mag" )
		if IsValid( mag ) then
			local pos , ang = self:GetMagazinePosAng()
			mag:SetPos( pos )
			mag:SetAngles( ang )
			
			mag:SetParent( self )
			mag:Spawn()
			mag:DestroyPhysics()
			
			self:SetMagazine( mag )
		end
	end

	function ENT:DropMagazine()
		if IsValid( self:GetMagazine() ) then
			self:GetMagazine():SetParent( NULL )
			self:GetMagazine():InitializePhysics()
			self:SetMagazine( NULL )
		end
	end
else
	function ENT:BuildAnimationBones( nbones )
		local gripbonematrix = self:GetBoneMatrix( self.GripBone )
		local triggerbonematrix = self:GetBoneMatrix( self.TriggerBone )
		local slidebonematrix = self:GetBoneMatrix( self.SlideBone )
		local bulletcasingbonematrix = self:GetBoneMatrix( self.BulletCasingBone )
		local bulletbonematrix = self:GetBoneMatrix( self.BulletBone )
		local hammerbonematrix = self:GetBoneMatrix( self.HammerBone )
		local magazinebonematrix = self:GetBoneMatrix( self.MagazineBone )
		
		if slidebonematrix and not self:GetBulletChambered() then
			local vec = Vector( 0 , 0 , 0 )

			local timefrac = math.TimeFraction( self:GetRechamberTime() , self:GetRechamberStartTime() , CurTime() )
			
			vec.z = Lerp( timefrac , 0 , -1.5 )
			
			slidebonematrix:Translate( vec )
			self:SetBoneMatrix( self.SlideBone , slidebonematrix )
			
		end
		
		if triggerbonematrix then
			local triggerfraction = self:GetAnalogTrigger()
			local vec = Vector( 0 , 0 , 0 )
			local ang = triggerbonematrix:GetAngles()
			
			if self:GetTriggerHeld() then
				vec.z = Lerp( triggerfraction , 0 , -0.5 )
				--ang.r = ang.r + Lerp( triggerfraction , 0 , 45 )
			end
			
			triggerbonematrix:SetAngles( ang )
			triggerbonematrix:Translate( vec )
			self:SetBoneMatrix( self.TriggerBone , triggerbonematrix )
		end
		
		if magazinebonematrix then
			magazinebonematrix:SetScale( vector_origin )
			self:SetBoneMatrix( self.MagazineBone , magazinebonematrix )
		end
	end
	
	function ENT:Draw( flags )
		if not self:GetBulletChambered() then
			self:SetSubMaterial( 1 , "engine/occlusionproxy" )
		else
			self:SetSubMaterial( 1 , nil )
		end
		--[[
		local bulletpos , bulletang = self:GetBulletPosAng()
		
		local startpos = bulletpos
		local endpos = bulletpos + bulletang:Forward() * 1024
		
		--render.DrawLine( startpos , endpos , color_white , true )
		]]
		
		self:DrawModel()
	end
end