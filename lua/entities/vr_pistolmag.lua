AddCSLuaFile()

DEFINE_BASECLASS( "base_vr_entity" )

ENT.Spawnable = true
ENT.PrintName = "VR Pistol Magazine"

ENT.CollisionsMin = Vector( -1.5 , -0.721349 , -3.411153 )
ENT.CollisionsMax = Vector( 1.5 , 0.719209 , 1.8)


function ENT:SpawnFunction( ply, tr, ClassName )

	if not tr.Hit then return end

	local SpawnPos = tr.HitPos + tr.HitNormal * 36

	local ent = ents.Create( ClassName )
	ent:SetPos( SpawnPos )
	ent:Spawn()
	return ent

end

function ENT:SetupDataTables()
	BaseClass.SetupDataTables( self )
	self:DefineNWVar( "Int" , "Bullets" )
end

function ENT:Initialize()
	if SERVER then
		self:SetModel( "models/ugc/76561197995159516/mickyan/w_hdpistol.mdl" )
		self:SetBullets( 18 )
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
			phys:SetMass( 5 )
			
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

function ENT:CalcAbsolutePosition()
	if IsValid( self:GetParent() ) then
		local pos , ang = self:GetPos() , self:GetAngles()
		
		if self:GetParent().GetMagazinePosAng then
			pos , ang = self:GetParent():GetMagazinePosAng()
		end
		
		return pos , ang
	end
end

--this will be moved to a main vr_magazine base entity later
function ENT:IsHeld()
	
	if IsValid( self:GetOwner() ) and IsValid( self:GetParent() ) and self:GetOwner() == self:GetParent() then
		return self:GetOwner():IsHeld()
	end
	
	return BaseClass.IsHeld( self )
end

if CLIENT then
	function ENT:ShouldPredict()
		
		--this could be way better
		if IsValid( self:GetOwner() ) and IsValid( self:GetParent() ) and self:GetOwner() == self:GetParent() then
			return self:GetOwner():ShouldPredict()
		end
		
		return BaseClass.IsHeld( self )
	end
	
	function ENT:BuildAnimationBones( nbones )
		for i = 0 , nbones - 1 do
			local m = self:GetBoneMatrix( i )
			if m then
				if i ~= self.MagazineBone and i ~= self.BulletBone and i ~= self.BulletCasingBone then
					m:SetScale( vector_origin )
					self:SetBoneMatrix( i , m )
				end
			end
			
			local bulletcasingbonematrix = self:GetBoneMatrix( self.BulletCasingBone )
			local bulletbonematrix = self:GetBoneMatrix( self.BulletBone )
			
			if bulletbonematrix and bulletcasingbonematrix then
				local translatevec = Vector( 0 , -0.11 , -0.1 )
				bulletbonematrix:Translate( translatevec )
				bulletcasingbonematrix:Translate( translatevec )
				
				
				bulletbonematrix:Scale( Vector( 1 , 1 , 1 ) * 0.97 )
				bulletcasingbonematrix:Scale( Vector( 1 , 1 , 1 ) * 0.97 )
				
				
				self:SetBoneMatrix( self.BulletBone , bulletbonematrix )
				self:SetBoneMatrix( self.BulletCasingBone , bulletcasingbonematrix )
				
			end
		end
		
		
	end
	
	function ENT:Draw( flags )
		--[[
		local bbmin , bbmax = self.CollisionsMin , self.CollisionsMax
		render.DrawWireframeBox( self:GetPos() , self:GetAngles() , bbmin , bbmax , color_white )
		]]
		if self:GetBullets() == 0 then
			self:SetSubMaterial( 1 , "engine/occlusionproxy" )
		else
			self:SetSubMaterial( 1 , nil )
		end
		
		self:DrawModel()
	end
end