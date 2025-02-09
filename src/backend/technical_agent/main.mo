import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Float "mo:base/Float";
import Buffer "mo:base/Buffer";
import HashMap "mo:base/HashMap";
import Error "mo:base/Error";
import Debug "mo:base/Debug";

actor class TechnicalAgent(role: { #TechnicalAnalyst }, name: Text) {
    type MarketData = actor {
        getPrice: (Text) -> async Result.Result<Float, Text>;
        getRSI: (Text, Nat) -> async Result.Result<Float, Text>;
        getMACD: (Text) -> async Result.Result<(Float, Float), Text>;
    };

    type AgentRegistry = actor {
        registerAgent: (Text, [Capability]) -> async Result.Result<Text, Text>;
        updateAgentStatus: (Bool) -> async Result.Result<Text, Text>;
    };

    type Capability = {
        #DataAnalysis;
        #Trading;
        #EventMonitoring;
        #TaskExecution;
    };

    type TechnicalAnalysis = {
        symbol: Text;
        timestamp: Int;
        rsi: Float;
        macdLine: Float;
        signalLine: Float;
        trend: {#Bullish; #Bearish; #Neutral};
        confidence: Float;
    };

    // State
    private let analyses = HashMap.HashMap<Text, TechnicalAnalysis>(10, Text.equal, Text.hash);
    private var isRegistered = false;
    private let agentName = name;
    private let agentRole = role;

    // Initialize connections to other canisters
    private let marketData : MarketData = actor("b77ix-eeaaa-aaaaa-qaada-cai");
    private let agentRegistry : AgentRegistry = actor("avqkn-guaaa-aaaaa-qaaea-cai");

    // Register agent with registry
    public shared(msg) func initialize() : async Result.Result<Text, Text> {
        if (isRegistered) {
            return #err("Agent already registered");
        };

        let capabilities : [Capability] = [#DataAnalysis, #Trading];
        let result = await agentRegistry.registerAgent(agentName, capabilities);
        
        switch(result) {
            case (#ok(_)) { 
                isRegistered := true;
                #ok("Technical agent initialized and registered")
            };
            case (#err(e)) { #err(e) };
        }
    };

    // Analyze market data
    public shared(msg) func analyzeTechnicals(symbol: Text) : async Result.Result<TechnicalAnalysis, Text> {
        if (not isRegistered) {
            return #err("Agent not registered");
        };

        try {
            let rsiResult = await marketData.getRSI(symbol, 14);
            let macdResult = await marketData.getMACD(symbol);

            switch (rsiResult, macdResult) {
                case (#ok(rsi), #ok((macdLine, signalLine))) {
                    let trend = if (macdLine > signalLine and rsi < 70) {
                        #Bullish
                    } else if (macdLine < signalLine and rsi > 30) {
                        #Bearish
                    } else {
                        #Neutral
                    };

                    let confidence = calculateConfidence(rsi, macdLine, signalLine);
                    
                    let analysis: TechnicalAnalysis = {
                        symbol = symbol;
                        timestamp = Time.now();
                        rsi = rsi;
                        macdLine = macdLine;
                        signalLine = signalLine;
                        trend = trend;
                        confidence = confidence;
                    };

                    analyses.put(symbol, analysis);
                    #ok(analysis)
                };
                case (_, _) {
                    #err("Failed to fetch technical indicators")
                };
            };
        }
        catch(e) {
            #err("Analysis failed: " # Error.message(e))
        }
    };

    // Helper function to calculate confidence score
    private func calculateConfidence(rsi: Float, macdLine: Float, signalLine: Float) : Float {
        let rsiStrength = if (rsi > 70 or rsi < 30) {
            0.8
        } else if (rsi > 60 or rsi < 40) {
            0.6
        } else {
            0.4
        };

        let macdStrength = Float.abs(macdLine - signalLine) / Float.max(Float.abs(macdLine), Float.abs(signalLine));
        
        (rsiStrength + macdStrength) / 2
    };

    // Query functions
    public query func getLatestAnalysis(symbol: Text) : async ?TechnicalAnalysis {
        analyses.get(symbol)
    };

    public query func getAgentInfo() : async (Text, { #TechnicalAnalyst }) {
        (agentName, agentRole)
    };
} 