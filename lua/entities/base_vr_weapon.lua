AddCSLuaFile()

DEFINE_BASECLASS( "base_vr_entity" )



function ENT:SetupDataTables()
	
	BaseClass.SetupDataTables( self )
	
	
	
	self:DefineNWVar( "Bool" , "TriggerHeld" ) --if the trigger is being pulled currently
	self:DefineNWVar( "Bool" , "WasTriggerHeld" ) --if the trigger was pulled last frame
	
	self:DefineNWVar( "Vector" , "AccuracyVector" ) --used for the LerpVector, good accuracy, VECTOR_CONE_1DEGREES

end

function ENT:WeaponThink()
	self:AutoRechamber()

	local triggerheld = self:GetAnalogTrigger() >= 0.5
	local wastriggerheld = self:GetTriggerHeld()

	if triggerheld and not wastriggerheld then
		self:WeaponFire()
	end

	self:SetWasTriggerHeld( wastriggerheld )
	self:SetTriggerHeld( triggerheld )

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

	return BaseClass.Think( self )
end

function ENT:WeaponFire()
	if self:GetNextFire() > CurTime() then
		return
	end

	self:WeaponFireBullet()
	self:SetNextFire( CurTime() + self:GetFireRate() )
end

function ENT:WeaponFireBullet()

end