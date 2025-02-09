import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Array "mo:base/Array";
import Time "mo:base/Time";
import Buffer "mo:base/Buffer";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Int "mo:base/Int";
import Iter "mo:base/Iter";

actor class TaskRegistry() {
    type TradingTask = {
        id: Text;
        name: Text;
        description: Text;
        requirements: [Text];  // Required capabilities
        parameters: {
            pairs: [Text];     // Trading pairs to monitor
            timeframes: [Text]; // Timeframes to analyze
            riskLevel: {#Low; #Medium; #High};
            targetReturn: Float;
            maxDrawdown: Float;
        };
        status: {#Active; #Paused; #Completed};
        assignedAgents: [Principal];
        createdAt: Int;
    };

    type AgentType = {
        #TechnicalAnalyst;
        #RiskManager;
        #MarketSentiment;
    };

    // State
    private stable var taskCount: Nat = 0;
    private let tasks = HashMap.HashMap<Text, TradingTask>(10, Text.equal, Text.hash);
    private let agentTasks = HashMap.HashMap<Principal, [Text]>(10, Principal.equal, Principal.hash);
    private let taskAgents = HashMap.HashMap<Text, [Principal]>(10, Text.equal, Text.hash);

    // Helper functions
    private func generateTaskId() : Text {
        taskCount += 1;
        return "task" # Int.toText(taskCount);
    };

    private func contains<T>(array: [T], element: T, equal: (T, T) -> Bool) : Bool {
        for (item in array.vals()) {
            if (equal(item, element)) {
                return true;
            };
        };
        false
    };

    private func agentTypeToText(agentType: AgentType) : Text {
        switch(agentType) {
            case (#TechnicalAnalyst) { "TechnicalAnalyst" };
            case (#RiskManager) { "RiskManager" };
            case (#MarketSentiment) { "MarketSentiment" };
        }
    };

    private func textToAgentType(text: Text) : ?AgentType {
        switch(text) {
            case ("TechnicalAnalyst") { ?#TechnicalAnalyst };
            case ("RiskManager") { ?#RiskManager };
            case ("MarketSentiment") { ?#MarketSentiment };
            case (_) { null };
        }
    };

    // Task management
    public shared(msg) func createTradingTask(
        name: Text,
        description: Text,
        requirements: [Text],
        parameters: {
            pairs: [Text];
            timeframes: [Text];
            riskLevel: {#Low; #Medium; #High};
            targetReturn: Float;
            maxDrawdown: Float;
        }
    ) : async Result.Result<Text, Text> {
        let taskId = generateTaskId();
        let task: TradingTask = {
            id = taskId;
            name = name;
            description = description;
            requirements = requirements;
            parameters = parameters;
            status = #Active;
            assignedAgents = [];
            createdAt = Time.now();
        };

        tasks.put(taskId, task);
        #ok(taskId)
    };

    // Agent assignment
    public shared(msg) func assignAgentToTask(
        taskId: Text,
        agentId: Principal,
        agentType: AgentType
    ) : async Result.Result<Text, Text> {
        switch(tasks.get(taskId)) {
            case null { #err("Task not found") };
            case (?task) {
                let agentTypeText = agentTypeToText(agentType);
                
                // Verify agent has required capabilities
                let hasRequiredCapability = contains<Text>(task.requirements, agentTypeText, Text.equal);

                if (not hasRequiredCapability) {
                    return #err("Agent does not have required capabilities");
                };

                // Update task agents
                let updatedAgents = Array.append(task.assignedAgents, [agentId]);
                let updatedTask: TradingTask = {
                    id = task.id;
                    name = task.name;
                    description = task.description;
                    requirements = task.requirements;
                    parameters = task.parameters;
                    status = task.status;
                    assignedAgents = updatedAgents;
                    createdAt = task.createdAt;
                };
                tasks.put(taskId, updatedTask);

                // Update agent tasks
                switch(agentTasks.get(agentId)) {
                    case null {
                        agentTasks.put(agentId, [taskId]);
                    };
                    case (?existingTasks) {
                        let newTasks = Array.append(existingTasks, [taskId]);
                        agentTasks.put(agentId, newTasks);
                    };
                };

                #ok("Agent assigned to task")
            };
        }
    };

    // Query functions
    public query func getTask(taskId: Text) : async ?TradingTask {
        tasks.get(taskId)
    };

    public query func getAgentTasks(agentId: Principal) : async [Text] {
        switch(agentTasks.get(agentId)) {
            case null { [] };
            case (?taskIds) { taskIds };
        }
    };

    public query func getTaskAgents(taskId: Text) : async [Principal] {
        switch(tasks.get(taskId)) {
            case null { [] };
            case (?task) { task.assignedAgents };
        }
    };

    public query func getActiveTasks() : async [TradingTask] {
        let buffer = Buffer.Buffer<TradingTask>(0);
        for ((_, task) in tasks.entries()) {
            if (task.status == #Active) {
                buffer.add(task);
            };
        };
        Buffer.toArray(buffer)
    };
} 