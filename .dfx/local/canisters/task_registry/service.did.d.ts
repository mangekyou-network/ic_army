import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';
import type { IDL } from '@dfinity/candid';

export type AgentType = { 'MarketSentiment' : null } |
  { 'RiskManager' : null } |
  { 'TechnicalAnalyst' : null };
export type Result = { 'ok' : string } |
  { 'err' : string };
export interface TaskRegistry {
  'assignAgentToTask' : ActorMethod<[string, Principal, AgentType], Result>,
  'createTradingTask' : ActorMethod<
    [
      string,
      string,
      Array<string>,
      {
        'timeframes' : Array<string>,
        'pairs' : Array<string>,
        'targetReturn' : number,
        'riskLevel' : { 'Low' : null } |
          { 'High' : null } |
          { 'Medium' : null },
        'maxDrawdown' : number,
      },
    ],
    Result
  >,
  'getActiveTasks' : ActorMethod<[], Array<TradingTask>>,
  'getAgentTasks' : ActorMethod<[Principal], Array<string>>,
  'getTask' : ActorMethod<[string], [] | [TradingTask]>,
  'getTaskAgents' : ActorMethod<[string], Array<Principal>>,
}
export interface TradingTask {
  'id' : string,
  'status' : { 'Paused' : null } |
    { 'Active' : null } |
    { 'Completed' : null },
  'name' : string,
  'createdAt' : bigint,
  'parameters' : {
    'timeframes' : Array<string>,
    'pairs' : Array<string>,
    'targetReturn' : number,
    'riskLevel' : { 'Low' : null } |
      { 'High' : null } |
      { 'Medium' : null },
    'maxDrawdown' : number,
  },
  'description' : string,
  'requirements' : Array<string>,
  'assignedAgents' : Array<Principal>,
}
export interface _SERVICE extends TaskRegistry {}
export declare const idlFactory: IDL.InterfaceFactory;
export declare const init: (args: { IDL: typeof IDL }) => IDL.Type[];
