import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Array "mo:base/Array";
import Time "mo:base/Time";
import Buffer "mo:base/Buffer";
import Result "mo:base/Result";
import Error "mo:base/Error";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Int "mo:base/Int";
import Float "mo:base/Float";

actor class CommunicationProtocol(contextId: Text) {
    // Core types
    type Discussion = {
        id: Text;
        taskId: Text;
        messages: [Message];
        status: {#Active; #Concluded};
        marketData: ?MarketSnapshot;
        votes: [(Principal, Bool)];
        finalDecision: ?Decision;
    };

    type Message = {
        author: Principal;
        content: Text;
        timestamp: Int;
        kind: {#Analysis; #Question; #Suggestion; #Concern};
    };

    type MarketSnapshot = {
        pair: Text;
        price: Float;
        rsi: Float;
        macd: (Float, Float);
        timestamp: Int;
    };

    type Decision = {
        action: {#Buy; #Sell; #Hold};
        pair: Text;
        targetPrice: Float;
        stopLoss: Float;
        confidence: Float;
    };

    // Types
    type EncryptionMetadata = {
        publicKeyHash: Text;     // Hash of recipient's public key used
        encryptionMethod: Text;  // Encryption method identifier
        nonce: ?Text;           // Optional nonce for encryption
    };

    type MessageType = {
        #TaskAssignment;
        #DataRequest;
        #DataResponse;
        #StatusUpdate;
    };

    type ContextConfig = actor {
        isNodeInContext : (Principal) -> async Bool;
        getContextMembers : () -> async [Principal];
    };

    // State
    private stable var messageCount: Nat = 0;
    private let messages = HashMap.HashMap<Text, Message>(10, Text.equal, Text.hash);
    private let contextConfig : ContextConfig = actor(contextId);
    private let agentPublicKeys = HashMap.HashMap<Principal, Text>(10, Principal.equal, Principal.hash);
    private let discussions = HashMap.HashMap<Text, Discussion>(10, Text.equal, Text.hash);
    private stable var discussionCount: Nat = 0;

    // External canister interfaces
    type TaskRegistry = actor {
        getTask: (Text) -> async ?TradingTask;
        getTaskAgents: (Text) -> async [Principal];
    };

    type TradingTask = {
        id: Text;
        parameters: {
            pairs: [Text];
            timeframes: [Text];
            riskLevel: {#Low; #Medium; #High};
            targetReturn: Float;
            maxDrawdown: Float;
        };
        assignedAgents: [Principal];
    };

    type MarketData = actor {
        getPrice: (Text) -> async Result.Result<Float, Text>;
        getRSI: (Text, Nat) -> async Result.Result<Float, Text>;
        getMACD: (Text) -> async Result.Result<(Float, Float), Text>;
    };

    // Helper functions
    private func generateMessageId() : Text {
        messageCount += 1;
        return Nat.toText(messageCount);
    };

    // Helper: Generate unique IDs
    private func generateId(prefix: Text) : Text {
        discussionCount += 1;
        prefix # Int.toText(discussionCount)
    };

    // Helper: Verify agent is assigned to task
    private func verifyAgentForTask(agent: Principal, taskId: Text, taskRegistry: TaskRegistry) : async Bool {
        let taskAgents = await taskRegistry.getTaskAgents(taskId);
        for (taskAgent in taskAgents.vals()) {
            if (Principal.equal(taskAgent, agent)) {
                return true;
            };
        };
        false
    };

    // Public functions
    public shared(msg) func registerPublicKey(publicKey: Text) : async Result.Result<Text, Text> {
        // Verify caller is in context
        let isInContext = await contextConfig.isNodeInContext(msg.caller);
        if (not isInContext) {
            return #err("Agent not in context");
        };

        agentPublicKeys.put(msg.caller, publicKey);
        #ok("Public key registered")
    };

    public shared(msg) func sendMessage(
        to: Principal,
        content: Text,
        messageType: MessageType,
        encryptionMetadata: ?EncryptionMetadata
    ) : async Result.Result<Text, Text> {
        // Verify both sender and receiver are in the context
        let senderInContext = await contextConfig.isNodeInContext(msg.caller);
        let receiverInContext = await contextConfig.isNodeInContext(to);

        if (not senderInContext or not receiverInContext) {
            return #err("Both sender and receiver must be in the context");
        };

        // Verify recipient has registered their public key if encryption is used
        switch(encryptionMetadata) {
            case (?metadata) {
                switch(agentPublicKeys.get(to)) {
                    case null return #err("Recipient has not registered their public key");
                    case (?_) {};
                };
            };
            case null {};
        };

        let message: Message = {
            author = msg.caller;
            content = content;
            timestamp = Time.now();
            kind = switch(messageType) {
                case (#TaskAssignment) { #Analysis };
                case (#DataRequest) { #Question };
                case (#DataResponse) { #Suggestion };
                case (#StatusUpdate) { #Concern };
            };
        };

        messages.put(message.id, message);
        #ok(message.id)
    };

    public query(msg) func getMessages(recipient: Principal) : async [Message] {
        let messageBuffer = Buffer.Buffer<Message>(0);
        for ((_, message) in messages.entries()) {
            if (message.author == recipient) {
                messageBuffer.add(message);
            };
        };
        Buffer.toArray(messageBuffer)
    };

    public query func getPublicKey(agent: Principal) : async ?Text {
        agentPublicKeys.get(agent)
    };

    public shared(msg) func getContextMembers() : async [Principal] {
        await contextConfig.getContextMembers()
    };

    // Start Discussion
    public shared(msg) func startDiscussion(taskId: Text, taskRegistryId: Text) : async Result.Result<Text, Text> {
        let taskRegistry : TaskRegistry = actor(taskRegistryId);
        
        if (not (await verifyAgentForTask(msg.caller, taskId, taskRegistry))) {
            return #err("Agent not authorized for task");
        };

        let discussionId = generateId("disc");
        let discussion: Discussion = {
            id = discussionId;
            taskId = taskId;
            messages = [];
            status = #Active;
            marketData = null;
            votes = [];
            finalDecision = null;
        };

        discussions.put(discussionId, discussion);
        #ok(discussionId)
    };

    // Add Message & Analysis
    public shared(msg) func addMessage(
        discussionId: Text,
        content: Text,
        kind: {#Analysis; #Question; #Suggestion; #Concern},
        taskRegistryId: Text
    ) : async Result.Result<Text, Text> {
        switch(discussions.get(discussionId)) {
            case null { #err("Discussion not found") };
            case (?disc) {
                if (disc.status == #Concluded) {
                    return #err("Discussion already concluded");
                };

                let taskRegistry : TaskRegistry = actor(taskRegistryId);
                if (not (await verifyAgentForTask(msg.caller, disc.taskId, taskRegistry))) {
                    return #err("Agent not authorized");
                };

                let message: Message = {
                    author = msg.caller;
                    content = content;
                    timestamp = Time.now();
                    kind = kind;
                };

                let updatedDiscussion: Discussion = {
                    id = disc.id;
                    taskId = disc.taskId;
                    messages = Array.append(disc.messages, [message]);
                    status = disc.status;
                    marketData = disc.marketData;
                    votes = disc.votes;
                    finalDecision = disc.finalDecision;
                };

                discussions.put(discussionId, updatedDiscussion);
                #ok("Message added")
            };
        }
    };

    // Update Market Data
    public shared(msg) func updateMarketData(
        discussionId: Text,
        pair: Text,
        taskRegistryId: Text,
        marketDataId: Text
    ) : async Result.Result<Text, Text> {
        switch(discussions.get(discussionId)) {
            case null { #err("Discussion not found") };
            case (?disc) {
                let taskRegistry : TaskRegistry = actor(taskRegistryId);
                if (not (await verifyAgentForTask(msg.caller, disc.taskId, taskRegistry))) {
                    return #err("Agent not authorized");
                };

                let marketData : MarketData = actor(marketDataId);
                let priceResult = await marketData.getPrice(pair);
                let rsiResult = await marketData.getRSI(pair, 14);
                let macdResult = await marketData.getMACD(pair);

                switch(priceResult, rsiResult, macdResult) {
                    case (#err(e), _, _) { #err("Price error: " # e) };
                    case (_, #err(e), _) { #err("RSI error: " # e) };
                    case (_, _, #err(e)) { #err("MACD error: " # e) };
                    case (#ok(price), #ok(rsi), #ok(macd)) {
                        let snapshot: MarketSnapshot = {
                            pair = pair;
                            price = price;
                            rsi = rsi;
                            macd = macd;
                            timestamp = Time.now();
                        };

                        let updatedDiscussion: Discussion = {
                            id = disc.id;
                            taskId = disc.taskId;
                            messages = disc.messages;
                            status = disc.status;
                            marketData = ?snapshot;
                            votes = disc.votes;
                            finalDecision = disc.finalDecision;
                        };

                        discussions.put(discussionId, updatedDiscussion);
                        #ok("Market data updated")
                    };
                }
            };
        }
    };

    // Vote on Strategy
    public shared(msg) func vote(
        discussionId: Text,
        approve: Bool,
        decision: ?{
            action: {#Buy; #Sell; #Hold};
            pair: Text;
            targetPrice: Float;
            stopLoss: Float;
            confidence: Float;
        },
        taskRegistryId: Text
    ) : async Result.Result<Text, Text> {
        switch(discussions.get(discussionId)) {
            case null { #err("Discussion not found") };
            case (?disc) {
                let taskRegistry : TaskRegistry = actor(taskRegistryId);
                if (not (await verifyAgentForTask(msg.caller, disc.taskId, taskRegistry))) {
                    return #err("Agent not authorized");
                };

                // Remove previous vote if exists
                let currentVotes = Array.filter<(Principal, Bool)>(
                    disc.votes,
                    func((voter, _): (Principal, Bool)) : Bool { voter != msg.caller }
                );

                let newVotes = Array.append(currentVotes, [(msg.caller, approve)]);
                
                // Check if we have consensus (>50% approval)
                let approvalCount = Array.filter<(Principal, Bool)>(newVotes, func((_, vote): (Principal, Bool)) : Bool { vote }).size();
                let taskAgents = await taskRegistry.getTaskAgents(disc.taskId);
                let consensusReached = Float.fromInt(approvalCount) / Float.fromInt(taskAgents.size()) > 0.5;

                let updatedDiscussion: Discussion = {
                    id = disc.id;
                    taskId = disc.taskId;
                    messages = disc.messages;
                    status = if (consensusReached) { #Concluded } else { disc.status };
                    marketData = disc.marketData;
                    votes = newVotes;
                    finalDecision = if (consensusReached and approve) { decision } else { disc.finalDecision };
                };

                discussions.put(discussionId, updatedDiscussion);
                #ok(if (consensusReached) { "Consensus reached" } else { "Vote recorded" })
            };
        }
    };

    // Query functions
    public query func getDiscussion(id: Text) : async ?Discussion {
        discussions.get(id)
    };

    public query func getActiveDiscussions() : async [Discussion] {
        let buffer = Buffer.Buffer<Discussion>(0);
        for ((_, disc) in discussions.entries()) {
            if (disc.status == #Active) {
                buffer.add(disc);
            };
        };
        Buffer.toArray(buffer)
    };
} 