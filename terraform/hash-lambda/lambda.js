import crypto from "crypto";
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, GetCommand, PutCommand } from "@aws-sdk/lib-dynamodb";

const client = new DynamoDBClient({});
const dynamodb = DynamoDBDocumentClient.from(client);

const TABLE_NAME = process.env.TABLE_NAME;
const HASH_LENGTH = Number(process.env.HASH_LENGTH || 6);
const MAX_HASH_ATTEMPTS = Number(process.env.MAX_HASH_ATTEMPTS || 10);

function createResponse(statusCode, payload) {
    return {
        statusCode,
        headers: {
            "Content-Type": "application/json"
        },
        body: JSON.stringify(payload)
    };
}

function parseRequestBody(event) {
    try {
        return typeof event.body === "string"
            ? JSON.parse(event.body)
            : event.body;
    } catch {
        return null;
    }
}

function generateHash(input, length = HASH_LENGTH) {
    return crypto
        .createHash("sha256")
        .update(input)
        .digest("hex")
        .substring(0, length);
}

function isValidUrl(url) {
    try {
        new URL(url);
        return true;
    } catch {
        return false;
    }
}

async function hashExists(hash) {
    const result = await dynamodb.send(new GetCommand({
        TableName: TABLE_NAME,
        Key: { hash }
    }));
    return !!result.Item;
}

async function saveUrlMapping(hash, originalUrl) {
    await dynamodb.send(new PutCommand({
        TableName: TABLE_NAME,
        Item: { hash, originalUrl },
    ConditionExpression: "attribute_not_exists(hash)"
}));
}

export const handler = async (event) => {
    try {
        if (!TABLE_NAME) {
            return createResponse(500, { error: "TABLE_NAME not set" });
        }

        const body = parseRequestBody(event);
        if (!body) {
            return createResponse(400, { error: "Invalid JSON body" });
        }

        const url = body?.url;
        if (!url) {
            return createResponse(400, { error: "Missing url" });
        }

        if (!isValidUrl(url)) {
            return createResponse(400, { error: "Invalid URL" });
        }

        let hash = generateHash(url);
        let attempts = 0;

        while (await hashExists(hash)) {
            if (++attempts >= MAX_HASH_ATTEMPTS) {
                return createResponse(500, { error: "Hash collision limit reached" });
            }

            hash = generateHash(url + Math.random());
        }

        await saveUrlMapping(hash, url);

        return createResponse(201, { hash });

    } catch (err) {
        console.error(err);
        return createResponse(500, { error: "Internal error" });
    }
};