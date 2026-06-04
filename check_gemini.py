import os
import requests
import json
import sys

def check_gemini_key(api_key):
    url = f"https://generativelanguage.googleapis.com/v1beta/models?key={api_key}"
    try:
        response = requests.get(url)
        if response.status_code == 200:
            print("Success! Your API key is valid.")
            models = response.json().get('models', [])
            print(f"Found {len(models)} models available.")
            for m in models:
                if 'flash' in m.get('name', '').lower():
                    print(f" - {m.get('name')}")
        else:
            print(f"Failed! Status Code: {response.status_code}")
            print("Response:", response.text)
    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == "__main__":
    key = input("Enter your Gemini API Key to test: ").strip()
    if key:
        check_gemini_key(key)
    else:
        print("No API key provided.")
