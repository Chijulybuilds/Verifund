import axios from "axios";

import { ethers } from "ethers";

export async function run(
    ctx: any
) {

    try {

        /**
         * Extract event data
         */
        const evidenceHash =
            ctx.event.args.evidenceHash;

        /**
         * Fetch backend verification
         */
        const response =
            await axios.post(
                process.env.BACKEND_URL!,
                {
                    evidenceHash
                }
            );

        const approved =
            response.data.approved;

        /**
         * ABI encode payload
         */
        const encoded =
            ethers.AbiCoder.defaultAbiCoder()
                .encode(
                    ["bool", "bytes32"],
                    [
                        approved,
                        evidenceHash
                    ]
                );

        return {
            data: encoded
        };

    } catch (error) {

        console.error(error);

        throw error;
    }
}