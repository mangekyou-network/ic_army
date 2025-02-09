import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';
import type { IDL } from '@dfinity/candid';

export interface Decision {
  'action' : { 'Buy' : null } |
    { 'Hold' : null } |
    { 'Sell' : null },
  'pair' : string,
  'targetPrice' : number,
  'stopLoss' : number,
  'confidence' : number,
}
export interface Discussion {
  'id' : string,
  'marketData' : [] | [MarketSnapshot],
  'status' : { 'Active' : null } |
    { 'Concluded' : null },
  'messages' : Array<Message>,
  'votes' : Array<[Principal, boolean]>,
  'taskId' : string,
  'finalDecision' : [] | [Decision],
}
export interface MarketSnapshot {
  'rsi' : number,
  'macd' : [number, number],
  'pair' : string,
  'timestamp' : bigint,
  'price' : number,
}
export interface Message {
  'content' : string,
  'kind' : { 'Question' : null } |
    { 'Suggestion' : null } |
    { 'Analysis' : null } |
    { 'Concern' : null },
  'author' : Principal,
  'timestamp' : bigint,
}
export interface Proposal {
  'id' : string,
  'status' : { 'Approved' : null } |
    { 'Rejected' : null } |
    { 'Executed' : null } |
    { 'Pending' : null },
  'proposalType' : ProposalType,
  'timestamp' : bigint,
  'proposer' : Principal,
  'approvals' : Array<Principal>,
}
export type ProposalType = {
    'ExternalCall' : {
      'method' : string,
      'args' : Uint8Array | number[],
      'canister' : Principal,
    }
  };
export type Result = { 'ok' : string } |
  { 'err' : string };
export interface TradingBot {
  'addMessage' : ActorMethod<
    [
      string,
      string,
      { 'Question' : null } |
        { 'Suggestion' : null } |
        { 'Analysis' : null } |
        { 'Concern' : null },
    ],
    Result
  >,
  'approveTradeProposal' : ActorMethod<[string, string], Result>,
  'checkProposalStatus' : ActorMethod<[string], [] | [Proposal]>,
  'executeDecision' : ActorMethod<[string], Result>,
  'getActiveDiscussions' : ActorMethod<[], Array<Discussion>>,
  'getDiscussion' : ActorMethod<[string], [] | [Discussion]>,
  'startDiscussion' : ActorMethod<[string], Result>,
  'updateMarketData' : ActorMethod<[string, string], Result>,
  'vote' : ActorMethod<
    [
      string,
      boolean,
      [] | [
        {
          'action' : { 'Buy' : null } |
            { 'Hold' : null } |
            { 'Sell' : null },
          'pair' : string,
          'targetPrice' : number,
          'stopLoss' : number,
          'confidence' : number,
        }
      ],
    ],
    Result
  >,
}
export interface _SERVICE extends TradingBot {}
export declare const idlFactory: IDL.InterfaceFactory;
export declare const init: (args: { IDL: typeof IDL }) => IDL.Type[];
