"""Structure and safety-invariant checks; not detector-accuracy validation."""
from pathlib import Path
from copy import deepcopy
import json
from jsonschema import Draft202012Validator, ValidationError

ROOT = Path(__file__).resolve().parents[1]
def read(path): return json.loads((ROOT / path).read_text(encoding="utf-8"))
def validate_result(result):
    Draft202012Validator(read("contracts/verification-result.schema.json")).validate(result)
    motors=result["motors"]
    ids=[m["motor_id"] for m in motors]
    if len(ids)!=len(set(ids)): raise ValueError("duplicate motor identity")
    for m in motors:
        box=m["bbox"]
        if box and (box[2]<=0 or box[3]<=0 or box[0]+box[2]>1.000001 or box[1]+box[3]>1.000001):
            raise ValueError("invalid normalized bounding box")
    if result["status"] in {"pass","incorrect_installation"}:
        if not result["reference_version"] or result["reference_version"]=="pending" or not result["engine_version"]:
            raise ValueError("reference/engine required")
        if not result["all_required_checks_observable"] or not motors or any(m["finding"]=="unknown" for m in motors):
            raise ValueError("required visual evidence unavailable")
        if result["reasons"]: raise ValueError("rejection reason cannot coexist with verified result")
        if any(not m["expected_type"] or not m["observed_type"] or not m["expected_orientation"] or not m["observed_orientation"] for m in motors):
            raise ValueError("incomplete class/orientation evidence")
    if result["status"]=="pass" and any(m["finding"]!="match" or m["observed_type"]!=m["expected_type"] or m["observed_orientation"]!=m["expected_orientation"] for m in motors):
        raise ValueError("unsafe Pass")
    if result["status"]=="incorrect_installation" and not any(m["finding"]=="mismatch" for m in motors):
        raise ValueError("incorrect result requires mismatch")

def validate_reference(ref):
    Draft202012Validator(read("contracts/reference.schema.json")).validate(ref)
    if ref["status"]=="pending" and ref["motors"]: raise ValueError("pending reference cannot imply a mapping")
    if ref["status"]=="verified":
        if not all(ref[k] for k in ["drone_variant","front_convention","source_evidence","supported_views","motors"]):
            raise ValueError("verified reference requires evidence and configuration")
        ids=[m["motor_id"] for m in ref["motors"]]
        if len(ids)!=len(set(ids)): raise ValueError("duplicate reference motor")

def main():
    for name in ["verification-result","reference"]:
        Draft202012Validator.check_schema(read(f"contracts/{name}.schema.json"))
    for path in (ROOT / "contracts/fixtures").glob("*.json"):
        validate_result(json.loads(path.read_text(encoding="utf-8")))
    validate_reference(read("reference/config/pending.json"))
    bundled_reference = ROOT / "apps/mobile/assets/reference.json"
    if bundled_reference.exists():
        validate_reference(read("apps/mobile/assets/reference.json"))
    base=read("contracts/fixtures/pass.json")
    mutations=[]
    for field,value in [("reference_version",None),("all_required_checks_observable",False),("reasons",["BLUR"]),("motors",[])]:
        bad=deepcopy(base); bad[field]=value; mutations.append(bad)
    for field,value in [("finding","mismatch"),("observed_type","wrong"),("bbox",[0.9,0,0.2,0.2])]:
        bad=deepcopy(base); bad["motors"][0][field]=value; mutations.append(bad)
    for bad in mutations:
        try: validate_result(bad)
        except (ValueError, ValidationError):
            pass
        else: raise AssertionError("unsafe mutation accepted")
    print(f"PASS: schemas, 4 labelled fixtures, pending reference, {len(mutations)} rejected unsafe mutations")

if __name__=="__main__": main()
