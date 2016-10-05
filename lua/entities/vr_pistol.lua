AddCSLuaFile()

DEFINE_BASECLASS( "base_vr_weapon" )

ENT.Spawnable = true
ENT.PrintName = "VR Pistol"


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
	BaseClass.SetupDataTables( self )
	
	self:DefineNWVar( "Float" , "RechamberStartTime" )
	self:DefineNWVar( "Float" , "RechamberTime" )

end

function ENT:Initialize()

	if SERVER then
		self:SetModel( "models/ugc/76561197995159516/mickyan/w_hdpistol.mdl" )

		self:SetWeaponSpread( Vector( 0.00873, 0.00873, 00873 ) )
		--considering the spread from a VR perpheral is actually from the hands
		--don't actually increase the spread for now
		self:SetHasMagazine( true )
		self:CreateMagazine()
		self:SetMagazineBullets( 18 )
		self:SetFireRate( 0.1 )
		
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



function ENT:GetMagazinePosAng()
	return LocalToWorld( self.MagazineOffset.Pos , self.MagazineOffset.Ang , self:GetPos() , self:GetAngles() )
end

--called as a bullet is fired


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
		Spread = self:GetWeaponSpread(),
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

	--don't bother with a rechambing if there's no more bullets to load
	if self:GetMagazineBullets() > 0 then
		self:SetRechamberStartTime( CurTime() )
		self:SetRechamberTime( CurTime() + self:GetFireRate() / 2 )
	end

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

		--debug code to test where the bullet will go
		--[[
		local bulletpos , bulletang = self:GetBulletPosAng()

		local startpos = bulletpos
		local endpos = bulletpos + bulletang:Forward() * 1024

		--render.DrawLine( startpos , endpos , color_white , true )
		]]

		self:DrawModel()
	end
end