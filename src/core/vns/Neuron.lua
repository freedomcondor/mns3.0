logger.register("Neuron")

local Neuron = {}

function Neuron.create(vns)
	vns.neuron = {input = {}}
end

function Neuron.reset(vns)
	vns.neuron = {input = {}}
end

function Neuron.step(vns)
	if vns.allocator.target == nil then return end
	if vns.allocator.target.neuron == nil then return end

	for _, msgM in ipairs(vns.Msg.getAM("ALLMSG", "neuron_data")) do
		if vns.allocator.target.neuron.input ~= nil and
		   vns.allocator.target.neuron.input[msgM.dataT.id] == true then
			vns.neuron.input[msgM.dataT.id] = msgM.dataT.output
		end
	end

	vns.neuron.output = vns.allocator.target.neuron.output(vns.neuron.input)

	vns.Msg.send("ALLMSG", "neuron_data",
		{
			id = vns.allocator.target.neuron.id,
			output = vns.neuron.output,
		}
	)
end

function Neuron.create_neuron_node(vns)
	return function()
		Neuron.step(vns)
		return false, true
	end
end

return Neuron