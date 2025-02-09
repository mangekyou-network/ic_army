import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Array "mo:base/Array";
import Time "mo:base/Time";
import Buffer "mo:base/Buffer";
import Result "mo:base/Result";
import Error "mo:base/Error";
import Text "mo:base/Text";
import Nat "mo:base/Nat";

// This actor runs in Calimero's private context
actor class PrivateCommunication(publicRegistryId: Text, contextId: Text) {
    // Types
    type Message = {
        id: Text;
        from: Principal;
        to: Principal;
        content: Text;  // Encrypted payload
        timestamp: Int;
        messageType: MessageType;
    };

    type MessageType = {
        #TaskAssignment: {
            taskId: Text;
            parameters: Text; // Encrypted task parameters
        };
        #DataRequest: {
            requestId: Text;
            dataType: Text;
        };
        #DataResponse: {
            requestId: Text;
            data: Text; // Encrypted data
        };
        #StatusUpdate: {
            status: Text;
            details: Text;
        };
    };

    type PublicRegistry = actor {
        getPublicAgentInfo: (Principal) -> async ?AgentPublicInfo;
        getAgentsInContext: (Text) -> async [Principal];
    };

    type AgentPublicInfo = {
        id: Principal;
        name: Text;
        capabilities: [Text];
        registrationTime: Int;
        contextId: ?Text;
    };

    // Private state - This stays in Calimero's private context
    private stable var messageCount: Nat = 0;
    private let messages = HashMap.HashMap<Text, Message>(10, Text.equal, Text.hash);
    private let publicRegistry : PublicRegistry = actor(publicRegistryId);
    
    // Private encryption keys and session data
    private let encryptionKeys = HashMap.HashMap<Principal, Text>(10, Principal.equal, Principal.hash);
    private let activeSessions = HashMap.HashMap<Text, Int>(10, Text.equal, Text.hash);

    // Helper functions
    private func generateMessageId() : Text {
        messageCount += 1;
        return Int.toText(messageCount);
    };

    // Private functions - These operations happen in Calimero's private context
    private func verifyAgentInContext(agent: Principal) : async Bool {
        let contextAgents = await publicRegistry.getAgentsInContext(contextId);
        Array.contains<Principal>(contextAgents, agent, Principal.equal)
    };

    // Public functions - These still execute in the private context
    public shared(msg) func sendPrivateMessage(
        to: Principal,
        encryptedContent: Text,
        messageType: MessageType,
    ) : async Result.Result<Text, Text> {
        // Verify both agents are in this context
        let senderVerified = await verifyAgentInContext(msg.caller);
        let receiverVerified = await verifyAgentInContext(to);

        if (not senderVerified or not receiverVerified) {
            return #err("Both agents must be verified in this context");
        };

        let message: Message = {
            id = generateMessageId();
            from = msg.caller;
            to = to;
            content = encryptedContent;
            timestamp = Time.now();
            messageType = messageType;
        };

        messages.put(message.id, message);
        #ok(message.id)
    };

    public query(msg) func getPrivateMessages() : async [Message] {
        let messageBuffer = Buffer.Buffer<Message>(0);
        for ((_, message) in messages.entries()) {
            if (message.to == msg.caller or message.from == msg.caller) {
                messageBuffer.add(message);
            };
        };
        Buffer.toArray(messageBuffer)
    };

    // Session management - All private in Calimero context
    public shared(msg) func startSession(encryptionKey: Text) : async Result.Result<Text, Text> {
        let isVerified = await verifyAgentInContext(msg.caller);
        if (not isVerified) {
            return #err("Agent not verified in this context");
        };

        encryptionKeys.put(msg.caller, encryptionKey);
        let sessionId = Principal.toText(msg.caller) # Int.toText(Time.now());
        activeSessions.put(sessionId, Time.now());
        #ok(sessionId)
    };

    public shared(msg) func endSession() : async Result.Result<Text, Text> {
        encryptionKeys.delete(msg.caller);
        #ok("Session ended")
    };
} 