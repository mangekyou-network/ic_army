import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Array "mo:base/Array";
import Time "mo:base/Time";
import Buffer "mo:base/Buffer";
import Result "mo:base/Result";
import Float "mo:base/Float";
import Int "mo:base/Int";
import Text "mo:base/Text";
import Random "mo:base/Random";

actor class AIAgent(
    agentType: {#TechnicalAnalyst; #RiskManager; #MarketSentiment},
    agentName: Text
) {
    // Agent state
    private var lastAnalysis = "";
    private var confidence: Float = 0.0;
    private var riskScore: Float = 0.0;

    // Mock analysis templates
    private let technicalPatterns = [
        "Bullish engulfing pattern detected on the 4h timeframe",
        "RSI indicates oversold conditions at 30",
        "MACD showing bullish crossover",
        "Double bottom formation complete",
        "200 EMA acting as strong support"
    ];

    private let riskAssessments = [
        "Current market volatility within acceptable range",
        "Position size should be limited to 2% of portfolio",
        "Stop loss recommended at 2% below entry",
        "Market liquidity is sufficient for planned position",
        "Current exposure allows for additional positions"
    ];

    private let sentimentIndicators = [
        "Social media mentions trending positive",
        "Institutional buying pressure increasing",
        "News sentiment analysis shows bullish bias",
        "Funding rates indicate long bias",
        "Retail sentiment metrics showing fear"
    ];

    // Generate mock analysis based on agent type
    public func analyzeMarket(pair: Text, price: Float) : async Text {
        let timestamp = Time.now();
        let index = Int.abs(timestamp) % 5;
        
        switch(agentType) {
            case (#TechnicalAnalyst) {
                lastAnalysis := technicalPatterns[Int.abs(index)];
                confidence := 0.7 + Float.fromInt(Int.abs(timestamp % 2)) / 10.0;
            };
            case (#RiskManager) {
                lastAnalysis := riskAssessments[Int.abs(index)];
                riskScore := 0.3 + Float.fromInt(Int.abs(timestamp % 3)) / 10.0;
            };
            case (#MarketSentiment) {
                lastAnalysis := sentimentIndicators[Int.abs(index)];
                confidence := 0.6 + Float.fromInt(Int.abs(timestamp % 3)) / 10.0;
            };
        };
        lastAnalysis
    };

    // Vote on trading decision
    public func voteOnStrategy(
        pair: Text,
        proposedAction: {#Buy; #Sell; #Hold},
        targetPrice: Float,
        stopLoss: Float
    ) : async (Bool, Float) {
        let timestamp = Time.now();
        
        // Mock decision making logic
        switch(agentType) {
            case (#TechnicalAnalyst) {
                // Technical analysts focus on price patterns
                let vote = timestamp % 2 == 0;
                let conf = 0.7 + Float.fromInt(timestamp % 3) / 10.0;
                (vote, conf)
            };
            case (#RiskManager) {
                // Risk managers focus on position sizing and risk metrics
                let riskAcceptable = stopLoss > 0 and (targetPrice - stopLoss) / stopLoss < 0.05;
                (riskAcceptable, riskScore)
            };
            case (#MarketSentiment) {
                // Sentiment analysts focus on market mood
                let vote = timestamp % 3 != 0;
                (vote, confidence)
            };
        }
    };

    // Suggest modifications to strategy
    public func suggestModification(
        pair: Text,
        currentPrice: Float,
        targetPrice: Float,
        stopLoss: Float
    ) : async ?{
        newTargetPrice: Float;
        newStopLoss: Float;
        reason: Text;
    } {
        switch(agentType) {
            case (#TechnicalAnalyst) {
                // Suggest based on technical levels
                ?{
                    newTargetPrice = targetPrice * 1.02;
                    newStopLoss = stopLoss * 1.01;
                    reason = "Key resistance level identified at " # Float.toText(targetPrice * 1.02);
                }
            };
            case (#RiskManager) {
                // Suggest tighter stops if risk too high
                if ((targetPrice - stopLoss) / stopLoss > 0.03) {
                    ?{
                        newTargetPrice = targetPrice;
                        newStopLoss = currentPrice * 0.98;
                        reason = "Reducing risk exposure with tighter stop loss";
                    }
                } else { null }
            };
            case (#MarketSentiment) {
                // Adjust based on sentiment
                if (confidence > 0.8) {
                    ?{
                        newTargetPrice = targetPrice * 1.05;
                        newStopLoss = stopLoss;
                        reason = "Strong positive sentiment suggests higher target";
                    }
                } else { null }
            };
        }
    };

    // Get agent info
    public query func getAgentInfo() : async {
        agentType: {#TechnicalAnalyst; #RiskManager; #MarketSentiment};
        name: Text;
        lastAnalysis: Text;
        confidence: Float;
    } {
        {
            agentType = agentType;
            name = agentName;
            lastAnalysis = lastAnalysis;
            confidence = confidence;
        }
    };
} 