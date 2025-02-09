import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Array "mo:base/Array";
import Time "mo:base/Time";
import Buffer "mo:base/Buffer";
import Result "mo:base/Result";
import Float "mo:base/Float";
import Int "mo:base/Int";
import Text "mo:base/Text";

actor class TradingBot() {
    // Types
    type Trade = {
        id: Text;
        taskId: Text;
        pair: Text;
        action: {#Buy; #Sell};
        amount: Float;
        price: Float;
        stopLoss: Float;
        timestamp: Int;
        status: {#Pending; #Executed; #Failed; #Cancelled};
    };

    type Decision = {
        action: {#Buy; #Sell; #Hold};
        pair: Text;
        targetPrice: Float;
        stopLoss: Float;
        confidence: Float;
    };

    // State
    private let trades = HashMap.HashMap<Text, Trade>(10, Text.equal, Text.hash);
    private stable var tradeCount: Nat = 0;

    // External canister interfaces
    type CommunicationProtocol = actor {
        getDiscussion: (Text) -> async ?{
            id: Text;
            taskId: Text;
            status: {#Active; #Concluded};
            finalDecision: ?Decision;
        };
    };

    type TaskRegistry = actor {
        getTask: (Text) -> async ?{
            id: Text;
            parameters: {
                pairs: [Text];
                timeframes: [Text];
                riskLevel: {#Low; #Medium; #High};
                targetReturn: Float;
                maxDrawdown: Float;
            };
        };
    };

    type ProxyContract = actor {
        createProposal: (Text, {#Buy; #Sell}, Float, Float) -> async Result.Result<Text, Text>;
        executeProposal: (Text) -> async Result.Result<Text, Text>;
    };

    // Helper: Generate unique IDs
    private func generateId(prefix: Text) : Text {
        tradeCount += 1;
        prefix # Int.toText(tradeCount)
    };

    // Execute Decision
    public shared(msg) func executeDecision(
        discussionId: Text,
        commProtocolId: Text,
        taskRegistryId: Text,
        proxyContractId: Text
    ) : async Result.Result<Text, Text> {
        let commProtocol : CommunicationProtocol = actor(commProtocolId);
        
        switch(await commProtocol.getDiscussion(discussionId)) {
            case null { #err("Discussion not found") };
            case (?disc) {
                if (disc.status != #Concluded) {
                    return #err("Discussion not concluded");
                };

                switch(disc.finalDecision) {
                    case null { #err("No final decision found") };
                    case (?decision) {
                        switch(decision.action) {
                            case (#Hold) { #ok("No trade needed - Hold position") };
                            case (action) {
                                let tradeId = generateId("trade");
                                let trade: Trade = {
                                    id = tradeId;
                                    taskId = disc.taskId;
                                    pair = decision.pair;
                                    action = action;
                                    amount = 1.0; // Default amount, should be calculated based on risk
                                    price = decision.targetPrice;
                                    stopLoss = decision.stopLoss;
                                    timestamp = Time.now();
                                    status = #Pending;
                                };

                                trades.put(tradeId, trade);

                                // Create and execute proposal through proxy contract
                                let proxyContract : ProxyContract = actor(proxyContractId);
                                let proposalResult = await proxyContract.createProposal(
                                    decision.pair,
                                    action,
                                    decision.targetPrice,
                                    decision.stopLoss
                                );

                                switch(proposalResult) {
                                    case (#err(e)) { #err("Proposal creation failed: " # e) };
                                    case (#ok(proposalId)) {
                                        let executionResult = await proxyContract.executeProposal(proposalId);
                                        switch(executionResult) {
                                            case (#err(e)) { 
                                                let updatedTrade = {
                                                    id = trade.id;
                                                    taskId = trade.taskId;
                                                    pair = trade.pair;
                                                    action = trade.action;
                                                    amount = trade.amount;
                                                    price = trade.price;
                                                    stopLoss = trade.stopLoss;
                                                    timestamp = trade.timestamp;
                                                    status = #Failed;
                                                };
                                                trades.put(tradeId, updatedTrade);
                                                #err("Trade execution failed: " # e) 
                                            };
                                            case (#ok(_)) {
                                                let updatedTrade = {
                                                    id = trade.id;
                                                    taskId = trade.taskId;
                                                    pair = trade.pair;
                                                    action = trade.action;
                                                    amount = trade.amount;
                                                    price = trade.price;
                                                    stopLoss = trade.stopLoss;
                                                    timestamp = trade.timestamp;
                                                    status = #Executed;
                                                };
                                                trades.put(tradeId, updatedTrade);
                                                #ok("Trade executed successfully")
                                            };
                                        }
                                    };
                                }
                            };
                        }
                    };
                }
            };
        }
    };

    // Query functions
    public query func getTrade(id: Text) : async ?Trade {
        trades.get(id)
    };

    public query func getTradesByTask(taskId: Text) : async [Trade] {
        let buffer = Buffer.Buffer<Trade>(0);
        for ((_, trade) in trades.entries()) {
            if (trade.taskId == taskId) {
                buffer.add(trade);
            };
        };
        Buffer.toArray(buffer)
    };
} 