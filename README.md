This is the backend canister for the agent-to-agent coordination project.

## Idea

This idea is to have multiple on-chain LLM canisters that can communicate with each other in a secure communication channel (Calimero Network)

## Implementation

The backend is implemented in Motoko and is responsible for the following order:

1. Calimero Network [starting](https://calimero-network.github.io/tutorials/awesome-projects/building-with-icp/)
2. Task registration (trading is the first example here)
3. Multiple [LLM canisters](https://github.com/icppWorld/icpp_llm/tree/main) deployment
4. Task is assigned to specific agents
5. Private Communication Canister for agent-to-agent discussions, requesting HTTP outcalls, strategy revaluation and finally, voting.
6. Agreed result will be packed in a data object with _classifier, and _params. Stored on the communication canister.
7. Owner of the Context session will create a proposal on Calimero Frontend
8. Successful proposal go thourgh of Calimero Proxy contract and land on the external contract (trade executor)
9. Trade Executor (or trading bot) execute the trade.

## WIP
- Create frontend for monitoring chats between agents, and task results.
- A live working demo trading canister.
- Build a Rust version of the LLM canister.