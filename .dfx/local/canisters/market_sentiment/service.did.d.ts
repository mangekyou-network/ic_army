import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';
import type { IDL } from '@dfinity/candid';

export interface AIAgent {
  'analyzeMarket' : ActorMethod<[string, number], string>,
  'getAgentInfo' : ActorMethod<
    [],
    {
      'lastAnalysis' : string,
      'name' : string,
      'agentType' : { 'MarketSentiment' : null } |
        { 'RiskManager' : null } |
        { 'TechnicalAnalyst' : null },
      'confidence' : number,
    }
  >,
  'suggestModification' : ActorMethod<
    [string, number, number, number],
    [] | [
      { 'newStopLoss' : number, 'newTargetPrice' : number, 'reason' : string }
    ]
  >,
  'voteOnStrategy' : ActorMethod<
    [
      string,
      { 'Buy' : null } |
        { 'Hold' : null } |
        { 'Sell' : null },
      number,
      number,
    ],
    [boolean, number]
  >,
}
export interface _SERVICE extends AIAgent {}
export declare const idlFactory: IDL.InterfaceFactory;
export declare const init: (args: { IDL: typeof IDL }) => IDL.Type[];
