import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';
import type { IDL } from '@dfinity/candid';

export interface CommunicationProtocol {
  'getContextMembers' : ActorMethod<[], Array<Principal>>,
  'getMessages' : ActorMethod<[Principal], Array<Message>>,
  'getPublicKey' : ActorMethod<[Principal], [] | [string]>,
  'registerPublicKey' : ActorMethod<[string], Result>,
  'sendMessage' : ActorMethod<
    [Principal, string, MessageType, [] | [EncryptionMetadata]],
    Result
  >,
}
export interface EncryptionMetadata {
  'publicKeyHash' : string,
  'nonce' : [] | [string],
  'encryptionMethod' : string,
}
export interface Message {
  'id' : string,
  'to' : Principal,
  'content' : string,
  'encryptionMetadata' : [] | [EncryptionMetadata],
  'from' : Principal,
  'messageType' : MessageType,
  'timestamp' : bigint,
}
export type MessageType = { 'DataRequest' : null } |
  { 'StatusUpdate' : null } |
  { 'DataResponse' : null } |
  { 'TaskAssignment' : null };
export type Result = { 'ok' : string } |
  { 'err' : string };
export interface _SERVICE extends CommunicationProtocol {}
export declare const idlFactory: IDL.InterfaceFactory;
export declare const init: (args: { IDL: typeof IDL }) => IDL.Type[];
