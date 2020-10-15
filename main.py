import requests
import random

# import json
import tronpy
from tronpy.keys import PrivateKey
from urllib.parse import urljoin
from pprint import pprint

EVENT_URL = "https://event.nileex.io"


# registered in Oracle
ADDR = "THbSb6bAYKjVzkVNWkyTgTHoNtmzwxQcaG"
PRIV_KEY = PrivateKey.fromhex("c0391dbbc8100288edc22dac08cf3e6566b97f504be200154dc2e4bb2b8ca955")
# works 😍

# not-registered in Oracle
# ADDR = "TXzTinuRvb87ZUtFVBbohfu1Hp3rU96uPm"
# PRIV_KEY = PrivateKey.fromhex("d832d4f22ae10fe5b4b749f843f3fd164d830d17066fdf17ee55a0f40bc73ccb")
# REVERT opcode executed: Not an authorized node to fulfill requests

# nile
# /event/contract/{}

# mainnet
# /v1/contracts/{}/events

"""
url = urljoin(EVENT_URL, "/event/contract/TYZxQSHAhxGgUWzxYEZAohvWc9cQWXtNBt")
resp = requests.get(url)

events = resp.json()
pprint(events)

raise SystemExit
"""

event = {
    'callbackAddr': '0x5a0d3ab8219a1bd91be27f8cbd8e12cf3fe1fcf6',
    'callbackFunctionId': '4357855e00000000000000000000000000000000000000000000000000000000',
    'cancelExpiration': '1602786717',
    'data': '',
    'dataVersion': '1',
    'payment': '1000000000000000',
    'requestId': 'c4b511027b1eb5d74bda40dda42e0a2a7734e37dcdd783e8b3ca689b2d961b30',
    'requester': '0x5a0d3ab8219a1bd91be27f8cbd8e12cf3fe1fcf6',
    'specId': '3239666139616131336266313436383738386237636334613530306134356238',
}

event = {
    'callbackAddr': '0x5a0d3ab8219a1bd91be27f8cbd8e12cf3fe1fcf6',
    'callbackFunctionId': '4357855e00000000000000000000000000000000000000000000000000000000',
    'cancelExpiration': '1602788640',
    'data': '',
    'dataVersion': '1',
    'payment': '1000000000000000',
    'requestId': '5030a698ec3d6e55fecc98b0bed592a578837bdc2fc964039712bec18ac9d04b',  # 返回给请求者
    'requester': '0x5a0d3ab8219a1bd91be27f8cbd8e12cf3fe1fcf6',
    'specId': '3239666139616131336266313436383738386237636334613530306134356238',
}

event = {
    'callbackAddr': '0x5a0d3ab8219a1bd91be27f8cbd8e12cf3fe1fcf6',
    'callbackFunctionId': '4357855e00000000000000000000000000000000000000000000000000000000',
    'cancelExpiration': '1602790200',
    'data': '',
    'dataVersion': '1',
    'payment': '1000000000000000',
    'requestId': '7907cb05f248e2cda73266426bdd3009557b112d385ea8baa1da79f1191f5df8',
    'requester': '0x5a0d3ab8219a1bd91be27f8cbd8e12cf3fe1fcf6',
    'specId': '3239666139616131336266313436383738386237636334613530306134356238',
}

client = tronpy.Tron(network="nile")

print('request from')
print(client.to_base58check_address(event['callbackAddr']))

reply_value = random.randint(0, 10000000000)

print('REPLY:', reply_value)

oracle = client.get_contract("TYZxQSHAhxGgUWzxYEZAohvWc9cQWXtNBt")

# fulfillOracleRequest(
#   bytes32 _requestId,
#   uint256 _payment,
#   address _callbackAddress,
#   bytes4 _callbackFunctionId,
#   uint256 _expiration,
#   bytes32 _data)
txn = (
    oracle.functions.fulfillOracleRequest(
        bytes.fromhex(event['requestId']),
        int(event['payment']),
        client.to_base58check_address(event['callbackAddr']),
        bytes.fromhex(event['callbackFunctionId'])[:4],
        int(event['cancelExpiration']),
        reply_value.to_bytes(32, 'big'),
    )
    .with_owner(ADDR)
    .fee_limit(5_000_000)
    .build()
    .sign(PRIV_KEY)
)

print(txn)
print(txn.broadcast().result())
