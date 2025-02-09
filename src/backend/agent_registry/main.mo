import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Result "mo:base/Result";
import Array "mo:base/Array";
import Time "mo:base/Time";
import Nat "mo:base/Nat";
import Int "mo:base/Int";

actor AgentRegistry {
    // Types
    type Agent = {
        id: Principal;
        name: Text;
        capabilities: [Capability];
        reputation: Nat;
        registrationTime: Int;
        lastActive: Int;
        isActive: Bool;
    };

    type Capability = {
        #DataAnalysis;
        #Trading;
        #EventMonitoring;
        #TaskExecution;
    };

    // State
    private let agents = HashMap.HashMap<Principal, Agent>(10, Principal.equal, Principal.hash);
    private let verifiedAgents = HashMap.HashMap<Principal, Bool>(10, Principal.equal, Principal.hash);

    // Public functions
    public shared(msg) func registerAgent(name: Text, capabilities: [Capability]) : async Result.Result<Text, Text> {
        let agent: Agent = {
            id = msg.caller;
            name = name;
            capabilities = capabilities;
            reputation = 0;
            registrationTime = Time.now();
            lastActive = Time.now();
            isActive = true;
        };

        switch (agents.get(msg.caller)) {
            case (?existing) {
                #err("Agent already registered");
            };
            case null {
                agents.put(msg.caller, agent);
                verifiedAgents.put(msg.caller, false);
                #ok("Agent registered successfully");
            };
        }
    };

    public query func getAgent(id: Principal) : async ?Agent {
        agents.get(id)
    };

    public query func isVerified(id: Principal) : async Bool {
        switch (verifiedAgents.get(id)) {
            case (?verified) { verified };
            case null { false };
        }
    };

    public shared(msg) func updateAgentStatus(isActive: Bool) : async Result.Result<Text, Text> {
        switch (agents.get(msg.caller)) {
            case (?agent) {
                let updatedAgent: Agent = {
                    id = agent.id;
                    name = agent.name;
                    capabilities = agent.capabilities;
                    reputation = agent.reputation;
                    registrationTime = agent.registrationTime;
                    lastActive = Time.now();
                    isActive = isActive;
                };
                agents.put(msg.caller, updatedAgent);
                #ok("Agent status updated");
            };
            case null {
                #err("Agent not found");
            };
        }
    };

    public shared(msg) func updateReputation(agentId: Principal, delta: Int) : async Result.Result<Text, Text> {
        // Only allow verified agents to update reputation
        switch (verifiedAgents.get(msg.caller)) {
            case (?verified) {
                if (not verified) {
                    return #err("Only verified agents can update reputation");
                };
            };
            case null {
                return #err("Caller not registered");
            };
        };

        switch (agents.get(agentId)) {
            case (?agent) {
                let currentReputation = agent.reputation;
                let newReputation = if (delta < 0 and Int.abs(delta) > currentReputation) {
                    0
                } else if (delta < 0) {
                    currentReputation - Int.abs(delta)
                } else {
                    currentReputation + Int.abs(delta)
                };

                let updatedAgent: Agent = {
                    id = agent.id;
                    name = agent.name;
                    capabilities = agent.capabilities;
                    reputation = newReputation;
                    registrationTime = agent.registrationTime;
                    lastActive = agent.lastActive;
                    isActive = agent.isActive;
                };
                agents.put(agentId, updatedAgent);
                #ok("Reputation updated");
            };
            case null {
                #err("Target agent not found");
            };
        }
    };

    // Admin functions
    public shared(msg) func verifyAgent(agentId: Principal) : async Result.Result<Text, Text> {
        // Add proper admin check here
        verifiedAgents.put(agentId, true);
        #ok("Agent verified");
    };
} 