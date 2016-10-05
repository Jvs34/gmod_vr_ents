AddCSLuaFile()

AccessorFunc( EFFECT , "StartPos" , "StartPos" )
AccessorFunc( EFFECT , "EndPos" , "EndPos" )
AccessorFunc( EFFECT , "Direction" , "Direction" )

AccessorFunc( EFFECT , "TracerTime" , "TracerTime" )

EFFECT.Length = 0.1
EFFECT.TracerMaterial = Material( "effects/spark" )
EFFECT.Speed = 10000

--copied from garry's laser tracer pretty much
function EFFECT:Init( effectdata )
	self:SetStartPos( effectdata:GetStart() )
	self:SetEndPos( effectdata:GetOrigin() )
	
	self:SetDirection( self:GetEndPos() - self:GetStartPos() )
	self:SetRenderBoundsWS( self:GetStartPos() , self:GetEndPos() )
	
	self:SetTracerTime( math.min( 1, self.StartPos:Distance( self:GetEndPos() ) / self.Speed ) )
	self.DieTime = CurTime() + self:GetTracerTime()
end

function EFFECT:Think()
	return self.DieTime > CurTime()
end

function EFFECT:Render()

	local fDelta = ( self.DieTime - CurTime() ) / self:GetTracerTime()
	fDelta = math.Clamp( fDelta, 0, 1 ) ^ 0.5

	render.SetMaterial( self.TracerMaterial )

	local sinWave = math.sin( fDelta * math.pi )
	
	local startpos = self:GetEndPos() - self:GetDirection() * ( fDelta - sinWave * self.Length )
	local endpos = self:GetEndPos() - self:GetDirection() * ( fDelta + sinWave * self.Length )
	
	render.DrawBeam( startpos , endpos , 2 , 1 , 0 , color_white )

end