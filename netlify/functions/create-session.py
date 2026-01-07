import json
import os
import requests

def handler(event, context):
    return {
        "statusCode": 500,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps({
            "error": "create-session function exists but is not wired yet"
        }),
    }