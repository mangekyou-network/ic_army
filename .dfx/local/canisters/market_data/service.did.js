export const idlFactory = ({ IDL }) => {
  const Result_1 = IDL.Variant({
    'ok' : IDL.Tuple(IDL.Float64, IDL.Float64),
    'err' : IDL.Text,
  });
  const Result = IDL.Variant({ 'ok' : IDL.Float64, 'err' : IDL.Text });
  const http_header = IDL.Record({ 'value' : IDL.Text, 'name' : IDL.Text });
  const http_request_result = IDL.Record({
    'status' : IDL.Nat,
    'body' : IDL.Vec(IDL.Nat8),
    'headers' : IDL.Vec(http_header),
  });
  return IDL.Service({
    'getMACD' : IDL.Func([IDL.Text], [Result_1], []),
    'getPrice' : IDL.Func([IDL.Text], [Result], []),
    'getRSI' : IDL.Func([IDL.Text, IDL.Nat], [Result], []),
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
};
export const init = ({ IDL }) => { return []; };
