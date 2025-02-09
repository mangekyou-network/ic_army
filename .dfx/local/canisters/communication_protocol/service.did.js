export const idlFactory = ({ IDL }) => {
  const EncryptionMetadata = IDL.Record({
    'publicKeyHash' : IDL.Text,
    'nonce' : IDL.Opt(IDL.Text),
    'encryptionMethod' : IDL.Text,
  });
  const MessageType = IDL.Variant({
    'DataRequest' : IDL.Null,
    'StatusUpdate' : IDL.Null,
    'DataResponse' : IDL.Null,
    'TaskAssignment' : IDL.Null,
  });
  const Message = IDL.Record({
    'id' : IDL.Text,
    'to' : IDL.Principal,
    'content' : IDL.Text,
    'encryptionMetadata' : IDL.Opt(EncryptionMetadata),
    'from' : IDL.Principal,
    'messageType' : MessageType,
    'timestamp' : IDL.Int,
  });
  const Result = IDL.Variant({ 'ok' : IDL.Text, 'err' : IDL.Text });
  const CommunicationProtocol = IDL.Service({
    'getContextMembers' : IDL.Func([], [IDL.Vec(IDL.Principal)], []),
    'getMessages' : IDL.Func([IDL.Principal], [IDL.Vec(Message)], ['query']),
    'getPublicKey' : IDL.Func([IDL.Principal], [IDL.Opt(IDL.Text)], ['query']),
    'registerPublicKey' : IDL.Func([IDL.Text], [Result], []),
    'sendMessage' : IDL.Func(
        [IDL.Principal, IDL.Text, MessageType, IDL.Opt(EncryptionMetadata)],
        [Result],
        [],
      ),
  });
  return CommunicationProtocol;
};
export const init = ({ IDL }) => { return [IDL.Text]; };
