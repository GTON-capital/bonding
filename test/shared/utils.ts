import { BigNumber } from "ethers"

import { TestAggregator } from "../../typechain/TestAggregator"
import { TestCan } from "../../typechain/TestCan"


export function expandTo18Decimals(n: number): BigNumber {
    return BigNumber.from(n).mul(BigNumber.from(10).pow(18))
}

export interface TokenData {
    can: TestCan,
    price: TestAggregator,
    minimalAmount: BigNumber
}
export async function mineBlocks(provider: any, blocks: number): Promise<void> {
    while(blocks > 0) {
        await provider.send("evm_mine")
        blocks -= 1
    }
}