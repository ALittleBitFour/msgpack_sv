import msgpack
import json
import argparse
from functools import singledispatch

parser = argparse.ArgumentParser(description='Convert MessagePack to JSON')
parser.add_argument('--from_json', action='store_true',
                    help='sum the integers (default: find the max)')
parser.add_argument('--msg', type=str,
                    help='an integer for the accumulator')
parser.add_argument('--file', type=str,
                    help='an integer for the accumulator')

args = parser.parse_args()

@singledispatch
def keys_to_strings(ob):
    return ob

@keys_to_strings.register
def _handle_dict(ob: dict):
    return {str(k): keys_to_strings(v) for k, v in ob.items()}

@keys_to_strings.register
def _handle_list(ob: list):
    return [keys_to_strings(v) for v in ob]           

if args.msg != None:
    print('\n')
    if args.from_json:
        print(msgpack.dumps(json.loads(args.msg)).hex())
    else:
        bytes_array = bytes.fromhex(args.msg)
        print(json.dumps(keys_to_strings(msgpack.loads(bytes_array, use_list=False, strict_map_key=False))))
else:
    print('\n')
    f = open(args.file)
    if args.from_json:
        print(msgpack.dumps(json.load(f)).hex())
    else:
        bytes_array = bytes.fromhex(f.read())
        print(json.dumps(keys_to_strings(msgpack.loads(bytes_array, use_list=False, strict_map_key=False))))
