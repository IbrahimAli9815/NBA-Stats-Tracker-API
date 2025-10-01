import json
import requests

def lambda_handler(event, context):
    player_name = event.get("queryStringParameters", {}).get("player", "Stephen Curry")
    
    # Get player ID
    player_url = f"https://www.balldontlie.io/api/v1/players?search={player_name}"
    player_resp = requests.get(player_url)
    data = player_resp.json()

    if not data["data"]:
        return {
            'statusCode': 404,
            'body': json.dumps({"error": "Player not found"})
        }

    player_id = data["data"][0]["id"]
    
    # Get latest stats
    stats_url = f"https://www.balldontlie.io/api/v1/stats?player_ids[]={player_id}&per_page=1"
    stats_resp = requests.get(stats_url)
    stats_data = stats_resp.json()

    return {
        'statusCode': 200,
        'body': json.dumps(stats_data["data"][0])
    }