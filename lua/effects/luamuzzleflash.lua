AddCSLuaFile()

EFFECT.ExpireTime = 0.05

AccessorFunc( EFFECT , "AttachedEntity" , "AttachedEntity" )
AccessorFunc( EFFECT , "OffsetPos" , "OffsetPos" )
AccessorFunc( EFFECT , "OffsetAng" , "OffsetAng" )
AccessorFunc( EFFECT , "MuzzleParticleEmitter" , "MuzzleParticleEmitter" )
AccessorFunc( EFFECT , "MuzzleScale" , "MuzzleScale" )
AccessorFunc( EFFECT , "EmitterParticles" , "EmitterParticles" )

EFFECT.MuzzleFlashMaterials = {}
EFFECT.CombineMuzzleFlashMaterials = {}


function EFFECT:Init( effectdata )
	self.DieTime = UnPredictedCurTime() + self.ExpireTime

	self:SetAttachedEntity( effectdata:GetEntity() )
	self:SetOffsetPos( effectdata:GetOrigin() )
	self:SetOffsetAng( effectdata:GetAngles() )
	
	self:SetMuzzleScale( effectdata:GetScale() )
	self:CacheMuzzleFlashes()
	
	if IsValid( self:GetAttachedEntity() ) then
		self:SetParent( self:GetAttachedEntity() )
		self:SetRenderBounds( self:GetAttachedEntity():GetRenderBounds() )
		self:SetLocalPos( vector_origin )
		self:SetLocalAngles( angle_zero )
	end
	
	
	self:SetMuzzleParticleEmitter( ParticleEmitter( vector_origin , false ) )
	self:SetEmitterParticles( {} )
	self:InitPistolMuzzleFlash( effectdata )
	
	
	--doesn't seem to work???
	--self.CalcAbsolutePosition = self.GetCustomParentPosAng
end

function EFFECT:GetMuzzlePosAng()
	if IsValid( self:GetAttachedEntity() ) then
		return LocalToWorld( self:GetOffsetPos() , self:GetOffsetAng() , self:GetPos() , self:GetAngles() )
	end
	
	return self:GetPos() , self:GetAngles()
end

function EFFECT:CacheMuzzleFlashes()

	for i = 1 , 4 do
		if not self.MuzzleFlashMaterials[i] then
			local str = ( "effects/muzzleflash%d" ):format( i )
			self.MuzzleFlashMaterials[i] = str
			Material( str )
		end
	end
	
	for i = 1 , 2 do
		if not self.CombineMuzzleFlashMaterials[i] then
			local str = ( "effects/combinemuzzle%d" ):format( i )
			self.CombineMuzzleFlashMaterials[i] = str
			Material( str )
		end
	end
end

function EFFECT:InitPistolMuzzleFlash( effectdata )
	local emitter = self:GetMuzzleParticleEmitter()
	
	if not emitter then
		return
	end
	
	emitter:SetNoDraw( true )
	
	
	
	local forward = Vector( 1 , 0 , 0 )
	
	local scale = 1.25
	
	for i = 1 , 6 do
		
		local matindex = math.random( 1 , 4 )
		local particle = emitter:Add( self.MuzzleFlashMaterials[matindex] , vector_origin )
		
		if particle then
			particle:SetLifeTime( 0 )
			particle:SetDieTime( self.ExpireTime ) --0.025 )
			
			particle:SetColor( 255 , 255 , 200 + math.random( 0 , 55 ) )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 255 )
			
			local particlesize = ( 4 + math.random( 0 , 200 ) / 100 ) * ( 8 - i ) / 6 * scale
			particlesize = particlesize * self:GetMuzzleScale()
			particle:SetStartSize( particlesize )
			particle:SetEndSize( particlesize )
			
			particle:SetRoll( math.random( 0 , 360 ) )
			particle:SetRollDelta( 0 )
			
			self:GetEmitterParticles()[i] = particle
		end
		
	end

end

function EFFECT:InitSMG1MuzzleFlash( effectdata )

end

function EFFECT:InitAR1MuzzleFlash( effectdata )

end

function EFFECT:InitShotgunMuzzleFlash( effectdata )

end


function EFFECT:Think()
	
	if not IsValid( self:GetAttachedEntity() ) then
		return
	end
	
	local shouldwelive = self.DieTime > CurTime()
	
	if not shouldwelive then
		self:CleanParticles()
	end
	
	return shouldwelive
end

function EFFECT:MoveParticles( pos , forward )
	for i , v in pairs( self:GetEmitterParticles() ) do
		if v then
			local offset = ( forward * ( i * 8 * 1.25 * 0.2 ) * self:GetMuzzleScale() ) --the 0.1 I added myself
			v:SetPos( pos + offset )
		end
	end
end

function EFFECT:CleanParticles()
	self:SetEmitterParticles( {} )
	
	if self:GetMuzzleParticleEmitter() then
		self:GetMuzzleParticleEmitter():Finish()
		self:SetMuzzleParticleEmitter( nil )
	end
end


function EFFECT:Render()
	
	local muzzlepos , muzzleang = self:GetMuzzlePosAng()
	local emitter = self:GetMuzzleParticleEmitter()
	
	if not emitter then
		return
	end
	
	self:MoveParticles( muzzlepos , muzzleang:Forward() )
	emitter:SetPos( muzzlepos )
	
	emitter:Draw()
	
end