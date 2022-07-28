using JSON

chars = JSON.parsefile("cleanedchars.json")

function sortCharsBy(key::AbstractString)::AbstractArray
	charsByKey = Dict()
	for char in chars
		val = char[key]
		if !isa(val, AbstractArray)
			val = [val]
		end
		for v in val
			if haskey(charsByKey, v)
				push!(charsByKey[v], char)
			else
				charsByKey[v] = [char]
			end
		end
	end

	l = []
	for k in keys(charsByKey)
		push!(l, [k, charsByKey[k]])
	end
	lt(x, y) = length(x[2]) < length(y[2])
	return sort(l, lt=lt, rev=true)
end

byCulture = sortCharsBy("culture")
byTitle = sortCharsBy("titles")
byAllegiance = sortCharsBy("allegiances")
byPOVBooks = sortCharsBy("povBooks")
byBooks = sortCharsBy("books")
byGender = sortCharsBy("gender")
byBirthDate = sortCharsBy("birthDate")
byDeathDate = sortCharsBy("deathDate")

