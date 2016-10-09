AddCSLuaFile()

--TODO

--TEMPORARY AGAIN
hook.Add( "SetupMove" , "VRInput" , function( ply , mv , cumd )
	local slot1 = "fake_vivecontroller_left"
	local slot2 = "fake_vivecontroller_right"
	
	if IsValid( ply:GetNW2Entity( slot1 ) ) then
		ply:GetNW2Entity( slot1 ):HandleInput( mv )
		ply:GetNW2Entity( slot1 ):HandleSimulate( mv )
	end
	
	if IsValid( ply:GetNW2Entity( slot2 ) ) then
		ply:GetNW2Entity( slot2 ):HandleInput( mv )
		ply:GetNW2Entity( slot2 ):HandleSimulate( mv )
	end
	
end)

--TEMPORARY TEMPORARY TEMPORARY TEMPORARY TEMPORARY TEMPORARY TEMPORARY TEMPORARY
--this comes from PAC3, I ripped it because I really can't be arsed to compile the vive models into source
--so I can just read the objects and draw them for the fake controllers
--this will be removed once actual testing will be available to me

if CLIENT then

local ipairs        = ipairs
local pairs         = pairs
local tonumber      = tonumber

local math_sqrt     = math.sqrt
local string_gmatch = string.gmatch
local string_gsub   = string.gsub
local string_match  = string.match
local string_sub    = string.sub
local string_Split  = string.Split
local string_Trim   = string.Trim
local table_concat  = table.concat
local table_insert  = table.insert

local Vector        = Vector


function ParseObj( data , generateNormals )
	
	local positions  = {}
	local texCoordsU = {}
	local texCoordsV = {}
	local normals    = {}

	local triangleList = {}

	local lines = {}
	local faceLines = {}

	local i = 1
	local inContinuation    = false
	local continuationLines = nil
	for line in string_gmatch (data, "(.-)\n") do
		local continuation = string_match (line, "\\\r?$")
		if continuation then
			line = string_sub (line, 1, -#continuation - 1)
			if inContinuation then
				continuationLines[#continuationLines + 1] = line
			else
				inContinuation    = true
				continuationLines = { line }
			end
		else
			if inContinuation then
				continuationLines[#continuationLines + 1] = line
				lines[#lines + 1] = table_concat (continuationLines)
				inContinuation    = false
				continuationLines = nil
			else
				lines[#lines + 1] = line
			end
		end
		i = i + 1
	end

	if inContinuation then
		continuationLines[#continuationLines + 1] = line
		lines[#lines + 1] = table.concat (continuationLines)
		inContinuation    = false
		continuationLines = nil
	end

	local lineCount = #lines
	local inverseLineCount = 1 / lineCount
	local i = 1
	while i <= lineCount do
		local processedLine = false

		-- Positions: v %f %f %f [%f]
		while i <= lineCount do
			local line = lines[i]
			local x, y, z = string_match(line, "^%s*v%s+(%-?%d*%.?%d*e?[+-]?%d*%.?%d*)%s+(%-?%d*%.?%d*e?[+-]?%d*%.?%d*)%s+(%-?%d*%.?%d*e?[+-]?%d*%.?%d*)")
			if not x then break end

			processedLine = true
			x, y, z = tonumber(x) or 0, tonumber(y) or 0, tonumber(z) or 0
			positions[#positions + 1] = Vector(x, y, z)

			i = i + 1
		end

		-- Texture coordinates: vt %f %f
		while i <= lineCount do
			local line = lines[i]
			local u, v = string_match(line, "^%s*vt%s+(%-?%d*%.?%d*e?[+-]?%d*%.?%d*)%s+(%-?%d*%.?%d*e?[+-]?%d*%.?%d*)")
			if not u then break end

			processedLine = true
			u, v = tonumber(u) or 0, tonumber(v) or 0

			local texCoordIndex = #texCoordsU + 1
			texCoordsU[texCoordIndex] =      u  % 1
			texCoordsV[texCoordIndex] = (1 - v) % 1

			i = i + 1
		end

		-- Normals: vn %f %f %f
		while i <= lineCount do
			local line = lines[i]
			local nx, ny, nz = string_match(line, "^%s*vn%s+(%-?%d*%.?%d*e?[+-]?%d*%.?%d*)%s+(%-?%d*%.?%d*e?[+-]?%d*%.?%d*)%s+(%-?%d*%.?%d*e?[+-]?%d*%.?%d*)")
			if not nx then break end

			processedLine = true

			if not generateNormals then
				nx, ny, nz = tonumber(nx) or 0, tonumber(ny) or 0, tonumber(nz) or 0

				local inverseLength = 1 / math_sqrt(nx * nx + ny * ny + nz * nz)
				nx, ny, nz = nx * inverseLength, ny * inverseLength, nz * inverseLength

				local normal = Vector(nx, ny, nz)
				normals[#normals + 1] = normal
			end

			i = i + 1
		end

		-- Faces: f %f %f %f+
		while i <= lineCount do
			local line = lines[i]
			if not string_match(line, "^%s*f%s+") then break end

			processedLine = true
			line = string_match (line, "^%s*(.-)[#%s]*$")

			-- Explode line
			local parts = {}
			for part in string_gmatch(line, "[^%s]+") do
				parts[#parts + 1] = part
			end
			faceLines[#faceLines + 1] = parts

			i = i + 1
		end

		-- Something else
		if not processedLine then
			i = i + 1
		end
	end

	local faceLineCount = #faceLines
	local inverseFaceLineCount = 1 / faceLineCount
	for i = 1, #faceLines do
		local parts = faceLines [i]

		if #parts >= 4 then
			local v1PositionIndex, v1TexCoordIndex, v1NormalIndex = string_match(parts[2], "(%d+)/?(%d*)/?(%d*)")
			local v3PositionIndex, v3TexCoordIndex, v3NormalIndex = string_match(parts[3], "(%d+)/?(%d*)/?(%d*)")

			v1PositionIndex, v1TexCoordIndex, v1NormalIndex = tonumber(v1PositionIndex), tonumber(v1TexCoordIndex), tonumber(v1NormalIndex)
			v3PositionIndex, v3TexCoordIndex, v3NormalIndex = tonumber(v3PositionIndex), tonumber(v3TexCoordIndex), tonumber(v3NormalIndex)

			for i = 4, #parts do
				local v2PositionIndex, v2TexCoordIndex, v2NormalIndex = string_match(parts[i], "(%d+)/?(%d*)/?(%d*)")
				v2PositionIndex, v2TexCoordIndex, v2NormalIndex = tonumber(v2PositionIndex), tonumber(v2TexCoordIndex), tonumber(v2NormalIndex)

				local v1 = { pos_index = nil, pos = nil, u = nil, v = nil, normal = nil }
				local v2 = { pos_index = nil, pos = nil, u = nil, v = nil, normal = nil }
				local v3 = { pos_index = nil, pos = nil, u = nil, v = nil, normal = nil }

				v1.pos_index = v1PositionIndex
				v2.pos_index = v2PositionIndex
				v3.pos_index = v3PositionIndex

				v1.pos = positions[v1PositionIndex]
				v2.pos = positions[v2PositionIndex]
				v3.pos = positions[v3PositionIndex]

				if #texCoordsU > 0 then
					v1.u = texCoordsU[v1TexCoordIndex]
					v1.v = texCoordsV[v1TexCoordIndex]

					v2.u = texCoordsU[v2TexCoordIndex]
					v2.v = texCoordsV[v2TexCoordIndex]

					v3.u = texCoordsU[v3TexCoordIndex]
					v3.v = texCoordsV[v3TexCoordIndex]
				end

				if #normals > 0 then
					v1.normal = normals[v1NormalIndex]
					v2.normal = normals[v2NormalIndex]
					v3.normal = normals[v3NormalIndex]
				end

				triangleList [#triangleList + 1] = v1
				triangleList [#triangleList + 1] = v2
				triangleList [#triangleList + 1] = v3

				v3PositionIndex, v3TexCoordIndex, v3NormalIndex = v2PositionIndex, v2TexCoordIndex, v2NormalIndex
			end
		end

	end

	if generateNormals then
		local vertexNormals = {}
		local triangleCount = #triangleList / 3
		local inverseTriangleCount = 1 / triangleCount
		for i = 1, triangleCount do
			local a, b, c = triangleList[1+(i-1)*3+0], triangleList[1+(i-1)*3+1], triangleList[1+(i-1)*3+2]
			local normal = (c.pos - a.pos):Cross(b.pos - a.pos):GetNormalized()

			vertexNormals[a.pos_index] = vertexNormals[a.pos_index] or Vector()
			vertexNormals[a.pos_index] = (vertexNormals[a.pos_index] + normal)

			vertexNormals[b.pos_index] = vertexNormals[b.pos_index] or Vector()
			vertexNormals[b.pos_index] = (vertexNormals[b.pos_index] + normal)

			vertexNormals[c.pos_index] = vertexNormals[c.pos_index] or Vector()
			vertexNormals[c.pos_index] = (vertexNormals[c.pos_index] + normal)
		end

		local defaultNormal = Vector(0, 0, -1)

		local vertexCount = #triangleList
		local inverseVertexCount = 1 / vertexCount
		for i = 1, vertexCount do
			local normal = vertexNormals[triangleList[i].pos_index] or defaultNormal
			normal:Normalize()
			normals[i] = normal
			triangleList[i].normal = normal
		end
	end

	return triangleList
end


function CreateModelFromObjData( objData )
	local mesh = Mesh()

	local meshData = ParseObj( objData , false )
	mesh:BuildFromTriangles( meshData )
	
	return mesh
end
	
end