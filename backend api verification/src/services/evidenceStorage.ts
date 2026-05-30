// src/services/evidenceStorage.ts

import fs from "fs";

export async function storeEvidence(
    hash: string,
    payload: string
) {
    const path = `./uploads/${hash}.json`;
    fs.writeFileSync(path, payload);
    return path;
}