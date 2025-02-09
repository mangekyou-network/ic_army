export const idlFactory = ({ IDL }) => {
  const AgentType = IDL.Variant({
    'MarketSentiment' : IDL.Null,
    'RiskManager' : IDL.Null,
    'TechnicalAnalyst' : IDL.Null,
  });
  const Result = IDL.Variant({ 'ok' : IDL.Text, 'err' : IDL.Text });
  const TradingTask = IDL.Record({
    'id' : IDL.Text,
    'status' : IDL.Variant({
      'Paused' : IDL.Null,
      'Active' : IDL.Null,
      'Completed' : IDL.Null,
    }),
    'name' : IDL.Text,
    'createdAt' : IDL.Int,
    'parameters' : IDL.Record({
      'timeframes' : IDL.Vec(IDL.Text),
      'pairs' : IDL.Vec(IDL.Text),
      'targetReturn' : IDL.Float64,
      'riskLevel' : IDL.Variant({
        'Low' : IDL.Null,
        'High' : IDL.Null,
        'Medium' : IDL.Null,
      }),
      'maxDrawdown' : IDL.Float64,
    }),
    'description' : IDL.Text,
    'requirements' : IDL.Vec(IDL.Text),
    'assignedAgents' : IDL.Vec(IDL.Principal),
  });
  const TaskRegistry = IDL.Service({
    'assignAgentToTask' : IDL.Func(
        [IDL.Text, IDL.Principal, AgentType],
        [Result],
        [],
      ),
    'createTradingTask' : IDL.Func(
        [
          IDL.Text,
          IDL.Text,
          IDL.Vec(IDL.Text),
          IDL.Record({
            'timeframes' : IDL.Vec(IDL.Text),
            'pairs' : IDL.Vec(IDL.Text),
            'targetReturn' : IDL.Float64,
            'riskLevel' : IDL.Variant({
              'Low' : IDL.Null,
              'High' : IDL.Null,
              'Medium' : IDL.Null,
            }),
            'maxDrawdown' : IDL.Float64,
          }),
        ],
        [Result],
        [],
      ),
    'getActiveTasks' : IDL.Func([], [IDL.Vec(TradingTask)], ['query']),
    'getAgentTasks' : IDL.Func([IDL.Principal], [IDL.Vec(IDL.Text)], ['query']),
    'getTask' : IDL.Func([IDL.Text], [IDL.Opt(TradingTask)], ['query']),
    'getTaskAgents' : IDL.Func([IDL.Text], [IDL.Vec(IDL.Principal)], ['query']),
  });
  return TaskRegistry;
};
export const init = ({ IDL }) => { return []; };
