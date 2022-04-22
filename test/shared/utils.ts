import { BigNumber, BigNumberish } from "ethers"
import { ContractReceipt } from "ethers"
export const timestampSetter: (provider: any) => (timestamp: number) => Promise<void> =
  (provider) => async (timestamp: number) => await provider.send("evm_mine", [timestamp])

export const blockGetter: (provider: any, type: string) => () => Promise<number> =
  (provider, type) => async () => (await provider.getBlock("latest"))[type]

export function expandTo18Decimals(n: BigNumberish): BigNumber {
  const decimals = BigNumber.from(10).pow(18)
  return BigNumber.from(n).mul(decimals)
}
export function expandToDecimals(n: BigNumberish, _decimals: number): BigNumber {
  const decimals = BigNumber.from(10).pow(_decimals)
  return BigNumber.from(n).mul(decimals)
}

export function extractTokenId(receipt: ContractReceipt): BigNumber {
  const event = receipt.events?.find(event => event.event === 'Mint');
  if (event == undefined || event?.args == undefined) {
    throw new Error("Missing receipt events")
  }
  const [id] = event.args;
  return id;
}
