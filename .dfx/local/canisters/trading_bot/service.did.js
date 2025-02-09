export const idlFactory = ({ IDL }) => {
  const Result = IDL.Variant({ 'ok' : IDL.Text, 'err' : IDL.Text });
  const ProposalType = IDL.Variant({
    'ExternalCall' : IDL.Record({
      'method' : IDL.Text,
      'args' : IDL.Vec(IDL.Nat8),
      'canister' : IDL.Principal,
    }),
  });
  const Proposal = IDL.Record({
    'id' : IDL.Text,
    'status' : IDL.Variant({
      'Approved' : IDL.Null,
      'Rejected' : IDL.Null,
      'Executed' : IDL.Null,
      'Pending' : IDL.Null,
    }),
    'proposalType' : ProposalType,
    'timestamp' : IDL.Int,
    'proposer' : IDL.Principal,
    'approvals' : IDL.Vec(IDL.Principal),
  });
  const MarketSnapshot = IDL.Record({
    'rsi' : IDL.Float64,
    'macd' : IDL.Tuple(IDL.Float64, IDL.Float64),
    'pair' : IDL.Text,
    'timestamp' : IDL.Int,
    'price' : IDL.Float64,
  });
  const Message = IDL.Record({
    'content' : IDL.Text,
    'kind' : IDL.Variant({
      'Question' : IDL.Null,
      'Suggestion' : IDL.Null,
      'Analysis' : IDL.Null,
      'Concern' : IDL.Null,
    }),
    'author' : IDL.Principal,
    'timestamp' : IDL.Int,
  });
  const Decision = IDL.Record({
    'action' : IDL.Variant({
      'Buy' : IDL.Null,
      'Hold' : IDL.Null,
      'Sell' : IDL.Null,
    }),
    'pair' : IDL.Text,
    'targetPrice' : IDL.Float64,
    'stopLoss' : IDL.Float64,
    'confidence' : IDL.Float64,
  });
  const Discussion = IDL.Record({
    'id' : IDL.Text,
    'marketData' : IDL.Opt(MarketSnapshot),
    'status' : IDL.Variant({ 'Active' : IDL.Null, 'Concluded' : IDL.Null }),
    'messages' : IDL.Vec(Message),
    'votes' : IDL.Vec(IDL.Tuple(IDL.Principal, IDL.Bool)),
    'taskId' : IDL.Text,
    'finalDecision' : IDL.Opt(Decision),
  });
  const TradingBot = IDL.Service({
    'addMessage' : IDL.Func(
        [
          IDL.Text,
          IDL.Text,
          IDL.Variant({
            'Question' : IDL.Null,
            'Suggestion' : IDL.Null,
            'Analysis' : IDL.Null,
            'Concern' : IDL.Null,
          }),
        ],
        [Result],
        [],
      ),
    'approveTradeProposal' : IDL.Func([IDL.Text, IDL.Text], [Result], []),
    'checkProposalStatus' : IDL.Func([IDL.Text], [IDL.Opt(Proposal)], []),
    'executeDecision' : IDL.Func([IDL.Text], [Result], []),
    'getActiveDiscussions' : IDL.Func([], [IDL.Vec(Discussion)], ['query']),
    'getDiscussion' : IDL.Func([IDL.Text], [IDL.Opt(Discussion)], ['query']),
    'startDiscussion' : IDL.Func([IDL.Text], [Result], []),
    'updateMarketData' : IDL.Func([IDL.Text, IDL.Text], [Result], []),
    'vote' : IDL.Func(
        [
          IDL.Text,
          IDL.Bool,
          IDL.Opt(
            IDL.Record({
              'action' : IDL.Variant({
                'Buy' : IDL.Null,
                'Hold' : IDL.Null,
                'Sell' : IDL.Null,
              }),
              'pair' : IDL.Text,
              'targetPrice' : IDL.Float64,
              'stopLoss' : IDL.Float64,
              'confidence' : IDL.Float64,
            })
          ),
        ],
        [Result],
        [],
      ),
  });
  return TradingBot;
};
export const init = ({ IDL }) => {
  return [IDL.Text, IDL.Text, IDL.Text, IDL.Text, IDL.Text, IDL.Text];
};
