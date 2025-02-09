import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';
import type { IDL } from '@dfinity/candid';

export interface Agent {
  'id' : Principal,
  'capabilities' : Array<Capability>,
  'name' : string,
  'reputation' : bigint,
  'isActive' : boolean,
  'registrationTime' : bigint,
  'lastActive' : bigint,
}
export type Capability = { 'DataAnalysis' : null } |
  { 'Trading' : null } |
  { 'TaskExecution' : null } |
  { 'EventMonitoring' : null };
export type Result = { 'ok' : string } |
  { 'err' : string };
export interface _SERVICE {
  'getAgent' : ActorMethod<[Principal], [] | [Agent]>,
  'isVerified' : ActorMethod<[Principal], boolean>,
  'registerAgent' : ActorMethod<[string, Array<Capability>], Result>,
  'updateAgentStatus' : ActorMethod<[boolean], Result>,
  'updateReputation' : ActorMethod<[Principal, bigint], Result>,
  'verifyAgent' : ActorMethod<[Principal], Result>,
}
export declare const idlFactory: IDL.InterfaceFactory;
export declare const init: (args: { IDL: typeof IDL }) => IDL.Type[];
