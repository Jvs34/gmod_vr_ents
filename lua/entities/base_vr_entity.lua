AddCSLuaFile()

DEFINE_BASECLASS( "base_entity" )

--An entity that can be interacted by vr players, not necessarely a weapon



function ENT:SetupDataTables()
	--do the same thing I did for predicted entities
	self.DefinedDTVars = {
		Entity = {
			Max = GMOD_MAXDTVARS,
		},
		Float = {
			Max = GMOD_MAXDTVARS,
			EditableElement = "Float",
		},
		Int = {
			Max = GMOD_MAXDTVARS,
			EditableElement = "Int",
		},
		Bool = {
			Max = GMOD_MAXDTVARS,
			EditableElement = "Boolean",
		},
		Vector = {
			Max = GMOD_MAXDTVARS,
		},
		Angle = {
			Max = GMOD_MAXDTVARS,
		},
		String = {
			Max = 4,
			EditableElement = "Generic",
		},
	}
	
	--
	--IN_USE is the sidegrip
	--IN_MENU is the button above the touchpad
	--IN_CANCEL is system button, I doubt it would be actually used as it triggers steam overlay
	--IN_ATTACK is the trigger fully clicked ( with trigger == 1 as well, there may be defective controllers where this isn't true )
	--IN_ATTACK2 is the touchpad click
	
	
	self:DefineNWVar( "Int" , "ButtonsInput" )

	self:DefineNWVar( "Entity" , "PlayerOwner" ) --the vr player owner
	self:DefineNWVar( "Entity" , "AttachedTo" ) --the vrcontroller we're attached to
	
	self:DefineNWVar( "Float" , "AnalogTrigger" ) --the analog trigger of the vr controller
	self:DefineNWVar( "Float" , "NextFire" )
	
	self:DefineNWVar( "Vector" , "AnalogInput" ) --the analog stick ( pad in case of vive )
	
	self:DefineNWVar( "Vector" , "CurrentOffsetPos" )
	self:DefineNWVar( "Angle" , "CurrentOffsetAngle" )
end

function ENT:DefineNWVar( dttype , dtname , editable , beautifulname , minval , maxval , customelement , filt )
	
	if not self.DefinedDTVars[dttype] then
		Error( "Wrong NWVar type " .. ( dttype or "nil" ) )
		return
	end

	local index = -1
	
	local maxindex = self.DefinedDTVars[dttype].Max

	for i = 0 , maxindex - 1 do
		--we either didn't find anything in this slot or we found the requested one again
		--in which case just override it again, someone might want to inherit and add an edit table or something
		if not self.DefinedDTVars[dttype][i] or self.DefinedDTVars[dttype][i] == dtname then
			index = i
			break
		end
	end

	if index == -1 then
		Error( "Not enough slots on "..dttype .. ",	could not add ".. dtname )
		return
	end
	
	self.DefinedDTVars[dttype][index] = dtname
	
	local edit = nil
	
	if editable then
		edit = {
			KeyName = dtname:lower(),
			Edit = {
				title = beautifulname or dtname,	--doesn't it do this internally already?
				min = minval,
				max = maxval,
				type = customelement or self.DefinedDTVars[dttype].EditableElement,
			}
		}
	end

	self:NetworkVar( dttype , index , dtname , edit )
end

function ENT:Initialize()

end

function ENT:HandleInput()
	--TEMPORARY AHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
	local attachedto = self:GetAttachedTo()
	
	if IsValid( attachedto ) then
		self:SetButtonsInput( attachedto:GetButtonsInput() )
		self:SetAnalogTrigger( attachedto:GetAnalogTrigger() )
		self:SetAnalogInput( attachedto:GetAnalogInput() )
	end
	
end

function ENT:GetOffsetPosAng()
	if IsValid( self:GetAttachedTo() ) then
		return LocalToWorld( self:GetCurrentOffsetPos() , self:GetCurrentOffsetAngle() , self:GetAttachedTo():GetPos() , self:GetAttachedTo():GetAngles() )
	end
end

function ENT:CalcAbsolutePosition( pos , ang )
	return self:GetOffsetPosAng()
end

function ENT:EquipTo( ply , controller )
	self:DestroyPhysics()
	self:SetOwner( ply )
	controller:SetHoldingEntity( self )
	self:SetParent( controller )
	self:SetPlayerOwner( ply )
	self:SetAttachedTo( controller )	
end

function ENT:Drop()
	
	if IsValid( self:GetAttachedTo() ) then
		self:GetAttachedTo():SetHoldingEntity( NULL )
	end
	
	self:SetParent( NULL )
	self:SetPlayerOwner( NULL )
	self:SetOwner( NULL )
	
	self:InitializePhysics()
end

function ENT:IsHeld()
	return IsValid( self:GetOwner() ) and IsValid( self:GetAttachedTo() ) and IsValid( self:GetParent() )
end

function ENT:Simulate( mv )
	if CLIENT and not self:GetPredictable() then
		return
	end
end

function ENT:Think()
	
	if CLIENT then
		self:HandlePrediction()
	end
	
	if not self:IsHeld() then
		self:Simulate()
	end
	
	self:NextThink( CurTime() + engine.TickInterval() )
	return true
end

function ENT:InitializePhysics()
end

function ENT:DestroyPhysics()

end

if SERVER then

else
	function ENT:ShouldPredict()
		return IsValid( self:GetPlayerOwner() ) and self:GetPlayerOwner() == LocalPlayer()
	end
	
	function ENT:HandlePrediction()
		if game.SinglePlayer() then
			return
		end
		
		if self:ShouldPredict() then
			if not self:GetPredictable() then
				self:SetPredictable( true )
			end
		else
			if self:GetPredictable() then
				self:SetPredictable( false )
			end
		end
	end
end