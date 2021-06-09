#!/usr/bin/env python3

import argparse
import json
import sys
import urllib.request

parser = argparse.ArgumentParser(
    description='Get all the data from a pretalx endpoint.')
parser.add_argument('token', help='token for the API')
parser.add_argument('url', help='pretalx API URL')

args = parser.parse_args()

url = args.url
token = args.token

# `combined` is the final output, it's the combined result of all requests
combined = {
    'count': 0,
    'next': None,
    'previous': None,
    'results': []
}

# Keep going as long as there are more pages to fetch
while (url):
    # Print the current URL that will be requested to stderr to see the
    # progress. This way you can easily pipe the actual result which is
    # printed to the stdout into a file.
    print(f'{url}', file=sys.stderr)

    req = urllib.request.Request(url, headers={
        'Authorization': f'Token {token}'
    })

    with urllib.request.urlopen(req) as resp:
        # Parse the response so that we combine it easily
        data = json.load(resp)

        # Add the current result to the combined data
        combined['results'].extend(data['results'])

        # The `count` is always the total number of items, so we can safely
        # override it
        combined['count'] = data['count']

        # Prepare for the next loop iteration. If there is no more data `next`
        # will be `None` and the loop will abort
        url = data['next']

print(json.dumps(combined))
