AddCSLuaFile()

DEFINE_BASECLASS( "base_vr_entity" )

function ENT:SetupDataTables()
	
	BaseClass.SetupDataTables( self )
	
	self:DefineNWVar( "Entity" , "Magazine" )
	
	
	self:DefineNWVar( "Float" , "FireRate" )
	
	self:DefineNWVar( "Bool" , "UsesMagazines" ) --if this weapon uses a magazine
	self:DefineNWVar( "Bool" , "TriggerHeld" ) --if the trigger is being pulled currently
	self:DefineNWVar( "Bool" , "WasTriggerHeld" ) --if the trigger was pulled last frame
	self:DefineNWVar( "Bool" , "BulletChambered" ) --this is checked before firing
	
	self:DefineNWVar( "Bool" , "AutomaticFireMode" ) --if we're singleshot or automatic
		
	self:DefineNWVar( "Vector" , "WeaponSpread" )

end

function ENT:WeaponThink()
	local buttons = self:GetButtonsInput()
	
	if bit.band( buttons , IN_ATTACK2 ) ~= 0 and self:GetUsesMagazines() then
		self:DropMagazine()
	end
	
	self:AutoRechamber()

	local triggerheld = self:GetAnalogTrigger() >= 0.5
	local wastriggerheld = self:GetTriggerHeld()

	if ( triggerheld and not wastriggerheld ) or ( triggerheld and self:GetAutomaticFireMode() ) then
		
		if self:GetNextFire() < CurTime() then
			self:WeaponFire()
		end
		
	end

	self:SetWasTriggerHeld( wastriggerheld )
	self:SetTriggerHeld( triggerheld )

end

function ENT:HandleInput()
	BaseClass.HandleInput( self )
	
	
end

function ENT:Simulate( mv )
	if CLIENT and not self:GetPredictable() then
		return
	end
	
	self:WeaponThink( mv )
end

function ENT:WeaponFire()
	local shouldlagcompensate = IsValid( self:GetOwner() )
	
	if shouldlagcompensate then
		self:GetOwner():LagCompensation( true )
	end
	
	self:WeaponFireBullet()
	
	if shouldlagcompensate then
		self:GetOwner():LagCompensation( false )
	end
	
	
	self:SetNextFire( CurTime() + self:GetFireRate() )
end

function ENT:WeaponFireBullet()

end

--OVERRIDE ME
function ENT:GetBulletPosAng()
	return self:GetPos() , self:GetAngles()
end

--OVERRIDE ME
function ENT:GetMuzzlePosAng()
	return vector_origin , angle_zero
end

--OVERRIDE ME
function ENT:GetMagazinePosAng()
	return self:GetPos() , self:GetAngles()
end

function ENT:DropMagazine()
	--ideally, we'll simply drop a cluaeffect as a fake magazine, and it'll disappear
	--after a while
	
	if CLIENT then
		return
	end
	
	if IsValid( self:GetMagazine() ) then
		self:GetMagazine():SetParent( NULL )
		self:GetMagazine():InitializePhysics()
		self:SetMagazine( NULL )
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


else

	function ENT:DrawSpread()
		--[[
		local bbmin , bbmax = self:GetCollisionBounds()
		render.DrawWireframeBox( self:GetPos() , angle_zero , bbmin , bbmax , color_white )
		]]
		
		--debug code to test where the bullet will go
		local bulletpos , bulletang = self:GetBulletPosAng()
		
		local startpos = bulletpos
		
		for i = 0 , 15 do
			local endpos = bulletpos + VRShotManipulator( bulletang:Forward() , self:GetWeaponSpread() ) * 1024
			
			render.DrawLine( startpos , endpos , color_white , true )
		end
		
	end
end