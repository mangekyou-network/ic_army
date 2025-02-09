import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Array "mo:base/Array";
import Time "mo:base/Time";
import Buffer "mo:base/Buffer";
import Result "mo:base/Result";
import Float "mo:base/Float";
import Int "mo:base/Int";
import Text "mo:base/Text";
import Error "mo:base/Error";
import IC "ic:aaaaa-aa";
import Debug "mo:base/Debug";
import Blob "mo:base/Blob";
import Cycles "mo:base/ExperimentalCycles";

// This canister runs on IC mainnet
actor class TradeExecutor(ledgerCanisterId: Text) {
    type Trade = {
        id: Text;
        pair: Text;
        action: {#Buy; #Sell};
        amount: Float;
        price: Float;
        stopLoss: Float;
        timestamp: Int;
        status: {#Pending; #Executed; #Failed};
        calimeroContextId: Text;  // Reference to Calimero context that initiated trade
        executionData: ?ExecutionData;
    };

    type ExecutionData = {
        executionPrice: Float;
        executionTimestamp: Int;
        txHash: Text;
        fees: Float;
    };

    type http_header = {
        name: Text;
        value: Text;
    };

    type http_response = {
        status: Nat;
        headers: [http_header];
        body: Blob;
    };

    type http_request_result = {
        status: Nat;
        headers: [http_header];
        body: Blob;
    };

    type CanisterHttpRequestArgs = {
        url: Text;
        max_response_bytes: ?Nat64;
        headers: [http_header];
        body: ?Blob;
        method: {#get; #post; #head};
        transform: ?{
            function: shared query ({context: Blob; response: http_request_result}) -> async http_request_result;
            context: Blob;
        };
    };

    // State
    private stable var tradeCount: Nat = 0;
    private let trades = HashMap.HashMap<Text, Trade>(10, Text.equal, Text.hash);
    private let authorizedContexts = HashMap.HashMap<Text, Bool>(10, Text.equal, Text.hash);
    private let LEDGER_ID = ledgerCanisterId;

    // Admin: Authorize Calimero context
    public shared(msg) func authorizeContext(contextId: Text) : async Result.Result<Text, Text> {
        // Add proper admin check here
        authorizedContexts.put(contextId, true);
        #ok("Context authorized")
    };

    // Execute trade from Calimero context decision
    public shared(msg) func executeTrade(
        contextId: Text,
        pair: Text,
        action: {#Buy; #Sell},
        amount: Float,
        price: Float,
        stopLoss: Float
    ) : async Result.Result<Text, Text> {
        // Verify request comes from authorized Calimero context
        switch(authorizedContexts.get(contextId)) {
            case null { return #err("Unauthorized context") };
            case (?authorized) {
                if (not authorized) {
                    return #err("Context not authorized");
                };
            };
        };

        let tradeId = "trade" # Int.toText(tradeCount);
        tradeCount += 1;

        let trade: Trade = {
            id = tradeId;
            pair = pair;
            action = action;
            amount = amount;
            price = price;
            stopLoss = stopLoss;
            timestamp = Time.now();
            status = #Pending;
            calimeroContextId = contextId;
            executionData = null;
        };

        // Execute trade through exchange API
        let result = await executeOnExchange(trade);
        switch(result) {
            case (#err(e)) {
                let failedTrade: Trade = {
                    id = trade.id;
                    pair = trade.pair;
                    action = trade.action;
                    amount = trade.amount;
                    price = trade.price;
                    stopLoss = trade.stopLoss;
                    timestamp = trade.timestamp;
                    status = #Failed;
                    calimeroContextId = trade.calimeroContextId;
                    executionData = null;
                };
                trades.put(tradeId, failedTrade);
                #err(e)
            };
            case (#ok(executionData)) {
                let executedTrade: Trade = {
                    id = trade.id;
                    pair = trade.pair;
                    action = trade.action;
                    amount = trade.amount;
                    price = trade.price;
                    stopLoss = trade.stopLoss;
                    timestamp = trade.timestamp;
                    status = #Executed;
                    calimeroContextId = trade.calimeroContextId;
                    executionData = ?executionData;
                };
                trades.put(tradeId, executedTrade);
                #ok(tradeId)
            };
        }
    };

    // Private function to execute trade on exchange
    private func executeOnExchange(trade: Trade) : async Result.Result<ExecutionData, Text> {
        // Example using a DEX API
        let request: CanisterHttpRequestArgs = {
            url = "https://api.exchange.example/v1/trade";
            max_response_bytes = ?2048;
            headers = [
                { name = "Content-Type"; value = "application/json" },
                { name = "Authorization"; value = "Bearer YOUR-API-KEY" }
            ];
            body = ?Text.encodeUtf8(
                "{"
                # "\"pair\":\"" # trade.pair # "\","
                # "\"side\":\"" # (if (trade.action == #Buy) "buy" else "sell") # "\","
                # "\"amount\":" # Float.toText(trade.amount) # ","
                # "\"price\":" # Float.toText(trade.price)
                # "}"
            );
            method = #post;
            transform = ?{
                function = transform;
                context = Text.encodeUtf8("trade");
            };
        };

        try {
            Cycles.add(230_949_972_000);
            let ic : actor { 
                http_request : CanisterHttpRequestArgs -> async http_response;
            } = actor("aaaaa-aa");
            
            let response = await ic.http_request(request);
            if (response.status != 200) {
                return #err("Trade execution failed with status: " # debug_show(response.status));
            };

            // Parse response and create execution data
            // For demo, using mock data
            let executionData: ExecutionData = {
                executionPrice = trade.price;
                executionTimestamp = Time.now();
                txHash = "0x" # Int.toText(Time.now());
                fees = 0.001;
            };

            #ok(executionData)
        }
        catch(error) {
            #err("Failed to execute trade: " # Error.message(error))
        }
    };

    public shared query func transform(args: {context: Blob; response: http_request_result}) : async http_request_result {
        {
            status = args.response.status;
            headers = [
                { name = "Content-Type"; value = "application/json" },
                { name = "Content-Security-Policy"; value = "default-src 'self'" },
                { name = "Strict-Transport-Security"; value = "max-age=63072000" }
            ];
            body = args.response.body;
        }
    };

    // Query functions
    public query func getTrade(tradeId: Text) : async ?Trade {
        trades.get(tradeId)
    };

    public query func getContextTrades(contextId: Text) : async [Trade] {
        let buffer = Buffer.Buffer<Trade>(0);
        for ((_, trade) in trades.entries()) {
            if (trade.calimeroContextId == contextId) {
                buffer.add(trade);
            };
        };
        Buffer.toArray(buffer)
    };
} 