import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';
import type { IDL } from '@dfinity/candid';

export interface ExecutionData {
  'executionTimestamp' : bigint,
  'fees' : number,
  'executionPrice' : number,
  'txHash' : string,
}
export type Result = { 'ok' : string } |
  { 'err' : string };
export interface Trade {
  'id' : string,
  'status' : { 'Failed' : null } |
    { 'Executed' : null } |
    { 'Pending' : null },
  'action' : { 'Buy' : null } |
    { 'Sell' : null },
  'pair' : string,
  'stopLoss' : number,
  'timestamp' : bigint,
  'price' : number,
  'executionData' : [] | [ExecutionData],
  'amount' : number,
  'calimeroContextId' : string,
}
export interface TradeExecutor {
  'authorizeContext' : ActorMethod<[string], Result>,
  'executeTrade' : ActorMethod<
    [
      string,
      string,
      { 'Buy' : null } |
        { 'Sell' : null },
      number,
      number,
      number,
    ],
    Result
  >,
  'getContextTrades' : ActorMethod<[string], Array<Trade>>,
  'getTrade' : ActorMethod<[string], [] | [Trade]>,
  'transform' : ActorMethod<
    [{ 'context' : Uint8Array | number[], 'response' : http_request_result }],
    http_request_result
  >,
}
export interface http_header { 'value' : string, 'name' : string }
export interface http_request_result {
  'status' : bigint,
  'body' : Uint8Array | number[],
  'headers' : Array<http_header>,
}
export interface _SERVICE extends TradeExecutor {}
export declare const idlFactory: IDL.InterfaceFactory;
export declare const init: (args: { IDL: typeof IDL }) => IDL.Type[];
