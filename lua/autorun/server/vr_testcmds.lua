concommand.Add( "vr_createfake" , function( ply , cmd , args , fullstr )
	
	if not IsValid( ply ) then
		return
	end
	
	local slot1 = "fake_vivecontroller_left"
	local slot2 = "fake_vivecontroller_right"
	
	if IsValid( ply:GetNW2Entity( slot1 ) ) then
		ply:GetNW2Entity( slot1 ):Remove()
	end
	
	if IsValid( ply:GetNW2Entity( slot2 ) ) then
		ply:GetNW2Entity( slot2 ):Remove()
	end
	
	local distancefromeye = 10
	
	local vive_left = ents.Create( "fake_vive_controller" )
	if IsValid( vive_left ) then
		vive_left:SetOwner( ply )
		vive_left:SetParent( ply )
		vive_left:SetIsLeft( true )
		vive_left:SetCurrentOffsetPos( Vector( 30 , distancefromeye , -10 ) )
		vive_left:Spawn()
		ply:SetNW2Entity( slot1 , vive_left )
		
		local pistol = ents.Create( "vr_pistol" )
		pistol:Spawn()
		pistol:EquipTo( ply , vive_left )
	end
	
	local vive_right = ents.Create( "fake_vive_controller" )
	if IsValid( vive_right ) then
		vive_right:SetOwner( ply )
		vive_right:SetParent( ply )
		vive_right:SetIsLeft( false )
		vive_right:SetCurrentOffsetPos( Vector( 30 , distancefromeye * -1 , -10 ) )
		vive_right:Spawn()
		ply:SetNW2Entity( slot2 , vive_right )
		
		local pistol = ents.Create( "vr_pistol" )
		pistol:Spawn()
		pistol:EquipTo( ply , vive_right )
	end
	
end)