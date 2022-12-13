@attached(peer, names: arbitrary)
@attached(accessor)
public macro Associated(
	_ policy: Policy
) = #externalMacro(
	module: "AssociationMacro",
	type: "AssociatedMacro"
)

@attached(accessor)
public macro _Associated(
	_ policy: Policy
) = #externalMacro(
	module: "AssociationMacro",
	type: "AssociatedMacro"
)
