import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Result "mo:base/Result";
import Array "mo:base/Array";
import Time "mo:base/Time";

actor PublicRegistry {
    // Types
    type AgentPublicInfo = {
        id: Principal;
        name: Text;
        capabilities: [Text];
        registrationTime: Int;
        contextId: ?Text;  // The Calimero context this agent is part of
    };

    // Public state - This will be on IC mainnet
    private stable var agentCount: Nat = 0;
    private let publicAgentInfo = HashMap.HashMap<Principal, AgentPublicInfo>(10, Principal.equal, Principal.hash);
    private let contextAssignments = HashMap.HashMap<Text, [Principal]>(10, Text.equal, Text.hash);

    // Public functions - These operations happen on IC mainnet
    public shared(msg) func registerAgent(name: Text, capabilities: [Text]) : async Result.Result<Text, Text> {
        let agentInfo: AgentPublicInfo = {
            id = msg.caller;
            name = name;
            capabilities = capabilities;
            registrationTime = Time.now();
            contextId = null;
        };

        switch (publicAgentInfo.get(msg.caller)) {
            case (?existing) {
                #err("Agent already registered on mainnet");
            };
            case null {
                publicAgentInfo.put(msg.caller, agentInfo);
                agentCount += 1;
                #ok("Agent registered on mainnet");
            };
        }
    };

    // Called when an agent joins a Calimero context
    public shared(msg) func assignAgentToContext(contextId: Text) : async Result.Result<Text, Text> {
        switch (publicAgentInfo.get(msg.caller)) {
            case (?agentInfo) {
                let updatedInfo: AgentPublicInfo = {
                    id = agentInfo.id;
                    name = agentInfo.name;
                    capabilities = agentInfo.capabilities;
                    registrationTime = agentInfo.registrationTime;
                    contextId = ?contextId;
                };
                publicAgentInfo.put(msg.caller, updatedInfo);

                // Update context assignments
                switch (contextAssignments.get(contextId)) {
                    case (?agents) {
                        let updatedAgents = Array.append(agents, [msg.caller]);
                        contextAssignments.put(contextId, updatedAgents);
                    };
                    case null {
                        contextAssignments.put(contextId, [msg.caller]);
                    };
                };
                #ok("Agent assigned to context");
            };
            case null {
                #err("Agent not registered on mainnet");
            };
        }
    };

    // Public queries - Available on IC mainnet
    public query func getPublicAgentInfo(id: Principal) : async ?AgentPublicInfo {
        publicAgentInfo.get(id)
    };

    public query func getAgentsInContext(contextId: Text) : async [Principal] {
        switch (contextAssignments.get(contextId)) {
            case (?agents) { agents };
            case null { [] };
        }
    };
} 