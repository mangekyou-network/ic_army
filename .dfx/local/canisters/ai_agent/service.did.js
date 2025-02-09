export const idlFactory = ({ IDL }) => {
  const AIAgent = IDL.Service({
    'analyzeMarket' : IDL.Func([IDL.Text, IDL.Float64], [IDL.Text], []),
    'getAgentInfo' : IDL.Func(
        [],
        [
          IDL.Record({
            'lastAnalysis' : IDL.Text,
            'name' : IDL.Text,
            'agentType' : IDL.Variant({
              'MarketSentiment' : IDL.Null,
              'RiskManager' : IDL.Null,
              'TechnicalAnalyst' : IDL.Null,
            }),
            'confidence' : IDL.Float64,
          }),
        ],
        ['query'],
      ),
    'suggestModification' : IDL.Func(
        [IDL.Text, IDL.Float64, IDL.Float64, IDL.Float64],
        [
          IDL.Opt(
            IDL.Record({
              'newStopLoss' : IDL.Float64,
              'newTargetPrice' : IDL.Float64,
              'reason' : IDL.Text,
            })
          ),
        ],
        [],
      ),
    'voteOnStrategy' : IDL.Func(
        [
          IDL.Text,
          IDL.Variant({
            'Buy' : IDL.Null,
            'Hold' : IDL.Null,
            'Sell' : IDL.Null,
          }),
          IDL.Float64,
          IDL.Float64,
        ],
        [IDL.Bool, IDL.Float64],
        [],
      ),
  });
  return AIAgent;
};
export const init = ({ IDL }) => {
  return [
    IDL.Variant({
      'MarketSentiment' : IDL.Null,
      'RiskManager' : IDL.Null,
      'TechnicalAnalyst' : IDL.Null,
    }),
    IDL.Text,
  ];
};
