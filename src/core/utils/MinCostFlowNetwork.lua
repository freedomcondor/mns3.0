local Dijkstra = function(w)
	-- w is a square of weight, w[i][j] = nil means no connect
	-- if w[i][j] is a table, means multiple connects between i and j
	-- find shortest path from 1 to i

	local INF = 1 / 0

	-- how many nodes
	local n = #w

	-- D[i] is the shortest distance from 1 to i
	local D = {0}
	-- D[i] is the unknown nodes
	local T = {}
	for i = 2, n do T[i] = INF end

	-- L[i] is the last node in the shortest path of i
	local L = {0}

	-- traverse all the nodes
	for i = 2, n do
		-- find a new shortest node
		local dis = INF
		local from = nil
		local to = nil
		-- from all known nodes
		for j, _ in pairs(D) do
			-- from all unknown nodes
			for k, _ in pairs(T) do
				if w[j][k] ~= nil and D[j] + w[j][k] < dis then
					dis = D[j] + w[j][k]
					from = j
					to = k
				end
			end
		end

		-- see whether find one
		if from ~= nil then
			D[to] = dis
			L[to] = from
			T[to] = nil
		else
			-- no longer new nodes
			break
		end
	end

	return D, L
end

function MinCostFlowNetwork(c, w)
	local INF = 1/0
	-- w is the weight
	-- c is the capacity  c[i][j] = nil means no connect
	-- assume the flow is one-directional 
	-- if c[j][i] = xxx then c[j][i] = nil

	-- n is the number of nodes
	local n = #c

	-- f is the flow f[i][j] = flow
	local f = {}
	for i = 1, n do
		f[i] = {}
		for j = 1, n do
			if c[i][j] == nil then
				f[i][j] = nil
			else
				f[i][j] = 0
			end
		end
	end

	while true do
		-- create a substitule graph
		local g = {}
		for i = 1, n do g[i] = {} end
		for i = 1, n do
			for j = 1, n do
				if c[i][j] ~= nil then
					if f[i][j] <= 0 then
						g[i][j] = w[i][j]
					elseif f[i][j] >= c[i][j] then
						g[j][i] = -w[i][j]
					else
						g[i][j] = w[i][j]
						g[j][i] = -w[i][j]
					end
				end
			end
		end

		-- find the shortest path for the graph
		local D, L = Dijkstra(g)
		if D[n] == nil then
			break
		end

		-- find the max increment amount
		local amount = INF
		local node = n
		while node ~= 1 do
			local from = L[node]
			local edgeSpace
			if f[from][node] ~= nil then
				edgeSpace = c[from][node] - f[from][node]
			else
				edgeSpace = f[node][from]
			end

			if edgeSpace < amount then
				amount = edgeSpace
			end
			node = from
		end

		-- change f
		node = n
		while node ~= 1 do
			local from = L[node]
			if f[from][node] ~= nil then
				f[from][node] = f[from][node] + amount
			else
				f[node][from] = f[node][from] - amount
			end
			node = from
		end
	end

	return f
end

return MinCostFlowNetwork
