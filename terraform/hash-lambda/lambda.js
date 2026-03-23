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
    const params = {
        TableName: TABLE_NAME,
        Key: { hash }
    };

    const result = await dynamodb.send(new GetCommand(params));
    return !!result.Item;
}

async function saveUrlMapping(hash, originalUrl) {
    const params = {
        TableName: TABLE_NAME,
        Item: {
            hash,
            originalUrl
        }
    };

    await dynamodb.send(new PutCommand(params));
}

export const handler = async (event) => {
    try {
        if (!TABLE_NAME) {
            return createResponse(500, { error: "TABLE_NAME environment variable is not set" });
        }

        const body = parseRequestBody(event);

        if (!body) {
            return createResponse(400, { error: "Invalid JSON body" });
        }

        const url = body?.url;

        if (!url) {
            return createResponse(400, { error: "Missing 'url' in request body" });
        }

        if (!isValidUrl(url)) {
            return createResponse(400, { error: "Invalid URL format" });
        }

        let hash = generateHash(url);
        let attempts = 0;

        while (await hashExists(hash)) {
            attempts++;

            if (attempts >= MAX_HASH_ATTEMPTS) {
                return createResponse(500, { error: "Unable to generate unique hash" });
            }

            const randomNumber = Math.floor(Math.random() * 1000000);
            hash = generateHash(url + randomNumber);
        }

        await saveUrlMapping(hash, url);

        return createResponse(201, { hash });
    } catch (error) {
        console.error("Error generating hash:", error);
        return createResponse(500, { error: "Internal server error" });
    }
};