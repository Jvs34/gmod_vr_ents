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
	
	if bit.band( buttons , IN_RELOAD ) ~= 0 and self:GetUsesMagazines() then
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
	self:WeaponThink( mv )
end

function ENT:WeaponFire()
	self:WeaponFireBullet()
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

function ENT:DrawSpread()

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
end