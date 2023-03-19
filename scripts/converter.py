import msgpack
import json
import argparse
from functools import singledispatch
from io import BytesIO, TextIOWrapper

parser = argparse.ArgumentParser(description='Convert MessagePack to JSON')
parser.add_argument('--from_json', action='store_true',
                    help='Convert from JSON to MessagePack')
parser.add_argument('--msg', type=str,
                    help='Use data from the command line argument')
parser.add_argument('--input', type=str,
                    help='Use data from a file')
parser.add_argument('--output', type=str,
                    help='Write result to a file')

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

buf = BytesIO()
if args.msg == None:
    f = open(args.input, mode="rb")
    buf.write(f.read())
    buf.seek(0)

output = TextIOWrapper
if args.output != None:
    output_mode = "wb" if args.from_json == True else "w"
    output = open(args.output, mode=output_mode)

if args.from_json:
    msg = msgpack.dumps(json.loads(buf.read() if args.msg == None else args.msg))
    if args.output:
        output.write(msg)
    else:
        print(msg)
else:
    json_string = ""
    if args.msg:
        bytes_array = bytes.fromhex(args.msg)
        json_string = (json.dumps(keys_to_strings(msgpack.loads(bytes_array, use_list=False, strict_map_key=False))))
    else:
        unpacker = msgpack.Unpacker(buf, raw=True, use_list=False, strict_map_key=False)
        message = []
        for unpacked in unpacker:
            message.append(unpacked)
        json_string = (json.dumps(keys_to_strings(message)))
    if args.output:
        output.write(json_string)
    else:
        print(json_string)
