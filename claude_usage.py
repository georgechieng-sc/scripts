# /// script
# requires-python = ">=3.11"
# dependencies = ["mcp[cli]", "curl_cffi"]
# ///

import os
from mcp.server.fastmcp import FastMCP
from curl_cffi import requests

ORG_ID = "5e5bfa51-7f7d-4ad2-8861-1f62493fa873"
ACCOUNT_UUID = "406af22e-5a75-4cd9-a098-3f39e5679950"

mcp = FastMCP("claude-usage")


@mcp.tool()
def get_usage() -> dict:
    """Get Claude.ai organisation overage spend limit and usage data."""
    session_key = os.environ.get("CLAUDE_SESSION_KEY")
    if not session_key:
        return {"error": "CLAUDE_SESSION_KEY environment variable not set"}

    url = f"https://claude.ai/api/organizations/{ORG_ID}/overage_spend_limit?account_uuid={ACCOUNT_UUID}"
    response = requests.get(
        url,
        impersonate="chrome124",
        cookies={"sessionKey": session_key},
        headers={
            "accept": "*/*",
            "content-type": "application/json",
            "anthropic-client-platform": "web_claude_ai",
        },
    )
    return response.json()


if __name__ == "__main__":
    mcp.run()
