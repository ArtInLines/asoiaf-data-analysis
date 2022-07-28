using HTTP, JSON

function find(f::Function, A)
	return A[findall(f, A)[1]]
end

getIDFromURL(s::AbstractString)::Integer = parse(Int, last(split(s, "/")))
	
parseDateAndPlace(s::Tuple) = begin
	if s == ""
		return (nothing, nothing)
	end
	
	# Parse Date
	digit = nothing
	digits = []
	idx = findfirst(isdigit, s)
	if idx !== nothing
		push!(digits, s[idx])
		digitidx = 1
		while true
			nextidx = findnext(isdigit, s, idx+1)
			if nextidx === nothing
				break
			elseif nextidx > idx + 1
				push!(digits, "")
				digitidx += 1
			end
			digits[digitidx] *= s[nextidx]
			idx = nextidx
		end
	end
	digits = parse.(Int, digits)
	if length(digits) > 1
		digit = min(digits...):max(digits...)
	# else
	# 	digit = digits[1]
	end
	
	# Parse Place
	idx = findfirst(isequal(','), s)
	if idx === nothing
		return (digit, nothing)
	end
	sub = SubString(s, idx+1)
	if startswith(lowercase(sub), " at")
		sub = SubString(sub, 4)
	end
	return digit, lstrip(sub)
end

function cleanData(chars)::AbstractArray
	return map!(chars, chars) do c
		c["id"] = getIDFromURL(c["url"])
		c["books"] = getIDFromURL.(c["books"])
		c["allegiances"] = getIDFromURL.(c["allegiances"])
		c["deathDate"], c["deathPlace"] = parseDateAndPlace(c["died"])
		c["birthDate"], c["birthPlace"] = parseDateAndPlace(c["born"])
		delete!(c, "died")
		delete!(c, "born")
		delete!(c, "url")
	end
end


page = 1
pageSize = 30
baseURL = "https://www.anapioficeandfire.com/api/characters"
headers = Dict("Accept" => "application/vnd.anapioficeandfire+json; version=1")
lastPage = Inf
chars = []

while page ≤ lastPage
	url = "$baseURL?page=$page&pageSize=$pageSize"
	res = HTTP.get(url, headers)
	page += 1
	linkHeader = find(p -> p.first == "Link", res.headers).second
	lastPage = parse(Int, split(split(linkHeader, "page=")[end], "&")[1])
	body_string = String(res.body)
	push!(chars, JSON.parse(body_string)...)
end

open("chars.json", "w") do io
	JSON.print(io, chars)
end

open("cleanedchars.json", "w") do io
	JSON.print(io, cleanData(chars))
end