export const idlFactory = ({ IDL }) => {
  const Result = IDL.Variant({ 'ok' : IDL.Text, 'err' : IDL.Text });
  const ExecutionData = IDL.Record({
    'executionTimestamp' : IDL.Int,
    'fees' : IDL.Float64,
    'executionPrice' : IDL.Float64,
    'txHash' : IDL.Text,
  });
  const Trade = IDL.Record({
    'id' : IDL.Text,
    'status' : IDL.Variant({
      'Failed' : IDL.Null,
      'Executed' : IDL.Null,
      'Pending' : IDL.Null,
    }),
    'action' : IDL.Variant({ 'Buy' : IDL.Null, 'Sell' : IDL.Null }),
    'pair' : IDL.Text,
    'stopLoss' : IDL.Float64,
    'timestamp' : IDL.Int,
    'price' : IDL.Float64,
    'executionData' : IDL.Opt(ExecutionData),
    'amount' : IDL.Float64,
    'calimeroContextId' : IDL.Text,
  });
  const http_header = IDL.Record({ 'value' : IDL.Text, 'name' : IDL.Text });
  const http_request_result = IDL.Record({
    'status' : IDL.Nat,
    'body' : IDL.Vec(IDL.Nat8),
    'headers' : IDL.Vec(http_header),
  });
  const TradeExecutor = IDL.Service({
    'authorizeContext' : IDL.Func([IDL.Text], [Result], []),
    'executeTrade' : IDL.Func(
        [
          IDL.Text,
          IDL.Text,
          IDL.Variant({ 'Buy' : IDL.Null, 'Sell' : IDL.Null }),
          IDL.Float64,
          IDL.Float64,
          IDL.Float64,
        ],
        [Result],
        [],
      ),
    'getContextTrades' : IDL.Func([IDL.Text], [IDL.Vec(Trade)], ['query']),
    'getTrade' : IDL.Func([IDL.Text], [IDL.Opt(Trade)], ['query']),
    'transform' : IDL.Func(
        [
          IDL.Record({
            'context' : IDL.Vec(IDL.Nat8),
            'response' : http_request_result,
          }),
        ],
        [http_request_result],
        ['query'],
      ),
  });
  return TradeExecutor;
};
export const init = ({ IDL }) => { return [IDL.Text]; };
