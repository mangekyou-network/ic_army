export const idlFactory = ({ IDL }) => {
  const Capability = IDL.Variant({
    'DataAnalysis' : IDL.Null,
    'Trading' : IDL.Null,
    'TaskExecution' : IDL.Null,
    'EventMonitoring' : IDL.Null,
  });
  const Agent = IDL.Record({
    'id' : IDL.Principal,
    'capabilities' : IDL.Vec(Capability),
    'name' : IDL.Text,
    'reputation' : IDL.Nat,
    'isActive' : IDL.Bool,
    'registrationTime' : IDL.Int,
    'lastActive' : IDL.Int,
  });
  const Result = IDL.Variant({ 'ok' : IDL.Text, 'err' : IDL.Text });
  return IDL.Service({
    'getAgent' : IDL.Func([IDL.Principal], [IDL.Opt(Agent)], ['query']),
    'isVerified' : IDL.Func([IDL.Principal], [IDL.Bool], ['query']),
    'registerAgent' : IDL.Func([IDL.Text, IDL.Vec(Capability)], [Result], []),
    'updateAgentStatus' : IDL.Func([IDL.Bool], [Result], []),
    'updateReputation' : IDL.Func([IDL.Principal, IDL.Int], [Result], []),
    'verifyAgent' : IDL.Func([IDL.Principal], [Result], []),
  });
};
export const init = ({ IDL }) => { return []; };
